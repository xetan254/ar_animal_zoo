import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import 'news_detail_screen.dart';

// 1. Chuyển thành StatefulWidget để quản lý trạng thái tìm kiếm
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  // Biến lưu từ khóa tìm kiếm
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Tin tức & Sự kiện',
            style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.green,
        elevation: 0,
        // Texture Gradient (Giữ nguyên như cũ)
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                left: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 20,
                child: Icon(Icons.article,
                    size: 60, color: Colors.white.withValues(alpha: 0.15)),
              ),
              Positioned(
                top: 40,
                right: -20,
                child: Icon(Icons.newspaper,
                    size: 80, color: Colors.white.withValues(alpha: 0.05)),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // 2. THANH TÌM KIẾM (Giống Library Screen)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: GoogleFonts.roboto(),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tin tức...', // Đổi text gợi ý
                hintStyle: GoogleFonts.roboto(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // 3. DANH SÁCH TIN TỨC (Có lọc)
          Expanded(
            child: StreamBuilder<List<NewsArticle>>(
              stream: FirebaseService().getNewsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allNews = snapshot.data ?? [];

                // Logic lọc dữ liệu
                final displayList = allNews.where((article) {
                  final query = _searchQuery.toLowerCase();
                  final title = article.title.toLowerCase();
                  final author = article.author.toLowerCase();
                  // Tìm theo tiêu đề hoặc tên tác giả
                  return title.contains(query) || author.contains(query);
                }).toList();

                if (displayList.isEmpty) {
                  // Giao diện khi không tìm thấy kết quả
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 60, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text(
                            _searchQuery.isEmpty
                                ? "Chưa có tin tức nào."
                                : "Không tìm thấy bài viết phù hợp.",
                            style: GoogleFonts.roboto(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayList.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final article = displayList[index];
                    return _buildNewsCard(context, article);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Tách Widget Card ra cho code gọn gàng
  Widget _buildNewsCard(BuildContext context, NewsArticle article) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => NewsDetailScreen(article: article))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                article.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title,
                      style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(article.date,
                          style: GoogleFonts.roboto(
                              color: Colors.grey[600], fontSize: 13)),
                      const Spacer(),
                      Icon(Icons.person_outline,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(article.author,
                          style: GoogleFonts.roboto(
                              color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
