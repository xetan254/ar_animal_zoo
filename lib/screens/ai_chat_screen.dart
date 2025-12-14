import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  // Controller để quản lý text nhập vào
  final TextEditingController _textController = TextEditingController();

  // Danh sách tin nhắn
  final List<Map<String, String>> _messages = [];

  // Trạng thái loading
  bool _isLoading = false;

  // Cấu hình Gemini
  // Lưu ý: Hiện tại model ổn định nhất là 'gemini-1.5-pro' hoặc 'gemini-pro'.
  // Nếu bạn có quyền truy cập 'gemini-2.5-pro' (future/beta), hãy đổi tên chuỗi bên dưới.
  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    // KHỞI TẠO GEMINI
    // Thay thế 'YOUR_API_KEY_HERE' bằng API Key thực tế của bạn
    const apiKey = 'AIzaSyB3KHjG2e_ugiJUySzRcK-Q4fRFRJgDJb0';
    _model = GenerativeModel(
      model: 'gemini-3-pro', // Hoặc 'gemini-pro'
      apiKey: apiKey,
    );
  }

  // Hàm gửi tin nhắn
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // 1. Thêm tin nhắn của User vào list và cập nhật UI
    setState(() {
      _messages.add({"role": "user", "text": text});
      _isLoading = true;
    });
    _textController.clear();

    try {
      // 2. Gọi API Gemini
      final content = [Content.text(text)];
      final response = await _model.generateContent(content);

      // 3. Nhận phản hồi và cập nhật UI
      setState(() {
        _messages.add({
          "role": "ai",
          "text": response.text ?? "Xin lỗi, tôi không thể trả lời lúc này."
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({"role": "ai", "text": "Lỗi kết nối: $e"});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat với AI Zoo"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // PHẦN 1: DANH SÁCH TIN NHẮN
          // Dùng Expanded để chiếm toàn bộ không gian còn lại -> SỬA LỖI OVERFLOW
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      "Hãy hỏi tôi về các loài động vật!",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Text(
                            msg['text']!,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Hiển thị loading khi đang chờ AI trả lời
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),

          // PHẦN 2: Ô NHẬP LIỆU
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "Nhập câu hỏi...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
