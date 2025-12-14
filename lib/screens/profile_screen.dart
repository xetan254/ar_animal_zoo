import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // THAY ĐỔI QUAN TRỌNG:
    // Dùng StreamBuilder lắng nghe sự thay đổi trạng thái đăng nhập (Login/Logout)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 1. Nếu đang chờ kiểm tra trạng thái đăng nhập
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        // 2. NẾU CHƯA ĐĂNG NHẬP (user == null) -> Hiện giao diện yêu cầu login
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
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

        // 3. NẾU ĐÃ ĐĂNG NHẬP -> Hiện giao diện Profile (Logic cũ của bạn dời vào đây)
        return Scaffold(
          appBar: AppBar(
            title: const Text('Hồ sơ'),
            backgroundColor: Colors.green,
          ),
          body: StreamBuilder<DocumentSnapshot>(
            // Gọi stream lấy dữ liệu chi tiết từ Firestore
            stream: FirebaseService().getUserStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text("Không có dữ liệu người dùng"));
              }

              // Kiểm tra data có tồn tại không trước khi ép kiểu
              final dataObj = snapshot.data!.data();
              if (dataObj == null) {
                // Trường hợp user đã tạo Auth nhưng chưa kịp lưu vào Firestore
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Đang cập nhật thông tin..."),
                      ElevatedButton(
                          onPressed: () => FirebaseService().signOut(),
                          child: const Text("Đăng xuất"))
                    ],
                  ),
                );
              }

              final userData = dataObj as Map<String, dynamic>;

              // Lấy dữ liệu an toàn (như code bạn đã viết)
              final nickname = userData['nickname'] as String? ?? "Người dùng";
              final email = userData['email'] as String? ??
                  user.email ??
                  "No Email"; // Fallback lấy email từ Auth nếu Firestore thiếu
              final ageStr = userData['age'] as String? ??
                  "0"; // Lưu ý: trong code cũ bạn dùng birthYear, nhưng form đăng ký là 'age' (String)
              final location = userData['location'] as String? ?? "--";
              // final createdAt = userData['createdAt']; // Timestamp firebase cần xử lý riêng nếu muốn hiện

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
                              leading:
                                  const Icon(Icons.cake, color: Colors.green),
                              title: const Text("Tuổi"),
                              trailing: Text(
                                "$ageStr tuổi",
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
                              title: const Text("Nơi sống"),
                              trailing: Text(
                                location,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
                          // Không cần Navigator hay SnackBar phức tạp,
                          // vì StreamBuilder ở trên cùng sẽ tự phát hiện logout
                          // và vẽ lại màn hình đăng nhập.
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
      },
    );
  }
}
