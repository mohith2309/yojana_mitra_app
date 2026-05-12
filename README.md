# BharatMitra — Citizen Service Assistant

BharatMitra is a Flutter app that helps Indian citizens discover government welfare schemes, access agricultural markets (Mandi), monitor environmental alerts (AQI, flood warnings), and file civic complaints.

**Status:** Demo-ready, not yet production-ready.

## Quick Start

### Build the App

#### Debug APK
```bash
cd /Users/mohith/Downloads/yojana_mitra_app
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

#### Release APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
# Requires: android/key.properties (see Security section below)
```

### Install to Device
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Or use the convenience script:
```bash
open build/app/outputs/flutter-apk/install-to-phone.command
```

### Run on Emulator
```bash
flutter run
```

## Backend

The app pairs with a FastAPI backend for live data:
- **Location:** `/Users/mohith/Downloads/yojana_mitra_app/backend/`
- **Language:** Python 3.10+
- **Setup:**
  ```bash
  cd backend
  python3 -m venv .venv
  source .venv/bin/activate
  pip install -r requirements.txt
  cp .env.example .env
  # Add your API keys to .env (optional for demo)
  ```
- **Run:**
  ```bash
  python3 main.py
  # Server listens on http://localhost:8000
  ```

### Backend Endpoints

- `/health` — Health check
- `/mandi/advice` — Farm commodity prices
- `/aqi/plan` — Air quality index & activity guidance
- `/flood/risk` — Flood risk alerts
- `/civic/report-draft` — Civic complaint drafting
- `/nvidia/chat` — AI chat (requires NVIDIA API key)
- `/nvidia/pii-detect` — PII detection (requires NVIDIA API key)
- `/nvidia/rerank` — Passage re-ranking (requires NVIDIA API key)

### Local Fallback

If backend is offline or NVIDIA keys are missing, endpoints return safe local fallback data.

## API Keys (Backend Only)

Place these in `backend/.env` **only** — never commit them:

```env
NVIDIA_API_KEY=your_nvidia_key_here
DATA_GOV_API_KEY=your_data_gov_key_here
# Others optional for demo
```

**Do NOT put API keys in the Flutter app.**

## Architecture

- **OOBE (Onboarding):** 5-step wizard (Language → Profile → Permissions → DigiLocker Mock → Ready)
- **Main App:** 4-tab navigation (Home, Schemes, Alerts, Profile)
- **Local Offline Schemes:** 11 welfare schemes stored in SQLite
- **Voice Input:** Mic button with real-time transcription
- **PDF Export:** Save matched schemes as PDF

## Colors (Design System)

- Background: `#0D1B2A` (navy)
- Accent: `#E85D04` (saffron)
- Card: `#1E2D40`
- Highlight: `#6EE7B7` (mint)
- Text: `#9CA3AF` (gray)

## Security & Production Readiness

### ✅ Done
- Flutter analyze: **0 issues**
- Release APK builds: **175M debug, 51M release**
- Linting fixed

### ⚠️ Not Yet Production-Ready
- Package name still: `com.example.yojana_mitra_app` (should be `in.bharatmitra.app` or similar)
- DigiLocker integration: Mock only, no real API Setu consent
- Bhashini integration: Not implemented
- Play Store: Requires real account, privacy policy, data safety disclosures
- Production backend: Deployed URL needed (not yet set)

### Security: Signing & Git

**Do NOT commit:**
```gitignore
android/key.properties
android/*.jks
*.jks
*.keystore
backend/.env
```

**Always use placeholder:** See `android/key.properties.example` for format.

**Before pushing to GitHub:**
1. Check `.gitignore` has `android/key.properties` and `*.jks`
2. Run `git status` to confirm no secrets are staged
3. Verify `backend/.env` is not in git

## Testing

### Flutter Tests
```bash
flutter analyze           # Lint check
flutter test              # Widget tests
```

### Backend Tests
```bash
cd backend
source .venv/bin/activate
python3 -m unittest       # All tests (expects local fallback behavior)
python3 -m unittest test_service_integrations.TestServiceIntegrationTests.test_pii_detect_without_key_returns_local_fallback
```

## Known Issues & Limitations

1. **DigiLocker:** Currently a mock with fake login/OTP. Real integration requires:
   - API Setu partnership
   - DigiLocker API credentials
   - User consent flow

2. **Bhashini ASR/TTS:** Not integrated. Currently using:
   - `speech_to_text` (Google, offline available)
   - `flutter_tts` (native TTS)

3. **Civic Complaints:** Draft only — does not submit to actual municipal systems.

4. **Mandi Prices:** Live data from data.gov.in (demo feed), fallback to static pricing.

5. **AQI & Flood Alerts:** Mock data only when backend is offline.

## File Structure

```
/Users/mohith/Downloads/yojana_mitra_app/
├── lib/main.dart                          # Main Flutter app (~4400 lines)
├── android/                               # Android build config
│   ├── app/build.gradle.kts               # Package: com.example.yojana_mitra_app
│   ├── app/src/main/AndroidManifest.xml   # Permissions, no cleartext in release
│   └── key.properties.example             # Signing key template
├── backend/                               # FastAPI backend
│   ├── main.py                            # Endpoints
│   ├── test_service_integrations.py       # Tests
│   ├── .env.example                       # Template
│   └── requirements.txt                   # Dependencies
├── test/                                  # Flutter widget tests
│   └── widget_test.dart
├── pubspec.yaml                           # Flutter dependencies
└── README.md                              # This file
```

## Next Steps to Production

1. **Package Renaming:** `in.bharatmitra.app` (or similar approved name)
2. **Real Integrations:**
   - DigiLocker via API Setu
   - Bhashini for multi-language ASR/TTS
   - Production backend URL
3. **Play Store:**
   - Privacy Policy
   - Data Safety Form
   - App signing key management
4. **Localization:** Multi-language UI (currently Simple English only)
5. **Permissions:** Runtime request flow for microphone, location, etc.

## Resources

- [Flutter Docs](https://docs.flutter.dev/)
- [myScheme.gov.in](https://www.myscheme.gov.in/) — Official schemes portal
- [data.gov.in](https://data.gov.in/) — Government data APIs
- [API Setu](https://www.apisetu.gov.in/) — DigiLocker integration

---

**Maintainer:** BharatMitra Team  
**Last Updated:** May 2026  
**License:** [To be determined]
