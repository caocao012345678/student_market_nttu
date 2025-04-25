// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:student_market_nttu/services/gemini_service.dart';
import 'package:student_market_nttu/services/app_layout_service.dart';
import 'package:student_market_nttu/services/db_service.dart';

import 'package:student_market_nttu/main.dart';

void main() {
  setUpAll(() async {
    // Mock loading environment variables
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // Set default values for testing
      dotenv.env['GEMINI_API_KEY'] = 'test_api_key';
    }
  });

  testWidgets('App initializes correctly', (WidgetTester tester) async {
    // Initialize required services for test
    final geminiService = GeminiService();
    final appLayoutService = AppLayoutService();
    final dbService = DbService();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      geminiService: geminiService,
      appLayoutService: appLayoutService,
      dbService: dbService,
    ));

    // Verify that app initializes without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
} 