import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class FirebaseService {
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  /// Khởi tạo Firebase với DefaultFirebaseOptions
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
    } catch (e) {
      // Trường hợp Firebase đã được khởi tạo trước đó ở native
      if (e.toString().contains('duplicate-app')) {
        _initialized = true;
      } else {
        rethrow;
      }
    }
  }

  /// Kiểm tra kết nối Firestore thực tế
  static Future<bool> testFirestoreConnection() async {
    try {
      // Gọi thử 1 truy vấn nhẹ để kiểm tra kết nối với Cloud Firestore
      await FirebaseFirestore.instance.collection('_healthcheck').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }
}
