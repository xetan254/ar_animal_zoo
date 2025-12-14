import 'package:flutter/material.dart';
import '../data/zoo_data.dart';
import '../services/firebase_service.dart'; // Dùng service để lấy data online
import 'animal_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thư viện động vật'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                labelText: 'Tìm kiếm tên động vật...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),

          // Danh sách
          Expanded(
            child: StreamBuilder<List<Animal>>(
              stream: FirebaseService().getAnimalsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Fallback nếu không có mạng thì dùng list cũ
                final allAnimals =
                    (snapshot.hasData && snapshot.data!.isNotEmpty)
                        ? snapshot.data!
                        : zooAnimals;

                // Lọc theo tìm kiếm
                final displayList = allAnimals
                    .where((animal) => animal.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

                if (displayList.isEmpty) {
                  return const Center(child: Text("Không tìm thấy kết quả."));
                }

                return ListView.builder(
                  itemCount: displayList.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, index) {
                    final animal = displayList[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  AnimalDetailScreen(animal: animal)),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        elevation: 3,
                        child: Row(
                          children: [
                            // ĐÃ XÓA HERO WIDGET Ở ĐÂY
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                              ),
                              child: Image.asset(
                                animal.imagePath,
                                width: 120,
                                height: 100,
                                fit: BoxFit.cover,
                                // Xử lý nếu ảnh online bị lỗi
                                errorBuilder: (c, e, s) => Container(
                                    width: 120,
                                    height: 100,
                                    color: Colors.grey,
                                    child:
                                        const Icon(Icons.image_not_supported)),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      animal.name,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      animal.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(right: 12.0),
                              child: Icon(Icons.arrow_forward_ios,
                                  color: Colors.grey, size: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
