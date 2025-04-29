import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/product.dart';
import '../services/chatbot_service.dart';
import '../services/product_service.dart';
import '../screens/product_detail_screen.dart';
import '../screens/chatbot_help_screen.dart';
import '../services/auth_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

class ChatbotScreen extends StatefulWidget {
  static const routeName = '/chatbot';

  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Khởi tạo locale tiếng Việt cho timeago
    timeago.setLocaleMessages('vi', timeago.ViMessages());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Cuộn xuống cuối danh sách tin nhắn khi có tin nhắn mới
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Gửi tin nhắn
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatbotService = Provider.of<ChatbotService>(context, listen: false);
    _messageController.clear();

    await chatbotService.addUserMessage(message);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final bool isAdmin = authService.isUserAdmin;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý ảo Student Market'),
        actions: [
          // Nút quản lý cơ sở tri thức (chỉ cho admin)
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.menu_book),
              tooltip: 'Quản lý cơ sở tri thức',
              onPressed: () {
                Navigator.of(context).pushNamed(ChatbotHelpScreen.routeName);
              },
            ),
          // Nút xóa lịch sử trò chuyện
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xóa lịch sử trò chuyện'),
                  content: const Text('Bạn có chắc muốn xóa tất cả tin nhắn?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () {
                        Provider.of<ChatbotService>(context, listen: false).clearMessages();
                        Navigator.of(ctx).pop();
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
      body: Column(
        children: [
          // Danh sách tin nhắn
          Expanded(
            child: Consumer<ChatbotService>(
              builder: (ctx, chatbotService, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatbotService.messages.length,
                  itemBuilder: (ctx, index) {
                    final message = chatbotService.messages[index];
                    return _buildMessageItem(message);
                  },
                );
              },
            ),
          ),
          
          // Hiển thị trạng thái đang gõ
          Consumer<ChatbotService>(
            builder: (ctx, chatbotService, child) {
              return chatbotService.isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Đang nhập...'),
                        ],
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          
          // Khung nhập tin nhắn
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Ô nhập tin nhắn
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[200]
                          : Colors.grey[800],
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                // Nút gửi tin nhắn
                Consumer<ChatbotService>(
                  builder: (ctx, chatbotService, child) {
                    return IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: chatbotService.isLoading ? null : _sendMessage,
                      color: Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị từng tin nhắn
  Widget _buildMessageItem(ChatMessage message) {
    // Căn lề tin nhắn dựa trên người gửi
    final isMe = message.isUser;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMe
        ? Colors.blue[700]
        : Theme.of(context).brightness == Brightness.light
            ? Colors.grey[200]
            : Colors.grey[800];
    final textColor = isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          // Tin nhắn sản phẩm
          if (message.type == MessageType.product)
            _buildProductMessage(message, bubbleColor!, textColor!)
          // Danh sách sản phẩm theo dạng trượt ngang
          else if (message.type == MessageType.productList)
            _buildProductListMessage(message, bubbleColor!, textColor!)
          // Tin nhắn trợ giúp
          else if (message.type == MessageType.help)
            _buildHelpMessage(message, bubbleColor!, textColor!)
          // Tin nhắn văn bản thông thường
          else
            _buildTextMessage(message, bubbleColor!, textColor!),
          
          // Thời gian
          Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 8.0, left: 8.0),
            child: Text(
              timeago.format(message.timestamp, locale: 'vi'),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị tin nhắn văn bản
  Widget _buildTextMessage(ChatMessage message, Color bubbleColor, Color? textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          color: textColor,
        ),
      ),
    );
  }

  // Widget hiển thị tin nhắn sản phẩm
  Widget _buildProductMessage(ChatMessage message, Color bubbleColor, Color textColor) {
    final metadata = message.metadata;
    if (metadata == null) return _buildTextMessage(message, bubbleColor, textColor);
    
    final productId = metadata['productId'] as String? ?? '';
    final productName = metadata['productName'] as String? ?? '';
    final productImage = metadata['productImage'] as String? ?? '';
    final productPrice = metadata['productPrice'] as double? ?? 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tin nhắn văn bản
        _buildTextMessage(message, bubbleColor, textColor),
        const SizedBox(height: 8),
        
        // Thẻ sản phẩm
        GestureDetector(
          onTap: () {
            // Chuyển đến trang chi tiết sản phẩm khi nhấp vào
            if (productId.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FutureBuilder<Product>(
                    future: Provider.of<ProductService>(context, listen: false).getProductById(productId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Scaffold(
                          appBar: AppBar(
                            title: const Text('Lỗi'),
                          ),
                          body: const Center(
                            child: Text('Không thể tải thông tin sản phẩm'),
                          ),
                        );
                      }
                      return ProductDetailScreen(product: snapshot.data!);
                    },
                  ),
                ),
              );
            }
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh sản phẩm
                if (productImage.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Image.network(
                      productImage,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                
                // Thông tin sản phẩm
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${productPrice.toStringAsFixed(0)} VND',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // Chuyển đến trang chi tiết sản phẩm
                              if (productId.isNotEmpty) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => FutureBuilder<Product>(
                                      future: Provider.of<ProductService>(context, listen: false).getProductById(productId),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Scaffold(
                                            body: Center(child: CircularProgressIndicator()),
                                          );
                                        }
                                        if (snapshot.hasError || !snapshot.hasData) {
                                          return Scaffold(
                                            appBar: AppBar(
                                              title: const Text('Lỗi'),
                                            ),
                                            body: const Center(
                                              child: Text('Không thể tải thông tin sản phẩm'),
                                            ),
                                          );
                                        }
                                        return ProductDetailScreen(product: snapshot.data!);
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Xem chi tiết'),
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
      ],
    );
  }

  // Widget hiển thị tin nhắn trợ giúp
  Widget _buildHelpMessage(ChatMessage message, Color bubbleColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề trợ giúp
          if (message.metadata != null && message.metadata!.containsKey('documentTitle'))
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                message.metadata!['documentTitle'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          
          // Nội dung trợ giúp
          Text(message.content),
        ],
      ),
    );
  }

  // Thêm phương thức hiển thị danh sách sản phẩm theo dạng trượt ngang
  Widget _buildProductListMessage(ChatMessage message, Color bubbleColor, Color textColor) {
    final products = (message.metadata?['products'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    
    return Container(
      margin: const EdgeInsets.only(left: 8.0, right: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nội dung tin nhắn
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              message.content,
              style: TextStyle(color: textColor),
            ),
          ),
          const SizedBox(height: 8),
          // Danh sách sản phẩm trượt ngang
          SizedBox(
            height: 300,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final String productId = product['productId'] ?? '';
                final String productName = product['productName'] ?? 'Sản phẩm';
                final String productImage = product['productImage'] ?? '';
                final double productPrice = (product['productPrice'] is double) 
                  ? product['productPrice'] 
                  : double.tryParse(product['productPrice'].toString()) ?? 0.0;
                final String productDescription = product['productDescription'] ?? '';
                final String productCategory = product['productCategory'] ?? '';
                final String productCondition = product['productCondition'] ?? '';
                
                // Format giá tiền theo định dạng VND
                final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
                final formattedPrice = formatCurrency.format(productPrice);
                
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      // Chuyển đến trang chi tiết sản phẩm
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FutureBuilder<Product>(
                            future: Provider.of<ProductService>(context, listen: false).getProductById(productId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Scaffold(
                                  body: Center(child: CircularProgressIndicator()),
                                );
                              }
                              if (snapshot.hasError || !snapshot.hasData) {
                                return Scaffold(
                                  appBar: AppBar(
                                    title: const Text('Lỗi'),
                                  ),
                                  body: const Center(
                                    child: Text('Không thể tải thông tin sản phẩm'),
                                  ),
                                );
                              }
                              return ProductDetailScreen(product: snapshot.data!);
                            },
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ảnh sản phẩm
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: productImage.isNotEmpty
                                ? Image.network(
                                    productImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(Icons.image_not_supported, color: Colors.grey),
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(Icons.image, color: Colors.grey),
                                    ),
                                  ),
                          ),
                        ),
                        // Thông tin sản phẩm
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tên sản phẩm
                                Text(
                                  productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                // Giá sản phẩm
                                Text(
                                  formattedPrice,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                // Tình trạng sản phẩm
                                if (productCondition.isNotEmpty) 
                                  Text(
                                    productCondition,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 