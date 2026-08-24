import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<Map<String, dynamic>> merchantLogin({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (cred.user == null) {
        return {'success': false, 'message': 'Login failed'};
      }

      return {
        'success': true,
        'user': cred.user,
        'message': 'Login successful',
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _mapFirebaseError(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> merchantRegister({
    required String storeName,
    required String ownerName,
    required String email,
    required String phone,
    required String category,
    required String location,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = cred.user!.uid;

      await _db.collection('merchants').doc(uid).set({
        'uid': uid,
        'storeName': storeName.trim(),
        'ownerName': ownerName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'category': category.trim(),
        'location': location.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'user': cred.user,
        'message': 'Registration successful',
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _mapFirebaseError(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<void> merchantLogout() async {
    await _auth.signOut();
  }

  static String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email format.';
      default:
        return 'Authentication failed: $code';
    }
  }
}
