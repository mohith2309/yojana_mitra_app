# BharatMitra App Features Not Working — Root Cause & Fix

**Date:** May 9, 2026  
**Issue:** App installed but all features return errors or no data  
**Root Cause:** Backend server not running

---

## ❌ The Problem

The BharatMitra app requires a **backend FastAPI server** to:
- Fetch Mandi prices
- Get AQI activity plans
- Retrieve flood alerts
- Draft civic complaints
- Process other requests

**Without the backend running, all features fail.**

---

## ✅ The Solution

### Step 1: Open Terminal on Mac

```bash
cd /Users/mohith/Downloads/yojana_mitra_app
chmod +x start-backend.sh
./start-backend.sh
```

**You should see:**
```
═════════════════════════════════════════════════════
  BharatMitra Backend Startup
═════════════════════════════════════════════════════

📦 Checking dependencies...
✓ .env configured
✓ uvicorn available

Starting FastAPI backend...
  Host: 0.0.0.0
  Port: 8000
  Local IP: 192.168.x.x:8000

🌍 Phone should use: http://192.168.x.x:8000

Press Ctrl+C to stop
═════════════════════════════════════════════════════

INFO:     Started server process [xxx]
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

**⚠️ KEEP THIS TERMINAL WINDOW OPEN** — The backend must stay running while you test the app.

---

### Step 2: Find Your Mac's Local IP

From the backend terminal output, you'll see something like:
```
🌍 Phone should use: http://192.168.x.x:8000
```

**Or manually find it:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Example output:
```
inet 192.168.1.15 netmask 0xffffff00 broadcast 192.168.1.255
```

Your IP is `192.168.1.15`

---

### Step 3: Update App Backend URL

**On Nothing Phone 1:**

1. Open BharatMitra app
2. Tap **Profile** tab (bottom right)
3. Scroll to **"Backend URL"** field
4. Replace `localhost` with your Mac's IP:
   - **Before:** `http://localhost:8000`
   - **After:** `http://192.168.1.15:8000` (use YOUR IP)
5. **Save** or confirm

*(If app doesn't have a settings screen, you'll need to rebuild with the IP hardcoded)*

---

### Step 4: Test Each Feature

Go back to the app and test:

✅ **Home Tab** → Should show welfare schemes  
✅ **Schemes Tab** → "Pradhan Mantri Suraksha Bima Yojana" card visible  
✅ **Alerts Tab** → Tap "Mandi" → Should show crop prices  
✅ **Alerts Tab** → Tap "AQI" → Should show air quality plan  
✅ **Profile Tab** → Should show user info

If features now work → **Backend is running correctly** ✓

If still broken → Check logs below

---

## 🔧 Troubleshooting

### Issue: "Connection refused" when tapping features

**Cause:** Phone can't reach the Mac

**Fix:**
1. Ensure **Mac and Nothing Phone are on same WiFi network**
2. Check firewall: `System Preferences → Security → Firewall`
   - If firewall is ON, may need to allow Python/uvicorn
   - Or temporarily disable for testing
3. Verify IP is correct (paste in phone browser: `http://192.168.x.x:8000`)
   - Should show: `{"status": "ok", ...}`

### Issue: "Phone doesn't have settings to change backend URL"

**Fix:** Need to hardcode URL in Flutter app

Edit `/Users/mohith/Downloads/yojana_mitra_app/lib/main.dart`:

Find (around line 70):
```dart
String baseUrl = "http://localhost:8000";
```

Replace with your Mac IP:
```dart
String baseUrl = "http://192.168.1.15:8000"; // Use YOUR IP
```

Then rebuild:
```bash
cd /Users/mohith/Downloads/yojana_mitra_app
/opt/homebrew/bin/flutter build apk --debug
```

Then reinstall on phone using:
```bash
bash install-to-phone.command
```

### Issue: Backend starts but crashes immediately

Check error in Terminal:
```bash
# If you see import errors, install missing package
pip install <package_name> --break-system-packages

# Then restart backend
./start-backend.sh
```

---

## 📊 Test Backend Directly (Mac Terminal)

**While backend is running**, open a NEW terminal tab and test:

```bash
curl http://localhost:8000/health
```

Expected response:
```json
{"status": "ok", "mode": "live", "ok": true, ...}
```

Test a feature:
```bash
curl -X POST http://localhost:8000/aqi/plan \
  -H "Content-Type: application/json" \
  -d '{"location": "Delhi"}'
```

Expected response:
```json
{
  "status": "ok",
  "activity_plan": "Avoid outdoor activities...",
  "guidance": "Wear N95 mask..."
}
```

---

## 📝 Summary

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `./start-backend.sh` | Backend listens on 0.0.0.0:8000 |
| 2 | Get local IP | E.g., 192.168.1.15 |
| 3 | Phone: Set URL to `http://192.168.1.15:8000` | Phone connects to Mac |
| 4 | Test features (Mandi, AQI, Flood, Schemes) | All show data ✅ |

---

## 🚀 For Production

When deploying to production:
1. Backend must run on a **real server** (AWS, Azure, GCP, etc.)
2. Update app to use **production URL** (not localhost or local IP)
3. Use **HTTPS** (not HTTP)
4. Set proper **CORS headers**
5. Keep backend **running 24/7**

For now: **Run on Mac locally for testing.** ✓

---

**Questions?** Check `/Users/mohith/Downloads/yojana_mitra_app/backend/README.md` for API details.
