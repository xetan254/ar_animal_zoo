import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 1. Thêm dòng này
import 'package:ar_animal_zoo/services/firebase_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  String? _selectedProvince;
  List<String> _provinces = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true); // Hiển thị loading khi bắt đầu tải

    // Lấy danh sách tỉnh thành
    final provinces = await FirebaseService().getProvinces();

    // 2. SỬA LỖI TẠI ĐÂY: Dùng FirebaseAuth trực tiếp
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (mounted && userDoc.exists) {
      final data = userDoc.data()!;
      setState(() {
        _provinces = provinces;
        _nameController.text = data['nickname'] ?? '';
        _yearController.text = (data['birthYear'] ?? '').toString();

        // Kiểm tra xem tỉnh đã lưu có trong danh sách API không
        String savedProv = data['province'] ?? '';

        // Logic chọn tỉnh: nếu tỉnh đã lưu có trong list thì chọn, không thì chọn cái đầu tiên
        if (provinces.contains(savedProv)) {
          _selectedProvince = savedProv;
        } else if (provinces.isNotEmpty) {
          _selectedProvince = provinces.first;
        }

        _isLoading = false; // Tắt loading
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error = await FirebaseService().updateUserProfile(
        nickname: _nameController.text,
        birthYear: int.tryParse(_yearController.text) ?? 2000,
        province: _selectedProvince ?? '',
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Cập nhật thành công!'),
              backgroundColor: Colors.green));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Thông tin cá nhân'),
          backgroundColor: Colors.green),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          labelText: 'Tên hiển thị (Nickname)',
                          border: OutlineInputBorder()),
                      validator: (value) =>
                          value!.isEmpty ? 'Vui lòng nhập tên' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Năm sinh', border: OutlineInputBorder()),
                      validator: (value) =>
                          value!.isEmpty ? 'Vui lòng nhập năm sinh' : null,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProvince,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'Tỉnh/Thành phố',
                          border: OutlineInputBorder()),
                      items: _provinces.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedProvince = val),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        child: const Text("Lưu thay đổi",
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
