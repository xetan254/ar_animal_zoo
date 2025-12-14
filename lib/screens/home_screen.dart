import 'package:flutter/material.dart';
import 'package:ar_animal_zoo/services/firebase_service.dart';
import 'package:ar_animal_zoo/screens/search_screen.dart';
import 'package:ar_animal_zoo/screens/news_detail_screen.dart';
import 'package:ar_animal_zoo/screens/animal_detail_screen.dart';
import 'package:ar_animal_zoo/data/zoo_data.dart';
import 'package:geolocator/geolocator.dart'; // Import thư viện định vị

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _featuredAnimalsFuture;
  late Future<Map<String, dynamic>?> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _featuredAnimalsFuture = FirebaseService().getFeaturedAnimals();
    // Khởi tạo weather future ban đầu (chưa có data)
    _weatherFuture = _determinePositionAndFetchWeather();
  }

  // Hàm xin quyền và lấy vị trí
  Future<Map<String, dynamic>?> _determinePositionAndFetchWeather() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Kiểm tra GPS có bật không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // GPS tắt -> Gọi API mặc định
      return FirebaseService().fetchWeather(21.0285, 105.8542);
    }

    // 2. Kiểm tra quyền
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Từ chối quyền -> Mặc định Hà Nội
        return FirebaseService().fetchWeather(21.0285, 105.8542);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Từ chối vĩnh viễn -> Mặc định Hà Nội
      return FirebaseService().fetchWeather(21.0285, 105.8542);
    }

    // 3. Lấy vị trí hiện tại
    Position position = await Geolocator.getCurrentPosition();

    // 4. Gọi API thời tiết với tọa độ thật
    return FirebaseService()
        .fetchWeather(position.latitude, position.longitude);
  }

  Future<void> _refreshData() async {
    setState(() {
      _featuredAnimalsFuture = FirebaseService().getFeaturedAnimals();
      _weatherFuture = _determinePositionAndFetchWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Khám phá ARZoo',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWeatherCard(),
              const SizedBox(height: 20),
              _buildSectionTitle(
                  'Động vật nổi bật', Icons.favorite, Colors.redAccent),
              _buildFeaturedAnimals(),
              const SizedBox(height: 20),
              _buildSectionTitle(
                  'Tin tức mới nhất', Icons.newspaper, Colors.blueAccent),
              _buildNewsSection(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 10),
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- WIDGET THỜI TIẾT ---
  Widget _buildWeatherCard() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        String city = "Đang tải...";
        String temp = "--";
        String desc = "Đang cập nhật";
        String iconUrl = "";

        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          city = data['name'] ?? "Không xác định";
          temp = (data['main']['temp'] as num).round().toString();
          String rawDesc = data['weather'][0]['description'] ?? "";
          if (rawDesc.isNotEmpty) {
            desc = rawDesc[0].toUpperCase() + rawDesc.substring(1);
          }
          String iconCode = data['weather'][0]['icon'];
          iconUrl = "https://openweathermap.org/img/wn/$iconCode@2x.png";
        }

        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlueAccent]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(city,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('$temp°C',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(desc,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              if (iconUrl.isNotEmpty)
                Image.network(iconUrl,
                    width: 80,
                    height: 80,
                    errorBuilder: (_, __, ___) => const Icon(Icons.cloud_off,
                        color: Colors.white, size: 60))
              else
                const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET THÚ NỔI BẬT ---
  Widget _buildFeaturedAnimals() {
    return SizedBox(
      height: 220,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _featuredAnimalsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final animals = snapshot.data ?? [];
          if (animals.isEmpty) {
            return const Center(child: Text("Chưa có dữ liệu"));
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20),
            itemCount: animals.length,
            itemBuilder: (context, index) => _buildAnimalCard(animals[index]),
          );
        },
      ),
    );
  }

  Widget _buildAnimalCard(Map<String, dynamic> animalData) {
    return GestureDetector(
      onTap: () {
        try {
          final localAnimal =
              zooAnimals.firstWhere((a) => a.id == animalData['id']);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AnimalDetailScreen(animal: localAnimal)));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Chưa có thông tin chi tiết")));
        }
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15, bottom: 5, top: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(2, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(animalData['image'],
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(height: 120, color: Colors.grey[200])),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(animalData['name'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.favorite,
                        color: Colors.redAccent, size: 14),
                    const SizedBox(width: 4),
                    Text('${animalData['likes']}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12))
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET TIN TỨC ---
  Widget _buildNewsSection() {
    return StreamBuilder<List<NewsArticle>>(
      stream: FirebaseService().getNewsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final newsList = snapshot.data!.take(7).toList();
        if (newsList.isEmpty) {
          return const Padding(
              padding: EdgeInsets.all(20), child: Text("Chưa có tin tức"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: newsList.length,
          itemBuilder: (context, index) => _buildNewsCard(newsList[index]),
        );
      },
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => NewsDetailScreen(article: article))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3))
            ]),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(15)),
              child: Image.network(article.imageUrl,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      height: 100, width: 100, color: Colors.grey[300])),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Text(article.date,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
