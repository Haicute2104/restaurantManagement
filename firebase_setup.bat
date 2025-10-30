@echo off
REM Firebase Setup Script for RMS Project (Windows)
REM This script automates Firebase configuration using FlutterFire CLI

echo.
echo 🔥 Restaurant Management System - Firebase Auto Setup
echo ======================================================
echo.

REM Check if Firebase CLI is installed
where firebase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Firebase CLI chưa được cài đặt!
    echo 📦 Đang cài đặt Firebase CLI...
    call npm install -g firebase-tools
)

REM Check if FlutterFire CLI is installed
where flutterfire >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ FlutterFire CLI chưa được cài đặt!
    echo 📦 Đang cài đặt FlutterFire CLI...
    call dart pub global activate flutterfire_cli
)

echo.
echo 🔐 Bước 1: Đăng nhập Firebase
echo ----------------------------
call firebase login

echo.
echo 🚀 Bước 2: Cấu hình FlutterFire cho dự án
echo ----------------------------------------
echo Lệnh này sẽ:
echo   - Tạo Firebase project (nếu chưa có)
echo   - Tạo Firebase apps cho Android và iOS
echo   - Tự động tạo firebase_options.dart
echo   - Download google-services.json và GoogleService-Info.plist
echo.

REM Run FlutterFire configure
call flutterfire configure ^
    --project=restaurant-rms ^
    --platforms=android,ios ^
    --out=lib/firebase_options.dart ^
    --android-package-name=com.example.quanlyphanmem ^
    --ios-bundle-id=com.example.quanlyphanmem

echo.
echo ✅ Bước 3: Cài đặt Firebase dependencies
echo ----------------------------------------
call flutter pub get

echo.
echo 🔥 Bước 4: Deploy Firestore Rules và Indexes
echo -------------------------------------------
call firebase deploy --only firestore:rules,firestore:indexes,storage:rules

echo.
echo ⚡ Bước 5: Deploy Cloud Functions
echo --------------------------------
cd functions
call npm install
cd ..
call firebase deploy --only functions

echo.
echo ✅ Setup hoàn tất!
echo ==================
echo.
echo 📱 Bây giờ bạn có thể chạy app:
echo   flutter run -t lib/main_customer.dart
echo   flutter run -t lib/main_staff.dart
echo   flutter run -t lib/main_admin.dart
echo.
pause





