import 'package:flutter/material.dart';
import '../data/zoo_data.dart';
import 'animal_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy 3 con đầu làm "Gần đây", 3 con sau làm "Nổi bật" (Demo)
    final recentAnimals = zooAnimals.take(3).toList();
    final featuredAnimals = zooAnimals.skip(3).take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khám phá thế giới',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1
            _buildSectionTitle('Tìm kiếm gần đây'),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentAnimals.length,
                itemBuilder: (context, index) {
                  return _buildAnimalCard(context, recentAnimals[index]);
                },
              ),
            ),

            const SizedBox(height: 20),

            // Section 2
            _buildSectionTitle('Thú nổi bật'),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: featuredAnimals.length,
                itemBuilder: (context, index) {
                  return _buildAnimalCard(context, featuredAnimals[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
      ),
    );
  }

  Widget _buildAnimalCard(BuildContext context, Animal animal) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AnimalDetailScreen(animal: animal)),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            // ĐÃ XÓA HERO WIDGET Ở ĐÂY
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                animal.imagePath,
                height: 80,
                width: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              animal.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
