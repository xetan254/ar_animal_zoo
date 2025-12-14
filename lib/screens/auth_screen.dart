// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true; // Trạng thái: Đang ở màn Login hay Register
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    String? error;
    final service = FirebaseService();

    if (isLogin) {
      error = await service.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else {
      error = await service.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nickname: _nicknameController.text.trim(),
        age: _ageController.text.trim(),
        location: _locationController.text.trim(),
      );
    }

    setState(() => isLoading = false);

    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red));
    } else {
      // Đăng nhập/ĐK thành công -> Thoát màn hình này
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(isLogin ? "Đăng Nhập" : "Đăng Ký"),
          backgroundColor: Colors.green),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                const Icon(Icons.pets, size: 80, color: Colors.green),
                const SizedBox(height: 20),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: "Email", prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) =>
                      val!.contains('@') ? null : "Email không hợp lệ",
                ),
                const SizedBox(height: 10),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                      labelText: "Mật khẩu", prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                  validator: (val) =>
                      val!.length < 6 ? "Mật khẩu phải trên 6 ký tự" : null,
                ),
                const SizedBox(height: 10),

                // Các trường chỉ hiện khi Đăng ký
                if (!isLogin) ...[
                  TextFormField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                        labelText: "Nickname (Tên hiển thị)",
                        prefixIcon: Icon(Icons.person)),
                    validator: (val) =>
                        val!.isEmpty ? "Vui lòng nhập tên" : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          decoration: const InputDecoration(
                              labelText: "Tuổi", prefixIcon: Icon(Icons.cake)),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                              labelText: "Nơi sống",
                              prefixIcon: Icon(Icons.map)),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 30),

                // Nút Submit
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(isLogin ? "ĐĂNG NHẬP" : "ĐĂNG KÝ NGAY",
                            style: const TextStyle(color: Colors.white)),
                      ),

                // Nút chuyển đổi chế độ
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(isLogin
                      ? "Chưa có tài khoản? Đăng ký ngay"
                      : "Đã có tài khoản? Đăng nhập"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
