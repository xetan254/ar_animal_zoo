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
              "Biến chuyến đi sở thú thành cuộc phiêu lưu kỳ thú cùng AR Animal Zoo! Ứng dụng giúp bạn khám phá thế giới hoang dã theo cách chưa từng có.\n\n"
              "Bạn có thể làm gì?\n"
              "- 🔍 Nhận diện nhanh: Gặp con vật lạ? Hãy để AI giúp bạn gọi tên.\n"
              "- ✨ Phép thuật AR: Xem động vật 3D chuyển động ngay trên tay bạn.\n"
              "- 🧠 Hỏi đáp thông minh: Trò chuyện cùng trợ lý ảo để hiểu thêm những điều thú vị.\n"
              "- 📚 Kiến thức bổ ích: Kho dữ liệu phong phú về các loài động vật tại sở thú.",
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
