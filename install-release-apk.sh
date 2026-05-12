#!/bin/bash
set -e

APK="/Users/mohith/Downloads/yojana_mitra_app/build/app/outputs/flutter-apk/app-release.apk"
ADB="/opt/homebrew/share/android-commandlinetools/platform-tools/adb"

echo "════════════════════════════════════════════════════"
echo "Installing BharatMitra Release APK"
echo "════════════════════════════════════════════════════"
echo ""

# Check APK exists
if [ ! -f "$APK" ]; then
  echo "❌ ERROR: APK not found at $APK"
  exit 1
fi

echo "✓ APK found: $(ls -lh "$APK" | awk '{print $5, $9}')"
echo ""

# Check ADB available
if [ ! -f "$ADB" ]; then
  echo "❌ ERROR: ADB not found at $ADB"
  exit 1
fi

echo "✓ ADB found"
echo ""

# List connected devices
echo "Connected devices:"
$ADB devices -l
echo ""

# Uninstall old version (if exists)
echo "Uninstalling old version..."
$ADB uninstall com.example.yojana_mitra_app 2>/dev/null || true
echo ""

# Install new APK
echo "Installing BharatMitra release APK..."
$ADB install -r "$APK"
echo ""

# Launch app
echo "Launching app..."
$ADB shell am start -n com.example.yojana_mitra_app/.MainActivity
echo ""

echo "════════════════════════════════════════════════════"
echo "✅ Installation complete!"
echo "════════════════════════════════════════════════════"
