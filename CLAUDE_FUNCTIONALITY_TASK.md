# BharatMitra — Full Functionality Task for Claude Code

Work ONLY in: /Users/mohith/Downloads/yojana_mitra_app/lib/main.dart
Do NOT touch backend. Keep ALL existing logic 100% intact.
Use /opt/homebrew/bin/flutter and /opt/homebrew/bin/dart for all commands.

---

## STEP 1 — Fix Lint Warnings First

Run: /opt/homebrew/bin/flutter analyze lib/main.dart
Fix every issue found:
- Remove unused variable `matchScore` (just delete the line that declares it — the `match` variable below it is already used)
- Add curly braces to any if-statements that are missing them
- Remove or keep `_ApiSetupCard` — if unreferenced, delete the entire class definition
- Fix any other warnings or infos

---

## STEP 2 — Real Backend Integration for Bharat Services

The app has a `_BharatServicesCard` widget and `BharatModuleAdvisor` class.
Currently when user taps a module tile it just puts a text prompt. Make each module tile ALSO call the backend and show a real result.

### Backend endpoints (base URL from `_backendController.text`, default http://10.0.2.2:8000):

**Mandi / Crop Prices:**
POST `{baseUrl}/mandi/advice`
Body: `{"crop": "rice", "state": "Andhra Pradesh"}`  ← use profile state and detected crop from text
Response: `{"advice": "...", "price_data": {...}}`
Show the `advice` field in a result card under the module.

**AQI / Air Quality:**
POST `{baseUrl}/aqi/plan`  
Body: `{"city": "Hyderabad"}` ← use profile state capital or city from text
Response: `{"plan": "...", "aqi": 45}`
Show plan + AQI number.

**Flood / Weather Risk:**
POST `{baseUrl}/flood/risk`
Body: `{"state": "Andhra Pradesh", "district": ""}`
Response: `{"risk_level": "low", "advice": "..."}`
Show risk level chip + advice.

**Civic Draft:**
POST `{baseUrl}/civic/report-draft`
Body: `{"issue": "road pothole", "location": "village"}`  ← extract from user text
Response: `{"draft": "To the collector..."}`
Show draft text in a copyable card.

### How to integrate:

In `_AssistantHomePageState`, add method `_callModule(BharatModule module, String prompt)` that:
1. Detects module type from `module.label` 
2. Calls appropriate endpoint
3. Updates `_backendAnswer` and `_backendStatus` and switches to show result
4. Shows a SnackBar with loading, then displays result in the existing `_BackendAiCard`

In `_BharatServicesCard`, change `onUsePrompt` to also trigger the backend call.
Pass a new `onModuleTap` callback: `void Function(BharatModule)`.

---

## STEP 3 — Voice Input Fix for Real Device

The `_listen()` method uses `speech_to_text`. On real Android device it needs:
- `await _speech.initialize(onError: (e) => ..., onStatus: (s) => ...)` with proper error handling
- Show SnackBar if not available: "Enable microphone permission in Settings"
- Add a visual pulse animation when listening (wrap the mic button in an AnimatedContainer that pulses red when `_isListening` is true)

---

## STEP 4 — Profile Auto-Update

When user changes state/name/occupation in Profile tab edit dialog and taps Save:
- Immediately rebuild the scheme prompt
- Auto-run `_runAssistant()` in background
- Show a SnackBar: "Schemes updated for [name]"

Make the "Update & Re-match Schemes" button in Profile tab do this properly.

---

## STEP 5 — After All Changes

1. Run: /opt/homebrew/bin/dart format lib/main.dart
2. Run: /opt/homebrew/bin/flutter analyze
3. Fix all errors and warnings
4. Run: /opt/homebrew/bin/flutter build apk --debug
5. Report: changes made, issues found, APK size

---

## Notes

- Background: Color(0xFF0D1B2A)
- Accent saffron: Color(0xFFE85D04)  
- Mint: Color(0xFF6EE7B7)
- Card: Color(0xFF1E2D40)
- Gray: Color(0xFF9CA3AF)
- The `_backendController` has the base URL
- The `schemes` const list has all WelfareScheme objects
- `_profileState`, `_profileName`, `_profileOccupation` are state vars in `_AssistantHomePageState`
