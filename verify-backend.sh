#!/bin/bash
# Verify BharatMitra Backend is working correctly

PORT=8000
HOST="127.0.0.1"

echo "═════════════════════════════════════════════════════"
echo "  BharatMitra Backend Verification"
echo "═════════════════════════════════════════════════════"
echo ""

# Test 1: Health check
echo "1️⃣ Health Check..."
HEALTH=$(curl -s http://$HOST:$PORT/health 2>/dev/null)
if [ -n "$HEALTH" ]; then
    echo "✅ Backend responding on http://$HOST:$PORT"
    echo "   Response: $(echo $HEALTH | head -c 100)..."
else
    echo "❌ Backend not responding"
    echo "   Please run: ./start-backend.sh"
    exit 1
fi

echo ""

# Test 2: AQI endpoint
echo "2️⃣ Testing AQI endpoint..."
AQI=$(curl -s -X POST http://$HOST:$PORT/aqi/plan \
  -H "Content-Type: application/json" \
  -d '{"location":"Delhi"}' 2>/dev/null)

if echo "$AQI" | grep -q "activity_plan\|guidance"; then
    echo "✅ AQI working"
    echo "   Sample: $(echo $AQI | grep -o '"activity_plan":"[^"]*"' | head -c 60)..."
else
    echo "❌ AQI failed"
    echo "   Response: $AQI"
fi

echo ""

# Test 3: Flood endpoint
echo "3️⃣ Testing Flood endpoint..."
FLOOD=$(curl -s -X POST http://$HOST:$PORT/flood/alert \
  -H "Content-Type: application/json" \
  -d '{"location":"Delhi"}' 2>/dev/null)

if echo "$FLOOD" | grep -q "risk\|checklist"; then
    echo "✅ Flood working"
    echo "   Sample: $(echo $FLOOD | grep -o '"risk":"[^"]*"' | head -c 60)..."
else
    echo "❌ Flood failed"
    echo "   Response: $FLOOD"
fi

echo ""

# Test 4: Mandi endpoint
echo "4️⃣ Testing Mandi endpoint..."
MANDI=$(curl -s -X POST http://$HOST:$PORT/mandi/prices \
  -H "Content-Type: application/json" \
  -d '{"crop":"wheat"}' 2>/dev/null)

if echo "$MANDI" | grep -q "price\|market"; then
    echo "✅ Mandi working"
    echo "   Response length: $(echo $MANDI | wc -c) bytes"
else
    echo "⚠️  Mandi response: $(echo $MANDI | head -c 100)..."
fi

echo ""

# Test 5: Civic endpoint
echo "5️⃣ Testing Civic endpoint..."
CIVIC=$(curl -s -X POST http://$HOST:$PORT/civic/draft-complaint \
  -H "Content-Type: application/json" \
  -d '{"issue":"Road damage","location":"Delhi"}' 2>/dev/null)

if echo "$CIVIC" | grep -q "complaint\|draft\|letter"; then
    echo "✅ Civic working"
    echo "   Response length: $(echo $CIVIC | wc -c) bytes"
else
    echo "⚠️  Civic response: $(echo $CIVIC | head -c 100)..."
fi

echo ""
echo "═════════════════════════════════════════════════════"
echo "✅ Backend verification complete"
echo ""
echo "Next steps:"
echo "1. Ensure phone is on same WiFi as Mac"
echo "2. Get Mac IP: ifconfig | grep 'inet ' | grep -v 127.0.0.1"
echo "3. Update app URL: http://<MAC_IP>:8000"
echo "4. Test features on phone"
echo "═════════════════════════════════════════════════════"
