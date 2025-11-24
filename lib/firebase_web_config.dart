// firebase_web_config.dart
import 'package:firebase_core/firebase_core.dart';

// firebase_web_config.dart
class FirebaseWebConfig {
  static const Map<String, String> firebaseConfig = {
    "apiKey": "AIzaSyBRyE61scbI21_JjKyW062VL5eYiHjSs3U",
    "authDomain": "wof-to-go.firebaseapp.com",
    "projectId": "wof-to-go",
    "storageBucket": "wof-to-go.firebasestorage.app", 
    "messagingSenderId": "630214947261",
    "appId": "1:630214947261:web:56d9e64b347e5016af22d4"
  };
    static FirebaseOptions get firebaseOptions {
    return FirebaseOptions(
      apiKey: "AIzaSyBRyE61scbI21_JjKyW062VL5eYiHjSs3U",
      authDomain: "wof-to-go.firebaseapp.com",
      projectId: "wof-to-go",
      storageBucket: "wof-to-go.firebasestorage.app",
      messagingSenderId: "630214947261",
      appId: "1:630214947261:web:56d9e64b347e5016af22d4",
    );
  }
}