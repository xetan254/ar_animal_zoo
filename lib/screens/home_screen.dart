// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:ar_animal_zoo/services/firebase_service.dart';
import 'package:ar_animal_zoo/screens/search_screen.dart';
import 'package:ar_animal_zoo/screens/news_detail_screen.dart';
import 'package:ar_animal_zoo/screens/animal_detail_screen.dart';
import 'package:ar_animal_zoo/data/zoo_data.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>?> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _weatherFuture = _determinePositionAndFetchWeather();
  }

  Future<Map<String, dynamic>?> _determinePositionAndFetchWeather() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return FirebaseService().fetchWeather(21.0285, 105.8542);
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return FirebaseService().fetchWeather(21.0285, 105.8542);
    }
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return FirebaseService().fetchWeather(21.0285, 105.8542);
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 5),
      );
      return FirebaseService()
          .fetchWeather(position.latitude, position.longitude);
    } catch (e) {
      return FirebaseService().fetchWeather(21.0285, 105.8542);
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _weatherFuture = _determinePositionAndFetchWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng CustomScrollView để tạo hiệu ứng cuộn header
    return Scaffold(
      backgroundColor: Colors.grey[50], // Nền sáng nhẹ
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- 1. Header co giãn (SliverAppBar) ---
            SliverAppBar(
              expandedHeight: 220.0,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.green.shade700,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
                centerTitle: true,
                title: const Text(
                  'Khám phá ARZoo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 5)],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Ảnh nền Banner (Chọn 1 ảnh đẹp từ assets)
                    Image.asset(
                      'assets/images/banner.jpg',
                      fit: BoxFit.cover,
                    ),
                    // Lớp phủ đen mờ để chữ dễ đọc hơn
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SearchScreen())),
                  ),
                ),
              ],
            ),

            // --- 2. Nội dung chính ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeatherCard(),
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                        'Động vật nổi bật', Icons.star_rounded, Colors.orange),
                    const SizedBox(height: 12),
                    _buildFeaturedAnimals(),
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                        'Tin tức mới nhất', Icons.newspaper, Colors.blue),
                    const SizedBox(height: 12),
                    _buildNewsSection(),
                    const SizedBox(height: 80), // Khoảng trống dưới cùng
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // --- WIDGET THÚ NỔI BẬT ---
  Widget _buildFeaturedAnimals() {
    return SizedBox(
      height: 240, // Tăng chiều cao để chứa Card đẹp hơn
      child: StreamBuilder<List<Animal>>(
        stream: FirebaseService().getAnimalsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Lỗi tải"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allAnimals = snapshot.data ?? [];
          if (allAnimals.isEmpty) {
            return const Center(child: Text("Chưa có dữ liệu"));
          }

          allAnimals.sort((a, b) => b.favoriteCount.compareTo(a.favoriteCount));
          final featuredAnimals = allAnimals.take(6).toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: featuredAnimals.length,
            itemBuilder: (context, index) =>
                _buildAnimalCard(featuredAnimals[index]),
          );
        },
      ),
    );
  }

  Widget _buildAnimalCard(Animal animal) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AnimalDetailScreen(animal: animal)));
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Card(
          elevation: 4,
          shadowColor: Colors.black26,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh động vật
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Hero(
                    tag: animal.id, // Hiệu ứng Hero khi chuyển trang
                    child: (animal.imagePath.startsWith('http'))
                        ? Image.network(
                            animal.imagePath,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey[200]),
                          )
                        : Image.asset(
                            animal.imagePath,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey[200]),
                          ),
                  ),
                ),
              ),
              // Thông tin
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded,
                            color: Colors.redAccent, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${animal.favoriteCount} yêu thích',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET THỜI TIẾT ---
  Widget _buildWeatherCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FutureBuilder<Map<String, dynamic>?>(
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4FACFE).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
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
                        const Icon(Icons.location_on_outlined,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 4),
                        Text(city,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('$temp°',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            height: 1.0)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(desc,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                if (iconUrl.isNotEmpty)
                  Image.network(iconUrl, width: 80, height: 80)
                else
                  const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET TIN TỨC ---
  Widget _buildNewsSection() {
    return StreamBuilder<List<NewsArticle>>(
      stream: FirebaseService().getNewsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final newsList = snapshot.data!.take(7).toList();

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: newsList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
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
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Image.network(
                article.imageUrl,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: 100, width: 100, color: Colors.grey[200]),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(article.date,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }
}
