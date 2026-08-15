#!/bin/bash

# iOS Build Setup Script for Pest Control Technician App
# This script automates the iOS build preparation process

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║   Pest Control Technician App - iOS Build Setup                   ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check Flutter installation
echo -n "Checking Flutter installation... "
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    echo -e "${GREEN}✓${NC}"
    echo "  Version: $FLUTTER_VERSION"
else
    echo -e "${RED}✗${NC}"
    echo "  Flutter not installed. Please install Flutter and add to PATH."
    exit 1
fi

# Step 2: Check iOS build requirements on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -n "Checking Xcode installation... "
    if command -v xcode-select &> /dev/null; then
        XCODE_VERSION=$(xcode-select -p 2>/dev/null)
        echo -e "${GREEN}✓${NC}"
        echo "  Path: $XCODE_VERSION"
    else
        echo -e "${RED}✗${NC}"
        echo "  Xcode not installed. Please install Xcode from App Store."
        exit 1
    fi

    echo -n "Checking CocoaPods installation... "
    if command -v pod &> /dev/null; then
        POD_VERSION=$(pod --version)
        echo -e "${GREEN}✓${NC}"
        echo "  Version: $POD_VERSION"
    else
        echo -e "${RED}✗${NC}"
        echo "  CocoaPods not installed. Installing..."
        sudo gem install cocoapods
    fi
else
    echo -e "${YELLOW}!${NC} Running on non-macOS system. iOS builds require macOS with Xcode."
    echo "  You can prepare dependencies but cannot build iOS apps on this system."
fi

# Step 3: Get Flutter dependencies
echo ""
echo -n "Getting Flutter dependencies... "
flutter pub get > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "  Failed to get dependencies."
    exit 1
fi

# Step 4: Update CocoaPods repository (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -n "Updating CocoaPods repository... "
    pod repo update > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}!${NC} (may have cache issues, continuing...)"
    fi
fi

# Step 5: Clean build directory
echo -n "Cleaning build directory... "
flutter clean > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
fi

# Step 6: Get dependencies again after clean
echo -n "Getting dependencies after clean... "
flutter pub get > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    exit 1
fi

# Step 7: Analyze project
echo -n "Analyzing project... "
if flutter analyze --no-pub > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}!${NC} (analysis completed with warnings)"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║   Setup Complete!                                                  ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo ""

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "1. To run on iOS Simulator:"
    echo "   ${YELLOW}flutter run${NC}"
    echo ""
    echo "2. To run on physical iOS device:"
    echo "   ${YELLOW}flutter run --release${NC}"
    echo ""
    echo "3. To build for App Store:"
    echo "   ${YELLOW}flutter build ipa --release${NC}"
    echo ""
    echo "4. To open Xcode project:"
    echo "   ${YELLOW}open ios/Runner.xcworkspace${NC}"
    echo ""
    echo "5. iOS Build Configuration:"
    echo "   - Bundle ID: com.pestcontrol.technician"
    echo "   - Minimum iOS Version: 14.0"
    echo "   - Deployment Target: 14.0"
    echo ""
else
    echo "1. This script was run on a non-macOS system."
    echo "2. iOS builds must be done on macOS with Xcode installed."
    echo "3. Copy the project to a Mac and run:"
    echo "   ${YELLOW}bash scripts/ios_setup.sh${NC}"
    echo ""
fi

echo "For more information, see: ${YELLOW}ios/README_iOS.md${NC}"
echo ""
