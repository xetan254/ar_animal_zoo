import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsArticle article;

  const NewsDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hiệu ứng ảnh bìa co giãn khi cuộn
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: Colors.green,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                article.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                    color: Colors.grey[300],
                    child:
                        const Center(child: Icon(Icons.image_not_supported))),
              ),
            ),
          ),

          // Nội dung bài viết
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 10),

                  // Metadata
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(article.date,
                          style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      const Icon(Icons.person, size: 14, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(article.author,
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1),

                  // Nội dung chính
                  Text(
                    article.content,
                    style: const TextStyle(
                        fontSize: 16, height: 1.6, color: Colors.black87),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
