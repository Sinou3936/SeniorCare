import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;
  static String? get uid => _auth.currentUser?.uid;
  static bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;
  static bool get isLinkedWithGoogle =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'google.com') ?? false;

  static Future<void> signInAnonymously() async {
    if (_auth.currentUser != null) return;
    await _auth.signInAnonymously();
  }

  /// ?�명 계정 ??Google 계정 ?�결 (?�그?�이??
  /// 반환�? 'success' | 'cancelled' | 'already_in_use' | 'error'
  static Future<String> linkWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'cancelled';

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.currentUser!.linkWithCredential(credential);
      return 'success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') return 'already_in_use';
      return 'error';
    } catch (_) {
      return 'error';
    }
  }

  /// Google 로그?�웃 (계정 ?�결 ?�제 ??
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
