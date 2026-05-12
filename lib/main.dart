import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const BharatMitraApp());
}

class BharatMitraApp extends StatelessWidget {
  const BharatMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFFE85D04); // saffron – India-inspired primary
    const darkBg = Color(0xFF0D1B2A);
    const surfaceBg = Color(0xFF111827);
    const cardBg = Color(0xFF1E2D40);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BharatMitra',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
          surface: surfaceBg,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: darkBg,
        useMaterial3: true,
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: cardBg,
          hintStyle: const TextStyle(color: Color(0xFF6B7280)),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Color(0xFF9CA3AF)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: seedColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: cardBg,
          selectedColor: seedColor.withValues(alpha: 0.3),
          labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1E2D40),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: const _OnboardingGate(),
    );
  }
}

class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate();

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  bool? _done;

  @override
  void initState() {
    super.initState();
    _loadOnboarding();
  }

  Future<void> _loadOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _done = prefs.getBool('setup_complete') ?? false);
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_complete', true);
    if (!mounted) return;
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_done == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _done!
        ? const AssistantHomePage()
        : _OobeWizard(onDone: _finishOnboarding);
  }
}

// ─────────────────────────────────────────────
//  OOBE Wizard  (5-step Windows-OOBE-style)
// ─────────────────────────────────────────────

class _OobeWizard extends StatefulWidget {
  const _OobeWizard({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_OobeWizard> createState() => _OobeWizardState();
}

class _OobeWizardState extends State<_OobeWizard> {
  int _step = 0;
  static const int _totalSteps = 5;

  // Step 2 — About You
  final _nameCtrl = TextEditingController();
  String _selectedState = 'Andhra Pradesh';
  String _selectedOccupation = 'Farmer 🌾';
  double _familySize = 3;

  // Step 3 — Permissions
  bool _micOn = true;
  bool _notifOn = true;

  // Step 4 — DigiLocker
  bool _digiConnected = false;

  // Step 1 — Language
  String _selectedLang = 'English';

  static const _stateList = [
    'Andhra Pradesh',
    'Bihar',
    'Delhi',
    'Gujarat',
    'Karnataka',
    'Kerala',
    'Maharashtra',
    'Rajasthan',
    'Tamil Nadu',
    'Telangana',
    'Uttar Pradesh',
    'West Bengal',
    'Other',
  ];

  static const _occupations = [
    'Farmer 🌾',
    'Student 📚',
    'Worker 👷',
    'Business 💼',
    'Other',
  ];

  static const _languages = ['English', 'हिंदी', 'తెలుగు', 'தமிழ்', 'বাংলা'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _goNext() =>
      setState(() => _step = (_step + 1).clamp(0, _totalSteps - 1));
  void _goBack() =>
      setState(() => _step = (_step - 1).clamp(0, _totalSteps - 1));

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_complete', true);
    if (_digiConnected) await prefs.setBool('digilocker_connected', true);
    if (_nameCtrl.text.trim().isNotEmpty) {
      await prefs.setString('user_name', _nameCtrl.text.trim());
    }
    await prefs.setString('user_state', _selectedState);
    await prefs.setString('user_occupation', _selectedOccupation);
    await prefs.setInt('user_family_size', _familySize.toInt());
    await prefs.setString('user_language', _selectedLang);
    widget.onDone();
  }

  Widget _progressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps, (i) {
        final done = i <= _step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: done ? 26 : 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: done ? const Color(0xFFE85D04) : Colors.transparent,
            border: Border.all(
              color: done ? const Color(0xFFE85D04) : const Color(0xFF4B5563),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }

  // ── Step 1: Welcome / Language ──────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          const Icon(Icons.account_balance, size: 80, color: Color(0xFFE85D04)),
          const SizedBox(height: 28),
          const Text(
            'Namaste! 🇮🇳',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your personal guide to government schemes',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 36),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Choose your language',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _languages.map((lang) {
              final selected = lang == _selectedLang;
              return GestureDetector(
                onTap: () => setState(() => _selectedLang = lang),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFE85D04).withValues(alpha: 0.15)
                        : const Color(0xFF1E2D40),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFE85D04)
                          : const Color(0xFF374151),
                      width: selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    lang,
                    style: TextStyle(
                      color: selected ? const Color(0xFFE85D04) : Colors.white,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _goNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE85D04),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Get Started →',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: About You ───────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell me about yourself',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E2D40),
              hintText: 'Your name',
              hintStyle: const TextStyle(color: Color(0xFF6B7280)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2D40),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButton<String>(
              value: _selectedState,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: const Color(0xFF1E2D40),
              style: const TextStyle(color: Colors.white),
              onChanged: (v) =>
                  setState(() => _selectedState = v ?? _selectedState),
              items: _stateList
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Occupation',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _occupations.map((occ) {
              final selected = occ == _selectedOccupation;
              return GestureDetector(
                onTap: () => setState(() => _selectedOccupation = occ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFE85D04).withValues(alpha: 0.15)
                        : const Color(0xFF1E2D40),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFE85D04)
                          : const Color(0xFF374151),
                      width: selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    occ,
                    style: TextStyle(
                      color: selected ? const Color(0xFFE85D04) : Colors.white,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Family size:',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(width: 8),
              Text(
                _familySize.toInt().toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFE85D04),
              thumbColor: const Color(0xFFE85D04),
              inactiveTrackColor: const Color(0xFF374151),
            ),
            child: Slider(
              value: _familySize,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => setState(() => _familySize = v),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _goNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE85D04),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Next →',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Permissions ─────────────────────────────
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Allow BharatMitra to help you better',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 32),
        _permissionCard(
          icon: '🎤',
          title: 'Microphone',
          subtitle: 'For voice input',
          value: _micOn,
          onChanged: (v) => setState(() => _micOn = v),
        ),
        const SizedBox(height: 14),
        _permissionCard(
          icon: '🔔',
          title: 'Notifications',
          subtitle: 'For scheme alerts',
          value: _notifOn,
          onChanged: (v) => setState(() => _notifOn = v),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _goNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE85D04),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Next →',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _permissionCard({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2D40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFFE85D04),
          ),
        ],
      ),
    );
  }

  // ── Step 4: DigiLocker ──────────────────────────────
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connect DigiLocker',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Optional',
          style: TextStyle(
            color: Color(0xFFE85D04),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Access your Aadhaar, Ration Card and more',
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2D40),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF374151)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.folder_special,
                size: 48,
                color: Color(0xFF6EE7B7),
              ),
              const SizedBox(height: 14),
              if (_digiConnected) ...[
                const Icon(
                  Icons.check_circle,
                  size: 36,
                  color: Color(0xFF22C55E),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connected ✓',
                  style: TextStyle(
                    color: Color(0xFF22C55E),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ] else ...[
                const Text(
                  'DigiLocker',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'One-tap access to your government documents',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showDigiLockerSheet(
                      context,
                      onConnected: () {
                        setState(() => _digiConnected = true);
                      },
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6EE7B7),
                      foregroundColor: const Color(0xFF0D1B2A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.folder_special),
                    label: const Text(
                      'Connect with DigiLocker',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _goNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE85D04),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Next →',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        TextButton(
          onPressed: _goNext,
          child: const Center(
            child: Text(
              'Skip for now',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 5: Ready ───────────────────────────────────
  Widget _buildStep5() {
    final summaryItems = [
      _selectedLang,
      _selectedState,
      _selectedOccupation,
      'Family: ${_familySize.toInt()}',
      if (_micOn) '🎤 Voice',
      if (_notifOn) '🔔 Alerts',
      if (_digiConnected) '📂 DigiLocker',
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 80,
          color: Color(0xFF6EE7B7),
        ),
        const SizedBox(height: 24),
        const Text(
          "You're all set!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'BharatMitra is ready to find schemes for you',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: summaryItems
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2D40),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF374151)),
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _finish,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE85D04),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Start Using BharatMitra →',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepWidgets = [
      _buildStep1(),
      _buildStep2(),
      _buildStep3(),
      _buildStep4(),
      _buildStep5(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              _progressDots(),
              const SizedBox(height: 28),
              if (_step > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _goBack,
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                    label: const Text(
                      'Back',
                      style: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                  ),
                ),
              Expanded(child: stepWidgets[_step]),
            ],
          ),
        ),
      ),
    );
  }
}

class AssistantHomePage extends StatefulWidget {
  const AssistantHomePage({super.key});

  @override
  State<AssistantHomePage> createState() => _AssistantHomePageState();
}

class _AssistantHomePageState extends State<AssistantHomePage> {
  final _assistant = SchemeAssistant();
  final _speech = stt.SpeechToText();
  final _tts = FlutterTts();
  final _requestController = TextEditingController();
  final _backendController = TextEditingController(
    text: '', // Empty = offline mode, app works without backend setup
  );
  String _language = 'Simple English';
  bool _isListening = false;
  bool _backendBusy = false;
  bool _backendOk = false;
  String _backendStatus = 'Backend not checked';
  String? _backendAnswer;
  CitizenProfile? _profile;
  List<SchemeMatch> _matches = [];
  List<AppNotice> _notices = [];
  Set<String> _savedSchemes = {};

  // Navigation
  int _navIndex = 0;

  // Profile data (loaded from SharedPreferences / OOBE)
  String _profileName = '';
  String _profileState = '';
  String _profileOccupation = '';
  int _profileFamilySize = 4;

  // Schemes tab search and filtering
  String _schemeSearch = '';
  Set<SchemeTag> _selectedTags = {};
  bool _showOnlyMatched = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSchemes();
    _loadProfileAndRun();
  }

  Future<void> _loadProfileAndRun() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final state = prefs.getString('user_state') ?? '';
    final occupation = prefs.getString('user_occupation') ?? '';
    final familySize = prefs.getInt('user_family_size') ?? 4;
    if (mounted) {
      setState(() {
        _profileName = name;
        _profileState = state;
        _profileOccupation = occupation;
        _profileFamilySize = familySize;
      });
    }
    // Auto-build prompt from OOBE data if available
    if (state.isNotEmpty || occupation.isNotEmpty) {
      final parts = <String>[];
      if (name.isNotEmpty) parts.add('My name is $name.');
      final occ = occupation.split(' ').first.toLowerCase();
      if (occ.isNotEmpty && occ != 'other') parts.add('I am a $occ.');
      if (state.isNotEmpty) parts.add('I live in $state.');
      parts.add('My family has $familySize members.');
      if (mounted) {
        setState(() => _requestController.text = parts.join(' '));
        _runAssistant();
      }
    } else {
      // Fallback demo prompt
      if (mounted) {
        setState(
          () => _requestController.text =
              'My husband passed away. I live in a village with two children and annual income around 70000.',
        );
      }
    }
  }

  Future<void> _saveProfileField(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) await prefs.setString(key, value);
    if (value is int) await prefs.setInt(key, value);
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _requestController.dispose();
    _backendController.dispose();
    super.dispose();
  }

  void _runAssistant() {
    final text = _requestController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tell BharatMitra your situation first.')),
      );
      return;
    }

    final profile = _assistant.extractProfile(text);
    final matches = _assistant.findSchemes(profile, text);
    final notices = _assistant.createNotices(profile, matches);

    setState(() {
      _profile = profile;
      _matches = matches;
      _notices = notices;
    });
  }

  void _useSample(String text) {
    setState(() => _requestController.text = text);
    _runAssistant();
  }

  void _markNoticeRead(AppNotice notice) {
    setState(() {
      final index = _notices.indexOf(notice);
      if (index != -1) {
        _notices[index] = notice.copyWith(read: true);
      }
    });
  }

  Future<void> _loadSavedSchemes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedSchemes = prefs.getStringList('saved_schemes')?.toSet() ?? {};
    });
  }

  Future<void> _toggleSaved(WelfareScheme scheme) async {
    setState(() {
      if (_savedSchemes.contains(scheme.name)) {
        _savedSchemes.remove(scheme.name);
      } else {
        _savedSchemes.add(scheme.name);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_schemes', _savedSchemes.toList()..sort());
  }

  Future<void> _listen() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    bool available = false;
    try {
      available = await _speech.initialize(
        onError: (error) {
          setState(() => _isListening = false);
          if (error.errorMsg.contains('permission') ||
              error.errorMsg.contains('denied')) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text(
                  'Enable microphone permission in Settings → App permissions → Microphone',
                ),
                duration: Duration(seconds: 4),
              ),
            );
          }
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
      );
    } catch (_) {
      available = false;
    }
    if (!available) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Enable microphone permission in Settings → App permissions → Microphone',
          ),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    setState(() => _isListening = true);
    await _speech.listen(
      localeId: 'en_IN',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      onResult: (result) {
        setState(() => _requestController.text = result.recognizedWords);
        if (result.finalResult) {
          setState(() => _isListening = false);
          _runAssistant();
        }
      },
    );
  }

  Future<void> _speakResults() async {
    if (_matches.isEmpty) {
      await _tts.speak('Tell me your situation and tap find schemes first.');
      return;
    }
    final top = _matches.take(3).map((match) => match.scheme.name).join(', ');
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(.45);
    await _tts.speak(
      'Top schemes found are $top. Please verify eligibility on the official portal.',
    );
  }

  Future<void> _shareChecklist() async {
    if (_matches.isEmpty) {
      _showMessage('Find schemes first, then share the checklist.');
      return;
    }
    await SharePlus.instance.share(ShareParams(text: _buildChecklistText()));
  }

  Future<void> _exportPdf() async {
    if (_matches.isEmpty) {
      _showMessage('Find schemes first, then export PDF.');
      return;
    }
    final bytes = await _buildChecklistPdf();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'yojana_mitra_checklist.pdf',
    );
  }

  Future<void> _openOfficialPortal(WelfareScheme scheme) async {
    final query = Uri.encodeComponent(scheme.name);
    final uri = Uri.parse('https://www.myscheme.gov.in/search?keyword=$query');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showMessage(
        'Could not open official portal. Search myScheme for ${scheme.name}.',
      );
    }
  }

  Future<void> _checkBackend() async {
    final baseUrl = _backendController.text.trim();
    if (baseUrl.isEmpty) {
      _showMessage('Enter backend URL first.');
      return;
    }
    setState(() {
      _backendBusy = true;
      _backendStatus = 'Checking backend...';
    });
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 8));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final configured = data['configured'] as Map<String, dynamic>? ?? {};
      setState(() {
        _backendOk = response.statusCode == 200 && data['ok'] == true;
        _backendStatus = _backendOk
            ? 'Backend online • NVIDIA: ${configured['nvidia'] == true ? 'ready' : 'no key'}'
            : 'Backend responded with ${response.statusCode}';
      });
    } catch (error) {
      setState(() {
        _backendOk = false;
        _backendStatus = 'Backend offline. Local mode still works.';
      });
    } finally {
      setState(() => _backendBusy = false);
    }
  }

  Future<void> _callModule(BharatModule module, String prompt) async {
    final baseUrl = _backendController.text.trim();
    final label = module.title.toLowerCase();
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _backendBusy = true;
      _backendAnswer = null;
      _backendStatus = 'Fetching ${module.title}...';
      _requestController.text = prompt;
      _navIndex = 0;
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text('Loading ${module.title}...'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      http.Response response;

      if (label.contains('mandi') ||
          label.contains('crop') ||
          label.contains('farm')) {
        // Extract crop from prompt text
        final cropMatch = RegExp(
          r'\b(rice|wheat|cotton|maize|sugarcane|soybean|potato|onion|tomato)\b',
          caseSensitive: false,
        ).firstMatch(prompt);
        final crop = cropMatch?.group(0) ?? 'rice';
        final state = _profileState.isNotEmpty
            ? _profileState
            : 'Andhra Pradesh';
        response = await http
            .post(
              Uri.parse('$baseUrl/mandi/advice'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'crop': crop.toLowerCase(), 'state': state}),
            )
            .timeout(const Duration(seconds: 15));
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        String answer;
        if (data['advice'] != null) {
          final advice = data['advice'];
          if (advice is List) {
            answer = advice.join('\n• ');
          } else {
            answer = advice.toString();
          }
        } else {
          answer = 'Price data: ${jsonEncode(data['price_data'] ?? {})}';
        }
        setState(() {
          _backendOk = true;
          _backendStatus = 'Mandi prices for $crop in $state';
          _backendAnswer = answer;
        });
      } else if (label.contains('aqi') ||
          label.contains('air') ||
          label.contains('weather')) {
        final city = _profileState.isNotEmpty ? _profileState : 'Hyderabad';
        response = await http
            .post(
              Uri.parse('$baseUrl/aqi/plan'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'location': city}),
            )
            .timeout(const Duration(seconds: 15));
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final aqi = data['aqi']?.toString() ?? '—';
        final plan = data['activity_plan']?.toString() ?? data['guidance']?.toString() ?? 'No plan returned.';
        setState(() {
          _backendOk = true;
          _backendStatus = 'AQI in $city: $aqi';
          _backendAnswer = 'AQI: $aqi\n\n$plan';
        });
      } else if (label.contains('flood') ||
          label.contains('risk') ||
          label.contains('disaster')) {
        final state = _profileState.isNotEmpty
            ? _profileState
            : 'Andhra Pradesh';
        response = await http
            .post(
              Uri.parse('$baseUrl/flood/risk'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'state': state, 'district': ''}),
            )
            .timeout(const Duration(seconds: 15));
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final risk = data['risk']?.toString() ?? 'unknown';
        final checklist = data['checklist']?.toString() ?? '';
        setState(() {
          _backendOk = true;
          _backendStatus = 'Flood risk in $state: $risk';
          _backendAnswer = 'Risk level: ${risk.toUpperCase()}\n\n$checklist';
        });
      } else if (label.contains('civic') ||
          label.contains('complaint') ||
          label.contains('draft')) {
        final issueMatch = RegExp(
          r'\b(pothole|road|water|electricity|garbage|sewer|light|drain)\b',
          caseSensitive: false,
        ).firstMatch(prompt);
        final issue = issueMatch?.group(0) ?? 'civic issue';
        response = await http
            .post(
              Uri.parse('$baseUrl/civic/report-draft'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'issue': issue,
                'location': _profileState.isNotEmpty
                    ? _profileState
                    : 'village',
              }),
            )
            .timeout(const Duration(seconds: 15));
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _backendOk = true;
          _backendStatus = 'Civic draft ready';
          _backendAnswer = data['draft']?.toString() ?? 'No draft returned.';
        });
      } else {
        // Fallback: use generic backend chat
        await _askBackend('consumer');
        return;
      }
    } catch (_) {
      setState(() {
        _backendOk = false;
        _backendStatus =
            '${module.title} — backend offline, showing local info';
        _backendAnswer = module.localAdvice;
      });
    } finally {
      setState(() => _backendBusy = false);
    }
  }

  Future<void> _askBackend(String mode) async {
    final baseUrl = _backendController.text.trim();
    final prompt = _buildBackendPrompt(mode);
    if (baseUrl.isEmpty) {
      _showMessage('Enter backend URL first.');
      return;
    }
    setState(() {
      _backendBusy = true;
      _backendAnswer = null;
      _backendStatus = mode == 'consumer'
          ? 'Asking fast Google model...'
          : 'Asking NVIDIA auto-task model...';
    });
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/nvidia/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mode': mode, 'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 45));
      if (response.statusCode == 503) {
        setState(() {
          _backendOk = false;
          _backendStatus = 'AI key missing. Local mode still works.';
          _backendAnswer =
              'Use the local scheme matches for now. Ask a helper to add backend keys only on the server.';
        });
        return;
      }
      if (response.statusCode >= 400) {
        throw Exception('Backend returned ${response.statusCode}');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      setState(() {
        _backendOk = true;
        _backendStatus = 'AI response from ${data['model'] ?? mode}';
        _backendAnswer = (data['answer'] ?? data['content'] ?? '')
            .toString()
            .trim();
      });
    } catch (error) {
      setState(() {
        _backendOk = false;
        _backendStatus = 'AI backend offline. Local mode still works.';
        _backendAnswer =
            'Use the local scheme matches now. Try backend AI again after the server is running.';
      });
    } finally {
      setState(() => _backendBusy = false);
    }
  }

  String _buildBackendPrompt(String mode) {
    final text = _requestController.text.trim();
    final topSchemes = _matches
        .take(3)
        .map((match) => '${match.scheme.name}: ${match.scheme.benefit}')
        .join('\n');
    if (mode == 'consumer') {
      return '''Explain these welfare scheme options in simple language for a citizen.

User situation: $text

Top local matches:
$topSchemes

Rules: keep it short, friendly, and tell them to verify on official portal or CSC.''';
    }
    return '''You are the backend automation model for BharatMitra.

User situation: $text

Local profile: ${_profile?.summaryChips.join(', ') ?? 'not extracted'}

Top local matches:
$topSchemes

Return concise structured next steps, missing documents, and which details to ask next. Do not invent final eligibility.''';
  }

  String _buildChecklistText() {
    final buffer = StringBuffer()
      ..writeln('BharatMitra checklist')
      ..writeln('')
      ..writeln('Profile: ${_profile?.summaryChips.join(', ') ?? 'Not filled'}')
      ..writeln('');
    for (final match in _matches.take(5)) {
      buffer
        ..writeln('${match.scheme.name} (${match.score}%)')
        ..writeln('Benefit: ${match.scheme.benefit}')
        ..writeln('Documents: ${match.scheme.documents.join(', ')}')
        ..writeln('Next: ${match.scheme.steps.first}')
        ..writeln('');
    }
    buffer.writeln(
      'Verify details on official myScheme/department portal or CSC before applying.',
    );
    return buffer.toString();
  }

  Future<Uint8List> _buildChecklistPdf() async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'BharatMitra checklist',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Profile: ${_profile?.summaryChips.join(', ') ?? 'Not filled'}',
          ),
          pw.SizedBox(height: 16),
          for (final match in _matches.take(5))
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${match.scheme.name} (${match.score}%)',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(match.scheme.benefit),
                  pw.Text('Why: ${match.why}'),
                  pw.Text('Documents: ${match.scheme.documents.join(', ')}'),
                  pw.Text('Next step: ${match.scheme.steps.first}'),
                ],
              ),
            ),
          pw.Text(
            'Prototype note: verify on official portal/CSC before applying.',
          ),
        ],
      ),
    );
    return doc.save();
  }

  List<String> get _topDocuments {
    final docs = <String>{};
    for (final match in _matches.take(4)) {
      docs.addAll(match.scheme.documents);
    }
    return docs.toList()..sort();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Tab routing ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final unread = _notices.where((n) => !n.read).length;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF111827),
        indicatorColor: const Color(0xFFE85D04).withValues(alpha: 0.2),
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Color(0xFF9CA3AF)),
            selectedIcon: Icon(Icons.home, color: Color(0xFFE85D04)),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.list_alt_outlined, color: Color(0xFF9CA3AF)),
            selectedIcon: Icon(Icons.list_alt, color: Color(0xFFE85D04)),
            label: 'Schemes',
          ),
          NavigationDestination(
            icon: Badge(
              label: unread > 0 ? Text('$unread') : null,
              isLabelVisible: unread > 0,
              child: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF9CA3AF),
              ),
            ),
            selectedIcon: const Icon(
              Icons.notifications,
              color: Color(0xFFE85D04),
            ),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline, color: Color(0xFF9CA3AF)),
            selectedIcon: Icon(Icons.person, color: Color(0xFFE85D04)),
            label: 'Profile',
          ),
        ],
      ),
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildHomeTab(),
          _buildSchemesTab(),
          _buildAlertsTab(),
          _buildProfileTab(),
        ],
      ),
    );
  }

  // ── HOME TAB ────────────────────────────────────────
  Widget _buildHomeTab() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
              child: _HeroCard(
                language: _language,
                onLanguageChanged: (value) => setState(() => _language = value),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: _AskCard(
                controller: _requestController,
                onRun: _runAssistant,
                onListen: _listen,
                onSample: _useSample,
                isListening: _isListening,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: _BharatServicesCard(
                modules: BharatModuleAdvisor.modulesFor(
                  _requestController.text,
                ),
                onUsePrompt: _useSample,
                onModuleTap: (module) =>
                    _callModule(module, module.samplePrompt),
              ),
            ),
          ),
          if (_profile != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: _ProfileSummary(profile: _profile!),
              ),
            ),
          if (_matches.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: _QuickStats(matches: _matches, notices: _notices),
              ),
            ),
          if (_matches.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: _ActionPanel(
                  savedCount: _savedSchemes.length,
                  docs: _topDocuments,
                  onSpeak: _speakResults,
                  onShare: _shareChecklist,
                  onPdf: _exportPdf,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: _DigiLockerCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: _BackendAiCard(
                controller: _backendController,
                busy: _backendBusy,
                ok: _backendOk,
                status: _backendStatus,
                answer: _backendAnswer,
                onCheck: _checkBackend,
                onConsumer: () => _askBackend('consumer'),
                onAuto: () => _askBackend('auto'),
              ),
            ),
          ),
          if (_matches.isNotEmpty)
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Best schemes for you',
                subtitle: 'Ranked by local rules. Verify before applying.',
                action: TextButton.icon(
                  onPressed: _runAssistant,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ),
            ),
          SliverList.builder(
            itemCount: _matches.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                index == 0 ? 4 : 10,
                18,
                index == _matches.length - 1 ? 10 : 0,
              ),
              child: _SchemeCard(
                match: _matches[index],
                saved: _savedSchemes.contains(_matches[index].scheme.name),
                onSave: () => _toggleSaved(_matches[index].scheme),
                onOpenOfficial: () =>
                    _openOfficialPortal(_matches[index].scheme),
              ),
            ),
          ),
          if (_savedSchemes.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: _SavedSchemesCard(savedSchemes: _savedSchemes),
              ),
            ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 12, 18, 28),
              child: _FreeStackNote(),
            ),
          ),
        ],
      ),
    );
  }

  // ── SCHEMES TAB ─────────────────────────────────────
  Widget _buildSchemesTab() {
    final query = _schemeSearch.toLowerCase();
    final all = schemes;

    // Filter by search query
    var filtered = (query.isEmpty
            ? all
            : all.where(
                (s) =>
                    s.name.toLowerCase().contains(query) ||
                    s.category.toLowerCase().contains(query) ||
                    s.benefit.toLowerCase().contains(query) ||
                    s.keywords.any((k) => k.contains(query)),
              ))
        .toList();

    // Filter by selected tags (AND logic - all selected tags must match)
    if (_selectedTags.isNotEmpty) {
      filtered = filtered
          .where((s) => _selectedTags.every((tag) => s.tags.contains(tag)))
          .toList();
    }

    // Filter by matched status
    if (_showOnlyMatched) {
      final matchedNames = _matches.map((m) => m.scheme.name).toSet();
      filtered = filtered.where((s) => matchedNames.contains(s.name)).toList();
    }

    // Put matched schemes first
    final matchedNames = _matches.map((m) => m.scheme.name).toSet();
    filtered.sort((a, b) {
      final aM = matchedNames.contains(a.name) ? 0 : 1;
      final bM = matchedNames.contains(b.name) ? 0 : 1;
      return aM.compareTo(bM);
    });

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Find Schemes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE85D04).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE85D04)),
                  ),
                  child: Text(
                    '${filtered.length}',
                    style: const TextStyle(
                      color: Color(0xFFE85D04),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E2D40),
                hintText: 'Search: widow, farmer, student, housing...',
                hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                suffixIcon: _schemeSearch.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Color(0xFF9CA3AF)),
                        onPressed: () =>
                            setState(() => _schemeSearch = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _schemeSearch = v),
            ),
          ),
          // Tag filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // "For You" chip - show only matched schemes
                  if (_matches.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('For You'),
                        selected: _showOnlyMatched,
                        onSelected: (v) =>
                            setState(() => _showOnlyMatched = v),
                        backgroundColor:
                            const Color(0xFF1E2D40),
                        selectedColor: const Color(0xFFE85D04)
                            .withValues(alpha: 0.3),
                        labelStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  // Category/Tag chips
                  ...[
                    (SchemeTag.widow, 'Widow'),
                    (SchemeTag.farmer, 'Farmer'),
                    (SchemeTag.student, 'Student'),
                    (SchemeTag.women, 'Women'),
                    (SchemeTag.housing, 'Housing'),
                    (SchemeTag.disability, 'Disability'),
                    (SchemeTag.rural, 'Rural'),
                    (SchemeTag.lowIncome, 'Low Income'),
                  ]
                      .map((pair) {
                    final (tag, label) = pair;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected:
                            _selectedTags.contains(tag),
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                        backgroundColor:
                            const Color(0xFF1E2D40),
                        selectedColor: const Color(0xFFE85D04)
                            .withValues(alpha: 0.3),
                        labelStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          // Results info
          if (_matches.isNotEmpty && !_showOnlyMatched)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  const Icon(Icons.star,
                      color: Color(0xFFE85D04), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${matchedNames.length} match your profile',
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          // Scheme list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 48,
                            color: Color(0xFF374151)),
                        const SizedBox(height: 12),
                        const Text(
                          'No schemes found',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedTags.isEmpty &&
                                  query.isEmpty
                              ? 'Try changing filters'
                              : 'Try different keywords',
                          style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12),
                        ),
                        if (_selectedTags.isNotEmpty ||
                            query.isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.only(
                                    top: 12),
                            child: TextButton(
                              onPressed: () => setState(
                                  () {
                                _selectedTags
                                    .clear();
                                _schemeSearch =
                                    '';
                              }),
                              child: const Text(
                                  'Clear filters'),
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        16, 0, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final scheme = filtered[i];
                      final match = _matches
                          .where((m) =>
                              m.scheme.name ==
                              scheme.name)
                          .firstOrNull;
                      return Padding(
                        padding:
                            const EdgeInsets.only(
                                bottom: 10),
                        child: match != null
                            ? _SchemeCard(
                                match: match,
                                saved: _savedSchemes
                                    .contains(
                                        scheme
                                            .name),
                                onSave: () =>
                                    _toggleSaved(
                                        scheme),
                                onOpenOfficial: () =>
                                    _openOfficialPortal(
                                        scheme),
                              )
                            : _SchemeListTile(
                                scheme: scheme,
                                saved: _savedSchemes
                                    .contains(
                                        scheme
                                            .name),
                                onSave: () =>
                                    _toggleSaved(
                                        scheme),
                                onOpen: () =>
                                    _openOfficialPortal(
                                        scheme),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── ALERTS TAB ──────────────────────────────────────
  Widget _buildAlertsTab() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Alerts & Reminders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                if (_notices.any((n) => !n.read))
                  TextButton(
                    onPressed: () => setState(() {
                      _notices = [
                        for (final n in _notices) n.copyWith(read: true),
                      ];
                    }),
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(color: Color(0xFFE85D04)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _notices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Color(0xFF374151),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No alerts yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Go to Home and run scheme matching',
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _navIndex = 0),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE85D04),
                          ),
                          icon: const Icon(Icons.home),
                          label: const Text('Go to Home'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _notices.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NoticeCard(
                        notice: _notices[i],
                        onDone: () => _markNoticeRead(_notices[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── PROFILE TAB ─────────────────────────────────────
  Widget _buildProfileTab() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE85D04), Color(0xFF1E2D40)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    _profileName.isNotEmpty
                        ? _profileName[0].toUpperCase()
                        : '🇮🇳',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profileName.isNotEmpty
                            ? _profileName
                            : 'BharatMitra User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        _profileState.isNotEmpty
                            ? '$_profileState • $_profileOccupation'
                            : 'Complete your profile',
                        style: const TextStyle(
                          color: Color(0xFFE6FFF5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Profile Details
          _profileSection('👤 Personal Info', [
            _profileField(
              Icons.person,
              'Name',
              _profileName.isNotEmpty ? _profileName : 'Not set',
              () => _editField(
                'Name',
                'user_name',
                _profileName,
                (v) => setState(() => _profileName = v),
              ),
            ),
            _profileField(
              Icons.location_on,
              'State',
              _profileState.isNotEmpty ? _profileState : 'Not set',
              () => _editField(
                'State',
                'user_state',
                _profileState,
                (v) => setState(() => _profileState = v),
              ),
            ),
            _profileField(
              Icons.work,
              'Occupation',
              _profileOccupation.isNotEmpty ? _profileOccupation : 'Not set',
              () => _editField(
                'Occupation',
                'user_occupation',
                _profileOccupation,
                (v) => setState(() => _profileOccupation = v),
              ),
            ),
            _profileField(
              Icons.people,
              'Family Size',
              '$_profileFamilySize members',
              null,
            ),
          ]),
          const SizedBox(height: 12),

          // DigiLocker
          const _DigiLockerCard(),
          const SizedBox(height: 12),

          // Backend Settings
          _profileSection('⚙️ Backend Settings', [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Backend URL',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _backendController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0D1B2A),
                      hintText: 'http://192.168.x.x:8000',
                      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _checkBackend,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _backendOk
                                ? const Color(0xFF156B4F)
                                : const Color(0xFFE85D04),
                          ),
                          child: Text(
                            _backendOk ? '✅ Online' : 'Test Connection',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_backendStatus.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _backendStatus,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Saved Schemes
          if (_savedSchemes.isNotEmpty) ...[
            _profileSection('⭐ Saved Schemes', [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: _savedSchemes
                      .map(
                        (name) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.bookmark,
                            color: Color(0xFFE85D04),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.open_in_new,
                              color: Color(0xFF9CA3AF),
                              size: 18,
                            ),
                            onPressed: () {
                              final scheme = schemes
                                  .where((s) => s.name == name)
                                  .firstOrNull;
                              if (scheme != null) _openOfficialPortal(scheme);
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ]),
            const SizedBox(height: 12),
          ],

          // Re-run scheme matching with updated profile
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Rebuild prompt from current profile data and re-run
                final parts = <String>[];
                if (_profileName.isNotEmpty) {
                  parts.add('My name is $_profileName.');
                }
                if (_profileOccupation.isNotEmpty) {
                  parts.add(
                    'I am a ${_profileOccupation.split(' ').first.toLowerCase()}.',
                  );
                }
                if (_profileState.isNotEmpty) {
                  parts.add('I live in $_profileState.');
                }
                parts.add('My family has $_profileFamilySize members.');
                setState(() {
                  _requestController.text = parts.join(' ');
                  _navIndex = 0;
                });
                _runAssistant();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Schemes updated for ${_profileName.isNotEmpty ? _profileName : 'you'}',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE85D04),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Update & Re-match Schemes',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _profileSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2D40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          const Divider(color: Color(0xFF374151), height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _profileField(
    IconData icon,
    String label,
    String value,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFE85D04), size: 20),
      title: Text(
        label,
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: onTap != null
          ? const Icon(Icons.edit, color: Color(0xFF9CA3AF), size: 16)
          : null,
      onTap: onTap,
    );
  }

  Future<void> _editField(
    String label,
    String prefKey,
    String current,
    ValueChanged<String> onSaved,
  ) async {
    final ctrl = TextEditingController(text: current);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2D40),
        title: Text('Edit $label', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0D1B2A),
            hintText: label,
            hintStyle: const TextStyle(color: Color(0xFF6B7280)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onSaved(ctrl.text.trim());
              _saveProfileField(prefKey, ctrl.text.trim());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE85D04),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.language, required this.onLanguageChanged});

  final String language;
  final ValueChanged<String> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFFE85D04), Color(0xFFF48C06), Color(0xFF1B4332)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -42,
            child: _SoftCircle(
              size: 150,
              color: Colors.white.withValues(alpha: .12),
            ),
          ),
          Positioned(
            right: 34,
            bottom: -48,
            child: _SoftCircle(
              size: 130,
              color: Colors.yellow.withValues(alpha: .12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.volunteer_activism,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BharatMitra',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Free citizen helper for Android',
                            style: TextStyle(color: Color(0xFFE6FFF5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Tell your situation. The app finds schemes, mandi help, alerts, career options, civic drafts, and next steps.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.28,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoPill(icon: Icons.currency_rupee, label: 'No paid API'),
                    _InfoPill(
                      icon: Icons.lock_outline,
                      label: 'Local demo data',
                    ),
                    _InfoPill(
                      icon: Icons.notifications_active_outlined,
                      label: 'In-app reminders',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: language,
                  iconEnabledColor: Colors.white,
                  dropdownColor: const Color(0xFF1E2D40),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: .13),
                    prefixIcon: const Icon(Icons.language, color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Simple English',
                      child: Text('Simple English'),
                    ),
                    DropdownMenuItem(
                      value: 'Hinglish',
                      child: Text('Hinglish'),
                    ),
                    DropdownMenuItem(
                      value: 'Hindi later',
                      child: Text('Hindi voice later'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onLanguageChanged(value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AskCard extends StatelessWidget {
  const _AskCard({
    required this.controller,
    required this.onRun,
    required this.onListen,
    required this.onSample,
    required this.isListening,
  });

  final TextEditingController controller;
  final VoidCallback onRun;
  final VoidCallback onListen;
  final ValueChanged<String> onSample;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'What help do you need?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isListening
                        ? Colors.red.withValues(alpha: 0.18)
                        : Colors.transparent,
                    boxShadow: isListening
                        ? [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.35),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ]
                        : [],
                  ),
                  child: IconButton.filledTonal(
                    onPressed: onListen,
                    icon: Icon(
                      isListening ? Icons.stop_circle_outlined : Icons.mic_none,
                      color: isListening ? Colors.red : null,
                    ),
                    tooltip: isListening ? 'Stop listening' : 'Speak now',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 4,
              maxLines: 7,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFF1E2D40),
                hintText:
                    'Example: I am a small farmer in Maharashtra with low income...',
                hintStyle: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: onRun,
                icon: const Icon(Icons.auto_awesome),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE85D04),
                  foregroundColor: Colors.white,
                ),
                label: const Text(
                  'Find schemes',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onListen,
                    icon: Icon(
                      isListening
                          ? Icons.hearing_disabled_outlined
                          : Icons.record_voice_over_outlined,
                    ),
                    label: Text(isListening ? 'Listening...' : 'Use voice'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => controller.clear(),
                    icon: const Icon(Icons.backspace_outlined),
                    label: const Text('Clear'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Try a sample',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SampleChip(
                  label: 'Widow support',
                  onTap: () => onSample(
                    'My husband passed away. I live in a village with two children and annual income around 70000.',
                  ),
                ),
                _SampleChip(
                  label: 'Small farmer',
                  onTap: () => onSample(
                    'I am a small farmer in Maharashtra. I own two acres and need income support and crop help.',
                  ),
                ),
                _SampleChip(
                  label: 'Student',
                  onTap: () => onSample(
                    'I am a girl student from a low income family. I need scholarship and hostel support.',
                  ),
                ),
                _SampleChip(
                  label: 'Housing',
                  onTap: () => onSample(
                    'My family lives in a kutcha house in a rural area. We need help for pucca house and LPG.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BharatServicesCard extends StatelessWidget {
  const _BharatServicesCard({
    required this.modules,
    required this.onUsePrompt,
    required this.onModuleTap,
  });

  final List<BharatModule> modules;
  final ValueChanged<String> onUsePrompt;
  final ValueChanged<BharatModule> onModuleTap;

  @override
  Widget build(BuildContext context) {
    final highlighted = modules.where((module) => module.relevant).length;
    final visibleModules = modules.take(5).toList();
    return Card(
      color: const Color(0xFF1E2D40),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dashboard_customize_outlined),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'BharatMitra local services',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                Chip(
                  label: Text(highlighted == 0 ? 'Demo' : '$highlighted fit'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The same free app can guide farmers, students, families, and citizens. These cards use local demo logic now and are ready for real API data later.',
              style: TextStyle(color: const Color(0xFF9CA3AF), height: 1.35),
            ),
            const SizedBox(height: 14),
            for (final module in visibleModules) ...[
              _BharatModuleTile(
                module: module,
                onUsePrompt: onUsePrompt,
                onModuleTap: onModuleTap,
              ),
              if (module != visibleModules.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _BharatModuleTile extends StatelessWidget {
  const _BharatModuleTile({
    required this.module,
    required this.onUsePrompt,
    required this.onModuleTap,
  });

  final BharatModule module;
  final ValueChanged<String> onUsePrompt;
  final ValueChanged<BharatModule> onModuleTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: module.color.withValues(alpha: module.relevant ? .11 : .06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: module.color.withValues(alpha: module.relevant ? .26 : .12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: module.color,
                foregroundColor: Colors.white,
                child: Icon(module.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            module.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (module.relevant)
                          const Icon(Icons.check_circle, size: 19),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      module.category,
                      style: TextStyle(
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            module.summary,
            style: const TextStyle(color: Color(0xFFD1D5DB), height: 1.32),
          ),
          const SizedBox(height: 8),
          Text(
            module.localAdvice,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.route_outlined, size: 18),
                label: Text(module.nextStep),
              ),
              ActionChip(
                avatar: const Icon(Icons.edit_note_outlined, size: 18),
                label: const Text('Use this prompt'),
                onPressed: () => onUsePrompt(module.samplePrompt),
              ),
              ActionChip(
                avatar: const Icon(Icons.api_outlined, size: 18),
                label: const Text('Get live data'),
                backgroundColor: const Color(
                  0xFFE85D04,
                ).withValues(alpha: 0.15),
                onPressed: () {
                  onUsePrompt(module.samplePrompt);
                  onModuleTap(module);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.profile});

  final CitizenProfile profile;

  @override
  Widget build(BuildContext context) {
    final chips = profile.summaryChips;
    return Card(
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFFE85D04), width: 5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_search_outlined),
                  SizedBox(width: 10),
                  Text(
                    'Understood profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (chips.isEmpty)
                const Text(
                  'Not enough details yet. Add income, state, work, family, or documents.',
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final chip in chips) Chip(label: Text(chip))],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.matches, required this.notices});

  final List<SchemeMatch> matches;
  final List<AppNotice> notices;

  @override
  Widget build(BuildContext context) {
    final docs = <String>{};
    for (final match in matches.take(3)) {
      docs.addAll(match.scheme.documents);
    }

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Matches',
            value: matches.length.toString(),
            icon: Icons.fact_check_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Docs',
            value: docs.length.toString(),
            icon: Icons.folder_copy_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Alerts',
            value: notices.where((notice) => !notice.read).length.toString(),
            icon: Icons.notifications_none,
          ),
        ),
      ],
    );
  }
}

class _SchemeCard extends StatelessWidget {
  const _SchemeCard({
    required this.match,
    required this.saved,
    required this.onSave,
    required this.onOpenOfficial,
  });

  final SchemeMatch match;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onOpenOfficial;

  @override
  Widget build(BuildContext context) {
    final scheme = match.scheme;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2D40),
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: const Color(0xFFE85D04), width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: scheme.color.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(scheme.icon, color: scheme.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scheme.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        scheme.category,
                        style: TextStyle(
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    _ScoreBadge(score: match.score),
                    IconButton(
                      onPressed: onSave,
                      icon: Icon(
                        saved ? Icons.bookmark : Icons.bookmark_border,
                      ),
                      tooltip: saved ? 'Saved' : 'Save scheme',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: Text(
                scheme.benefit,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: Color(0xFF6EE7B7),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(match.why, style: const TextStyle(height: 1.35)),
            const SizedBox(height: 14),
            const Text(
              'Documents to keep ready',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final doc in scheme.documents)
                  Chip(
                    avatar: const Icon(Icons.description_outlined, size: 18),
                    label: Text(doc),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _showNextSteps(context, match),
                    icon: const Icon(Icons.directions_walk),
                    label: const Text('Steps'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onOpenOfficial,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Official'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNextSteps(BuildContext context, SchemeMatch match) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                match.scheme.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < match.scheme.steps.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(match.scheme.steps[i]),
                ),
              const SizedBox(height: 6),
              const Text(
                'Prototype note: confirm details on myScheme, official portal, or nearest CSC before applying.',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Simple tile for schemes not matched by profile (used in Schemes tab)
class _SchemeListTile extends StatelessWidget {
  const _SchemeListTile({
    required this.scheme,
    required this.saved,
    required this.onSave,
    required this.onOpen,
  });
  final WelfareScheme scheme;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2D40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(scheme.icon, color: scheme.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scheme.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  scheme.category,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              saved ? Icons.bookmark : Icons.bookmark_border,
              color: saved ? const Color(0xFFE85D04) : const Color(0xFF9CA3AF),
            ),
            onPressed: onSave,
          ),
          IconButton(
            icon: const Icon(
              Icons.open_in_new,
              color: Color(0xFF9CA3AF),
              size: 18,
            ),
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice, required this.onDone});

  final AppNotice notice;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notice.read ? const Color(0xFF1A2535) : const Color(0xFF1E2D40),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: notice.read
                  ? const Color(0xFF374151)
                  : const Color(0xFF156B4F),
              child: Icon(
                notice.read ? Icons.done : Icons.notifications_active_outlined,
                color: notice.read ? const Color(0xFF9CA3AF) : Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(notice.body, style: const TextStyle(height: 1.35)),
                ],
              ),
            ),
            if (!notice.read)
              TextButton(onPressed: onDone, child: const Text('Done')),
          ],
        ),
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.savedCount,
    required this.docs,
    required this.onSpeak,
    required this.onShare,
    required this.onPdf,
  });

  final int savedCount;
  final List<String> docs;
  final VoidCallback onSpeak;
  final VoidCallback onShare;
  final VoidCallback onPdf;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assistant actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Speak results, save a checklist, or share with family/CSC. Everything works free on-device.',
              style: TextStyle(color: const Color(0xFF9CA3AF), height: 1.35),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onSpeak,
                  icon: const Icon(Icons.volume_up_outlined),
                  label: const Text('Read aloud'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('Share text'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Export PDF'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Saved schemes: $savedCount • Checklist docs: ${docs.length}'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DigiLocker shared mock auth bottom sheet
// ─────────────────────────────────────────────

Future<void> _showDigiLockerSheet(
  BuildContext context, {
  required VoidCallback onConnected,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E2D40),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _DigiLockerAuthSheet(onConnected: onConnected),
  );
}

class _DigiLockerAuthSheet extends StatefulWidget {
  const _DigiLockerAuthSheet({required this.onConnected});
  final VoidCallback onConnected;

  @override
  State<_DigiLockerAuthSheet> createState() => _DigiLockerAuthSheetState();
}

class _DigiLockerAuthSheetState extends State<_DigiLockerAuthSheet> {
  final _aadhaarCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;

  @override
  void dispose() {
    _aadhaarCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _sendOtp() {
    setState(() => _otpSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP sent to registered mobile')),
    );
  }

  Future<void> _verify() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('digilocker_connected', true);
    widget.onConnected();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.folder_special,
                color: Color(0xFF6EE7B7),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'DigiLocker Login',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _aadhaarCtrl,
            keyboardType: TextInputType.number,
            obscureText: false,
            maxLength: 12,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0D1B2A),
              hintText: 'Aadhaar number (12 digits)',
              hintStyle: const TextStyle(color: Color(0xFF6B7280)),
              counterStyle: const TextStyle(color: Color(0xFF6B7280)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF374151),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Send OTP'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _otpCtrl,
            enabled: _otpSent,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0D1B2A),
              hintText: 'Enter 6-digit OTP',
              hintStyle: const TextStyle(color: Color(0xFF6B7280)),
              counterStyle: const TextStyle(color: Color(0xFF6B7280)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _otpSent ? _verify : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6EE7B7),
                foregroundColor: const Color(0xFF0D1B2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Verify & Connect',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Use DigiLocker App instead',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DigiLocker Card (main app)
// ─────────────────────────────────────────────

class _DigiLockerCard extends StatefulWidget {
  const _DigiLockerCard();

  @override
  State<_DigiLockerCard> createState() => _DigiLockerCardState();
}

class _DigiLockerCardState extends State<_DigiLockerCard> {
  bool _connected = false;
  bool _loading = true;

  static const _documents = [
    (icon: '📄', name: 'Aadhaar Card', detail: 'XXXX XXXX 8842'),
    (icon: '📋', name: 'Ration Card', detail: 'AP/2024/XXXXXX'),
    (icon: '💰', name: 'Income Certificate', detail: 'Issued: Jan 2025'),
    (icon: '🏠', name: 'Land Records', detail: 'Survey #XXXX'),
  ];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _connected = prefs.getBool('digilocker_connected') ?? false;
        _loading = false;
      });
    }
  }

  Future<void> _disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('digilocker_connected', false);
    setState(() => _connected = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF6EE7B7)),
        ),
      );
    }

    if (!_connected) {
      return Card(
        color: const Color(0xFF1E2D40),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.folder_special,
                    color: Color(0xFF6EE7B7),
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'DigiLocker Not Connected',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect to access Aadhaar, Ration Card, Income Certificate',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showDigiLockerSheet(
                    context,
                    onConnected: () {
                      setState(() => _connected = true);
                    },
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6EE7B7),
                    foregroundColor: const Color(0xFF0D1B2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.folder_special),
                  label: const Text(
                    'Connect Now',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Connected state
    return Card(
      color: const Color(0xFF1E2D40),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF156B4F),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
                SizedBox(width: 8),
                Text(
                  'DigiLocker Connected ✓',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                for (final doc in _documents)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B2A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF374151)),
                    ),
                    child: Row(
                      children: [
                        Text(doc.icon, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                doc.detail,
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ActionChip(
                          backgroundColor: const Color(0xFF1E2D40),
                          side: const BorderSide(color: Color(0xFF6EE7B7)),
                          label: const Text(
                            'View',
                            style: TextStyle(
                              color: Color(0xFF6EE7B7),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Opening ${doc.name} in DigiLocker...',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                TextButton(
                  onPressed: _disconnect,
                  child: const Text(
                    'Disconnect',
                    style: TextStyle(color: Color(0xFF9CA3AF)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackendAiCard extends StatelessWidget {
  const _BackendAiCard({
    required this.controller,
    required this.busy,
    required this.ok,
    required this.status,
    required this.answer,
    required this.onCheck,
    required this.onConsumer,
    required this.onAuto,
  });

  final TextEditingController controller;
  final bool busy;
  final bool ok;
  final String status;
  final String? answer;
  final VoidCallback onCheck;
  final VoidCallback onConsumer;
  final VoidCallback onAuto;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ok ? Icons.cloud_done_outlined : Icons.cloud_queue_outlined,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Backend AI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                if (busy)
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Fast consumer replies use Google Gemma. Auto tasks use NVIDIA-hosted Mistral. If backend is off, local app still works.',
              style: TextStyle(color: const Color(0xFF9CA3AF), height: 1.35),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                hintText: 'http://10.0.2.2:8000',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: ok
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status,
                    style: const TextStyle(color: Color(0xFFD1D5DB)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : onCheck,
                  icon: const Icon(Icons.health_and_safety_outlined),
                  label: const Text('Check'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: busy ? null : onConsumer,
                        icon: const Icon(Icons.flash_on_outlined),
                        label: const Text('Ask AI (Fast)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: busy ? null : onAuto,
                        icon: const Icon(
                          Icons.precision_manufacturing_outlined,
                        ),
                        label: const Text('Ask AI (Smart)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (answer != null && answer!.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Color(0xFF111827)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 4, color: const Color(0xFF76ABDF)),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            answer!,
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SavedSchemesCard extends StatelessWidget {
  const _SavedSchemesCard({required this.savedSchemes});

  final Set<String> savedSchemes;

  @override
  Widget build(BuildContext context) {
    final saved = savedSchemes.toList()..sort();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bookmarks_outlined),
                SizedBox(width: 10),
                Text(
                  'Saved schemes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final name in saved) Chip(label: Text(name))],
            ),
          ],
        ),
      ),
    );
  }
}

class _FreeStackNote extends StatelessWidget {
  const _FreeStackNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Free-only MVP stack',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'This build uses local demo scheme data, rule-based matching, BharatMitra service cards, Android speech, TTS, PDF export, sharing, saved schemes, and official myScheme search links. No paid model/API is required.',
            style: TextStyle(height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(color: const Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2D40),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF6EE7B7),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(label, style: const TextStyle(color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleChip extends StatelessWidget {
  const _SampleChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      backgroundColor: const Color(0xFF1E2D40),
      side: const BorderSide(color: Color(0xFFE85D04)),
      shape: const StadiumBorder(),
      avatar: const Icon(
        Icons.touch_app_outlined,
        size: 18,
        color: Color(0xFFE85D04),
      ),
      label: Text(label),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
      onPressed: onTap,
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF156B4F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$score%',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class BharatModuleAdvisor {
  static List<BharatModule> modulesFor(String input) {
    final text = input.toLowerCase();
    final modules = <BharatModule>[
      _mandiModule(text),
      _aqiModule(text),
      _floodModule(text),
      _careerModule(text),
      _civicModule(text),
    ];
    return [
      ...modules.where((module) => module.relevant),
      ...modules.where((module) => !module.relevant),
    ];
  }

  static BharatModule _mandiModule(String text) {
    final relevant = _hasAny(text, [
      'farmer',
      'kisan',
      'crop',
      'mandi',
      'sell',
      'price',
      'market',
      'agriculture',
    ]);
    final crop = _cropFor(text);
    final place = _placeFor(text);
    return BharatModule(
      title: 'Mandi price advisor',
      category: 'Farmer income',
      summary:
          'Demo helper for comparing nearby mandi rates before selling $crop in $place.',
      localAdvice: relevant
          ? 'Local rule: ask two nearby mandis, check transport cost, and sell in parts if prices are moving fast.'
          : 'Type your crop and district to get a sell/hold checklist for the nearest market.',
      nextStep: 'Needs AGMARKNET/data.gov.in',
      samplePrompt:
          'I grow onion in Nashik. Should I sell today or wait for better mandi price?',
      icon: Icons.storefront_outlined,
      color: const Color(0xFF3F7F2B),
      relevant: relevant,
    );
  }

  static BharatModule _aqiModule(String text) {
    final relevant = _hasAny(text, [
      'aqi',
      'pollution',
      'smoke',
      'dust',
      'outdoor',
      'school run',
      'air quality',
    ]);
    final aqi = _aqiValue(text);
    final band = aqi == null
        ? 'your local AQI'
        : aqi > 200
        ? 'very poor AQI $aqi'
        : aqi > 100
        ? 'moderate to poor AQI $aqi'
        : 'acceptable AQI $aqi';
    return BharatModule(
      title: 'AQI activity planner',
      category: 'Daily safety',
      summary:
          'Turns $band into simple activity guidance for school, work, travel, and outdoor chores.',
      localAdvice: relevant
          ? 'Local rule: keep heavy outdoor work for cleaner hours and prefer short trips when air is poor.'
          : 'Type AQI or pollution conditions to get a plain-language activity plan.',
      nextStep: 'Needs CPCB/OpenAQ feed',
      samplePrompt:
          'AQI is 220 near my area. Plan school run, outdoor work, and evening walk.',
      icon: Icons.air_outlined,
      color: const Color(0xFF007C91),
      relevant: relevant,
    );
  }

  static BharatModule _floodModule(String text) {
    final relevant = _hasAny(text, [
      'flood',
      'rain',
      'river',
      'waterlogging',
      'cyclone',
      'landslide',
      'dam',
    ]);
    return BharatModule(
      title: 'Flood and disaster alert',
      category: 'Emergency readiness',
      summary:
          'Demo checklist for rain, flood, cyclone, and waterlogging risk using official-alert style steps.',
      localAdvice: relevant
          ? 'Local rule: charge phone, keep documents in plastic, avoid flooded roads, and follow district alerts.'
          : 'Type your district and risk, like heavy rain or river level, to get a family checklist.',
      nextStep: 'Needs IMD/CWC/NDMA data',
      samplePrompt:
          'Heavy rain warning in my district. Make a flood safety checklist for my family.',
      icon: Icons.flood_outlined,
      color: const Color(0xFF1D5FA7),
      relevant: relevant,
    );
  }

  static BharatModule _careerModule(String text) {
    final relevant = _hasAny(text, [
      'student',
      'career',
      'job',
      'skill',
      'college',
      'scholarship',
      'class ',
      'marks',
    ]);
    final classMatch = RegExp(r'class\s*(\d{1,2})').firstMatch(text);
    final stage = classMatch == null
        ? 'your class/skill level'
        : 'class ${classMatch.group(1)}';
    return BharatModule(
      title: 'Student career guide',
      category: 'Education and jobs',
      summary:
          'Maps $stage, interests, budget, and location to scholarships, skills, and next study options.',
      localAdvice: relevant
          ? 'Local rule: first secure scholarships, then compare nearby low-cost courses and apprenticeships.'
          : 'Type class, marks, interests, and family budget to get a practical path.',
      nextStep: 'Needs NSP/Skill India data',
      samplePrompt:
          'I am in class 12 with low family income. Suggest scholarships and career options.',
      icon: Icons.menu_book_outlined,
      color: const Color(0xFF6D5BD0),
      relevant: relevant,
    );
  }

  static BharatModule _civicModule(String text) {
    final relevant = _hasAny(text, [
      'pothole',
      'garbage',
      'drain',
      'streetlight',
      'water supply',
      'road',
      'sewage',
      'complaint',
    ]);
    final issue = _civicIssueFor(text);
    return BharatModule(
      title: 'Civic report helper',
      category: 'Local governance',
      summary:
          'Drafts a short complaint for $issue with location, photo reminder, and escalation checklist.',
      localAdvice: relevant
          ? 'Local rule: mention landmark, ward, date, risk, and attach one clear photo if available.'
          : 'Type the civic issue and location to create a ready-to-send complaint draft.',
      nextStep: 'Needs city/grievance API',
      samplePrompt:
          'There is garbage and blocked drain near my lane. Draft a municipal complaint.',
      icon: Icons.report_problem_outlined,
      color: const Color(0xFFC2611A),
      relevant: relevant,
    );
  }

  static bool _hasAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  static String _cropFor(String text) {
    const crops = {
      'onion': 'onion',
      'wheat': 'wheat',
      'rice': 'rice',
      'paddy': 'rice/paddy',
      'cotton': 'cotton',
      'soybean': 'soybean',
      'tomato': 'tomato',
      'potato': 'potato',
      'maize': 'maize',
      'sugarcane': 'sugarcane',
      'tur': 'tur dal',
      'chana': 'chana',
    };
    for (final entry in crops.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return 'your crop';
  }

  static String _placeFor(String text) {
    const places = [
      'nashik',
      'pune',
      'nagpur',
      'mumbai',
      'patna',
      'lucknow',
      'jaipur',
      'surat',
      'bengaluru',
      'chennai',
      'bhopal',
      'indore',
      'kolkata',
      'hyderabad',
      'bhubaneswar',
    ];
    for (final place in places) {
      if (text.contains(place)) return place;
    }
    return 'your district';
  }

  static int? _aqiValue(String text) {
    final match = RegExp(r'\baqi\s*(\d{2,3})').firstMatch(text);
    return int.tryParse(match?.group(1) ?? '');
  }

  static String _civicIssueFor(String text) {
    const issues = [
      'pothole',
      'garbage',
      'blocked drain',
      'streetlight',
      'water supply',
      'sewage',
      'road damage',
    ];
    for (final issue in issues) {
      if (text.contains(issue)) return issue;
    }
    return 'a local issue';
  }
}

class BharatModule {
  const BharatModule({
    required this.title,
    required this.category,
    required this.summary,
    required this.localAdvice,
    required this.nextStep,
    required this.samplePrompt,
    required this.icon,
    required this.color,
    required this.relevant,
  });

  final String title;
  final String category;
  final String summary;
  final String localAdvice;
  final String nextStep;
  final String samplePrompt;
  final IconData icon;
  final Color color;
  final bool relevant;
}

class SchemeAssistant {
  CitizenProfile extractProfile(String input) {
    final text = input.toLowerCase();
    final income = _extractIncome(text);

    return CitizenProfile(
      rawText: input,
      state: _extractState(text),
      rural: _hasAny(text, ['village', 'rural', 'gaon', 'gram']),
      lowIncome: income != null
          ? income <= 120000
          : _hasAny(text, ['low income', 'poor', 'garib', 'bpl']),
      annualIncome: income,
      farmer: _hasAny(text, [
        'farmer',
        'kisan',
        'crop',
        'land',
        'acre',
        'agriculture',
      ]),
      widow: _hasAny(text, [
        'widow',
        'husband passed',
        'pati nahi',
        'pati died',
        'single mother',
      ]),
      student: _hasAny(text, [
        'student',
        'school',
        'college',
        'scholarship',
        'hostel',
      ]),
      girlOrWoman: _hasAny(text, [
        'woman',
        'female',
        'girl',
        'daughter',
        'mother',
        'widow',
        'mahila',
      ]),
      disability: _hasAny(text, [
        'disabled',
        'disability',
        'divyang',
        'handicap',
      ]),
      housingNeed: _hasAny(text, [
        'kutcha',
        'house',
        'housing',
        'pucca',
        'home',
      ]),
      lpgNeed: _hasAny(text, ['lpg', 'cylinder', 'gas', 'chulha', 'smoke']),
      childrenCount: _extractChildren(text),
    );
  }

  List<SchemeMatch> findSchemes(CitizenProfile profile, String input) {
    final text = input.toLowerCase();
    final matches = <SchemeMatch>[];

    for (final scheme in schemes) {
      var score = 12;
      final reasons = <String>[];

      for (final keyword in scheme.keywords) {
        if (text.contains(keyword)) score += 8;
      }

      void add(bool condition, int points, String reason) {
        if (condition) {
          score += points;
          reasons.add(reason);
        }
      }

      add(
        profile.lowIncome && scheme.tags.contains(SchemeTag.lowIncome),
        18,
        'low-income household',
      );
      add(
        profile.rural && scheme.tags.contains(SchemeTag.rural),
        12,
        'rural residence',
      );
      add(
        profile.farmer && scheme.tags.contains(SchemeTag.farmer),
        26,
        'farmer/agriculture need',
      );
      add(
        profile.widow && scheme.tags.contains(SchemeTag.widow),
        30,
        'widow support need',
      );
      add(
        profile.student && scheme.tags.contains(SchemeTag.student),
        26,
        'student education need',
      );
      add(
        profile.girlOrWoman && scheme.tags.contains(SchemeTag.women),
        16,
        'women/girl beneficiary',
      );
      add(
        profile.disability && scheme.tags.contains(SchemeTag.disability),
        28,
        'disability support need',
      );
      add(
        profile.housingNeed && scheme.tags.contains(SchemeTag.housing),
        26,
        'housing support need',
      );
      add(
        profile.lpgNeed && scheme.tags.contains(SchemeTag.lpg),
        24,
        'clean cooking/LPG need',
      );

      if (score >= 26) {
        matches.add(
          SchemeMatch(
            scheme: scheme,
            score: math.min(score, 98),
            why: reasons.isEmpty
                ? 'This may be relevant based on your message. Verify eligibility on the official portal.'
                : 'Matched because you mentioned ${_joinReasons(reasons)}.',
          ),
        );
      }
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches.take(6).toList();
  }

  List<AppNotice> createNotices(
    CitizenProfile profile,
    List<SchemeMatch> matches,
  ) {
    if (matches.isEmpty) return [];

    final first = matches.first.scheme;
    final docs = <String>{};
    for (final match in matches.take(3)) {
      docs.addAll(match.scheme.documents);
    }

    return [
      AppNotice(
        title: 'Check ${first.name}',
        body:
            'This is your strongest match. Read eligibility once and confirm with CSC or official portal.',
      ),
      AppNotice(
        title: 'Keep ${math.min(docs.length, 5)} documents ready',
        body: docs.take(5).join(', '),
      ),
      if (profile.annualIncome == null)
        const AppNotice(
          title: 'Add income details',
          body:
              'Adding annual income improves matching for pensions, scholarships, and housing schemes.',
        ),
      const AppNotice(
        title: 'Next step reminder',
        body:
            'Visit nearest CSC or official scheme portal with documents. Do not pay unofficial agents.',
      ),
    ];
  }

  int? _extractIncome(String text) {
    final match = RegExp(
      r'(income|annual|rs\.?|around|about)?\s*(\d{4,7})',
    ).allMatches(text).lastOrNull;
    if (match == null) return null;
    final value = int.tryParse(match.group(2) ?? '');
    if (value == null || value < 1000) return null;
    return value;
  }

  int? _extractChildren(String text) {
    if (!_hasAny(text, ['child', 'children', 'kids', 'bachche'])) return null;
    final match = RegExp(
      r'(\d+)\s*(child|children|kids|bachche)',
    ).firstMatch(text);
    return int.tryParse(match?.group(1) ?? '');
  }

  String? _extractState(String text) {
    const states = [
      'maharashtra',
      'uttar pradesh',
      'bihar',
      'karnataka',
      'tamil nadu',
      'rajasthan',
      'gujarat',
      'madhya pradesh',
      'kerala',
      'odisha',
      'west bengal',
      'telangana',
      'andhra pradesh',
    ];
    for (final state in states) {
      if (text.contains(state)) return state;
    }
    return null;
  }

  bool _hasAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  String _joinReasons(List<String> reasons) {
    if (reasons.length == 1) return reasons.first;
    return '${reasons.take(reasons.length - 1).join(', ')} and ${reasons.last}';
  }
}

class CitizenProfile {
  const CitizenProfile({
    required this.rawText,
    required this.rural,
    required this.lowIncome,
    required this.farmer,
    required this.widow,
    required this.student,
    required this.girlOrWoman,
    required this.disability,
    required this.housingNeed,
    required this.lpgNeed,
    this.state,
    this.annualIncome,
    this.childrenCount,
  });

  final String rawText;
  final String? state;
  final bool rural;
  final bool lowIncome;
  final int? annualIncome;
  final bool farmer;
  final bool widow;
  final bool student;
  final bool girlOrWoman;
  final bool disability;
  final bool housingNeed;
  final bool lpgNeed;
  final int? childrenCount;

  List<String> get summaryChips {
    return [
      if (state != null) 'State: $state',
      if (rural) 'Rural',
      if (lowIncome) 'Low income',
      if (annualIncome != null) 'Income: Rs. $annualIncome/year',
      if (farmer) 'Farmer',
      if (widow) 'Widow',
      if (student) 'Student',
      if (girlOrWoman) 'Women/girl',
      if (disability) 'Disability',
      if (housingNeed) 'Housing need',
      if (lpgNeed) 'LPG need',
      if (childrenCount != null) '$childrenCount children',
    ];
  }
}

class SchemeMatch {
  const SchemeMatch({
    required this.scheme,
    required this.score,
    required this.why,
  });

  final WelfareScheme scheme;
  final int score;
  final String why;
}

class AppNotice {
  const AppNotice({required this.title, required this.body, this.read = false});

  final String title;
  final String body;
  final bool read;

  AppNotice copyWith({bool? read}) {
    return AppNotice(title: title, body: body, read: read ?? this.read);
  }
}

class WelfareScheme {
  const WelfareScheme({
    required this.name,
    required this.category,
    required this.benefit,
    required this.documents,
    required this.steps,
    required this.tags,
    required this.keywords,
    required this.icon,
    required this.color,
  });

  final String name;
  final String category;
  final String benefit;
  final List<String> documents;
  final List<String> steps;
  final Set<SchemeTag> tags;
  final List<String> keywords;
  final IconData icon;
  final Color color;
}

enum SchemeTag {
  lowIncome,
  rural,
  farmer,
  widow,
  student,
  women,
  disability,
  housing,
  lpg,
}

const schemes = [
  WelfareScheme(
    name: 'PM-KISAN',
    category: 'Farmer income support',
    benefit:
        'Eligible farmer families may receive Rs. 6000 per year in installments.',
    documents: ['Aadhaar', 'Bank account', 'Land record', 'Mobile number'],
    steps: [
      'Confirm land and farmer eligibility on official portal or CSC.',
      'Keep Aadhaar, bank account, and land record ready.',
      'Apply through CSC, state agriculture office, or PM-KISAN portal.',
    ],
    tags: {SchemeTag.farmer, SchemeTag.rural, SchemeTag.lowIncome},
    keywords: ['farmer', 'kisan', 'crop', 'land', 'acre', 'agriculture'],
    icon: Icons.agriculture_outlined,
    color: Color(0xFF4B8B2B),
  ),
  WelfareScheme(
    name: 'Widow Pension Support',
    category: 'Social security',
    benefit:
        'State pension support may be available for eligible widows from low-income households.',
    documents: [
      'Aadhaar',
      'Death certificate',
      'Income certificate',
      'Bank passbook',
    ],
    steps: [
      'Check your state widow pension rules on myScheme or state portal.',
      'Collect death certificate, income certificate, Aadhaar, and bank details.',
      'Submit through CSC, panchayat, or state social welfare portal.',
    ],
    tags: {
      SchemeTag.widow,
      SchemeTag.women,
      SchemeTag.lowIncome,
      SchemeTag.rural,
    },
    keywords: ['widow', 'husband', 'single mother', 'pension', 'pati'],
    icon: Icons.elderly_woman_outlined,
    color: Color(0xFF9B5BC8),
  ),
  WelfareScheme(
    name: 'National Scholarship Portal Schemes',
    category: 'Education support',
    benefit:
        'Eligible students can apply for central and state scholarships from one portal.',
    documents: [
      'Aadhaar',
      'Income certificate',
      'Marksheets',
      'Bank account',
      'Caste certificate if applicable',
    ],
    steps: [
      'Create or login to National Scholarship Portal.',
      'Choose schemes based on class, income, category, and state.',
      'Upload documents and track application status.',
    ],
    tags: {SchemeTag.student, SchemeTag.lowIncome, SchemeTag.women},
    keywords: [
      'student',
      'scholarship',
      'school',
      'college',
      'hostel',
      'marksheet',
    ],
    icon: Icons.school_outlined,
    color: Color(0xFF2C6DCB),
  ),
  WelfareScheme(
    name: 'PMAY-Gramin / Housing Assistance',
    category: 'Rural housing',
    benefit:
        'Eligible rural families may receive assistance for a pucca house.',
    documents: [
      'Aadhaar',
      'Ration card',
      'Income proof',
      'Land/house status proof',
    ],
    steps: [
      'Confirm if your household appears in local housing beneficiary list.',
      'Keep ration card, Aadhaar, and house status proof ready.',
      'Contact gram panchayat, block office, or CSC.',
    ],
    tags: {SchemeTag.housing, SchemeTag.rural, SchemeTag.lowIncome},
    keywords: ['house', 'housing', 'kutcha', 'pucca', 'home', 'rural'],
    icon: Icons.home_work_outlined,
    color: Color(0xFFB76E22),
  ),
  WelfareScheme(
    name: 'PM Ujjwala Yojana',
    category: 'Clean cooking support',
    benefit:
        'Eligible households may receive LPG connection support for clean cooking.',
    documents: ['Aadhaar', 'Ration card', 'Bank account', 'Address proof'],
    steps: [
      'Check household eligibility with LPG distributor or official portal.',
      'Keep Aadhaar, ration card, bank account, and address proof ready.',
      'Apply through nearby LPG distributor or CSC.',
    ],
    tags: {
      SchemeTag.lpg,
      SchemeTag.women,
      SchemeTag.lowIncome,
      SchemeTag.rural,
    },
    keywords: ['lpg', 'gas', 'cylinder', 'smoke', 'chulha', 'cooking'],
    icon: Icons.local_fire_department_outlined,
    color: Color(0xFFE07A24),
  ),
  WelfareScheme(
    name: 'Divyangjan Assistance Schemes',
    category: 'Disability support',
    benefit:
        'Eligible persons with disabilities may get assistive devices, pension, or education support.',
    documents: [
      'Aadhaar',
      'Disability certificate',
      'Income certificate',
      'Bank account',
    ],
    steps: [
      'Confirm disability certificate and percentage requirements.',
      'Search central/state disability schemes on myScheme.',
      'Apply through district social welfare office, CSC, or official portal.',
    ],
    tags: {SchemeTag.disability, SchemeTag.lowIncome, SchemeTag.student},
    keywords: ['disabled', 'disability', 'divyang', 'handicap', 'assistive'],
    icon: Icons.accessible_forward_outlined,
    color: Color(0xFF167C8C),
  ),
  WelfareScheme(
    name: 'MGNREGA Job Card Support',
    category: 'Rural wage employment',
    benefit:
        'Rural households can seek wage employment and job card support through gram panchayat systems.',
    documents: ['Aadhaar', 'Ration card', 'Bank account', 'Address proof'],
    steps: [
      'Ask gram panchayat or CSC about job card registration.',
      'Keep Aadhaar, household details, bank account, and address proof ready.',
      'Track work demand and payment status through official channels.',
    ],
    tags: {SchemeTag.rural, SchemeTag.lowIncome},
    keywords: [
      'job',
      'work',
      'labour',
      'wage',
      'nrega',
      'mgnrega',
      'daily wage',
    ],
    icon: Icons.construction_outlined,
    color: Color(0xFF795548),
  ),
  WelfareScheme(
    name: 'Sukanya Samriddhi Yojana',
    category: 'Girl child savings',
    benefit:
        'Families with a girl child can open a long-term savings account with government-backed benefits.',
    documents: ['Birth certificate', 'Aadhaar', 'Guardian ID', 'Address proof'],
    steps: [
      'Confirm girl child age eligibility at post office or bank.',
      'Carry birth certificate, guardian ID, and address proof.',
      'Open account at participating post office or bank branch.',
    ],
    tags: {SchemeTag.women, SchemeTag.student, SchemeTag.lowIncome},
    keywords: ['girl', 'daughter', 'sukanya', 'child', 'savings'],
    icon: Icons.savings_outlined,
    color: Color(0xFFD05B8C),
  ),
  WelfareScheme(
    name: 'PM Vishwakarma',
    category: 'Artisan and skill support',
    benefit:
        'Traditional artisans may get skill training, toolkit support, and credit linkage.',
    documents: [
      'Aadhaar',
      'Mobile number',
      'Bank account',
      'Occupation proof if available',
    ],
    steps: [
      'Check artisan trade eligibility on official PM Vishwakarma channels.',
      'Keep Aadhaar-linked mobile and bank details ready.',
      'Apply through CSC or official portal if eligible.',
    ],
    tags: {SchemeTag.lowIncome},
    keywords: [
      'artisan',
      'tailor',
      'carpenter',
      'blacksmith',
      'potter',
      'vishwakarma',
      'skill',
    ],
    icon: Icons.handyman_outlined,
    color: Color(0xFF6D6ACF),
  ),
  WelfareScheme(
    name: 'NRLM Self Help Group Support',
    category: 'Women livelihood',
    benefit:
        'Rural women may join self-help groups for savings, credit, training, and livelihood support.',
    documents: ['Aadhaar', 'Bank account', 'Address proof', 'Mobile number'],
    steps: [
      'Ask gram panchayat or block mission office about SHG groups nearby.',
      'Join or form a self-help group with required documents.',
      'Use SHG channel for training, credit, and livelihood schemes.',
    ],
    tags: {SchemeTag.women, SchemeTag.rural, SchemeTag.lowIncome},
    keywords: [
      'women group',
      'self help',
      'shg',
      'livelihood',
      'loan',
      'business',
    ],
    icon: Icons.groups_2_outlined,
    color: Color(0xFF00897B),
  ),
  WelfareScheme(
    name: 'Old Age Pension Support',
    category: 'Senior citizen social security',
    benefit:
        'Eligible low-income senior citizens may receive monthly pension support through state/central schemes.',
    documents: ['Aadhaar', 'Age proof', 'Income certificate', 'Bank passbook'],
    steps: [
      'Confirm age and income rules for your state pension scheme.',
      'Keep age proof, income certificate, Aadhaar, and bank details ready.',
      'Apply through CSC, panchayat, or state social welfare portal.',
    ],
    tags: {SchemeTag.lowIncome, SchemeTag.rural},
    keywords: ['old age', 'senior', 'elderly', 'pension', 'aged'],
    icon: Icons.elderly_outlined,
    color: Color(0xFF607D8B),
  ),
];
