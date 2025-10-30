import 'package:flutter/material.dart';

class AppConstants {
  // App Names
  static const String customerAppName = 'Restaurant - Khách hàng';
  static const String staffAppName = 'Restaurant - Nhân viên';
  static const String adminAppName = 'Restaurant - Quản lý';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxTableNumber = 100;

  // Timeouts
  static const Duration orderUpdateTimeout = Duration(seconds: 30);
  
  // Pagination
  static const int itemsPerPage = 20;
}

class AppColors {
  // Customer App - Warm & Inviting (Coral/Orange theme)
  static const Color customerPrimary = Color(0xFFFF6B35);  // Vibrant Coral
  static const Color customerAccent = Color(0xFFFFB84D);   // Warm Orange
  
  // Staff App - Fresh & Energetic (Teal/Cyan theme)
  static const Color staffPrimary = Color(0xFF00B4D8);     // Bright Cyan
  static const Color staffAccent = Color(0xFF0077B6);      // Deep Blue
  
  // Admin App - Professional & Bold (Indigo/Purple theme)
  static const Color adminPrimary = Color(0xFF6366F1);     // Modern Indigo
  static const Color adminAccent = Color(0xFF4F46E5);      // Deep Indigo
  
  // Common - Modern & Clean
  static const Color success = Color(0xFF10B981);          // Emerald Green
  static const Color warning = Color(0xFFF59E0B);          // Amber
  static const Color error = Color(0xFFEF4444);            // Modern Red
  static const Color info = Color(0xFF3B82F6);             // Blue
  
  // Order Status Colors - Clear & Distinct
  static const Color statusPending = Color(0xFFFBBF24);    // Yellow (Pending/Waiting)
  static const Color statusConfirmed = Color(0xFF3B82F6);  // Blue (Confirmed)
  static const Color statusPreparing = Color(0xFFF97316);  // Orange (In Progress)
  static const Color statusReady = Color(0xFF10B981);      // Green (Ready)
  static const Color statusCompleted = Color(0xFF8B5CF6);  // Purple (Completed)
  static const Color statusCancelled = Color(0xFF6B7280);  // Gray (Cancelled)
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppBorderRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double round = 100.0;
}


