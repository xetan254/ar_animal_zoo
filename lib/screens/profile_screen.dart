import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Nếu chưa đăng nhập -> Hiện nút đăng nhập
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hồ sơ'),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "Vui lòng đăng nhập để xem hồ sơ",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  "Đăng nhập",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Nếu đã đăng nhập -> Lấy dữ liệu từ Firestore
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseService().getUserStream(),
        builder: (context, snapshot) {
          // ✅ FIX 1: Kiểm tra connection state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ✅ FIX 2: Kiểm tra có dữ liệu không
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text("Không có dữ liệu người dùng"),
            );
          }

          // ✅ FIX 3: Cast an toàn với null check
          final docData = snapshot.data!.data();
          if (docData == null) {
            return const Center(
              child: Text("Dữ liệu người dùng bị lỗi"),
            );
          }

          final userData = docData as Map<String, dynamic>;

          // ✅ FIX 4: Lấy giá trị an toàn từ map
          final nickname = userData['nickname'] as String? ?? "Người dùng";
          final email = userData['email'] as String? ?? "Chưa có email";
          final birthYear = userData['birthYear'] as int? ?? 0;
          final province = userData['province'] as String? ?? "--";
          final createdAt = userData['createdAt'] as String? ?? "--";

          // Tính tuổi từ năm sinh
          int age = 0;
          if (birthYear > 0) {
            age = DateTime.now().year - birthYear;
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Avatar
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/images/bear.jpg'),
                ),
                const SizedBox(height: 16),

                // Tên người dùng
                Text(
                  nickname,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Email
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Thẻ thông tin
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.cake, color: Colors.green),
                          title: const Text("Năm sinh"),
                          trailing: Text(
                            birthYear > 0 ? "$birthYear" : "--",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.cake_outlined,
                              color: Colors.green),
                          title: const Text("Tuổi"),
                          trailing: Text(
                            age > 0 ? "$age tuổi" : "--",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.location_on,
                              color: Colors.green),
                          title: const Text("Tỉnh/Thành phố"),
                          trailing: Text(
                            province,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.calendar_today,
                              color: Colors.green),
                          title: const Text("Ngày tham gia"),
                          trailing: Text(
                            createdAt.split('T').first,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Nút đăng xuất
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseService().signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Đã đăng xuất")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      "Đăng xuất",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
