import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  // Hàm tạo link avatar từ tên (Hoặc dùng link ảnh thật nếu có)
  String _getAvatarUrl(User? user) {
    if (user == null) return '';

    // 1. Ưu tiên ảnh thật nếu user đã từng có (ví dụ ảnh từ Google Sign-In)
    if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      return user.photoURL!;
    }

    // 2. Nếu không có ảnh thật, dùng UI Avatars
    // Lấy tên hiển thị, nếu null thì lấy "User"
    String name = user.displayName ?? "User";
    if (name.isEmpty) name = "User";

    // Tạo link: encodeComponent để xử lý tên có dấu hoặc khoảng trắng
    return "https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&color=fff&size=256";
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

        // Lấy link ảnh đã xử lý
        String finalAvatarUrl = _getAvatarUrl(user);

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
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          // Nếu đã login -> Load ảnh từ link (UI Avatar hoặc Google)
                          // Nếu chưa login -> Hiện null để fallback xuống child icon
                          backgroundImage:
                              (isLoggedIn && finalAvatarUrl.isNotEmpty)
                                  ? NetworkImage(finalAvatarUrl)
                                  : null,
                          child: (isLoggedIn && finalAvatarUrl.isNotEmpty)
                              ? null
                              : const Icon(Icons.person,
                                  size: 60, color: Colors.grey),
                        ),
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
                        isLoggedIn: true,
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
                        isLoggedIn: isLoggedIn,
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
                        isLoggedIn: isLoggedIn,
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
                        isLoggedIn: true,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AboutScreen())),
                      ),
                      const SizedBox(height: 20),

                      // Nút Đăng xuất
                      if (isLoggedIn)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await FirebaseService().signOut();
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isLoggedIn ? Colors.black87 : Colors.grey,
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
