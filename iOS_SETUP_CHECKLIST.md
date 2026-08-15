# iOS Technician App - Pre-Build Checklist

## ✓ Development Environment Setup

### System Requirements
- [ ] macOS 13.0 or later
- [ ] Xcode 15.0 or later
- [ ] Xcode Command Line Tools installed
- [ ] CocoaPods 1.13 or later
- [ ] Flutter 3.44.8 or later
- [ ] iOS deployment target: 14.0+

### Verification Commands
```bash
# Check macOS version
sw_vers

# Check Xcode installation
xcode-select --version

# Check Flutter
flutter --version

# Check CocoaPods
pod --version
```

---

## ✓ Project Configuration

### App Information
- [ ] **App Name**: Pest Control Tech
- [ ] **Package Name**: pest_control_app
- [ ] **Bundle Identifier**: com.pestcontrol.technician (update in Xcode)
- [ ] **Version**: 1.0.0 (defined in pubspec.yaml)
- [ ] **Build Number**: 1

### Info.plist Verification
- [ ] CFBundleDisplayName: "Pest Control Tech"
- [ ] CFBundleName: "pest_control_app"
- [ ] UIMainStoryboardFile: "Main"
- [ ] UISupportedInterfaceOrientations configured
- [ ] LSRequiresIPhoneOS: true
- [ ] Minimum deployment target: iOS 14.0

### Required Permissions Configured
- [ ] NSLocationWhenInUseUsageDescription
- [ ] NSLocationAlwaysAndWhenInUseUsageDescription
- [ ] NSCameraUsageDescription
- [ ] NSPhotoLibraryUsageDescription
- [ ] NSPhotoLibraryAddOnlyUsageDescription

---

## ✓ Dependencies & Pod Configuration

### Flutter Dependencies Check
```bash
flutter pub get
flutter pub outdated
```

- [ ] All packages have iOS support
- [ ] No broken dependencies
- [ ] geolocator_apple installed
- [ ] permission_handler_apple installed
- [ ] image_picker_ios installed
- [ ] url_launcher_ios installed

### CocoaPods Setup
```bash
cd ios
pod repo update
pod install
cd ..
```

- [ ] Podfile exists in ios/
- [ ] Podfile.lock generated
- [ ] Pods/ folder created
- [ ] Runner.xcworkspace created

---

## ✓ iOS Project Configuration

### Xcode Project Setup
1. [ ] Open ios/Runner.xcworkspace in Xcode
2. [ ] Select Runner project
3. [ ] Verify Target settings

### Build Settings
- [ ] Minimum Deployment Target: iOS 14.0
- [ ] Supported Architectures: arm64, armv7k (device), x86_64, i386 (simulator)
- [ ] Swift Language Version: 5.5+
- [ ] iOS SDK: Latest available

### Signing & Capabilities
- [ ] Team ID configured (for device/App Store builds)
- [ ] Code signing identity set
- [ ] Provisioning profile assigned
- [ ] Automatic signing enabled or manual profiles configured

---

## ✓ Permissions & Capabilities

### iOS Capabilities (if building for device)
1. Open ios/Runner.xcworkspace in Xcode
2. Select Runner target
3. Go to "Signing & Capabilities"
4. Add capabilities as needed:
   - [ ] Location Services
   - [ ] Camera
   - [ ] Photos Library
   - [ ] Network Extension (if needed)

### Privacy Policy
- [ ] Privacy policy URL configured (for App Store)
- [ ] Privacy policy covers all permissions used

---

## ✓ Pre-Build Testing

### Run on Simulator
```bash
flutter run
```
- [ ] App launches without errors
- [ ] No permission dialogs on startup
- [ ] Location services working
- [ ] UI renders correctly
- [ ] Navigation working
- [ ] All screens responsive

### Run on Physical Device (if available)
```bash
flutter devices  # List connected devices
flutter run -d <device-id>
```
- [ ] App installs successfully
- [ ] App launches without errors
- [ ] All permissions request properly
- [ ] Location tracking works
- [ ] Camera access works
- [ ] Photo upload functionality works
- [ ] Internet connectivity working
- [ ] Offline mode functioning

### Analyze Code
```bash
flutter analyze
```
- [ ] No critical errors
- [ ] Warnings reviewed
- [ ] Code quality acceptable

---

## ✓ Build Configuration Files

### Flutter Configuration
- [ ] pubspec.yaml updated with correct version
- [ ] pubspec.lock regenerated
- [ ] .flutter-plugins updated
- [ ] Generated.xcconfig present in ios/Flutter/

### iOS Specific Files
- [ ] ios/Runner/Info.plist configured
- [ ] ios/Runner/GeneratedPluginRegistrant.m exists
- [ ] ios/Podfile properly configured
- [ ] ios/Podfile.lock present

---

## ✓ Documentation & Resources

- [ ] README.md updated with iOS instructions
- [ ] ios/README_iOS.md created and reviewed
- [ ] Build commands documented
- [ ] Troubleshooting guide available
- [ ] Deployment steps outlined

---

## ✓ Release Preparation (App Store)

### Version Management
- [ ] Version number updated in pubspec.yaml
- [ ] Build number incremented
- [ ] Changelog prepared
- [ ] Release notes written

### App Store Connect Setup
- [ ] App created in App Store Connect
- [ ] Bundle ID matches project configuration
- [ ] App categories selected
- [ ] Age rating completed
- [ ] Privacy policy URL configured
- [ ] Contact information provided

### Build for App Store
```bash
flutter build ipa --release
```
- [ ] Build completes without errors
- [ ] IPA file created successfully
- [ ] IPA validated in Xcode

### TestFlight Testing
- [ ] Internal testing build uploaded
- [ ] QA team tests on real devices
- [ ] Bug fixes applied if needed
- [ ] External testing initiated

### App Store Submission
- [ ] Screenshots prepared for all screen sizes
- [ ] App preview videos (optional)
- [ ] Metadata reviewed
- [ ] Keywords optimized
- [ ] Support email configured
- [ ] Support URL configured
- [ ] Version release notes updated

---

## ✓ Post-Build Verification

### App Functionality Testing
- [ ] User login/authentication works
- [ ] Technician data loads correctly
- [ ] Job assignment displays properly
- [ ] Location tracking functional
- [ ] Photo capture and upload working
- [ ] QR code scanning operational
- [ ] PDF generation functional
- [ ] Signature capture working
- [ ] Push notifications (if configured)
- [ ] Offline data sync working

### Device Compatibility
- [ ] Tested on iPhone 14 or later
- [ ] Tested on iPad (if supported)
- [ ] Tested on iOS 14, 15, 16, 17, 18
- [ ] Portrait and landscape orientations
- [ ] Various screen sizes

### Performance
- [ ] App startup time acceptable
- [ ] No memory leaks
- [ ] Battery usage reasonable
- [ ] Network requests optimized
- [ ] Database queries performant

---

## Troubleshooting Quick Reference

### Build Fails
```bash
flutter clean
rm -rf ios/Pods
rm ios/Podfile.lock
cd ios
pod repo update
pod install
cd ..
flutter pub get
flutter run -v
```

### Pods Issues
```bash
cd ios
pod repo update
pod install --repo-update
cd ..
```

### Xcode Issues
- Clean build folder: Cmd + Shift + K
- Clean Xcode cache: Cmd + Shift + K
- Remove derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`

### Permission Issues
- Verify Info.plist has all required keys
- Check Runner target Signing & Capabilities
- Review Xcode build warnings

---

## Deployment Checklist Summary

- [ ] All system requirements met
- [ ] All dependencies installed and verified
- [ ] Project builds successfully
- [ ] Tests pass on simulator
- [ ] Tests pass on physical device
- [ ] Code analyzed without critical issues
- [ ] App Store configuration complete (for release)
- [ ] Version and build numbers updated
- [ ] IPA built successfully
- [ ] Ready for submission or internal testing

---

## Contact & Support

For issues or questions:
1. Check ios/README_iOS.md
2. Review Flutter official documentation
3. Consult project lead or iOS specialist
4. Check app logs: `flutter run -v`

---

**Last Updated**: August 15, 2026
**App Version**: 1.0.0
**Flutter Version**: 3.44.8
