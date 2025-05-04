import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'dart:async'; // Thêm import Zone
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:student_market_nttu/screens/chatbot_screen.dart';
import 'package:student_market_nttu/screens/chatbot_help_screen.dart';
import 'package:student_market_nttu/screens/home_screen.dart';
import 'package:student_market_nttu/screens/splash_screen.dart';
import 'package:student_market_nttu/screens/chat_list_screen.dart';
import 'package:student_market_nttu/screens/chat_detail_screen.dart';
import 'package:student_market_nttu/screens/notification_screen.dart';
import 'package:student_market_nttu/screens/notification_detail_screen.dart';
import 'package:student_market_nttu/screens/ntt_point_history_screen.dart';
import 'package:student_market_nttu/screens/order_detail_screen.dart';
import 'package:student_market_nttu/screens/product_detail_screen.dart';
import 'package:student_market_nttu/services/auth_service.dart';
import 'package:student_market_nttu/services/theme_service.dart';
import 'package:student_market_nttu/services/shipper_service.dart';
import 'package:student_market_nttu/services/order_service.dart';
import 'package:student_market_nttu/services/review_service.dart';
import 'package:student_market_nttu/services/product_service.dart';
import 'package:student_market_nttu/services/user_service.dart';
import 'package:student_market_nttu/services/favorites_service.dart';
import 'package:student_market_nttu/services/cart_service.dart';
import 'package:student_market_nttu/services/payment_service.dart';
import 'package:student_market_nttu/services/category_service.dart';
import 'package:student_market_nttu/services/chatbot_service.dart';
import 'package:student_market_nttu/services/chat_service.dart';
import 'package:student_market_nttu/services/ntt_point_service.dart';
import 'package:student_market_nttu/services/firebase_messaging_service.dart';
import 'package:student_market_nttu/services/knowledge_base_service.dart';
import 'package:student_market_nttu/services/notification_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
// import 'package:student_market_nttu/services/wishlist_service.dart'; // Xóa import này vì không tồn tại
// import 'package:student_market_nttu/services/search_service.dart';
// import 'package:student_market_nttu/services/messaging_service.dart';
import 'package:student_market_nttu/utils/web_utils.dart' if (dart.library.html) 'package:student_market_nttu/utils/web_utils_web.dart';
import 'firebase_options.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() async {
  // Đảm bảo ràng buộc Flutter được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Khởi tạo biến môi trường
  await dotenv.load(fileName: ".env");

  // Đặt xử lý lỗi toàn cục
  FlutterError.onError = (details) {
    debugPrint('Flutter error: ${details.exception}');
    if (kReleaseMode) {
      // Báo cáo lỗi cho dịch vụ
      Zone.current.handleUncaughtError(details.exception, details.stack!);
    }
  };

  // Đăng ký locale tiếng Việt cho timeago
  timeago.setLocaleMessages('vi', timeago.ViMessages());

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Khởi tạo push notification service sau khi widget đã build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFirebaseMessaging();
    });
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Đảm bảo context đã được tạo
      final context = _navigatorKey.currentContext;
      if (context != null) {
        await FirebaseMessagingService.initialize(context);
      }
    } catch (e) {
      debugPrint('Lỗi khi khởi tạo Firebase Messaging: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => NTTPointService()),
        ChangeNotifierProxyProvider<NTTPointService, ProductService>(
          create: (context) => ProductService(
            nttPointService: Provider.of<NTTPointService>(context, listen: false)),
          update: (context, nttPointService, previous) => 
            ProductService(nttPointService: nttPointService),
        ),
        ChangeNotifierProvider(create: (_) => ReviewService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
        ChangeNotifierProvider(create: (_) => ShipperService()),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => FavoritesService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => PaymentService()),
        ChangeNotifierProvider(create: (_) => CategoryService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => KnowledgeBaseService()),
        ChangeNotifierProxyProvider<ProductService, ChatbotService>(
          create: (context) => ChatbotService(Provider.of<ProductService>(context, listen: false)),
          update: (_, productService, previousChatbotService) => 
              previousChatbotService == null
                  ? ChatbotService(productService)
                  : previousChatbotService..updateProductService(productService),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Student Market NTTU',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue[900]!,
                brightness: Brightness.light,
                primary: Colors.blue[900],
                secondary: Colors.blue[700],
                surface: Colors.white,
                background: Colors.grey[50],
                onPrimary: Colors.white,
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.notoSansTextTheme(
                Theme.of(context).textTheme,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue[900]!,
                brightness: Brightness.dark,
                primary: Colors.blue[900],
                secondary: Colors.blue[700],
                surface: Colors.grey[900],
                background: Colors.black,
                onPrimary: Colors.white,
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.notoSansTextTheme(
                Theme.of(context).textTheme,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('vi', 'VN'),
              Locale('en', 'US'),
            ],
            locale: const Locale('vi', 'VN'),
            routes: {
              '/': (ctx) {
                final args = ModalRoute.of(ctx)?.settings.arguments as Map<String, dynamic>?;
                final initialIndex = args?['initialIndex'] as int? ?? 0;
                return initialIndex == -1 ? const SplashScreen() : HomeScreen(initialIndex: initialIndex);
              },
              ChatbotScreen.routeName: (ctx) => const ChatbotScreen(),
              ChatbotHelpScreen.routeName: (ctx) => const ChatbotHelpScreen(),
              ChatListScreen.routeName: (ctx) => const ChatListScreen(),
              NTTPointHistoryScreen.routeName: (ctx) => const NTTPointHistoryScreen(),
              NotificationScreen.routeName: (ctx) => const NotificationScreen(),
              NotificationDetailScreen.routeName: (ctx) {
                final args = ModalRoute.of(ctx)?.settings.arguments as Map<String, dynamic>?;
                final notificationId = args?['notificationId'] as String? ?? '';
                return NotificationDetailScreen(notificationId: notificationId);
              },
              '/chat-detail': (ctx) {
                final args = ModalRoute.of(ctx)?.settings.arguments as Map<String, dynamic>?;
                final chatId = args?['chatId'] as String? ?? '';
                return ChatDetailScreen(chatId: chatId);
              },
              OrderDetailScreen.routeName: (ctx) {
                final args = ModalRoute.of(ctx)?.settings.arguments as Map<String, dynamic>?;
                final orderId = args?['orderId'] as String? ?? '';
                return OrderDetailScreen(orderId: orderId);
              },
              ProductDetailScreen.routeName: (ctx) {
                final args = ModalRoute.of(ctx)?.settings.arguments as Map<String, dynamic>?;
                final productId = args?['productId'] as String? ?? '';
                
                // Chuyển đến màn hình "đang phát triển" khi được gọi từ thông báo
                if (args != null && args.containsKey('fromNotification') && args['fromNotification'] == true) {
                  return Scaffold(
                    appBar: AppBar(
                      title: const Text('Chi tiết sản phẩm'),
                    ),
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shopping_cart,
                            size: 64,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Đang tải thông tin sản phẩm...',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mã sản phẩm: $productId',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Quay lại'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // Khi được gọi trực tiếp với một đối tượng Product
                final product = args?['product'];
                if (product == null) {
                  return const Scaffold(
                    body: Center(
                      child: Text('Không tìm thấy thông tin sản phẩm'),
                    ),
                  );
                }
                
                return ProductDetailScreen(product: product);
              },
            },
          );
        },
      ),
    );
  }
}
