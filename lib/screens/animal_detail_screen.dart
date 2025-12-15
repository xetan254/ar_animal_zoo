import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Để dùng MethodChannel
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // Để mở CH Play
import '../data/zoo_data.dart';
import '../services/firebase_service.dart';
import 'ar_screen.dart';

class AnimalDetailScreen extends StatefulWidget {
  final Animal animal;
  const AnimalDetailScreen({super.key, required this.animal});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  bool isFavorite = false;
  bool isLoading = true;
  late int _currentFavoriteCount;
  final FirebaseService _firebaseService = FirebaseService();

  // Kênh giao tiếp với code Native (Kotlin)
  static const platform = MethodChannel('com.example.ar_animal_zoo/ar_check');

  @override
  void initState() {
    super.initState();
    _currentFavoriteCount = widget.animal.favoriteCount;
    _checkFavoriteStatus();
  }

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
        debugPrint("Error: $e");
      }
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cần đăng nhập để yêu thích!')));
      return;
    }
    setState(() {
      isFavorite = !isFavorite;
      isFavorite ? _currentFavoriteCount++ : _currentFavoriteCount--;
    });

    try {
      if (isFavorite) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'favorites': FieldValue.arrayUnion([widget.animal.id])
        });
        await _firebaseService.loveAnimal(widget.animal.id);
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'favorites': FieldValue.arrayRemove([widget.animal.id])
        });
        await _firebaseService.unLoveAnimal(widget.animal.id);
      }
    } catch (e) {
      setState(() {
        isFavorite = !isFavorite;
        isFavorite ? _currentFavoriteCount++ : _currentFavoriteCount--;
      });
    }
  }

  // --- HÀM KIỂM TRA VÀ MỞ AR ---
  Future<void> _checkAndOpenAR() async {
    try {
      // 1. Gọi code Kotlin để kiểm tra
      final bool isInstalled = await platform.invokeMethod('isARCoreInstalled');

      if (!mounted) return;

      if (isInstalled) {
        // 2. Nếu đã cài, vào màn hình AR bình thường
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ARScreen(animal: widget.animal)));
      } else {
        // 3. Nếu chưa cài, hiện thông báo
        _showInstallDialog();
      }
    } on PlatformException catch (e) {
      debugPrint("Lỗi kiểm tra AR: '${e.message}'.");
      // Nếu lỗi (ví dụ chạy trên iOS hoặc máy quá cũ), cứ thử mở đại
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ARScreen(animal: widget.animal)));
    }
  }

  void _showInstallDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Yêu cầu ARCore",
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: Text(
            "Để xem chế độ thực tế ảo (AR), thiết bị của bạn cần cài đặt 'Google Play Services for AR'.",
            style: GoogleFonts.roboto()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text("Để sau", style: GoogleFonts.roboto(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              _openStore();
            },
            child: Text("Tải ngay",
                style: GoogleFonts.roboto(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _openStore() async {
    // Link trực tiếp đến ARCore trên CH Play
    final Uri url = Uri.parse(
        "https://play.google.com/store/apps/details?id=com.google.ar.core");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Không thể mở cửa hàng ứng dụng")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = (widget.animal.imagePath.startsWith('http'))
        ? NetworkImage(widget.animal.imagePath)
        : AssetImage(widget.animal.imagePath) as ImageProvider;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 320.0,
            pinned: true,
            backgroundColor: Colors.green,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.animal.name,
                  style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        const Shadow(color: Colors.black45, blurRadius: 10)
                      ])),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image(image: imageProvider, fit: BoxFit.cover),
                  const DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black26]))),
                ],
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle),
                child: IconButton(
                  icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.redAccent : Colors.white),
                  onPressed: isLoading ? null : toggleFavorite,
                ),
              )
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(widget.animal.scientificName,
                              style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600]))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [
                          const Icon(Icons.favorite,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Text("$_currentFavoriteCount",
                              style: GoogleFonts.roboto(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold))
                        ]),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildInfoChip(Icons.place, "Môi trường",
                          widget.animal.habitat, Colors.blue),
                      _buildInfoChip(Icons.restaurant, "Chế độ ăn",
                          widget.animal.diet, Colors.orange),
                      _buildInfoChip(Icons.timer, "Tuổi thọ",
                          widget.animal.lifespan, Colors.purple),
                      _buildInfoChip(Icons.verified_user, "Bảo tồn",
                          widget.animal.conservationStatus, Colors.teal),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text("Thông tin chi tiết",
                      style: GoogleFonts.roboto(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(widget.animal.description,
                      style: GoogleFonts.roboto(
                          fontSize: 16, height: 1.6, color: Colors.grey[800]),
                      textAlign: TextAlign.justify),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ]),
        child: ElevatedButton.icon(
          // SỬA: Gọi hàm kiểm tra thay vì push trực tiếp
          onPressed: _checkAndOpenAR,
          icon: const Icon(Icons.view_in_ar),
          label: Text('Xem mô hình AR 3D',
              style: GoogleFonts.roboto(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 5,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.roboto(
                    fontSize: 12, color: color, fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}
