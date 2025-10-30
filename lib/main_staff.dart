import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'shared/utils/constants.dart';
import 'shared/providers/auth_provider.dart';
import 'staff/screens/auth/staff_login_screen.dart';
import 'staff/screens/home/staff_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: StaffApp()));
}

class StaffApp extends ConsumerWidget {
  const StaffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: AppConstants.staffAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.staffPrimary,
          primary: AppColors.staffPrimary,
        ),
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      home: authState.when(
        data: (user) => user != null ? const StaffHomeScreen() : const StaffLoginScreen(),
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

