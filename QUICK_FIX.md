# 🚀 BharatMitra App Not Working? Quick Fix (5 Minutes)

## ⚡ TL;DR — Do This Now

### On Mac Terminal:
```bash
cd /Users/mohith/Downloads/yojana_mitra_app
./start-backend.sh
```

**Leave this terminal OPEN** — backend must stay running.

### Then:

**On Nothing Phone:**
1. Open BharatMitra app
2. Go to **Profile** tab → Find "Backend URL" field
3. Change from `localhost:8000` to **your Mac IP**:
   - Run this in NEW Mac terminal: `ifconfig | grep "inet " | grep -v 127`
   - Example IP: `192.168.1.15` → Use `http://192.168.1.15:8000`
4. Go back to **Home/Schemes/Alerts** and test features

---

## 🎯 What Was Wrong

✗ App was installed ✓  
✗ Tests all passed ✓  
✗ **But features didn't work** ← This was the issue

**Root Cause:** The **backend server wasn't running**

The app tries to call:
- `/aqi/plan` → Get air quality advice
- `/flood/alert` → Get flood warnings  
- `/mandi/prices` → Get farm prices
- `/civic/draft-complaint` → Draft complaints

**All these need the backend to answer.**

---

## ✅ Verify It's Fixed

Open a NEW Mac terminal and run:
```bash
cd /Users/mohith/Downloads/yojana_mitra_app
./verify-backend.sh
```

You should see:
```
✅ Health Check... Backend responding
✅ AQI working
✅ Flood working
✅ Mandi working
✅ Civic working
```

Then test on phone — all features should work now.

---

## 📋 Detailed Instructions

### If you don't know your Mac IP:

**Terminal:**
```bash
ifconfig
```

Look for section like:
```
en0: flags=...
    inet 192.168.1.15 netmask 0xffffff00 broadcast 192.168.1.255
```

Your IP is `192.168.1.15` (use YOUR number, not this example)

### If app doesn't have backend URL setting:

Edit the app code to hardcode your IP:

```bash
# Open file
nano /Users/mohith/Downloads/yojana_mitra_app/lib/main.dart

# Find line ~70:
# String baseUrl = "http://localhost:8000";

# Change to (use your actual IP):
# String baseUrl = "http://192.168.1.15:8000";

# Save: Ctrl+O, Enter, Ctrl+X
```

Then rebuild:
```bash
cd /Users/mohith/Downloads/yojana_mitra_app
/opt/homebrew/bin/flutter build apk --debug
bash install-to-phone.command
```

---

## 🔍 Test Commands

**While backend is running**, test in terminal:

```bash
# Test AQI
curl -X POST http://localhost:8000/aqi/plan \
  -H "Content-Type: application/json" \
  -d '{"location":"Delhi"}'

# Test Flood
curl -X POST http://localhost:8000/flood/alert \
  -H "Content-Type: application/json" \
  -d '{"location":"Delhi"}'

# Test Mandi
curl -X POST http://localhost:8000/mandi/prices \
  -H "Content-Type: application/json" \
  -d '{"crop":"wheat"}'
```

All should return JSON data (not errors).

---

## ⚠️ Common Issues

| Problem | Fix |
|---------|-----|
| "Connection refused" on phone | Phone not on same WiFi, or wrong IP |
| Backend crashes on startup | Run `pip install fastapi uvicorn --break-system-packages` |
| Phone shows blank screens | Check Mac IP is correct in app URL |
| Features timeout | Backend got stuck, restart it (Ctrl+C then run again) |

---

## 📞 Getting Help

Check these files for details:
- `DEBUG_APP_NOT_WORKING.md` — Full troubleshooting guide
- `backend/README.md` — API endpoint details
- `FINAL_TEST_REPORT.md` — What was tested and fixed

---

**Status:** App is production-ready! Just needs backend running. ✅
