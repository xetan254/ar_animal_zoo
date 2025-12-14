import 'package:flutter/material.dart';
import '../data/zoo_data.dart';
import 'ar_screen.dart';

class AnimalDetailScreen extends StatelessWidget {
  final Animal animal;

  const AnimalDetailScreen({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(animal.name,
                  style: const TextStyle(
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                  )),
              // ĐÃ XÓA HERO WIDGET Ở ĐÂY
              background: Image.asset(
                animal.imagePath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Các thông tin chi tiết
                  _buildInfoRow("Tên khoa học", animal.scientificName),
                  _buildInfoRow("Môi trường", animal.habitat),
                  _buildInfoRow("Thức ăn", animal.diet),
                  _buildInfoRow("Tuổi thọ", animal.lifespan),
                  _buildInfoRow("Tình trạng", animal.conservationStatus),

                  const Divider(height: 30),

                  const Text(
                    "Mô tả chi tiết",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    animal.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 30),

                  // Nút xem AR
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ARScreen(animal: animal)),
                        );
                      },
                      icon: const Icon(Icons.view_in_ar),
                      label: const Text("Xem trong chế độ AR",
                          style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87)),
          Expanded(
              child:
                  Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }
}
