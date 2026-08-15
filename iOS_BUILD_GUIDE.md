# iOS Build & Deployment Guide
# Technician Pest Control App

## Quick Start (macOS)

### Prerequisites
```bash
# Verify Flutter installation
flutter --version

# Verify Xcode installation
xcode-select --version

# Install/Update CocoaPods
sudo gem install cocoapods
```

### Setup in 5 Minutes
```bash
# 1. Navigate to project
cd "path/to/technician app"

# 2. Clean and get dependencies
flutter clean
flutter pub get

# 3. Run on simulator
flutter run

# 4. (Optional) Run setup script
bash scripts/ios_setup.sh

# 5. (Optional) Open in Xcode for configuration
open ios/Runner.xcworkspace
```

---

## Build Modes Explained

### 1. Debug Mode (Development)
```bash
flutter run
```
**Use for:**
- Local development
- Testing on simulator
- Quick iteration

**Characteristics:**
- Unoptimized code
- Includes debug symbols
- Slower startup
- Larger app size
- Fast build time

---

### 2. Profile Mode (Performance Testing)
```bash
flutter run --profile
```
**Use for:**
- Performance profiling
- Memory leak detection
- Battery usage testing

**Characteristics:**
- Optimized code
- Profiling enabled
- Near-production performance
- Medium app size

---

### 3. Release Mode (Production)
```bash
flutter run --release
```
**Use for:**
- Final testing before submission
- Device compatibility testing
- Real-world performance testing

**Characteristics:**
- Fully optimized code
- No debug symbols
- Fastest performance
- Smallest app size
- Longest build time

---

## Building for Different Targets

### Build for Physical Device
```bash
# 1. Connect iPhone via USB
# 2. Trust this computer (on device)
# 3. Verify device is recognized
flutter devices

# 4. Run on device
flutter run -d <device-id>

# 5. For release
flutter run -d <device-id> --release
```

### Build for App Store
```bash
# Create IPA for App Store submission
flutter build ipa --release

# Output location:
# build/ios/ipa/pest_control_app.ipa
```

### Build for TestFlight
1. Run build command above
2. Upload to App Store Connect
3. Select for TestFlight testing
4. Send to internal testers

---

## Advanced Build Options

### Change Bundle Identifier
Edit `ios/Runner.xcodeproj/project.pbxproj` or use Xcode:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Go to Build Settings
4. Search for "Bundle Identifier"
5. Change to your identifier (e.g., `com.yourcompany.techapp`)

### Change App Name
Edit `ios/Runner/Info.plist`:
```xml
<key>CFBundleDisplayName</key>
<string>Your App Name</string>
```

### Change Deployment Target
In Xcode:
1. Select Runner project
2. Select Runner target
3. General tab
4. Minimum Deployments: Select iOS version

### Enable/Disable Architectures
In Build Settings:
- Search for "Valid Architectures"
- Configure supported architectures
- Common: `arm64` for device, `x86_64 arm64` for simulator

---

## Troubleshooting Common Issues

### Issue 1: "CocoaPods could not find compatible versions"
**Solution:**
```bash
cd ios
rm Podfile.lock
pod repo update
pod install --repo-update
cd ..
flutter pub get
flutter run -v
```

### Issue 2: "Device locked" or "Trust Developer"
**Solution:**
1. On iPhone: Settings → General → Device Management
2. Trust your developer certificate
3. Reconnect and try again

### Issue 3: "Code signing error"
**Solution:**
```bash
# Clean everything
flutter clean
rm -rf ios/Pods
rm ios/Podfile.lock

# Rebuild
cd ios
pod repo update
pod install
cd ..
flutter pub get
flutter run -v
```

### Issue 4: "Swift compiler error"
**Solution:**
```bash
cd ios
pod install --repo-update
cd ..
flutter clean
flutter pub get
flutter run -v
```

### Issue 5: "App crashes immediately"
**Solution:**
1. Run with verbose output: `flutter run -v`
2. Check console logs for errors
3. Verify all permissions in Info.plist
4. Test on simulator first

### Issue 6: "Provisioning profile error"
**Solution:**
1. Open Xcode project
2. Select Runner target
3. Go to Signing & Capabilities
4. Select correct team
5. Let Xcode auto-manage signing

### Issue 7: "Build hangs or times out"
**Solution:**
```bash
# Kill flutter daemon
flutter clean

# Restart with verbose
flutter run -v

# Or use Xcode directly
open ios/Runner.xcworkspace
# Product → Run
```

---

## Building with Xcode Directly

### Open Project
```bash
open ios/Runner.xcworkspace
# Note: Use .xcworkspace, NOT .xcodeproj
```

### Build Steps in Xcode
1. **Select Target**: Scheme selector → Runner
2. **Select Device**: Device selector → iPhone/Simulator
3. **Build**: Product → Build (⌘B)
4. **Run**: Product → Run (⌘R)
5. **Archive** (for distribution):
   - Product → Build For → Archiving
   - Product → Archive
   - Window → Organizer → Select app → Distribute App

---

## Platform-Specific Configuration

### Permissions
All permissions are configured in `ios/Runner/Info.plist`:

- **Location**: NSLocationWhenInUseUsageDescription
- **Camera**: NSCameraUsageDescription
- **Photos**: NSPhotoLibraryUsageDescription
- **Photos Write**: NSPhotoLibraryAddOnlyUsageDescription

Users will be prompted when features requiring these permissions are first used.

### Orientation
Currently configured for portrait and landscape on both iPhone and iPad.
Edit in Info.plist → UISupportedInterfaceOrientations

### Status Bar
Configure in Info.plist:
- Status bar style
- Status bar hidden

---

## Performance & Optimization

### Reduce Build Size
1. Enable App Thinning in Xcode
2. Remove unused assets
3. Use release mode: `flutter run --release`
4. Split builds per architecture

### Improve Build Speed
1. Use fast CPU
2. Close other apps
3. Use local CocoaPods: `pod repo update` less frequently
4. Cache dependencies properly

### Monitor Performance
1. Use Xcode Instruments
2. Run: `flutter run --profile`
3. Open DevTools: `flutter pub global run devtools`
4. Profile memory, CPU, and GPU

---

## App Store Deployment

### Before Submission
- [ ] All tests pass
- [ ] App builds without warnings
- [ ] iOS 14+ supported
- [ ] All permissions justified
- [ ] Screenshots prepared
- [ ] Privacy policy updated
- [ ] Contact information provided

### Build for App Store
```bash
flutter build ipa --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

### Upload Options
1. **Xcode**: Open organizer, upload archive
2. **Transporter**: Apple's command-line tool
3. **App Store Connect**: Web upload

### After Submission
- Monitor review status
- Fix rejected submissions
- Release to production
- Monitor crash reports

---

## Version Management

### Update Version Number
Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

Format: `major.minor.patch+build`

### Update in Xcode
1. Open `ios/Runner/Info.plist`
2. CFBundleShortVersionString: Version number
3. CFBundleVersion: Build number

---

## Useful Commands Reference

```bash
# Setup
flutter pub get
flutter clean

# Development
flutter run                    # Run on default device
flutter run -d <id>          # Run on specific device
flutter devices               # List devices
flutter run --profile        # Profile mode
flutter run --release        # Release mode

# Building
flutter build ios --release  # Build IPA
flutter build ios --debug    # Build debug

# Xcode
open ios/Runner.xcworkspace  # Open in Xcode
open -a Xcode ios/Runner.xcworkspace  # Force open in Xcode

# Debugging
flutter run -v               # Verbose output
flutter logs                 # Stream logs
flutter attach               # Attach to running app

# Cleanup
flutter clean
flutter pub cache repair
```

---

## Environment Variables

### Required Environment Variables
```bash
# If Flutter SDK is not in PATH
export PATH="$PATH:~/flutter/bin"

# For Xcode command line tools
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

---

## CI/CD Integration

For automated builds, create a `build.sh` script:

```bash
#!/bin/bash
set -e

echo "Building iOS app..."
cd "path/to/app"

# Prepare
flutter clean
flutter pub get

# Build IPA
flutter build ipa --release

echo "Build complete: build/ios/ipa/pest_control_app.ipa"
```

---

## Support & Resources

- **Flutter Docs**: https://flutter.dev/docs/deployment/ios
- **Apple Developer**: https://developer.apple.com
- **App Store Connect**: https://appstoreconnect.apple.com
- **Xcode Help**: Help → Xcode Help (within Xcode)
- **Flutter Community**: https://flutter.dev/community

---

## Next Steps

1. **For Development**: See README.md
2. **For Testing**: Follow "Quick Start" above
3. **For Release**: See "App Store Deployment" section
4. **For Issues**: Check "Troubleshooting" section

---

**Last Updated**: August 15, 2026  
**Flutter Version**: 3.44.8  
**iOS Deployment Target**: 14.0  
**Xcode Version Required**: 15.0+
