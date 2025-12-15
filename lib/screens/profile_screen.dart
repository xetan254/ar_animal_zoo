import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ar_animal_zoo/services/firebase_service.dart';
import 'package:ar_animal_zoo/screens/auth_screen.dart';
// Import sub-screens...
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

  String _getAvatarUrl(User? user, String? firestoreNickname) {
    if (user == null) return '';
    if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      return user.photoURL!;
    }
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
      String? error =
          await FirebaseService().uploadAvatar(File(pickedFile.path));
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error ?? "Cập nhật thành công!"),
            backgroundColor: error == null ? Colors.green : Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final bool isLoggedIn = user != null;

        if (!isLoggedIn) {
          return _buildUI(context,
              isLoggedIn: false,
              displayName: 'Khách',
              email: 'Đăng nhập để lưu dữ liệu',
              user: null,
              firestoreNickname: null);
        }
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseService().getUserStream(),
          builder: (context, snapshot) {
            String displayName = 'Loading...';
            String? firestoreNickname;
            if (snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
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

  Widget _buildUI(BuildContext context,
      {required bool isLoggedIn,
      required String displayName,
      required String email,
      required User? user,
      required String? firestoreNickname}) {
    final avatarUrl = _getAvatarUrl(user, firestoreNickname);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Hồ sơ cá nhân',
            style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // Avatar & Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10)
                  ]),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: (isLoggedIn && avatarUrl.isNotEmpty)
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: _isUploading
                            ? const CircularProgressIndicator()
                            : ((!isLoggedIn || avatarUrl.isEmpty)
                                ? const Icon(Icons.person,
                                    size: 50, color: Colors.grey)
                                : null),
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
                                    color: Colors.green,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 18)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(displayName,
                      style: GoogleFonts.roboto(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(email,
                      style:
                          GoogleFonts.roboto(fontSize: 14, color: Colors.grey)),
                  if (!isLoggedIn)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AuthScreen())),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: const StadiumBorder()),
                        child: Text("Đăng nhập / Đăng ký",
                            style: GoogleFonts.roboto(color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Menu Options
            _buildSectionTitle("Tiện ích"),
            _buildMenuCard([
              _buildMenuItem(
                  context,
                  Icons.favorite_rounded,
                  'Động vật yêu thích',
                  Colors.redAccent,
                  isLoggedIn,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FavoriteAnimalsScreen()))),
              _buildMenuItem(
                  context,
                  Icons.smart_toy_rounded,
                  'Trợ lý ảo AI',
                  Colors.blueAccent,
                  true,
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AIChatScreen()))),
            ]),

            const SizedBox(height: 20),
            _buildSectionTitle("Tài khoản"),
            _buildMenuCard([
              _buildMenuItem(
                  context,
                  Icons.person_rounded,
                  'Thông tin cá nhân',
                  Colors.green,
                  isLoggedIn,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PersonalInfoScreen()))),
              _buildMenuItem(
                  context,
                  Icons.lock_rounded,
                  'Đổi mật khẩu',
                  Colors.orange,
                  isLoggedIn,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen()))),
            ]),

            const SizedBox(height: 20),
            _buildSectionTitle("Khác"),
            _buildMenuCard([
              _buildMenuItem(
                  context,
                  Icons.info_rounded,
                  'Giới thiệu',
                  Colors.purple,
                  true,
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()))),
              if (isLoggedIn)
                ListTile(
                  leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.logout, color: Colors.grey)),
                  title: Text('Đăng xuất',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w500)),
                  onTap: () async => await FirebaseService().signOut(),
                ),
            ]),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Align(
          alignment: Alignment.centerLeft,
          child: Text(title,
              style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700]))));

  Widget _buildMenuCard(List<Widget> children) => Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)
          ]),
      child: Column(children: children));

  Widget _buildMenuItem(BuildContext context, IconData icon, String text,
      Color color, bool isLoggedIn, VoidCallback onTap) {
    return ListTile(
      leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color)),
      title: Text(text,
          style: GoogleFonts.roboto(
              fontWeight: FontWeight.w500,
              color: isLoggedIn ? Colors.black87 : Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 16, color: Colors.grey),
      onTap: isLoggedIn
          ? onTap
          : () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Vui lòng đăng nhập!"))),
    );
  }
}
