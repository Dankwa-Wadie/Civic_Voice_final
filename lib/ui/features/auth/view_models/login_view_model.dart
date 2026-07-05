import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum LoginState { idle, loading, success, error }

/// Login view model — supports live FirebaseAuth with auto-provisioning and role checks.
class LoginViewModel extends ChangeNotifier {
  LoginState _state = LoginState.idle;
  String _errorMessage = '';
  String _email = '';
  String _password = '';
  bool _isAdmin = false;
  bool _isSignUp = false;

  LoginState get state => _state;
  String get errorMessage => _errorMessage;
  String get email => _email;
  String get password => _password;
  bool get isAdmin => _isAdmin;
  bool get isSignUp => _isSignUp;
  bool get isLoading => _state == LoginState.loading;
  bool get canSubmit => _email.isNotEmpty && _password.isNotEmpty && !isLoading;

  void toggleMode() {
    _isSignUp = !_isSignUp;
    _errorMessage = '';
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value.trim();
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

  /// Authenticates credentials. Uses FirebaseAuth if Firebase is active; otherwise uses mock logic.
  Future<bool> login() async {
    if (!canSubmit) return false;
    _state = LoginState.loading;
    _errorMessage = '';
    _isAdmin = false;
    notifyListeners();

    final hasFirebase = Firebase.apps.isNotEmpty;
    if (!hasFirebase) {
      // ── Phase 1 / Mock Fallback Auth ────────────────────────────────────────
      await Future.delayed(const Duration(milliseconds: 900));

      if (_email == 'fail@test.com') {
        _state = LoginState.error;
        _errorMessage = 'Invalid credentials. Please try again.';
        notifyListeners();
        return false;
      }

      _isAdmin = _email == 'admin@civicvoice.org' ||
          _email == 'admin@civicvoice.gov' ||
          _email.contains('admin') ||
          _email.endsWith('.gov');
      _state = LoginState.success;
      notifyListeners();
      return true;
    }

    // ── Phase 2: Live FirebaseAuth ───────────────────────────────────────────
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: _email, password: _password);

      final user = userCredential.user;
      if (user != null) {
        // 1. Resolve role from email pattern first
        final isEmailAdmin = user.email == 'admin@civicvoice.org' ||
            user.email == 'admin@civicvoice.gov' ||
            user.email?.startsWith('admin') == true ||
            user.email?.contains('admin') == true ||
            user.email?.endsWith('.gov') == true;

        if (isEmailAdmin) {
          _isAdmin = true;
          // Backfill admin role document in Firestore
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({'role': 'admin'}, SetOptions(merge: true));
          } catch (_) {}
        }

        // 2. Validate against custom claims
        try {
          final tokenResult = await user.getIdTokenResult();
          final claims = tokenResult.claims;
          if (claims != null &&
              (claims['admin'] == true || claims['role'] == 'admin')) {
            _isAdmin = true;
          }
        } catch (_) {}

        // 3. Fallback database verification
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
            _isAdmin = true;
          }
        } catch (_) {}
      }

      _state = LoginState.success;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _state = LoginState.error;
      _errorMessage = e.message ?? 'Authentication failed.';
      notifyListeners();
      return false;
    } catch (e) {
      _state = LoginState.error;
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Registers a new user. Uses FirebaseAuth if Firebase is active; otherwise uses mock logic.
  Future<bool> signUp() async {
    if (!canSubmit) return false;
    _state = LoginState.loading;
    _errorMessage = '';
    _isAdmin = false;
    notifyListeners();

    final hasFirebase = Firebase.apps.isNotEmpty;
    if (!hasFirebase) {
      await Future.delayed(const Duration(milliseconds: 900));
      _isAdmin = _email == 'admin@civicvoice.org' ||
          _email == 'admin@civicvoice.gov' ||
          _email.contains('admin') ||
          _email.endsWith('.gov');
      _state = LoginState.success;
      notifyListeners();
      return true;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: _email, password: _password);
      
      final user = userCredential.user;
      if (user != null) {
        // Resolve role from email pattern first
        final isEmailAdmin = user.email == 'admin@civicvoice.org' ||
            user.email == 'admin@civicvoice.gov' ||
            user.email?.startsWith('admin') == true ||
            user.email?.contains('admin') == true ||
            user.email?.endsWith('.gov') == true;

        if (isEmailAdmin) {
          _isAdmin = true;
        }

        // Initialize user document in Firestore
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'uid': user.uid,
            'email': user.email,
            'role': _isAdmin ? 'admin' : 'citizen',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      _state = LoginState.success;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _state = LoginState.error;
      _errorMessage = e.message ?? 'Registration failed.';
      notifyListeners();
      return false;
    } catch (e) {
      _state = LoginState.error;
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _state = LoginState.idle;
    _errorMessage = '';
    _isAdmin = false;
    notifyListeners();
  }
}
