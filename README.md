# Pest Control Technician App

A professional Flutter-based pest control technician mobile application for iOS and Android platforms.

## 📱 Platform Support

### ✅ Android
- Full support with optimized UI/UX
- Android 8.0 (API 26) and above
- See: `android/README_ANDROID.md` (if exists)

### ✅ iOS (NEW)
- Full support with native iOS design patterns
- iOS 14.0 and above
- See: `ios/README_iOS.md`

---

## 🚀 Quick Start

### Prerequisites
- Flutter 3.44.8 or later
- Dart 3.12+
- iOS: Xcode 15.0+ (macOS required)
- Android: Android Studio or Android SDK

### Android Development
```bash
flutter run
# or run on specific device
flutter run -d <device-id>
```

### iOS Development (macOS only)
```bash
# Setup iOS environment
bash scripts/ios_setup.sh

# Run on simulator
flutter run

# Run on device
flutter run -d <device-id>

# For detailed iOS setup, see
cat iOS_BUILD_GUIDE.md
```

---

## 📋 Features

### Core Functionality
- ✅ Technician authentication & login
- ✅ Job assignment management
- ✅ Real-time job status tracking
- ✅ Location services with GPS tracking
- ✅ Photo capture (before/after)
- ✅ QR code scanning for quick job access
- ✅ Digital signature capture
- ✅ PDF report generation
- ✅ Offline mode with data synchronization
- ✅ Commission tracking
- ✅ Availability management (blocked slots)

### Technical Features
- Modern Flutter architecture
- Responsive UI for all screen sizes
- Native platform integration (iOS & Android)
- REST API integration
- Local data persistence
- Comprehensive error handling
- Detailed logging & debugging

---

## 📂 Project Structure

```
technician app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── config/                   # App configuration
│   │   ├── app_constants.dart
│   │   └── api_config.dart
│   ├── models/                   # Data models
│   │   ├── technician.dart
│   │   ├── job.dart
│   │   └── ...
│   ├── screens/                  # UI screens
│   │   ├── login/
│   │   ├── dashboard/
│   │   ├── jobs/
│   │   └── ...
│   ├── services/                 # Business logic
│   │   ├── api_service.dart
│   │   ├── location_service.dart
│   │   └── ...
│   ├── utils/                    # Utility functions
│   │   ├── helpers.dart
│   │   └── validators.dart
│   └── widgets/                  # Reusable UI components
│       ├── custom_buttons.dart
│       └── ...
├── assets/                       # Images, icons, fonts
├── android/                      # Android platform files
├── ios/                          # iOS platform files (NEW)
├── pubspec.yaml                  # Dependencies
└── README.md                     # This file
```

---

## 🔧 Setup Instructions

### 1. Clone/Extract Project
```bash
cd technician\ app
```

### 2. Get Dependencies
```bash
flutter pub get
```

### 3. Run Application

**Android:**
```bash
flutter run
```

**iOS (macOS):**
```bash
flutter run
# or
open ios/Runner.xcworkspace  # For Xcode configuration
```

---

## 📦 Dependencies

### Core Flutter
- `flutter` - Core framework
- `cupertino_icons` - iOS icons

### UI & Fonts
- `google_fonts` - Custom fonts from Google
- `table_calendar` - Calendar widget for scheduling

### Data & API
- `http` - HTTP client for REST API
- `shared_preferences` - Local data storage
- `intl` - Internationalization

### Location & Maps
- `geolocator` - GPS location services
- `geocoding` - Address geocoding/reverse geocoding

### Media & Scanning
- `qr_flutter` - QR code generation
- `image_picker` - Photo selection and capture
- `signature` - Signature capture widget

### Documents
- `pdf` - PDF generation
- `printing` - Print functionality

### Permissions
- `permission_handler` - Request user permissions

### Platform Support
- `geolocator_apple` - iOS location services
- `permission_handler_apple` - iOS permissions
- `image_picker_ios` - iOS camera/photo library
- `url_launcher_ios` - iOS URL handling
- `geocoding_ios` - iOS reverse geocoding

See `pubspec.yaml` for complete dependency list and versions.

---

## 🏗️ Build & Deployment

### Android Build

#### Debug
```bash
flutter build apk --debug
```

#### Release
```bash
flutter build apk --release
```

#### App Bundle (Google Play)
```bash
flutter build appbundle --release
```

### iOS Build

#### Development (Simulator)
```bash
flutter run
```

#### Device Build
```bash
flutter run --release
```

#### App Store Build
```bash
flutter build ipa --release
```

#### Detailed iOS Instructions
See: `iOS_BUILD_GUIDE.md`

---

## 🔍 Development

### Code Analysis
```bash
flutter analyze
```

### Run Tests
```bash
flutter test
```

### Format Code
```bash
flutter format lib/
```

### Generate Platform-Specific Code
```bash
flutter pub get
flutter pub run build_runner build
```

---

## 🐛 Debugging

### Verbose Output
```bash
flutter run -v
```

### View Logs
```bash
flutter logs
```

### Attach to Running App
```bash
flutter attach
```

### iOS-Specific Debugging
1. Open `ios/Runner.xcworkspace` in Xcode
2. Run app: Product → Run
3. View logs: View → Debug Area

---

## 📋 iOS Setup Checklist

Before building for iOS, verify:
- [ ] macOS 13.0 or later
- [ ] Xcode 15.0+ installed
- [ ] CocoaPods installed (`gem install cocoapods`)
- [ ] iOS deployment target: 14.0+
- [ ] All permissions in `ios/Runner/Info.plist`
- [ ] Bundle identifier configured
- [ ] Signing & capabilities configured in Xcode

See: `iOS_SETUP_CHECKLIST.md` for detailed checklist

---

## 🔐 Configuration

### API Endpoints
Edit `lib/config/api_config.dart`:
```dart
const String baseUrl = 'https://your-api-endpoint.com/api';
```

### iOS-Specific Settings
Edit `ios/Runner/Info.plist`:
- App name: CFBundleDisplayName
- Bundle ID: CFBundleIdentifier
- Permissions: NSLocation*, NSCamera*, NSPhotoLibrary*

### Android-Specific Settings
Edit `android/app/build.gradle`:
- minSdkVersion
- targetSdkVersion
- versionCode / versionName

---

## 🌍 Localization & Internationalization

The app supports multiple languages through `intl` package:

Supported languages:
- English (default)
- Add more by extending `lib/config/app_constants.dart`

---

## 📊 Project Statistics

- **Platform**: Flutter 3.44.8
- **Languages**: Dart, Swift (iOS), Kotlin (Android)
- **Minimum SDK**: 
  - iOS: 14.0
  - Android: 8.0 (API 26)
- **Dependencies**: 25+ packages
- **Status**: Production-ready

---

## 🤝 Contributing

When making changes:

1. Follow Flutter style guide
2. Run `flutter format` before committing
3. Run `flutter analyze` and fix warnings
4. Test on both Android and iOS
5. Update documentation

---

## 📞 Support & Documentation

### Quick Links
- [Flutter Documentation](https://flutter.dev/docs)
- [iOS Setup Guide](iOS_BUILD_GUIDE.md)
- [iOS Platform Config](ios/iOS_PLATFORM_CONFIG.md)
- [iOS Checklist](iOS_SETUP_CHECKLIST.md)

### Common Issues
See troubleshooting sections in:
- iOS Development: `iOS_BUILD_GUIDE.md` → Troubleshooting
- iOS Setup: `ios/README_iOS.md` → Troubleshooting Build Issues

---

## 📝 Version History

| Version | Date | Platform | Status |
|---------|------|----------|--------|
| 1.0.0 | Aug 2026 | Android + iOS | Current |
| 0.9.0 | Jul 2026 | Android | Archived |

---

## 🎯 Future Enhancements

- [ ] Push notifications
- [ ] Real-time communication
- [ ] Advanced analytics
- [ ] Offline map support
- [ ] Video documentation
- [ ] Voice notes
- [ ] Multi-language support expansion

---

## 📄 License

[Add your license information here]

---

## 👥 Team

**Pest Control Technology Team**
- Lead Developer
- iOS Specialist (as needed)
- Android Specialist (as needed)
- QA Team

---

## 🗓️ Last Updated

- **Date**: August 15, 2026
- **Flutter Version**: 3.44.8
- **Dart Version**: 3.12.2
- **iOS Target**: 14.0+

For iOS-specific information, see the iOS documentation files in this project.
