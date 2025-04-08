import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:student_market_nttu/screens/splash_screen.dart';
import 'package:student_market_nttu/services/auth_service.dart';
import 'package:student_market_nttu/services/theme_service.dart';
import 'package:student_market_nttu/services/shipper_service.dart';
import 'package:student_market_nttu/services/order_service.dart';
import 'package:student_market_nttu/services/review_service.dart';
import 'package:student_market_nttu/services/product_service.dart';
import 'package:student_market_nttu/services/user_service.dart';
import 'package:student_market_nttu/utils/web_utils.dart' if (dart.library.html) 'package:student_market_nttu/utils/web_utils_web.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Pass Firebase config to JavaScript if running on web
  if (kIsWeb) {
    final FirebaseOptions options = DefaultFirebaseOptions.web;
    initializeFirebaseWeb(options);
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => ProductService()),
        ChangeNotifierProvider(create: (_) => ReviewService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
        ChangeNotifierProvider(create: (_) => ShipperService()),
        ChangeNotifierProvider(create: (_) => UserService()),
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
