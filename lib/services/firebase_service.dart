import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/zoo_data.dart'; // Đảm bảo model Animal của bạn ở đúng đường dẫn này

// --- MODEL CHO TIN TỨC ---
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

// --- SERVICE CHÍNH ---
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==========================================
  // 0. API & TIỆN ÍCH KHÁC
  // ==========================================

  // Lấy danh sách tỉnh thành Việt Nam
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

  // Lấy thời tiết theo tọa độ (OpenWeatherMap)
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
      debugPrint('Lỗi gọi API thời tiết: $e');
      return null;
    }
  }

  // ==========================================
  // 1. QUẢN LÝ TÀI KHOẢN (AUTH)
  // ==========================================

  // Kiểm tra email đã tồn tại trong Firestore chưa
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

  // Đăng ký tài khoản mới
  Future<String?> signUp({
    required String email,
    required String password,
    required String nickname,
    required int birthYear,
    required String province,
  }) async {
    email = email.trim();

    try {
      // Kiểm tra trùng email logic nghiệp vụ
      bool emailExists = await isEmailExists(email);
      if (emailExists) {
        return "Email này đã được sử dụng.";
      }

      UserCredential? userCredential;
      try {
        // B1: Tạo tài khoản Auth
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final uid = userCredential.user?.uid;
        if (uid == null) throw Exception("Không thể lấy UID");

        // B2: Lưu data vào Firestore
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

        return null; // Thành công
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          return "Email này đã được sử dụng.";
        }
        return _translateAuthError(e.code);
      } catch (e) {
        // Rollback nếu lỗi khi lưu Firestore
        if (userCredential != null) await userCredential.user?.delete();
        return "Lỗi hệ thống: $e";
      }
    } catch (e) {
      return "Lỗi không xác định: $e";
    }
  }

  // Đăng nhập
  Future<String?> signIn(
      {required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return "Email không tồn tại.";
      if (e.code == 'wrong-password') return "Mật khẩu sai.";
      if (e.code == 'invalid-credential') return "Email hoặc mật khẩu sai.";
      return "Lỗi đăng nhập: ${e.code}";
    } catch (e) {
      return "Lỗi hệ thống. Vui lòng thử lại.";
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Upload Avatar lên Storage
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return "Chưa đăng nhập";

      final ref = _storage.ref().child('user_avatars/${user.uid}.jpg');
      await ref.putFile(imageFile);
      final imageUrl = await ref.getDownloadURL();

      // Update cả Auth Profile và Firestore
      await user.updatePhotoURL(imageUrl);
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': imageUrl,
      });

      return null;
    } catch (e) {
      return "Lỗi upload: $e";
    }
  }

  // Cập nhật thông tin profile
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
      return null;
    } catch (e) {
      return "Lỗi cập nhật: $e";
    }
  }

  // Dịch mã lỗi Auth
  String _translateAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (cần > 6 ký tự).';
      default:
        return 'Lỗi: $code';
    }
  }

  // ==========================================
  // 2. DỮ LIỆU ĐỘNG VẬT & TIN TỨC
  // ==========================================

  // Stream User hiện tại
  Stream<DocumentSnapshot> getUserStream() {
    if (_auth.currentUser == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .snapshots();
  }

  // Lấy danh sách Động vật (Real-time)
  Stream<List<Animal>> getAnimalsStream() {
    return _firestore.collection('animals').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Lưu ý: Đảm bảo class Animal.fromMap xử lý cả ID nếu cần
        return Animal.fromMap(doc.data());
      }).toList();
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

  // Lấy thú nổi bật (Top likes)
  Future<List<Map<String, dynamic>>> getFeaturedAnimals() async {
    try {
      final snapshot = await _firestore
          .collection('animals')
          .orderBy('likes', descending: true) // Sắp xếp theo field 'likes'
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

  // ==========================================
  // 3. TƯƠNG TÁC (YÊU THÍCH / LIKE) - MỚI
  // ==========================================

  // ✅ Hàm tăng lượt thích (Increment Like)
  Future<void> loveAnimal(String animalId) async {
    try {
      // FieldValue.increment(1) giúp tăng an toàn, tránh race condition
      await _firestore.collection('animals').doc(animalId).update({
        'likes': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint("Lỗi khi yêu thích: $e");
      rethrow;
    }
  }

  // ✅ (Tuỳ chọn) Hàm bỏ thích (Decrement Like)
  Future<void> unLoveAnimal(String animalId) async {
    try {
      await _firestore.collection('animals').doc(animalId).update({
        'likes': FieldValue.increment(-1),
      });
    } catch (e) {
      debugPrint("Lỗi khi bỏ thích: $e");
    }
  }
}
