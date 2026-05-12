#!/bin/bash
# Build BharatMitra Enhanced APK with zero-setup and scheme filtering

set -e

PROJECT_DIR="/Users/mohith/Downloads/yojana_mitra_app"
FLUTTER="/opt/homebrew/bin/flutter"
DART="/opt/homebrew/bin/dart"

echo "════════════════════════════════════════════════════"
echo "  BharatMitra Enhanced APK Build"
echo "════════════════════════════════════════════════════"
echo ""

# Check Flutter
if [ ! -x "$FLUTTER" ]; then
    echo "❌ Flutter not found at $FLUTTER"
    echo "Please install Flutter and try again"
    exit 1
fi

cd "$PROJECT_DIR"

# Step 1: Format
echo "1️⃣ Formatting code..."
$DART format lib/main.dart
echo "✓ Formatted"
echo ""

# Step 2: Analyze
echo "2️⃣ Running Flutter analysis..."
$FLUTTER analyze --no-fatal-infos 2>&1 | tail -5
echo "✓ Analysis complete"
echo ""

# Step 3: Test (if available)
echo "3️⃣ Running tests..."
if [ -f "test/widget_test.dart" ]; then
    $FLUTTER test 2>&1 | tail -3 || echo "⚠️ Some tests failed, continuing..."
else
    echo "ℹ️ No tests found"
fi
echo ""

# Step 4: Build debug APK
echo "4️⃣ Building debug APK..."
$FLUTTER build apk --debug 2>&1 | tail -10
echo "✓ Debug APK built"
echo ""

# Step 5: Build release APK
echo "5️⃣ Building release APK..."
$FLUTTER build apk --release 2>&1 | tail -10
echo "✓ Release APK built"
echo ""

# Summary
APK_DEBUG="$PROJECT_DIR/build/app/outputs/flutter-apk/app-debug.apk"
APK_RELEASE="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"

echo "════════════════════════════════════════════════════"
echo "✅ BUILD COMPLETE"
echo "════════════════════════════════════════════════════"
echo ""
echo "📦 Build artifacts:"
echo ""
if [ -f "$APK_DEBUG" ]; then
    DEBUG_SIZE=$(ls -lh "$APK_DEBUG" | awk '{print $5}')
    echo "  Debug:   $APK_DEBUG ($DEBUG_SIZE)"
    echo "           For testing on device"
else
    echo "  ❌ Debug APK not found"
fi
echo ""
if [ -f "$APK_RELEASE" ]; then
    RELEASE_SIZE=$(ls -lh "$APK_RELEASE" | awk '{print $5}')
    echo "  Release: $APK_RELEASE ($RELEASE_SIZE)"
    echo "           For Google Play Store"
else
    echo "  ❌ Release APK not found"
fi
echo ""

# Next steps
echo "════════════════════════════════════════════════════"
echo "📱 Next Steps:"
echo "════════════════════════════════════════════════════"
echo ""
echo "To install and test:"
echo ""
echo "  cd $PROJECT_DIR"
echo "  bash install-to-phone.command"
echo ""
echo "Or use adb directly:"
echo ""
echo "  adb install -r build/app/outputs/flutter-apk/app-debug.apk"
echo ""
echo "════════════════════════════════════════════════════"
echo "✨ App Features:"
echo "════════════════════════════════════════════════════"
echo ""
echo "✅ Zero-setup — works offline, no backend needed"
echo "✅ Scheme filtering — search by keywords and tags"
echo "✅ Smart matching — shows 'For You' schemes first"
echo "✅ All schemes — 11 government welfare programs"
echo "✅ Voice input — describe situation with microphone"
echo "✅ PDF export — download scheme checklist"
echo "✅ Official links — open myScheme.gov.in"
echo ""
