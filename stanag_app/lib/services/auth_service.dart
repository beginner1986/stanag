import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  User? get currentUser => _auth.currentUser;

  Future<void> signInAnonymously() async {
    if (_auth.currentUser == null) return;
    await _auth.signInAnonymously();
  }
}