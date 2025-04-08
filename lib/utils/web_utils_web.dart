import 'dart:js' as js;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// Actual implementation for web platforms
void initializeFirebaseWeb(FirebaseOptions options) {
  if (!kIsWeb) return;
  
  try {
    final Map<String, dynamic> firebaseConfig = {
      'apiKey': options.apiKey,
      'authDomain': options.authDomain,
      'databaseURL': options.databaseURL,
      'projectId': options.projectId,
      'storageBucket': options.storageBucket,
      'messagingSenderId': options.messagingSenderId,
      'appId': options.appId,
      'measurementId': options.measurementId,
    };
    
    // Expose config to JavaScript
    js.context['firebaseConfig'] = firebaseConfig;
    // Call the initialization function
    js.context.callMethod('initializeFirebase');
  } catch (e) {
    debugPrint('Error initializing web config: $e');
  }
} 