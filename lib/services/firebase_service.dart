import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // --- 1. QUẢN LÝ TÀI KHOẢN (AUTH) ---

  // Đăng ký (Có Rollback: Xóa user nếu lưu thông tin thất bại)
  Future<String?> signUp({
    required String email,
    required String password,
    required String nickname,
    required String age,
    required String location,
  }) async {
    UserCredential? userCredential;
    try {
      // B1: Tạo tài khoản Authentication
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // B2: Lưu thông tin chi tiết vào Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'nickname': nickname,
        'age': age,
        'location': location,
        'createdAt': FieldValue.serverTimestamp(),
        'favorites': [],
      });

      return null; // Thành công
    } on FirebaseAuthException catch (e) {
      return _translateAuthError(e.code);
    } catch (e) {
      // QUAN TRỌNG: Nếu lỗi ở bước B2 (lưu Firestore), xóa tài khoản B1 đi
      // để người dùng có thể đăng ký lại email này.
      if (userCredential != null) {
        await userCredential.user?.delete();
      }
      return "Lỗi hệ thống: $e. Vui lòng thử lại.";
    }
  }

  // Đăng nhập
  Future<String?> signIn(
      {required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return "Sai email hoặc mật khẩu.";
      }
      return "Lỗi đăng nhập: ${e.code}";
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
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

  // Lấy danh sách Động vật
  Stream<List<Animal>> getAnimalsStream() {
    return _firestore.collection('animals').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Animal.fromMap(doc.data())).toList();
    });
  }

  // Lấy danh sách Tin tức (Sắp xếp theo ngày mới nhất)
  Stream<List<NewsArticle>> getNewsStream() {
    return _firestore
        .collection('news')
        // .orderBy('date', descending: true) // Bỏ comment nếu muốn sắp xếp
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NewsArticle.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Upload dữ liệu mẫu (Chạy 1 lần)
  Future<void> seedData() async {
    final collection = _firestore.collection('animals');
    var snapshot = await collection.limit(1).get();
    if (snapshot.docs.isEmpty) {
      for (var animal in zooAnimals) {
        await collection.doc(animal.id).set(animal.toMap());
      }
    }
  }
}
