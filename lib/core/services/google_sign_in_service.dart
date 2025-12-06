import 'package:google_sign_in/google_sign_in.dart';

/// Singleton service for Google Sign-In
/// Shared between AuthService and GoogleDriveService
class GoogleSignInService {
  // Singleton instance
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  /// Get the GoogleSignIn instance
  GoogleSignIn get googleSignIn => _googleSignIn;

  /// Get current user
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _googleSignIn.currentUser != null;
}
