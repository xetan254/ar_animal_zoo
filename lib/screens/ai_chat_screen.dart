import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  // ⚠️ QUAN TRỌNG: Thay bằng API Key mới của bạn lấy từ https://aistudio.google.com/
  final String _apiKey = 'AIzaSyB3KHjG2e_ugiJUySzRcK-Q4fRFRJgDJb0';

  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    try {
      // Sử dụng model gemini-1.5-pro (mạnh hơn, thông minh hơn)
      _model = GenerativeModel(
        model: 'gemini-2.5-pro',
        apiKey: _apiKey,
        // Tắt bộ lọc an toàn để tránh bị chặn câu trả lời vô lý
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
        ],
      );

      _chatSession = _model.startChat(history: [
        Content.text(
            'Bạn là trợ lý ảo về động vật của ứng dụng ARZoo. Hãy trả lời ngắn gọn, thân thiện.'),
      ]);

      _addMessage('model',
          'Chào bạn! Mình là Gemini 1.5 Pro. Bạn muốn hỏi về con vật nào?');
    } catch (e) {
      _addMessage('model', 'Lỗi khởi tạo: $e');
    }
  }

  void _addMessage(String role, String text) {
    if (mounted) {
      setState(() => _messages.add({'role': role, 'text': text}));
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _addMessage('user', text);
    _controller.clear();
    setState(() => _isLoading = true);

    try {
      final response = await _chatSession.sendMessage(Content.text(text));

      if (response.text != null) {
        _addMessage('model', response.text!);
      } else {
        _addMessage('model', 'AI không phản hồi (Lỗi data null).');
      }
    } catch (e) {
      _addMessage('model', 'Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          title: const Text('Chat với Gemini 1.5 Pro'),
          backgroundColor: Colors.blueAccent),
      body: Column(
        children: [
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
                      borderRadius: BorderRadius.circular(15),
                    ),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8),
                    child: Text(msg['text']!,
                        style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87)),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Hỏi Gemini Pro...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25)),
                      filled: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: _isLoading ? null : _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
