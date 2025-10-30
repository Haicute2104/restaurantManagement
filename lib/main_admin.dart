import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'shared/utils/constants.dart';
import 'shared/providers/auth_provider.dart';
import 'admin/screens/auth/admin_login_screen.dart';
import 'admin/screens/home/admin_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: AdminApp()));
}

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: AppConstants.adminAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.adminPrimary,
          primary: AppColors.adminPrimary,
        ),
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      home: authState.when(
        data: (user) => user != null ? const AdminHomeScreen() : const AdminLoginScreen(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          body: Center(child: Text('Lỗi: $error')),
        ),
      ),
    );
  }
}

