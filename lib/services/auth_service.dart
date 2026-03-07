import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _fetchUserDetails(user.uid);
      } else {
        _currentUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      final creds = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (creds.user != null) {
        await _fetchUserDetails(creds.user!.uid);
      }
    } catch (e) {
      debugPrint("Login error: $e");
      rethrow;
    }
  }

  Future<void> registerWithEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final creds = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (creds.user != null) {
        final newUser = UserModel(
          id: creds.user!.uid,
          name: name,
          email: email,
        );
        await _firestore
            .collection('users')
            .doc(newUser.id)
            .set(newUser.toJson());
        _currentUser = newUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Register error: $e");
      rethrow;
    }
  }

  Future<void> _fetchUserDetails(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromJson(doc.data()!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile(String newName) async {
    try {
      if (_currentUser != null) {
        await _firestore.collection('users').doc(_currentUser!.id).update({
          'name': newName,
        });
        _currentUser = _currentUser!.copyWith(name: newName);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Update profile error: $e");
      rethrow;
    }
  }

  Future<void> changePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      debugPrint("Change password error: $e");
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user document from firestore
        if (_currentUser != null) {
          await _firestore.collection('users').doc(_currentUser!.id).delete();
        }
        await user.delete();
        _currentUser = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Delete account error: $e");
      rethrow;
    }
  }
}
