import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Giới thiệu"), backgroundColor: Colors.purple),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 100, color: Colors.purple),
            SizedBox(height: 20),
            Text(
              "AR Animal Zoo",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple),
            ),
            SizedBox(height: 10),
            Text("Phiên bản 1.0.0", style: TextStyle(color: Colors.grey)),
            SizedBox(height: 30),
            Text(
              "AR Animal Zoo là ứng dụng giáo dục giúp người dùng khám phá thế giới động vật thông qua công nghệ Thực tế ảo tăng cường (AR). \n\n"
              "Tính năng chính:\n"
              "- Tra cứu thông tin động vật.\n"
              "- Xem mô hình 3D trong không gian thật.\n"
              "- Nhận diện động vật bằng AI (Camera).\n"
              "- Hỏi đáp với trợ lý ảo thông minh.",
              style: TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 40),
            Text("Phát triển bởi Nhóm 11",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
