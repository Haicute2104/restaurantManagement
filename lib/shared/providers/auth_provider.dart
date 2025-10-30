import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.asyncMap((user) async {
    if (user != null) {
      return await authService.getUserData(user.uid);
    }
    return null;
  });
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).value;
});





