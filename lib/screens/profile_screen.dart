import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // Cần import package này
import 'package:ar_animal_zoo/services/firebase_service.dart';
import 'package:ar_animal_zoo/screens/auth_screen.dart';

// Import các màn hình con
import 'package:ar_animal_zoo/screens/favorite_animals_screen.dart';
import 'package:ar_animal_zoo/screens/ai_chat_screen.dart';
import 'package:ar_animal_zoo/screens/personal_info_screen.dart';
import 'package:ar_animal_zoo/screens/change_password_screen.dart';
import 'package:ar_animal_zoo/screens/about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;

  // Hàm chọn ảnh và upload
  Future<void> _pickAndUploadImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Không cho sửa nếu chưa đăng nhập

    final picker = ImagePicker();
    // Chọn ảnh từ thư viện
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isUploading = true);

      File file = File(pickedFile.path);
      String? error = await FirebaseService().uploadAvatar(file);

      setState(() => _isUploading = false);

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Cập nhật ảnh đại diện thành công!"),
                backgroundColor: Colors.green),
          );
          // Gọi setState rỗng để UI vẽ lại ảnh mới (do user.photoURL đã đổi)
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe trạng thái đăng nhập realtime
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final bool isLoggedIn = user != null;

        // Dữ liệu hiển thị
        String displayName = isLoggedIn
            ? (user.displayName ?? 'Chưa đặt tên')
            : 'Chưa đăng nhập';
        String email = isLoggedIn
            ? (user.email ?? '')
            : 'Vui lòng đăng nhập để sử dụng đầy đủ tính năng';
        String photoUrl = isLoggedIn ? (user.photoURL ?? '') : '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hồ sơ cá nhân'),
            centerTitle: true,
            backgroundColor: Colors.green,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // --- PHẦN 1: HEADER (AVATAR & INFO) ---
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 5)),
                              ],
                            ),
                            child: _isUploading
                                ? const CircleAvatar(
                                    radius: 60,
                                    child: CircularProgressIndicator())
                                : CircleAvatar(
                                    radius: 60,
                                    backgroundImage: (isLoggedIn &&
                                            photoUrl.isNotEmpty)
                                        ? NetworkImage(photoUrl)
                                        : null, // Nếu null thì dùng child bên dưới
                                    child: (isLoggedIn && photoUrl.isNotEmpty)
                                        ? null
                                        : const Icon(Icons.person,
                                            size: 60, color: Colors.grey),
                                  ),
                          ),
                          // Nút Camera nhỏ để đổi ảnh (chỉ hiện khi đã đăng nhập)
                          if (isLoggedIn)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickAndUploadImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        displayName,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        email,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),

                      // Nút Đăng nhập nếu chưa login
                      if (!isLoggedIn)
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (_) => const AuthScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            child: const Text("Đăng nhập ngay",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // --- PHẦN 2: MENU CHỨC NĂNG ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.favorite,
                        text: 'Động vật yêu thích',
                        color: Colors.redAccent,
                        isLoggedIn: isLoggedIn,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FavoriteAnimalsScreen())),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.smart_toy_outlined,
                        text: 'Chat Box AI',
                        color: Colors.blueAccent,
                        isLoggedIn:
                            true, // Chat có thể cho dùng thử hoặc bắt buộc login tùy bạn
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AiChatScreen())),
                      ),
                      const Divider(height: 30),

                      _buildMenuItem(
                        context,
                        icon: Icons.person_outline,
                        text: 'Thông tin cá nhân',
                        color: Colors.green,
                        isLoggedIn: isLoggedIn, // Bắt buộc login
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PersonalInfoScreen())),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.lock_outline,
                        text: 'Đổi mật khẩu',
                        color: Colors.orange,
                        isLoggedIn: isLoggedIn, // Bắt buộc login
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ChangePasswordScreen())),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.info_outline,
                        text: 'Giới thiệu về ARZoo',
                        color: Colors.purple,
                        isLoggedIn: true, // Ai cũng xem được
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AboutScreen())),
                      ),
                      const SizedBox(height: 20),

                      // Nút Đăng xuất (Chỉ hiện khi đã đăng nhập)
                      if (isLoggedIn)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await FirebaseService().signOut();
                              // Không cần navigator push vì StreamBuilder sẽ tự render lại giao diện Guest
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Đăng xuất'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
    required bool isLoggedIn,
  }) {
    // Nếu yêu cầu login mà chưa login thì làm mờ đi hoặc disable
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), // Đã sửa lỗi deprecated
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isLoggedIn
                ? Colors.black87
                : Colors.grey, // Làm mờ text nếu chưa login
          ),
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          if (isLoggedIn) {
            onTap();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Bạn cần đăng nhập để sử dụng tính năng này!")),
            );
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        tileColor: Colors.white,
      ),
    );
  }
}
