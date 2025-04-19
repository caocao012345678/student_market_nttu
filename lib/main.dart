import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:student_market_nttu/screens/splash_screen.dart';
import 'package:student_market_nttu/services/auth_service.dart';
import 'package:student_market_nttu/services/theme_service.dart';
import 'package:student_market_nttu/services/shipper_service.dart';
import 'package:student_market_nttu/services/order_service.dart';
import 'package:student_market_nttu/services/review_service.dart';
import 'package:student_market_nttu/services/product_service.dart';
import 'package:student_market_nttu/services/user_service.dart';
import 'package:student_market_nttu/services/favorites_service.dart';
import 'package:student_market_nttu/services/chat_service.dart';
import 'package:student_market_nttu/services/cart_service.dart';
import 'package:student_market_nttu/services/gemini_service.dart';
import 'package:student_market_nttu/services/rag_service.dart';
import 'package:student_market_nttu/services/app_layout_service.dart';
import 'package:student_market_nttu/services/db_service.dart';
import 'package:student_market_nttu/services/auto_improvement_service.dart';
import 'package:student_market_nttu/services/category_service.dart';
import 'package:student_market_nttu/utils/web_utils.dart' if (dart.library.html) 'package:student_market_nttu/utils/web_utils_web.dart';
import 'firebase_options.dart';

// Thêm lớp MyApp để sử dụng trong widget_test.dart
class MyApp extends StatelessWidget {
  final GeminiService geminiService;
  final AppLayoutService appLayoutService;
  final DbService dbService;

  const MyApp({
    Key? key, 
    required this.geminiService, 
    required this.appLayoutService, 
    required this.dbService
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider<ThemeService>(
          create: (_) => ThemeService(),
        ),
        ChangeNotifierProvider(create: (_) => ProductService()),
        ChangeNotifierProvider(create: (_) => ReviewService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
        ChangeNotifierProvider(create: (_) => ShipperService()),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => FavoritesService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => CategoryService()),
        ChangeNotifierProvider.value(value: geminiService),
        ChangeNotifierProvider.value(value: appLayoutService),
        ChangeNotifierProvider(create: (_) => RAGService(geminiService)),
        Provider.value(value: dbService),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
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
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Nạp biến môi trường từ .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Không thể tải tệp .env: $e");
    // Đặt giá trị mặc định
    dotenv.env['GEMINI_API_KEY'] = const String.fromEnvironment('GEMINI_API_KEY', 
        defaultValue: 'AIzaSyCGPdS0XY68bFH7ADXcpKd83aEyuWX8hWA');
  }
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Pass Firebase config to JavaScript if running on web
  if (kIsWeb) {
    final FirebaseOptions options = DefaultFirebaseOptions.web;
    initializeFirebaseWeb(options);
  }
  
  // Khởi tạo các services chính
  final geminiService = GeminiService();
  await geminiService.initialize();
  
  final appLayoutService = AppLayoutService();
  final dbService = DbService();
  
  final ragService = RAGService(geminiService);
  ragService.setAppLayoutService(appLayoutService);
  
  // Tạo service tự động cải thiện
  final autoImprovementService = AutoImprovementService(geminiService, appLayoutService);
  
  // Khởi động quá trình tự động cải thiện 1 lần mỗi ngày
  autoImprovementService.startAutoImprovement(interval: const Duration(hours: 24));
  
  // Đảm bảo rằng các services được khởi tạo trước khi chạy ứng dụng
  runApp(
    MyApp(
      geminiService: geminiService,
      appLayoutService: appLayoutService,
      dbService: dbService,
    ),
  );
}

// Hàm đồng bộ dữ liệu RAG
Future<void> _syncRAGData(AppLayoutService appLayoutService, DbService dbService) async {
  try {
    // Đồng bộ dữ liệu bố cục ứng dụng (UI, màn hình, tính năng)
    await dbService.syncUIComponentsData(appLayoutService);
    
    // Đồng bộ metadata sản phẩm (thực hiện trong nền)
    dbService.enhanceProductMetadata().catchError((e) {
      debugPrint('Lỗi khi nâng cao metadata sản phẩm: $e');
    });
    
    // Đồng bộ mối quan hệ danh mục (thực hiện trong nền)
    dbService.createCategoryRelations().catchError((e) {
      debugPrint('Lỗi khi tạo mối quan hệ danh mục: $e');
    });
    
    // Đồng bộ dữ liệu FAQ
    final faqData = _getDefaultFAQs();
    await dbService.syncFAQData(faqData).catchError((e) {
      debugPrint('Lỗi khi đồng bộ dữ liệu FAQ: $e');
    });
    
    debugPrint('Đồng bộ dữ liệu RAG thành công');
  } catch (e) {
    debugPrint('Lỗi khi đồng bộ dữ liệu RAG: $e');
  }
}

// Dữ liệu FAQ mặc định
List<Map<String, dynamic>> _getDefaultFAQs() {
  return [
    {
      'question': 'Làm thế nào để đăng bán sản phẩm?',
      'answer': 'Để đăng bán sản phẩm, hãy nhấn vào nút "+" ở góc dưới phải của màn hình chính hoặc vào mục "Sản phẩm của tôi" trong trang hồ sơ, sau đó chọn "Đăng sản phẩm mới". Điền thông tin sản phẩm, thêm hình ảnh và nhấn "Đăng bán".',
      'category': 'Đăng bán',
      'tags': ['đăng bán', 'sản phẩm mới', 'tạo sản phẩm'],
    },
    {
      'question': 'Làm thế nào để tìm kiếm sản phẩm?',
      'answer': 'Để tìm kiếm sản phẩm, nhấn vào biểu tượng kính lúp ở thanh tìm kiếm phía trên màn hình chính hoặc chọn tab Tìm kiếm. Nhập từ khóa và sử dụng bộ lọc để tìm sản phẩm theo danh mục, giá cả hoặc tình trạng.',
      'category': 'Tìm kiếm',
      'tags': ['tìm kiếm', 'bộ lọc', 'danh mục'],
    },
    {
      'question': 'Làm thế nào để liên hệ với người bán?',
      'answer': 'Để liên hệ với người bán, vào trang chi tiết sản phẩm và nhấn vào nút "Chat với người bán". Điều này sẽ mở cuộc trò chuyện riêng giữa bạn và người bán để trao đổi về sản phẩm.',
      'category': 'Liên hệ',
      'tags': ['chat', 'liên hệ', 'người bán'],
    },
    {
      'question': 'Làm thế nào để thanh toán?',
      'answer': 'Để thanh toán, thêm sản phẩm vào giỏ hàng và nhấn "Thanh toán". Chọn địa chỉ giao hàng, phương thức thanh toán và xác nhận đơn hàng. Ứng dụng hỗ trợ thanh toán khi nhận hàng, chuyển khoản ngân hàng và ví điện tử.',
      'category': 'Thanh toán',
      'tags': ['thanh toán', 'giỏ hàng', 'đặt hàng'],
    },
    {
      'question': 'Làm thế nào để theo dõi đơn hàng?',
      'answer': 'Để theo dõi đơn hàng, vào trang hồ sơ và chọn mục "Đơn hàng". Bạn sẽ thấy danh sách các đơn hàng đã đặt/bán và tình trạng hiện tại của chúng. Nhấn vào đơn hàng cụ thể để xem chi tiết và theo dõi quá trình giao hàng.',
      'category': 'Đơn hàng',
      'tags': ['theo dõi', 'đơn hàng', 'tình trạng'],
    },
    {
      'question': 'Làm thế nào để đánh giá sản phẩm?',
      'answer': 'Để đánh giá sản phẩm, vào mục "Đơn hàng" trong trang hồ sơ, chọn đơn hàng đã hoàn thành, và nhấn vào "Đánh giá". Cho điểm (1-5 sao), viết nhận xét và tải lên hình ảnh thực tế của sản phẩm nếu muốn.',
      'category': 'Đánh giá',
      'tags': ['đánh giá', 'nhận xét', 'sao'],
    },
    {
      'question': 'Điểm NTT là gì và sử dụng như thế nào?',
      'answer': 'Điểm NTT là điểm thưởng trong ứng dụng Student Market NTTU. Bạn nhận được điểm khi mua hàng, bán hàng hoặc đánh giá sản phẩm. Điểm NTT có thể dùng để đổi lấy ưu đãi, giảm giá hoặc các dịch vụ đặc biệt trong ứng dụng.',
      'category': 'Điểm thưởng',
      'tags': ['điểm NTT', 'ưu đãi', 'thưởng'],
    },
    {
      'question': 'Làm thế nào để đổi mật khẩu?',
      'answer': 'Để đổi mật khẩu, vào trang hồ sơ và chọn mục "Cài đặt". Chọn "Đổi mật khẩu", nhập mật khẩu hiện tại và mật khẩu mới, sau đó xác nhận để hoàn tất việc đổi mật khẩu.',
      'category': 'Tài khoản',
      'tags': ['mật khẩu', 'bảo mật', 'đổi mật khẩu'],
    },
    {
      'question': 'Làm thế nào để đăng ký làm shipper?',
      'answer': 'Để đăng ký làm shipper, vào trang hồ sơ và chọn mục "Trở thành Shipper". Điền thông tin cá nhân, phương tiện di chuyển, khu vực hoạt động và tải lên các giấy tờ xác thực. Sau khi gửi đơn, đội ngũ xét duyệt sẽ liên hệ lại với bạn.',
      'category': 'Shipper',
      'tags': ['shipper', 'đăng ký', 'giao hàng'],
    },
    {
      'question': 'Làm thế nào để báo cáo sản phẩm vi phạm?',
      'answer': 'Để báo cáo sản phẩm vi phạm, vào trang chi tiết sản phẩm, nhấn vào biểu tượng "..." ở góc phải trên cùng và chọn "Báo cáo". Chọn lý do báo cáo, cung cấp thông tin bổ sung và gửi báo cáo để đội ngũ kiểm duyệt xem xét.',
      'category': 'Báo cáo',
      'tags': ['báo cáo', 'vi phạm', 'kiểm duyệt'],
    },
  ];
}
