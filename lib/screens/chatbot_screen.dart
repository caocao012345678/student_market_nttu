import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:student_market_nttu/services/gemini_service.dart';
import 'package:student_market_nttu/services/rag_service.dart';
import 'package:student_market_nttu/services/theme_service.dart';
import 'package:student_market_nttu/screens/models_info_screen.dart';
import 'package:student_market_nttu/services/app_layout_service.dart';
import 'package:student_market_nttu/widgets/app_drawer.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  // Thêm biến để theo dõi xem màn hình có đang mounted hay không
  bool _isMounted = true;
  
  // Thêm biến để kiểm soát việc gửi tin nhắn
  bool _isSendingMessage = false;
  
  // Thêm timer cho debounce
  Timer? _debounceTimer;
  
  // Gợi ý cho người dùng mới
  final List<String> _suggestions = [
    'Làm thế nào để tìm kiếm sản phẩm?',
    'Làm thế nào để đăng bán sản phẩm mới?',
    'Cách thanh toán trong ứng dụng?',
    'Làm thế nào để trò chuyện với người bán?',
    'Cách theo dõi đơn hàng của tôi?',
    'Điểm NTT là gì và sử dụng như thế nào?',
  ];

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    
    // Cấu hình RAGService với AppLayoutService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isMounted) return;
      
      final ragService = Provider.of<RAGService>(context, listen: false);
      final appLayoutService = Provider.of<AppLayoutService>(context, listen: false);
      
      // Thiết lập AppLayoutService cho RAGService
      ragService.setAppLayoutService(appLayoutService);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    _isMounted = false;
    super.dispose();
  }

  // Hàm gửi tin nhắn với debounce
  void _debouncedSendMessage(String message) {
    // Hủy timer cũ nếu có
    _debounceTimer?.cancel();
    
    // Nếu đang xử lý tin nhắn hoặc tin nhắn trống, không làm gì cả
    if (_isSendingMessage || message.trim().isEmpty) return;
    
    final String trimmedMessage = message.trim();
    
    // Tạo timer mới (300ms để tránh double-tap)
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_isMounted && trimmedMessage.isNotEmpty) {
        // Kiểm tra cờ trạng thái trước khi gửi
        if (!_isSendingMessage) {
          _sendRAGMessage(trimmedMessage);
        } else {
          debugPrint('Đã bỏ qua tin nhắn vì đang trong quá trình gửi tin nhắn khác');
        }
      }
    });
  }

  void _scrollToBottom() {
    if (!_isMounted) return;
    
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

  Widget _buildChatBubble(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    final timestamp = DateTime.fromMillisecondsSinceEpoch(message['timestamp']);
    final formattedTime = DateFormat('HH:mm').format(timestamp);
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDarkMode = themeService.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: Colors.blue[900],
              radius: 16,
              child: const Icon(Icons.assistant, size: 18, color: Colors.white),
            ),
            
          const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser 
                  ? Colors.blue[900] 
                  : isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['content'],
                    style: TextStyle(
                      color: isUser ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isUser)
            const SizedBox(width: 8),
            
          if (isUser)
            CircleAvatar(
              backgroundColor: Colors.blue[700],
              radius: 16,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return ActionChip(
      label: Text(
        suggestion,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.blue[50],
      onPressed: () {
        if (!_isSendingMessage) {
          _debouncedSendMessage(suggestion);
          _messageController.clear();
          _scrollToBottom();
        }
      },
    );
  }

  // Phương thức xử lý gửi tin nhắn với RAG
  Future<void> _sendRAGMessage(String message) async {
    // 1. Không gửi nếu đang xử lý tin nhắn khác hoặc tin nhắn trống
    if (_isSendingMessage || message.trim().isEmpty) {
      return;
    }

    // Lưu lại tin nhắn hiện tại để phòng trường hợp trùng lặp
    final currentMessage = message.trim();
    
    // Kiểm tra xem tin nhắn đã có trong lịch sử gần đây chưa
    // Sử dụng thời gian để tránh trùng lặp tin nhắn trong vòng 3 giây
    final now = DateTime.now().millisecondsSinceEpoch;
    final recentMessages = context.read<GeminiService>().chatHistory
        .where((msg) => 
            msg['role'] == 'user' && 
            msg['content'] == currentMessage &&
            (now - (msg['timestamp'] as int) < 3000)) // 3 giây
        .toList();
    
    if (recentMessages.isNotEmpty) {
      debugPrint('Phát hiện tin nhắn trùng lặp gần đây, bỏ qua: $currentMessage');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn vừa gửi tin nhắn này, vui lòng đợi phản hồi'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 2. Cài đặt trạng thái loading và cập nhật UI
    setState(() {
      _isSendingMessage = true;
      _messageController.clear();
    });
    
    // Xóa text field và focus lại để chuẩn bị cho tin nhắn tiếp theo
    _messageController.clear();
    _focusNode.requestFocus();

    // 3. Thêm tin nhắn người dùng vào danh sách trước khi gửi
    final geminiService = context.read<GeminiService>();
    geminiService.addUserMessageToHistory(currentMessage);
    
    // Cuộn xuống tin nhắn mới nhất
    _scrollToBottom();

    try {
      // 4. Gửi tin nhắn đến RAG Service và nhận phản hồi
      final response = await context.read<RAGService>().generateRAGResponse(currentMessage);

      // 5. Cập nhật UI với phản hồi từ RAG
      if (mounted) {
        setState(() {
          // Thêm tin nhắn từ bot vào danh sách chat
          geminiService.addBotMessageToHistory(response);
          _isSendingMessage = false;
        });
        
        // Lưu lịch sử chat
        await geminiService.saveChatHistory();
        
        // Cuộn xuống để hiển thị phản hồi mới
        _scrollToBottom();
      }
    } catch (e) {
      // 6. Xử lý lỗi và hiển thị thông báo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  Widget _buildSuggestions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bạn có thể hỏi:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((suggestion) => _buildSuggestionChip(suggestion)).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Trợ lý ảo NTTU'),
        actions: [
          // Hiển thị icon khi đang tìm kiếm dữ liệu
          Consumer<RAGService>(
            builder: (context, ragService, child) {
              return ragService.isSearching
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.model_training),
            tooltip: 'Xem danh sách models',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GeminiModelsInfoScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xóa cuộc trò chuyện'),
                  content: const Text('Bạn có chắc muốn xóa toàn bộ cuộc trò chuyện này?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Provider.of<GeminiService>(context, listen: false).clearChat();
                      },
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<GeminiService>(
        builder: (context, geminiService, child) {
          _scrollToBottom();
          
          return Column(
            children: [
              // Chat messages hoặc Welcome message
              Expanded(
                child: geminiService.chatHistory.isEmpty 
                  ? _buildWelcomeMessage() // Sử dụng widget tách riêng
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: geminiService.chatHistory.length,
                      itemBuilder: (context, index) {
                        return _buildChatBubble(geminiService.chatHistory[index]);
                      },
                    ),
              ),

              // Loading indicator
              if (geminiService.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),

              // Error message từ RAG hoặc Gemini
              Consumer<RAGService>(
                builder: (context, ragService, child) {
                  final String errorMessage = ragService.searchError.isNotEmpty 
                      ? ragService.searchError 
                      : geminiService.errorMessage;
                      
                  return errorMessage.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Lỗi xảy ra',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                errorMessage,
                                style: TextStyle(color: Colors.red[900]),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Thử lại'),
                                  onPressed: () {
                                    if (geminiService.chatHistory.isNotEmpty) {
                                      final lastUserMessage = geminiService.chatHistory
                                          .lastWhere((msg) => msg['role'] == 'user', orElse: () => {'content': ''})['content'] as String;
                                      if (lastUserMessage.isNotEmpty) {
                                        _sendRAGMessage(lastUserMessage);
                                      }
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red[700],
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: const Size(0, 0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),

              // Hiển thị các kết quả tìm kiếm (tùy chọn)
              Consumer<RAGService>(
                builder: (context, ragService, child) {
                  final retrievedDocs = ragService.retrievedDocuments;
                  
                  return retrievedDocs.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đã tìm thấy ${retrievedDocs.length} kết quả liên quan',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Câu trả lời dựa trên thông tin trên...',
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),

              // Input field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          hintText: 'Nhập câu hỏi của bạn...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        enabled: !_isSendingMessage,
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty && !_isSendingMessage) {
                            _debouncedSendMessage(value);
                            _messageController.clear();
                            _focusNode.requestFocus();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      mini: true,
                      onPressed: _isSendingMessage 
                          ? null
                          : () {
                              final message = _messageController.text;
                              if (message.trim().isNotEmpty) {
                                _debouncedSendMessage(message);
                                _messageController.clear();
                                _focusNode.requestFocus();
                              }
                            },
                      backgroundColor: _isSendingMessage 
                          ? Colors.grey
                          : Colors.blue,
                      child: _isSendingMessage
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Tách phần welcome message thành widget riêng để dễ quản lý
  Widget _buildWelcomeMessage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Tránh chiếm không gian không cần thiết
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: Colors.blue,
              child: Icon(Icons.assistant, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Xin chào! Tôi là trợ lý ảo NTTU',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tôi có thể giúp bạn tìm kiếm sản phẩm, hướng dẫn sử dụng ứng dụng và trả lời các câu hỏi của bạn.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildSuggestions(),
          ],
        ),
      ),
    );
  }
} 