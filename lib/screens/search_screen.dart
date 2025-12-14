import 'package:flutter/material.dart';
import '../data/zoo_data.dart'; // Import model Animal
import '../services/firebase_service.dart'; // Import Service

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Khởi tạo Service
  final FirebaseService _firebaseService = FirebaseService();

  // Danh sách gốc (chứa tất cả dữ liệu từ Firebase)
  List<Animal> _allAnimals = [];
  // Danh sách hiển thị (kết quả tìm kiếm)
  List<Animal> _foundAnimals = [];

  bool _isLoading = true; // Trạng thái đang tải

  @override
  void initState() {
    super.initState();
    _fetchAnimals();
  }

  // Hàm lấy dữ liệu từ Firebase
  void _fetchAnimals() {
    // Lắng nghe Stream từ Service để lấy dữ liệu realtime
    _firebaseService.getAnimalsStream().listen((animals) {
      if (mounted) {
        setState(() {
          _allAnimals = animals; // Lưu vào danh sách gốc
          _foundAnimals = animals; // Mặc định hiển thị tất cả ban đầu
          _isLoading = false; // Tắt loading
        });
      }
    }, onError: (error) {
      debugPrint("Lỗi khi tải dữ liệu: $error");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // Hàm lọc kết quả (Tìm kiếm Client-side)
  void _runFilter(String enteredKeyword) {
    List<Animal> results = [];
    if (enteredKeyword.isEmpty) {
      // Nếu ô tìm kiếm rỗng, hiển thị lại toàn bộ danh sách gốc
      results = _allAnimals;
    } else {
      // Lọc từ danh sách gốc (_allAnimals)
      results = _allAnimals
          .where((animal) =>
              animal.name.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    setState(() {
      _foundAnimals = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thư viện Động vật'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Thanh tìm kiếm
            TextField(
              onChanged: (value) => _runFilter(value),
              decoration: InputDecoration(
                labelText: 'Tìm kiếm động vật...',
                suffixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 20),

            // Phần hiển thị danh sách
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator()) // Hiện loading khi chưa có data
                  : _foundAnimals.isNotEmpty
                      ? ListView.builder(
                          itemCount: _foundAnimals.length,
                          itemBuilder: (context, index) {
                            final animal = _foundAnimals[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      // Logic xử lý ảnh: Nếu link bắt đầu bằng http thì là ảnh mạng,
                                      // ngược lại dùng ảnh asset (đề phòng data cũ)
                                      image:
                                          (animal.imagePath.startsWith('http'))
                                              ? NetworkImage(animal.imagePath)
                                                  as ImageProvider
                                              : AssetImage(animal.imagePath),
                                      fit: BoxFit.cover,
                                      onError: (exception, stackTrace) =>
                                          const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                                title: Text(animal.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(animal
                                    .diet), // Giả sử model có field category
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 16),
                                onTap: () {
                                  // Navigate to details screen
                                  // Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(animal: animal)));
                                },
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Text('Không tìm thấy kết quả nào'),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
