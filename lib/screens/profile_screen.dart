import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import 'auth_screen.dart'; // Bạn cần tạo trang đăng nhập (xem bên dưới)

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Nếu chưa đăng nhập -> Hiện nút đăng nhập
    if (user == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              // Điều hướng tới trang đăng nhập
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()));
            },
            child: const Text("Vui lòng đăng nhập"),
          ),
        ),
      );
    }

    // Nếu đã đăng nhập -> Lấy dữ liệu từ Firestore
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ'), backgroundColor: Colors.green),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseService().getUserStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/images/bear.jpg')),
              const SizedBox(height: 10),
              Text(userData['nickname'] ?? "No Name",
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              Text("Email: ${userData['email']}"),
              const SizedBox(height: 20),

              // Thẻ thông tin
              Card(
                margin: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                        title: const Text("Tuổi"),
                        trailing: Text(userData['age'] ?? "--")),
                    const Divider(),
                    ListTile(
                        title: const Text("Nơi sống"),
                        trailing: Text(userData['location'] ?? "--")),
                  ],
                ),
              ),

              ElevatedButton(
                onPressed: () => FirebaseService().signOut(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Đăng xuất",
                    style: TextStyle(color: Colors.white)),
              )
            ],
          );
        },
      ),
    );
  }
}
