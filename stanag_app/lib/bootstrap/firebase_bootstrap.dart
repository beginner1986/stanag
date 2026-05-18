import 'package:firebase_core/firebase_core.dart';
import 'package:stanag_app/firebase_options_dev.dart' as dev;
import 'package:stanag_app/firebase_options_prod.dart' as prod;
import 'package:stanag_app/firebase_options_staging.dart' as staging;

class FirebaseBootstrap {
  static Future<void> initialize(String flavor) async {
    final options = switch (flavor) {
      'staging' => staging.DefaultFirebaseOptions.currentPlatform,
      'prod' => prod.DefaultFirebaseOptions.currentPlatform,
      _ => dev.DefaultFirebaseOptions.currentPlatform,
    };
    await Firebase.initializeApp(options: options);
  }
}
