import 'package:flutter/material.dart';
import '../data/zoo_data.dart';
import '../services/firebase_service.dart';
import 'animal_detail_screen.dart'; // ✅ Import màn hình chi tiết

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Animal> _allAnimals = []; // Tất cả động vật
  List<Animal> _displayAnimals =
      []; // Danh sách đang hiển thị (Search hoặc Top 3)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnimals();
  }

  void _fetchAnimals() {
    // Lắng nghe dữ liệu Real-time
    _firebaseService.getAnimalsStream().listen((animals) {
      if (!mounted) return;

      // 1. Sắp xếp để lấy Top 3 nổi bật (theo favoriteCount giảm dần)
      animals.sort((a, b) => b.favoriteCount.compareTo(a.favoriteCount));
      final top3Animals = animals.take(3).toList();

      setState(() {
        _allAnimals = animals; // Lưu data gốc (đã sort)

        // 2. Logic hiển thị:
        // Nếu đang không tìm kiếm gì -> Hiển thị Top 3
        // Nếu đang tìm kiếm -> Chạy lại bộ lọc với data mới
        if (_searchController.text.isEmpty) {
          _displayAnimals = top3Animals;
        } else {
          _runFilter(_searchController.text);
        }

        _isLoading = false;
      });
    }, onError: (error) {
      debugPrint("Lỗi tải data: $error");
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _runFilter(String keyword) {
    List<Animal> results = [];
    if (keyword.isEmpty) {
      // Nếu ô tìm kiếm trống -> Lấy lại Top 3 từ _allAnimals
      results = _allAnimals.take(3).toList();
    } else {
      // Nếu có từ khóa -> Lọc trong toàn bộ danh sách
      results = _allAnimals
          .where((animal) =>
              animal.name.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }

    setState(() {
      _displayAnimals = results;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh tìm kiếm
            TextField(
              controller: _searchController,
              onChanged: _runFilter,
              decoration: InputDecoration(
                labelText: 'Tìm kiếm động vật...',
                hintText: 'Nhập tên con vật (VD: Voi, Hổ...)',
                prefixIcon: const Icon(Icons.search),
                // Nút xóa nhanh
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _runFilter(''); // Reset về Top 3
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 20),

            // Tiêu đề danh sách (Thay đổi theo ngữ cảnh)
            Text(
              _searchController.text.isEmpty
                  ? "🔥 Động vật nổi bật (Top 3)"
                  : "🔎 Kết quả tìm kiếm",
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
            const SizedBox(height: 10),

            // Danh sách hiển thị
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _displayAnimals.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 50, color: Colors.grey),
                              SizedBox(height: 10),
                              Text('Không tìm thấy kết quả nào'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _displayAnimals.length,
                          itemBuilder: (context, index) {
                            final animal = _displayAnimals[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(10),
                                leading: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image:
                                          (animal.imagePath.startsWith('http'))
                                              ? NetworkImage(animal.imagePath)
                                                  as ImageProvider
                                              : AssetImage(animal.imagePath),
                                      fit: BoxFit.cover,
                                      onError: (_, __) =>
                                          const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  animal.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(animal.diet),
                                    const SizedBox(height: 4),
                                    // Hiển thị số lượt yêu thích
                                    Row(
                                      children: [
                                        const Icon(Icons.favorite,
                                            size: 14, color: Colors.red),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${animal.favoriteCount} yêu thích",
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Colors.grey),
                                onTap: () {
                                  // ✅ Chuyển sang màn hình chi tiết
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AnimalDetailScreen(animal: animal),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
