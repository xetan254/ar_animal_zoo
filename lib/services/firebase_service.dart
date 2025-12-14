import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/zoo_data.dart';

// Model cho Tin tức
class NewsArticle {
  final String id;
  final String title;
  final String imageUrl;
  final String content;
  final String date;
  final String author;

  NewsArticle({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.content,
    required this.date,
    required this.author,
  });

  factory NewsArticle.fromMap(String id, Map<String, dynamic> map) {
    return NewsArticle(
      id: id,
      title: map['title'] ?? 'Không có tiêu đề',
      imageUrl: map['imageUrl'] ?? '',
      content: map['content'] ?? '',
      date: map['date'] ?? '',
      author: map['author'] ?? 'Admin',
    );
  }
}

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- 0. LẤY DỮ LIỆU TỈNH THÀNH TỪ API ---
  Future<List<String>> getProvinces() async {
    try {
      final response = await http
          .get(Uri.parse('https://provinces.open-api.vn/api/?depth=1'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item['name'] as String).toList();
      } else {
        debugPrint("❌ Error fetching provinces: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching provinces: $e");
      return [];
    }
  }

  // --- 1. QUẢN LÝ TÀI KHOẢN (AUTH) ---

  // ✅ HÀM KIỂM TRA EMAIL ĐÃ TỒN TẠI TRONG FIRESTORE
  Future<bool> isEmailExists(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint("❌ Error checking email: $e");
      return false;
    }
  }

  // Đăng ký
  Future<String?> signUp({
    required String email,
    required String password,
    required String nickname,
    required int birthYear,
    required String province,
  }) async {
    email = email.trim();

    try {
      bool emailExists = await isEmailExists(email);
      if (emailExists) {
        debugPrint("❌ Email already exists: $email");
        return "Email này đã được sử dụng.";
      }
      debugPrint("✅ Email is available: $email");
    } catch (e) {
      debugPrint("❌ Error checking email existence: $e");
      return "Không thể kiểm tra email. Vui lòng thử lại.";
    }

    UserCredential? userCredential;
    try {
      debugPrint("📝 Starting registration for: $email");

      // B1: Tạo tài khoản Authentication
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;
      if (uid == null) {
        throw Exception("Không thể lấy UID người dùng");
      }

      // B2: Lưu thông tin chi tiết vào Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'nickname': nickname,
        'birthYear': birthYear,
        'province': province,
        'createdAt': DateTime.now().toIso8601String(),
        'photoUrl': '',
        'favorites': [],
      });

      debugPrint("✅ Registration completed successfully!");
      return null; // Thành công
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Firebase Auth Error: ${e.code} - ${e.message}");
      if (e.code == 'email-already-in-use') {
        return "Email này đã được sử dụng.";
      }
      return _translateAuthError(e.code);
    } on FirebaseException catch (e) {
      debugPrint("❌ Firebase Error: ${e.code} - ${e.message}");
      // Rollback
      if (userCredential != null) {
        try {
          await userCredential.user?.delete();
        } catch (_) {}
      }
      return "Lỗi lưu dữ liệu: ${e.message}";
    } catch (e) {
      debugPrint("❌ Unexpected Error: ${e.runtimeType} - $e");
      // Rollback
      if (userCredential != null) {
        try {
          await userCredential.user?.delete();
        } catch (_) {}
      }
      return "Lỗi hệ thống: $e";
    }
  }

  // Đăng nhập
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint("✅ User signed in: $email");
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Sign In Error: ${e.code}");
      if (e.code == 'user-not-found') return "Email không tồn tại.";
      if (e.code == 'wrong-password') return "Mật khẩu sai.";
      if (e.code == 'invalid-credential') return "Email hoặc mật khẩu sai.";
      return "Lỗi đăng nhập: ${e.code}";
    } catch (e) {
      debugPrint("❌ Sign In Error: $e");
      return "Lỗi hệ thống. Vui lòng thử lại.";
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
    debugPrint("✅ User signed out");
  }

  // Dịch mã lỗi sang tiếng Việt
  String _translateAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (cần > 6 ký tự).';
      case 'operation-not-allowed':
        return 'Tính năng này chưa được bật.';
      default:
        return 'Lỗi: $code';
    }
  }

  // --- 2. LẤY DỮ LIỆU (DATA) ---

  // Lấy thông tin User hiện tại
  Stream<DocumentSnapshot> getUserStream() {
    if (_auth.currentUser == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .snapshots();
  }

  // --- 3. UPLOAD AVATAR ---
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return "Chưa đăng nhập";

      final ref = _storage.ref().child('user_avatars/${user.uid}.jpg');
      await ref.putFile(imageFile);
      final imageUrl = await ref.getDownloadURL();
      await user.updatePhotoURL(imageUrl);

      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': imageUrl,
      });

      return null;
    } catch (e) {
      debugPrint("Lỗi upload ảnh: $e");
      return "Lỗi upload: $e";
    }
  }

  // Cập nhật thông tin User
  Future<String?> updateUserProfile({
    required String nickname,
    required int birthYear,
    required String province,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return "Chưa đăng nhập";

      await _firestore.collection('users').doc(uid).update({
        'nickname': nickname,
        'birthYear': birthYear,
        'province': province,
      });
      debugPrint("✅ Profile updated");
      return null;
    } catch (e) {
      return "Lỗi cập nhật: $e";
    }
  }

  // Lấy danh sách Động vật
  Stream<List<Animal>> getAnimalsStream() {
    return _firestore.collection('animals').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Animal.fromMap(doc.data())).toList();
    });
  }

  // Lấy danh sách Tin tức
  Stream<List<NewsArticle>> getNewsStream() {
    return _firestore.collection('news').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return NewsArticle.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // --- 4. CÁC HÀM MỚI (FIX LỖI) ---

  // ✅ [MỚI] Hàm lấy thú nổi bật (KHẮC PHỤC LỖI undefined_method)
  Future<List<Map<String, dynamic>>> getFeaturedAnimals() async {
    try {
      final snapshot = await _firestore
          .collection('animals')
          .orderBy('likes', descending: true)
          .limit(6)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Không tên',
          'image': data['imagePath'] ?? '',
          'likes': data['likes'] ?? 0,
        };
      }).toList();
    } catch (e) {
      debugPrint("Lỗi lấy thú nổi bật: $e");
      return [];
    }
  }

  // ✅ [SỬA] Hàm lấy thời tiết theo tọa độ (Đã sửa lỗi cú pháp 'catch (e) {a')
  Future<Map<String, dynamic>?> fetchWeather(double lat, double lon) async {
    // ⚠️ Thay API Key của bạn vào đây
    const apiKey = '73106710a0fed9e9783784aeed44bf93';

    try {
      final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=vi');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Lỗi API thời tiết: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // <-- Đã xóa chữ 'a' thừa ở đây
      debugPrint('Lỗi gọi API thời tiết: $e');
      return null;
    }
  }
}
