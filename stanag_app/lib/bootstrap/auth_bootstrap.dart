import 'package:firebase_auth/firebase_auth.dart';
import 'package:stanag_app/services/auth_service.dart';

class AuthBootstrap {
  static Future<User?> initialize() async {
    final auth = FirebaseAuth.instance;
    await AuthService(auth).signInAnonymously();
    return auth.currentUser;
  }
}
