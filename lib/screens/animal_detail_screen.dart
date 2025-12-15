import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/zoo_data.dart';
import '../services/firebase_service.dart';
import 'ar_screen.dart'; // ✅ Đã import màn hình AR

class AnimalDetailScreen extends StatefulWidget {
  final Animal animal;

  const AnimalDetailScreen({super.key, required this.animal});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  bool isFavorite = false;
  bool isLoading = true;

  // ✅ Biến này để hiển thị số like tăng/giảm ngay lập tức trên UI
  late int _currentFavoriteCount;

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _currentFavoriteCount =
        widget.animal.favoriteCount; // Khởi tạo giá trị ban đầu
    _checkFavoriteStatus();
  }

  // 1. Kiểm tra trạng thái yêu thích ban đầu
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

  // 2. Xử lý khi bấm nút Tim
  Future<void> toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để lưu yêu thích!')),
      );
      return;
    }

    // ✅ Optimistic UI: Cập nhật giao diện NGAY LẬP TỨC trước khi gọi server
    setState(() {
      isFavorite = !isFavorite;
      if (isFavorite) {
        _currentFavoriteCount++; // Tăng số hiển thị
      } else {
        _currentFavoriteCount--; // Giảm số hiển thị
      }
    });

    try {
      if (isFavorite) {
        // --- THÍCH ---
        // 1. Lưu vào danh sách cá nhân
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'favorites': FieldValue.arrayUnion([widget.animal.id])
        });
        // 2. Tăng counter trên server
        await _firebaseService.loveAnimal(widget.animal.id);
      } else {
        // --- BỎ THÍCH ---
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'favorites': FieldValue.arrayRemove([widget.animal.id])
        });
        await _firebaseService.unLoveAnimal(widget.animal.id);
      }
    } catch (e) {
      // Nếu lỗi mạng, hoàn tác lại UI
      setState(() {
        isFavorite = !isFavorite;
        if (isFavorite) {
          _currentFavoriteCount++;
        } else {
          _currentFavoriteCount--;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Xử lý ảnh
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.animal.name,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      // ✅ Hiển thị số lượt thích real-time
                      Row(
                        children: [
                          const Icon(Icons.favorite,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            "$_currentFavoriteCount",
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                        ],
                      )
                    ],
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

                  const Text("Mô tả",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    widget.animal.description,
                    style: const TextStyle(
                        fontSize: 16, height: 1.6, color: Colors.black87),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 30),

                  // ✅ NÚT XEM AR ĐÃ ĐƯỢC KÍCH HOẠT
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ARScreen(animal: widget.animal),
                        ),
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
                          borderRadius: BorderRadius.circular(12)),
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
