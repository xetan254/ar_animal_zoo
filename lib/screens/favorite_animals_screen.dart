import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ar_animal_zoo/data/zoo_data.dart'; // Chứa list zooAnimals và class Animal
import 'package:ar_animal_zoo/services/firebase_service.dart';
import 'package:ar_animal_zoo/screens/animal_detail_screen.dart';

class FavoriteAnimalsScreen extends StatelessWidget {
  const FavoriteAnimalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Động vật yêu thích'),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseService().getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Chưa có dữ liệu"));
          }

          // Lấy mảng 'favorites' từ Firestore (chứa các ID: ['elephant', 'tiger'...])
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> favoriteIds = data['favorites'] ?? [];

          if (favoriteIds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Bạn chưa yêu thích động vật nào.",
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          // Lọc danh sách zooAnimals dựa trên ID
          List<Animal> favoriteAnimals = zooAnimals
              .where((animal) => favoriteIds.contains(animal.id))
              .toList();

          return ListView.builder(
            itemCount: favoriteAnimals.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final animal = favoriteAnimals[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      animal.imagePath, // Đảm bảo dùng imagePath
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                  title: Text(animal.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text(animal.scientificName,
                      style: const TextStyle(fontStyle: FontStyle.italic)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnimalDetailScreen(animal: animal),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
