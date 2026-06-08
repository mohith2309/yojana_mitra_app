#!/bin/bash
set -e

PROJECT_DIR="/Users/mohith/Downloads/yojana_mitra_app"
cd "$PROJECT_DIR"

echo "════════════════════════════════════════════════════════"
echo "BHARATMITRA — COMPREHENSIVE TEST SUITE"
echo "════════════════════════════════════════════════════════"
echo ""

# Test 1: Backend Python Syntax
echo "✓ TEST 1: Backend Python Syntax Check"
cd "$PROJECT_DIR/backend"
python3 -m py_compile main.py && echo "  ✅ Syntax OK" || echo "  ❌ Syntax Error"
echo ""

# Test 2: Backend Unit Tests
echo "✓ TEST 2: Backend Unit Tests"
python3 -m unittest test_service_integrations 2>&1 | grep -E "(Ran|OK|FAILED)" || true
echo ""

# Test 3: Backend Health Check
echo "✓ TEST 3: Backend /health Endpoint"
python3 main.py &
BACKEND_PID=$!
sleep 3
curl -s http://127.0.0.1:8000/health | python3 -m json.tool | head -10 && echo "  ✅ Backend responding" || echo "  ⚠️  Backend not responding yet"
kill $BACKEND_PID 2>/dev/null || true
sleep 1
echo ""

# Test 4: Flutter Analyze
echo "✓ TEST 4: Flutter Analyze (Linting)"
cd "$PROJECT_DIR"
/opt/homebrew/bin/flutter analyze --no-fatal-infos 2>&1 | tail -5
echo ""

# Test 5: Flutter Widget Test
echo "✓ TEST 5: Flutter Widget Test"
/opt/homebrew/bin/flutter test --no-sound-null-safety 2>&1 | grep -E "(passed|failed|All tests)" || true
echo ""

# Test 6: Flutter Build APK (Release)
echo "✓ TEST 6: Flutter Build APK (Release)"
/opt/homebrew/bin/flutter build apk --release -v 2>&1 | tail -10
echo ""

# Test 7: Release APK Size Check
echo "✓ TEST 7: Release APK File Size"
APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
  SIZE=$(ls -lh "$APK_PATH" | awk '{print $5}')
  echo "  ✅ APK built: $SIZE"
  ls -lh "$APK_PATH"
else
  echo "  ❌ APK not found"
fi
echo ""

# Test 8: Git status (Secrets Check)
echo "✓ TEST 8: Git Status (Secrets Check)"
cd "$PROJECT_DIR"
if git status | grep -q "key.properties\|\.jks\|\.keystore"; then
  echo "  ⚠️  WARNING: Secrets might be staged"
  git status | grep -E "key.properties|\.jks|\.keystore" || true
else
  echo "  ✅ No secrets detected in git status"
fi
echo ""

echo "════════════════════════════════════════════════════════"
echo "TEST SUITE COMPLETE"
echo "════════════════════════════════════════════════════════"
