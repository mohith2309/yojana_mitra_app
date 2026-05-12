# BharatMitra — OOBE + DigiLocker Task for Claude Code

Work ONLY in: /Users/mohith/Downloads/yojana_mitra_app/lib/main.dart
Do NOT touch backend. Keep ALL existing logic 100% intact.
Use /opt/homebrew/bin/flutter and /opt/homebrew/bin/dart for all commands.

---

## TASK 1 — Windows OOBE-style First Launch Setup

Replace the existing simple onboarding with a full OOBE setup wizard.
Use SharedPreferences key `'setup_complete'` (not `'onboarding_done'`).
On first launch show the setup wizard. After completion go to main app.

### Setup Wizard — 5 Steps with progress indicator dots at top

**Step 1 — Welcome / Language**
- Full dark screen, BharatMitra logo (Icon(Icons.account_balance, size:80, color: Color(0xFFE85D04)))
- Large "Namaste! 🇮🇳" in white, bold
- Subtitle: "Your personal guide to government schemes" in gray
- Language chips (just visual, no logic needed): English, हिंदी, తెలుగు, தமிழ், বাংলা
- English selected by default (saffron border)
- "Get Started →" button, saffron, full width

**Step 2 — About You**
- Title: "Tell me about yourself"
- Name TextField (dark fill, white text, hint "Your name")
- State DropdownButton with list: ["Andhra Pradesh","Bihar","Delhi","Gujarat","Karnataka","Kerala","Maharashtra","Rajasthan","Tamil Nadu","Telangana","Uttar Pradesh","West Bengal","Other"]
- Occupation chips: Farmer 🌾, Student 📚, Worker 👷, Business 💼, Other
- Family size slider 1–10 with value display
- "Next →" button

**Step 3 — Permissions**
- Title: "Allow BharatMitra to help you better"
- Two permission cards:
  - 🎤 Microphone — "For voice input" — Switch (default on)
  - 🔔 Notifications — "For scheme alerts" — Switch (default on)  
- Both are visual only (no actual permission API calls needed)
- "Next →" button

**Step 4 — DigiLocker Setup** (SEE TASK 2 BELOW for DigiLocker details)
- Title: "Connect DigiLocker (Optional)"
- Subtitle: "Access your Aadhaar, Ration Card and more"
- Big DigiLocker card (dark bg #1E2D40, rounded)
- DigiLocker logo area: Icon(Icons.folder_special, size:48, color: Color(0xFF6EE7B7))
- "Connect with DigiLocker" button → shows bottom sheet mock auth flow (see Task 2)
- "Skip for now" text button below
- If connected: show green checkmark + "Connected ✓"

**Step 5 — Ready!**
- Animated checkmark or large ✅ icon in mint green
- "You're all set!" in white, large bold
- "BharatMitra is ready to find schemes for you" in gray
- Summary chips showing what was set up
- "Start Using BharatMitra →" button → saves setup_complete=true → goes to main app

### Setup Wizard UI Rules:
- Background: Color(0xFF0D1B2A) throughout
- Cards: Color(0xFF1E2D40)  
- Accent: Color(0xFFE85D04)
- Mint: Color(0xFF6EE7B7)
- Gray text: Color(0xFF9CA3AF)
- White text for headings
- Progress dots at top (5 dots, filled saffron = done, outline = pending)
- Back button on steps 2-5
- Smooth PageView or manual setState index navigation

---

## TASK 2 — DigiLocker Finalization

### In the OOBE Step 4 AND in the main app DigiLocker section:

**Mock Auth Flow (BottomSheet):**
When user taps "Connect with DigiLocker":
- Show a ModalBottomSheet with dark bg
- Header: "DigiLocker Login" with close button
- Aadhaar number field (12 digits, obscured after 4 chars shown)
- OTP field (6 digits)  
- "Send OTP" button → after tap, show a SnackBar "OTP sent to registered mobile" and enable OTP field
- "Verify & Connect" button → closes sheet, sets `digilocker_connected = true` in SharedPreferences, shows success
- "Use DigiLocker App instead" secondary button

**Main App DigiLocker Card (replace existing mock):**
Check SharedPreferences `digilocker_connected`:

If NOT connected:
- Card with Icon(Icons.folder_special) in mint
- "DigiLocker Not Connected"
- "Connect to access Aadhaar, Ration Card, Income Certificate"
- "Connect Now" button → opens auth BottomSheet above

If connected:
- Green header bar: "DigiLocker Connected ✓"
- List of 4 document tiles:
  1. 📄 Aadhaar Card — "XXXX XXXX 8842" — [View] chip
  2. 📋 Ration Card — "AP/2024/XXXXXX" — [View] chip  
  3. 💰 Income Certificate — "Issued: Jan 2025" — [View] chip
  4. 🏠 Land Records — "Survey #XXXX" — [View] chip
- Each [View] chip → SnackBar: "Opening [doc] in DigiLocker..."
- "Disconnect" text button at bottom → sets digilocker_connected=false, rebuilds

---

## TASK 3 — After changes

1. Run: /opt/homebrew/bin/dart format lib/main.dart
2. Run: /opt/homebrew/bin/flutter analyze
3. Fix any errors found
4. Run: /opt/homebrew/bin/flutter build apk --debug
5. Report: what was changed, analyze result, APK size
