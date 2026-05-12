# BharatMitra UI Revamp Task for Claude Code

The theme in lib/main.dart has been updated to a dark India-inspired palette:
- Primary: #E85D04 (saffron orange)
- Background: #0D1B2A (deep navy)
- Surface: #111827
- Cards: #1E2D40

## Your tasks — update the Flutter widgets in lib/main.dart:

### 1. _HeroCard
Replace with a gradient header card using:
- LinearGradient from #E85D04 → #F48C06 → #1B4332
- "Namaste 🇮🇳" greeting text in white
- BharatMitra subtitle in white/70
- User avatar circle (M initials) top-right
- Live status chips row (Backend: Online/Offline dot indicator)

### 2. _AskCard
- Dark card background (#1E2D40)
- White text input with hint "Tell me your situation..."
- Saffron orange mic button when listening (animated pulse)
- "Find Schemes" button in saffron orange (#E85D04)
- Quick sample chips below in rounded pill style

### 3. _BharatServicesCard
- Grid of 2x2 service icon cards (like the mockup)
- Each card: colored icon background, title in white, subtitle in gray
- Colors: Mandi=orange, AQI=blue, Flood=green, Civic=purple, AI=navy

### 4. _BackendAiCard  
- Status dot (green/red) with clean status text
- "Ask AI (Fast)" and "Ask AI (Smart)" buttons side by side
- Answer card with left accent border in #76ABDF

### 5. Bottom navigation bar
Add a BottomNavigationBar with: Home, Schemes, Alerts, Profile
- Selected: #E85D04, Unselected: gray/50
- Background: #0D1B2A

### General rules:
- All text on dark surfaces must be white or white/opacity
- Accent color: #E85D04 (saffron)
- Secondary accent: #6EE7B7 (mint green for success states)
- Error/warning: #FCA5A5 (soft red)
- Keep ALL existing logic/API calls 100% intact
- Run: flutter analyze && flutter test after changes

Run this now: cd /Users/mohith/Downloads/yojana_mitra_app && flutter analyze
