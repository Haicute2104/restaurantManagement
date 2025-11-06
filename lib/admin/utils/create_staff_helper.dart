// HELPER để Admin tạo Staff users
// Chỉ dùng trong Admin App

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/user_model.dart';

class CreateStaffHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tạo Staff user (chỉ Admin mới được gọi)
  static Future<String?> createStaffUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Tạo user trong Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Tạo document trong Firestore với role STAFF
        final staffUser = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          role: UserRole.staff,  // STAFF role
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(staffUser.uid)
            .set(staffUser.toJson());

        return staffUser.uid;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Tạo Admin user
  static Future<String?> createAdminUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final adminUser = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          role: UserRole.admin,  // ADMIN role
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(adminUser.uid)
            .set(adminUser.toJson());

        return adminUser.uid;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user role (chỉ admin)
  static Future<void> updateUserRole(String uid, UserRole newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': newRole.name,
      });
    } catch (e) {
      rethrow;
    }
  }
}










