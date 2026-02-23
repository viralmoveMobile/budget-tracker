import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;

  AuthRepository() {
    try {
      // Safely attempt to get instance. If Firebase.initializeApp() failed,
      // this might throw or effectively be unusable.
      // However, usually checking instance is fine if the app didn't crash on init.
      // But user reports core/no-app error, so we must be defensive.
      _auth = FirebaseAuth.instance;
      _googleSignIn = GoogleSignIn();
    } catch (e) {
      print(
          "AuthRepository: Firebase not initialized. Mode: Offline/Mock. Error: $e");
    }
  }

  // Stream of auth changes
  Stream<User?> get authStateChanges {
    if (_auth == null) return Stream.value(null);
    return _auth!.authStateChanges();
  }

  // Mock Login for UI testing (since Firebase might not be configured)
  Future<void> signInMock() async {
    // No-op for mock
  }

  Future<UserCredential> signInWithGoogle() async {
    if (_auth == null || _googleSignIn == null)
      throw Exception("Firebase not initialized");

    final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
    if (googleUser == null) throw Exception('Google Sign In Aborted');

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth!.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (_googleSignIn != null) await _googleSignIn!.signOut();
    if (_auth != null) await _auth!.signOut();
  }

  Future<void> updatePassword(String newPassword) async {
    if (_auth == null || _auth!.currentUser == null) {
      throw Exception("User not authenticated or Firebase not initialized");
    }
    await _auth!.currentUser!.updatePassword(newPassword);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (_auth == null) throw Exception("Firebase not initialized");
    await _auth!.sendPasswordResetEmail(email: email);
  }
}
