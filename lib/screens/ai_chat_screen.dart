import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Import thư viện Gemini

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  // --- CẤU HÌNH GEMINI ---
  // ⚠️ QUAN TRỌNG: Thay thế bằng API Key của bạn
  final String _apiKey = 'AIzaSyB3KHjG2e_ugiJUySzRcK-Q4fRFRJgDJb0';

  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Danh sách tin nhắn hiển thị lên màn hình
  // Cấu trúc: {'role': 'user' | 'model', 'text': 'Nội dung'}
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo model Gemini (sử dụng gemini-pro hoặc gemini-1.5-flash)
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );

    // Bắt đầu phiên chat (có lưu lịch sử ngữ cảnh)
    _chatSession = _model.startChat(history: [
      // Bạn có thể "mớm" lời cho AI biết nó là ai ở đây
      Content.text(
          'Bạn là trợ lý ảo thông minh của ứng dụng vườn thú AR tên là ARZoo. '
          'Hãy trả lời ngắn gọn, thân thiện và tập trung vào chủ đề động vật.'),
    ]);

    // Tin nhắn chào mừng
    _messages.add({
      'role': 'model',
      'text':
          'Xin chào! Tôi là trợ lý ảo ARZoo sử dụng công nghệ Gemini. Bạn muốn tìm hiểu về loài động vật nào?'
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // 1. Hiển thị tin nhắn người dùng
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      // 2. Gửi tin nhắn đến Gemini
      final response = await _chatSession.sendMessage(Content.text(text));

      final responseText = response.text;

      if (responseText != null) {
        setState(() {
          _messages.add({'role': 'model', 'text': responseText});
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'model',
            'text': 'Xin lỗi, tôi không phản hồi được lúc này.'
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'model', 'text': 'Lỗi kết nối: $e'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat với Gemini AI'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // Khu vực hiển thị tin nhắn
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: isUser
                            ? const Radius.circular(15)
                            : const Radius.circular(0),
                        bottomRight: isUser
                            ? const Radius.circular(0)
                            : const Radius.circular(15),
                      ),
                    ),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Thanh trạng thái loading
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child:
                  LinearProgressIndicator(backgroundColor: Colors.transparent),
            ),

          // Khu vực nhập liệu
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Hỏi về động vật...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(), // Gửi khi nhấn Enter
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _isLoading ? Colors.grey : Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
