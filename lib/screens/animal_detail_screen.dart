import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/zoo_data.dart';
import '../services/firebase_service.dart'; // Import service để dùng hàm loveAnimal
// import 'ar_screen.dart'; // Bỏ comment nếu bạn đã có file màn hình AR

class AnimalDetailScreen extends StatefulWidget {
  final Animal animal;

  const AnimalDetailScreen({super.key, required this.animal});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  bool isFavorite = false;
  bool isLoading = true; // Trạng thái tải ban đầu
  final FirebaseService _firebaseService =
      FirebaseService(); // Khởi tạo Service

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  // 1. Kiểm tra trạng thái yêu thích ban đầu của User
  Future<void> _checkFavoriteStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          // Lấy mảng favorites từ Firestore
          List<dynamic> favorites = doc.data()?['favorites'] ?? [];
          // Kiểm tra xem ID con vật có trong mảng không
          if (favorites.contains(widget.animal.id)) {
            if (mounted) setState(() => isFavorite = true);
          }
        }
      } catch (e) {
        debugPrint("Lỗi kiểm tra yêu thích: $e");
      }
    }
    if (mounted) setState(() => isLoading = false);
  }

  // 2. Xử lý khi bấm nút Tim
  Future<void> toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;

    // Yêu cầu đăng nhập
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để lưu yêu thích!')),
      );
      return;
    }

    // Đảo ngược trạng thái UI ngay lập tức (Optimistic UI)
    setState(() {
      isFavorite = !isFavorite;
    });

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      if (isFavorite) {
        // --- TRƯỜNG HỢP: THÍCH (LIKE) ---

        // A. Thêm vào danh sách cá nhân của User
        await userRef.update({
          'favorites': FieldValue.arrayUnion([widget.animal.id])
        });

        // B. Tăng số lượng like toàn cục (Service)
        // Lưu ý: Đảm bảo 'id' của Animal trùng với Document ID trên Firebase
        await _firebaseService.loveAnimal(widget.animal.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Đã thích ${widget.animal.name} ❤️ (+1 lượt thích)'),
                duration: const Duration(seconds: 1)),
          );
        }
      } else {
        // --- TRƯỜNG HỢP: BỎ THÍCH (UNLIKE) ---

        // A. Xóa khỏi danh sách cá nhân
        await userRef.update({
          'favorites': FieldValue.arrayRemove([widget.animal.id])
        });

        // B. Giảm số lượng like toàn cục (Service)
        await _firebaseService.unLoveAnimal(widget.animal.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Đã bỏ yêu thích'),
                duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      // Nếu lỗi, quay ngược lại trạng thái UI cũ
      setState(() {
        isFavorite = !isFavorite;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Xử lý hiển thị ảnh (Asset hoặc Network)
    final imageProvider = (widget.animal.imagePath.startsWith('http'))
        ? NetworkImage(widget.animal.imagePath)
        : AssetImage(widget.animal.imagePath) as ImageProvider;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.animal.name),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                    size: 30,
                  ),
            onPressed: isLoading ? null : toggleFavorite,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Ảnh bìa
            Image(
              image: imageProvider,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 300,
                child: Center(child: Icon(Icons.broken_image, size: 50)),
              ),
            ),

            // Nội dung chi tiết
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.animal.name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    widget.animal.scientificName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Các thông tin chi tiết
                  _buildInfoRow(
                      Icons.place, "Môi trường sống", widget.animal.habitat),
                  _buildInfoRow(
                      Icons.restaurant, "Chế độ ăn", widget.animal.diet),
                  _buildInfoRow(
                      Icons.timer, "Tuổi thọ", widget.animal.lifespan),
                  _buildInfoRow(Icons.warning_amber_rounded, "Bảo tồn",
                      widget.animal.conservationStatus),

                  const Divider(height: 30),

                  const Text(
                    "Mô tả",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.animal.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 30),

                  // Nút xem AR
                  ElevatedButton.icon(
                    onPressed: () {
                      // Nếu bạn có màn hình AR, hãy dùng lệnh này:
                      /*
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ARScreen(animal: widget.animal),
                        ),
                      );
                      */
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Tính năng AR đang tải...")),
                      );
                    },
                    icon: const Icon(Icons.view_in_ar),
                    label: const Text('Xem trong không gian AR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.black),
                children: [
                  TextSpan(
                      text: "$label: ",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
