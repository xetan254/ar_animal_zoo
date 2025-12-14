import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  bool isLoadingProvinces = false;

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _birthYearController = TextEditingController();

  String? _selectedProvince;
  List<String> _provinces = [];

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  // Tải danh sách tỉnh thành
  Future<void> _loadProvinces() async {
    setState(() => isLoadingProvinces = true);
    final provinces = await FirebaseService().getProvinces();
    setState(() {
      _provinces = provinces;
      isLoadingProvinces = false;
    });
  }

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
      // Kiểm tra province được chọn
      if (_selectedProvince == null) {
        error = "Vui lòng chọn tỉnh/thành phố.";
      } else {
        int? birthYear = int.tryParse(_birthYearController.text.trim());
        if (birthYear == null) {
          error = "Năm sinh không hợp lệ.";
        } else if (birthYear < 1900 || birthYear > DateTime.now().year) {
          error = "Năm sinh phải từ 1900 đến năm hiện tại.";
        } else {
          error = await service.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            nickname: _nicknameController.text.trim(),
            birthYear: birthYear,
            province: _selectedProvince!,
          );
        }
      }
    }

    setState(() => isLoading = false);

    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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
        title: Text(isLogin ? 'Đăng nhập' : 'Đăng ký'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Logo
                const Icon(Icons.pets, size: 80, color: Colors.green),
                const SizedBox(height: 20),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Vui lòng nhập email';
                    if (!value!.contains('@')) return 'Email không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Vui lòng nhập mật khẩu';
                    if (value!.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Hiển thị form đăng ký nếu không phải login
                if (!isLogin) ...[
                  // Nickname
                  TextFormField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên hiển thị',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Vui lòng nhập tên';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Năm sinh
                  TextFormField(
                    controller: _birthYearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Năm sinh (VD: 2000)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập năm sinh';
                      }
                      int? year = int.tryParse(value!);
                      if (year == null ||
                          year < 1900 ||
                          year > DateTime.now().year) {
                        return 'Năm sinh không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Tỉnh/Thành phố
                  if (isLoadingProvinces)
                    const SizedBox(
                      height: 60,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProvince,
                      items: _provinces
                          .map((province) => DropdownMenuItem(
                                value: province,
                                child: Text(province),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedProvince = value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Tỉnh/Thành phố',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng chọn tỉnh/thành phố';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 12),
                ],

                // Nút Submit
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isLogin ? 'Đăng nhập' : 'Đăng ký',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Nút chuyển đổi
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                      _formKey.currentState?.reset();
                      _selectedProvince = null;
                    });
                  },
                  child: Text(
                    isLogin
                        ? 'Chưa có tài khoản? Đăng ký'
                        : 'Đã có tài khoản? Đăng nhập',
                    style: const TextStyle(color: Colors.green, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }
}
