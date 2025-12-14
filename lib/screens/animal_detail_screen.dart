import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ar_animal_zoo/data/zoo_data.dart';

class AnimalDetailScreen extends StatefulWidget {
  final Animal animal;

  const AnimalDetailScreen({super.key, required this.animal});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  bool isFavorite = false;
  bool isLoading = true; // Biến để chờ load trạng thái ban đầu

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  // Kiểm tra xem con vật này đã được like chưa
  Future<void> _checkFavoriteStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          List<dynamic> favorites = doc.data()?['favorites'] ?? [];
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

  // Hàm xử lý khi bấm nút tim
  Future<void> toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để lưu yêu thích!')),
      );
      return;
    }

    // Đổi trạng thái UI ngay lập tức cho mượt (Optimistic UI update)
    setState(() {
      isFavorite = !isFavorite;
    });

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      if (isFavorite) {
        // Thêm vào mảng favorites
        await userRef.update({
          'favorites': FieldValue.arrayUnion([widget.animal.id])
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Đã thêm ${widget.animal.name} vào yêu thích ❤️'),
                duration: const Duration(seconds: 1)),
          );
        }
      } else {
        // Xóa khỏi mảng favorites
        await userRef.update({
          'favorites': FieldValue.arrayRemove([widget.animal.id])
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Đã bỏ yêu thích'),
                duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      // Nếu lỗi thì hoàn tác lại UI
      setState(() {
        isFavorite = !isFavorite;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Image.asset(
              widget.animal.imagePath,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
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
                      // Logic điều hướng sang màn hình AR
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
