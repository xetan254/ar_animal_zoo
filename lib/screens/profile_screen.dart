import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:image_picker/image_picker.dart';
import 'package:ar_animal_zoo/services/firebase_service.dart';
import 'package:ar_animal_zoo/screens/auth_screen.dart';

// Import sub-screens
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

  // Helper to generate avatar URL
  String _getAvatarUrl(User? user, String? firestoreNickname) {
    if (user == null) return '';

    // 1. Prioritize real photo if available
    if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      return user.photoURL!;
    }

    // 2. Use Nickname from Firestore, fallback to "User"
    String nameToUse =
        (firestoreNickname != null && firestoreNickname.isNotEmpty)
            ? firestoreNickname
            : "User";

    return "https://ui-avatars.com/api/?name=${Uri.encodeComponent(nameToUse)}&background=random&color=fff&size=256";
  }

  Future<void> _pickAndUploadImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      File file = File(pickedFile.path);
      String? error = await FirebaseService().uploadAvatar(file);
      setState(() => _isUploading = false);

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Cập nhật ảnh đại diện thành công!"),
              backgroundColor: Colors.green));
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Listen to Authentication State
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final bool isLoggedIn = user != null;

        if (!isLoggedIn) {
          return _buildUI(context,
              isLoggedIn: false,
              displayName: 'Chưa đăng nhập',
              email: 'Vui lòng đăng nhập',
              user: null,
              firestoreNickname: null);
        }

        // 2. Listen to Firestore Data (To get 'nickname')
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseService().getUserStream(),
          builder: (context, snapshot) {
            String displayName = 'Loading...';
            String? firestoreNickname;

            if (snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              // Get nickname from Firestore
              firestoreNickname = data['nickname'];
              displayName =
                  firestoreNickname ?? user.displayName ?? 'Người dùng';
            } else {
              displayName = user.displayName ?? 'Người dùng';
            }

            return _buildUI(context,
                isLoggedIn: true,
                displayName: displayName,
                email: user.email ?? '',
                user: user,
                firestoreNickname: firestoreNickname);
          },
        );
      },
    );
  }

  Widget _buildUI(
    BuildContext context, {
    required bool isLoggedIn,
    required String displayName,
    required String email,
    required User? user,
    required String? firestoreNickname,
  }) {
    final avatarUrl = _getAvatarUrl(user, firestoreNickname);

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
            // HEADER
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
                                radius: 60, child: CircularProgressIndicator())
                            : CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                backgroundImage:
                                    (isLoggedIn && avatarUrl.isNotEmpty)
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                child: (isLoggedIn && avatarUrl.isNotEmpty)
                                    ? null
                                    : const Icon(Icons.person,
                                        size: 60, color: Colors.grey),
                              ),
                      ),
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
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(displayName,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold)), // Correct name displayed
                  const SizedBox(height: 5),
                  Text(email,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600])),

                  if (!isLoggedIn)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AuthScreen())),
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
            // MENU
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildMenuItem(
                      context,
                      Icons.favorite,
                      'Động vật yêu thích',
                      Colors.redAccent,
                      isLoggedIn,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const FavoriteAnimalsScreen()))),
                  _buildMenuItem(
                      context,
                      Icons.smart_toy_outlined,
                      'Chat Box AI',
                      Colors.blueAccent,
                      true,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AiChatScreen()))),
                  const Divider(height: 30),
                  _buildMenuItem(
                      context,
                      Icons.person_outline,
                      'Thông tin cá nhân',
                      Colors.green,
                      isLoggedIn,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PersonalInfoScreen()))),
                  _buildMenuItem(
                      context,
                      Icons.lock_outline,
                      'Đổi mật khẩu',
                      Colors.orange,
                      isLoggedIn,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen()))),
                  _buildMenuItem(
                      context,
                      Icons.info_outline,
                      'Giới thiệu về ARZoo',
                      Colors.purple,
                      true,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AboutScreen()))),
                  const SizedBox(height: 20),
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
                            padding: const EdgeInsets.symmetric(vertical: 12)),
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
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String text,
      Color color, bool isLoggedIn, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color)),
        title: Text(text,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isLoggedIn ? Colors.black87 : Colors.grey)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          if (isLoggedIn) {
            onTap();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Bạn cần đăng nhập để sử dụng tính năng này!")));
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        tileColor: Colors.white,
      ),
    );
  }
}
