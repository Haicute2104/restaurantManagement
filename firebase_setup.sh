#!/bin/bash

# Firebase Setup Script for RMS Project
# This script automates Firebase configuration using FlutterFire CLI

echo "🔥 Restaurant Management System - Firebase Auto Setup"
echo "======================================================"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI chưa được cài đặt!"
    echo "📦 Đang cài đặt Firebase CLI..."
    npm install -g firebase-tools
fi

# Check if FlutterFire CLI is installed
if ! command -v flutterfire &> /dev/null; then
    echo "❌ FlutterFire CLI chưa được cài đặt!"
    echo "📦 Đang cài đặt FlutterFire CLI..."
    dart pub global activate flutterfire_cli
fi

echo ""
echo "🔐 Bước 1: Đăng nhập Firebase"
echo "----------------------------"
firebase login

echo ""
echo "🚀 Bước 2: Cấu hình FlutterFire cho dự án"
echo "----------------------------------------"
echo "Lệnh này sẽ:"
echo "  - Tạo Firebase project (nếu chưa có)"
echo "  - Tạo Firebase apps cho Android & iOS"
echo "  - Tự động tạo firebase_options.dart"
echo "  - Download google-services.json và GoogleService-Info.plist"
echo ""

# Run FlutterFire configure
flutterfire configure \
    --project=restaurant-rms \
    --platforms=android,ios \
    --out=lib/firebase_options.dart \
    --android-package-name=com.example.quanlyphanmem \
    --ios-bundle-id=com.example.quanlyphanmem

echo ""
echo "✅ Bước 3: Cài đặt Firebase dependencies"
echo "----------------------------------------"
flutter pub get

echo ""
echo "🔥 Bước 4: Deploy Firestore Rules & Indexes"
echo "-------------------------------------------"
firebase deploy --only firestore:rules,firestore:indexes,storage:rules

echo ""
echo "⚡ Bước 5: Deploy Cloud Functions"
echo "--------------------------------"
cd functions
npm install
cd ..
firebase deploy --only functions

echo ""
echo "✅ Setup hoàn tất!"
echo "=================="
echo ""
echo "📱 Bây giờ bạn có thể chạy app:"
echo "  flutter run -t lib/main_customer.dart"
echo "  flutter run -t lib/main_staff.dart"
echo "  flutter run -t lib/main_admin.dart"
echo ""





