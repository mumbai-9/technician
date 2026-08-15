# iOS Setup for Pest Control Technician App

## Overview
This folder contains the iOS platform configuration for the Pest Control Technician Flutter application. This iOS app mirrors the Android technician app with all the same features and functionality.

## Prerequisites

### System Requirements
- **Mac with Xcode 15.0+** or later
- **iOS 14.0** or later deployment target
- **CocoaPods** for dependency management
- **Xcode Command Line Tools**

### Flutter Installation
Ensure Flutter is properly installed:
```bash
flutter --version
```

Expected: Flutter 3.44.8 or later

## iOS-Specific Configuration

### Bundle Identifier
- **Bundle ID**: `com.pestcontrol.technician` (update in Xcode build settings)
- **App Name**: Pest Control Tech
- **App Version**: 1.0.0 (defined in pubspec.yaml)

### Build Configuration
Located in `ios/Runner.xcodeproj`:
- **Target**: Runner
- **Minimum Deployment Target**: iOS 14.0
- **Supported Architectures**: arm64, armv7k (for devices), x86_64, i386 (for simulator)

### Signing & Capabilities
Before building for device or App Store:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner target
3. In "Signing & Capabilities", configure:
   - Team ID
   - Code signing certificate
   - App ID / Bundle identifier
   - Provisioning profile

## Permissions & Privacy

### Info.plist Permissions
The following permissions are configured in `ios/Runner/Info.plist`:

- **Location Services** (NSLocationWhenInUseUsageDescription)
  - Purpose: Track technician availability and job assignments
  
- **Camera** (NSCameraUsageDescription)
  - Purpose: Capture job site photos and before/after images
  
- **Photo Library** (NSPhotoLibraryUsageDescription)
  - Purpose: Upload job documentation
  
- **Photo Library Add Only** (NSPhotoLibraryAddOnlyUsageDescription)
  - Purpose: Save photos to the library

## Building for iOS

### Development Build (Simulator)
```bash
cd /path/to/technician\ app
flutter pub get
flutter run
```

### Device Build
```bash
flutter run --release
```

### Production Build (App Store)
1. Update version in `pubspec.yaml`:
   ```yaml
   version: 1.0.0+1
   ```

2. Build for production:
   ```bash
   flutter build ipa --release
   ```

3. This creates an IPA file at:
   ```
   build/ios/ipa/pest_control_app.ipa
   ```

### Troubleshooting Build Issues

#### Pod Issues
```bash
cd ios
pod repo update
pod install --repo-update
cd ..
flutter clean
flutter pub get
flutter run
```

#### Xcode Build Issues
```bash
flutter clean
rm -rf build/
flutter pub get
flutter run -v  # Verbose output for debugging
```

#### Swift Compatibility
The project uses Swift 5.5+. Ensure Xcode language setting is correct:
- Xcode → Build Settings → Swift Language Version → 5.5 or later

## Dependencies with iOS Support

All Flutter packages in pubspec.yaml have iOS-compatible implementations:

### Core Dependencies
- `google_fonts`: Google Fonts API support
- `http`: HTTP client for API calls
- `intl`: Internationalization
- `shared_preferences`: Local key-value storage

### Platform-Specific Dependencies
- `geolocator_apple`: Location services for iOS
- `permission_handler_apple`: Permission requests for iOS
- `image_picker_ios`: Camera and photo library access
- `url_launcher_ios`: URL handling for iOS
- `geocoding_ios`: Reverse geocoding for iOS

## App Store Deployment

### Requirements
1. **Apple Developer Account**
2. **Certificates**:
   - iOS App Development
   - iOS App Store Distribution
3. **Identifiers**: App ID
4. **Provisioning Profiles**:
   - Development profile
   - App Store Distribution profile

### Deployment Steps
1. Update version number in Xcode
2. Create archive:
   ```bash
   flutter build ipa --release
   ```
3. Upload to App Store Connect
4. Submit for review

### Submission Checklist
- [ ] App name set correctly
- [ ] App description updated
- [ ] Screenshots for all screen sizes
- [ ] Privacy policy URL set
- [ ] Support email configured
- [ ] Category selected
- [ ] Minimum iOS version: 14.0
- [ ] All permissions justified in privacy policy

## Debugging on iOS

### Enable Device Logging
```bash
flutter run -v
```

### Xcode Console
Open `ios/Runner.xcworkspace` in Xcode and use the console for real-time logs.

### Flutter DevTools
```bash
flutter pub global activate devtools
devtools
```

Then run:
```bash
flutter run --profile --dev-tools-server-address=localhost:9100
```

## Performance Optimization

### Build Size Optimization
```bash
flutter build ipa --release --split-per-abi
```

### App Thinning
Xcode automatically applies app thinning for App Store distribution.

### Flutter Release Mode
Always use release mode for production:
```bash
flutter run --release
flutter build ios --release
```

## Known Issues & Solutions

### CocoaPods Compatibility
If CocoaPods is outdated:
```bash
sudo gem install cocoapods
pod repo update
```

### Provisioning Profile Issues
Regenerate provisioning profiles in Apple Developer Portal:
1. Go to [developer.apple.com](https://developer.apple.com)
2. Navigate to Certificates, Identifiers & Profiles
3. Regenerate profiles for this app ID
4. Download and install in Xcode

## Support & Resources

- [Flutter iOS Documentation](https://flutter.dev/docs/deployment/ios)
- [Xcode Documentation](https://developer.apple.com/documentation/xcode)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Flutter Troubleshooting Guide](https://flutter.dev/docs/testing/troubleshooting)

## Maintenance

### Regular Updates
Keep the following updated:
- Flutter SDK: `flutter upgrade`
- Dependencies: `flutter pub upgrade`
- Xcode: Update from App Store
- iOS Deployment Target: Review and update when necessary

### Testing Before Release
1. Test on iOS 14 (minimum supported)
2. Test on latest iOS version
3. Test on various device sizes
4. Test all permissions
5. Test offline functionality
6. Performance testing on lower-end devices
