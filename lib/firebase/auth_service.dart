import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Web (server) OAuth client ID. Must match the "Web application" client in the
/// Firebase console (Authentication > Sign-in method > Google). This is what
/// [GoogleSignIn] uses on Android to present the Google account chooser and
/// mint the idToken that Firebase consumes.
const String _webClientId =
    '158761867423-hlef2i3m28hu1r8ht1sjpiqgfo0oqr9m.apps.googleusercontent.com';

/// Thin wrapper around [FirebaseAuth] and [GoogleSignIn].
///
/// Every Google account maps to one permanent Firebase user whose UID is the
/// stable Google identity. The session is persisted by Firebase, so the player
/// stays signed in across restarts and is restored automatically on launch.
/// Each account keeps a fully isolated `players/{uid}` cloud profile.
class AuthService extends ChangeNotifier {
  AuthService(this._auth, {GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  AuthService.disabled({GoogleSignIn? googleSignIn})
      : _auth = null,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn;

  User? _user;
  String? _error;

  User? get currentUser => _user;
  User? get user => _user;
  String? get uid => _user?.uid;
  bool get isSignedIn => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? true;
  String? get error => _error;

  /// True when Firebase already holds a persisted, non-anonymous user from a
  /// previous sign-in (i.e. the player does not need to pick an account again).
  bool get hasPersistedUser {
    final auth = _auth;
    if (auth == null) return false;
    final user = auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  /// Restores a previously authenticated session without any user interaction.
  /// Reads [FirebaseAuth.instance.currentUser] (Firebase persists this across
  /// restarts) and refreshes the token if needed. Returns the [User] if a
  /// sessions exists, or `null` if the player must sign in.
  Future<User?> restoreSession() async {
    final auth = _auth;
    if (auth == null) {
      _user = null;
      notifyListeners();
      return null;
    }
    _user = auth.currentUser;
    if (_user == null) {
      notifyListeners();
      return null;
    }
    // Silently refresh the credential if it has aged; ignore failures so a
    // stale token never crashes the auto-login path.
    try {
      final u = _user;
      if (u == null) return null; // already null, shouldn't reach here
      await u.reload();
      _user = auth.currentUser;
      final refreshed = _user;
      if (refreshed != null && refreshed.isAnonymous) {
        // Anonymous-only sessions are not valid for persistent Google profiles.
        _user = null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AuthService: session refresh failed: $e');
      // Keep the cached user; the next Firestore call will surface re-auth needs.
    }
    _error = null;
    notifyListeners();
    return _user;
  }

  /// Signs in with Google, minting (or restoring) the permanent Firebase user
  /// for that Google account. The Google UID is authoritative and persisted by
  /// Firebase, so every Google account owns an isolated cloud profile. Returns
  /// the Firebase [User] on success, or `null` if the flow was cancelled/failed.
  Future<User?> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      _error =
          'Google Sign-In is unavailable right now. Play Offline still works.';
      notifyListeners();
      return null;
    }
    try {
      await _googleSignIn.initialize(serverClientId: _webClientId);

      // Always clear any cached Google account first. The v7 plugin caches the
      // last signed-in account, and without this `authenticate()` returns it
      // silently WITHOUT showing the Google Account Chooser. Clearing here
      // guarantees the chooser opens every time "Continue with Google" is tapped
      // (including right after a logout).
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Best-effort: ignore if there was no cached account.
      }

      final googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) return null;

      // The v7 plugin only exposes the idToken directly; the access token is
      // fetched on demand via the authorization client for the requested scopes.
      String? accessToken;
      try {
        final authz = await googleUser.authorizationClient
            .authorizationForScopes(const ['email', 'profile']);
        accessToken = authz?.accessToken;
      } catch (_) {
        // Non-fatal: idToken alone is enough for Firebase on most setups.
        accessToken = null;
      }

      // Build the Firebase credential. idToken is what Firebase validates; the
      // access token is included when available.
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      // Always use signInWithCredential so the Google UID is the persistent,
      // authoritative identity for this account (no anonymous linking).
      final result = await auth.signInWithCredential(credential);
      _user = result.user;

      _error = null;
      notifyListeners();
      return _user;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      _error = e.toString();
      if (kDebugMode) {
        debugPrint('AuthService: Google sign-in failed: $e');
      }
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        debugPrint('AuthService: Google sign-in failed: $e');
      }
      notifyListeners();
      return null;
    }
  }

  /// Re-authenticates the current user with Google. Required when Firebase
  /// operations need a recent login (e.g. account deletion).
  Future<User?> reauthenticateWithGoogle() async {
    return signInWithGoogle();
  }

  /// Signs out from both Google and Firebase and clears only the local
  /// authentication / session cache. No Firestore data is deleted, so the
  /// player's cloud profile is fully restored on the next sign-in.
  ///
  /// [clearLocalSession] is invoked to wipe locally-persisted session flags
  /// (e.g. SharedPreferences keys). Passing it lets callers control exactly what
  /// is cleared without touching cloud documents.
  Future<void> signOut({Future<void> Function()? clearLocalSession}) async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // ignore Google sign-out failures
    }
    try {
      await _auth?.signOut();
    } catch (_) {
      // ignore Firebase sign-out failures
    }
    if (clearLocalSession != null) {
      try {
        await clearLocalSession();
      } catch (_) {
        // best-effort: never block sign-out on local cache cleanup failing
      }
    }
    _user = null;
    _error = null;
    notifyListeners();
  }
}
