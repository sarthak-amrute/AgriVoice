// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:agrivoice/app_translations.dart';
import 'package:agrivoice/chat_screen.dart';

// ─────────────────────────────────────────────────────────────
//  VOICE SERVICE
//  • STT listens in the farmer's selected app language
//  • TTS speaks in same language
// ─────────────────────────────────────────────────────────────

enum _VoiceState { idle, speaking, listening }

class _VoiceService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  final ValueNotifier<_VoiceState> state = ValueNotifier(_VoiceState.idle);
  final ValueNotifier<String> transcript = ValueNotifier('');

  bool _sttAvailable = false;
  bool get sttAvailable => _sttAvailable;

  Future<void> init() async {
    await _tts.setSharedInstance(true);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (state.value == _VoiceState.speaking) state.value = _VoiceState.idle;
    });
    try {
      _sttAvailable = await _stt.initialize(
        onError: (e) {
          debugPrint('STT error: $e');
          state.value = _VoiceState.idle;
        },
        onStatus: (s) {
          debugPrint('STT status: $s');
          if (s == 'done' || s == 'notListening') {
            state.value = _VoiceState.idle;
          }
        },
      );
      debugPrint('STT available: $_sttAvailable');
    } catch (e) {
      debugPrint('STT init error: $e');
      _sttAvailable = false;
    }
  }

  /// Speak advisory text using TTS
  Future<void> speak(String text, String ttsLocale) async {
    if (state.value == _VoiceState.speaking) {
      await _tts.stop();
      state.value = _VoiceState.idle;
      return;
    }
    await stopListening();
    await _tts.setLanguage(ttsLocale);
    state.value = _VoiceState.speaking;
    await _tts.speak(text);
  }

  /// Start STT using the farmer's selected language locale
  Future<void> startListening(String localeId) async {
    if (!_sttAvailable) {
      debugPrint('STT not available');
      return;
    }
    transcript.value = '';
    state.value = _VoiceState.listening;
    try {
      await _stt.listen(
        onResult: (r) {
          transcript.value = r.recognizedWords;
          debugPrint('STT result: ${r.recognizedWords}');
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        localeId: localeId, // ← farmer's selected language
        cancelOnError: false,
        partialResults: true,
      );
    } catch (e) {
      debugPrint('STT listen error: $e');
      state.value = _VoiceState.idle;
    }
  }

  Future<void> stopListening() async {
    try {
      await _stt.stop();
    } catch (_) {}
    if (state.value == _VoiceState.listening) state.value = _VoiceState.idle;
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
    state.value = _VoiceState.idle;
  }

  Future<void> dispose() async {
    await stopSpeaking();
    await stopListening();
  }
}

// ─────────────────────────────────────────────────────────────
//  ADVISORY ENGINE  — multilingual advisory text
// ─────────────────────────────────────────────────────────────

class _AdvisoryEngine {
  static const Map<String, String> _advisories = {
    'en':
        'Tomato Early Blight detected with 94 percent confidence. '
        'Prune and remove infected lower leaves immediately. '
        'Apply copper-based fungicide early in the morning. '
        'Space plants 24 inches apart for better air circulation.',
    'hi':
        'टमाटर में अर्ली ब्लाइट 94 प्रतिशत आत्मविश्वास से पहचानी गई। '
        'संक्रमित निचली पत्तियाँ तुरंत काटें और हटाएँ। '
        'सुबह जल्दी कॉपर-आधारित फफूंदनाशक लगाएँ। '
        'पौधों के बीच 24 इंच की दूरी रखें।',
    'mr':
        'टोमॅटोवर अर्ली ब्लाइट 94 टक्के आत्मविश्वासाने ओळखली. '
        'संक्रमित खालची पाने लगेच काढून टाका. '
        'सकाळी लवकर तांबे-आधारित बुरशीनाशक फवारा. '
        'झाडांमध्ये 24 इंच अंतर ठेवा.',
    'bn':
        'টমেটোতে আর্লি ব্লাইট ৯৪% নিশ্চিততায় শনাক্ত হয়েছে। '
        'সংক্রমিত নিচের পাতা সঙ্গে সঙ্গে কেটে ফেলুন। '
        'সকালে তামা-ভিত্তিক ছত্রাকনাশক প্রয়োগ করুন।',
    'te':
        'టమాటోలో ఎర్లీ బ్లైట్ 94% నమ్మకంతో గుర్తించబడింది. '
        'వెంటనే సంక్రమించిన ఆకులు తొలగించండి. '
        'ఉదయం రాగి ఆధారిత శిలీంధ్రనాశనిని వేయండి.',
    'ta':
        'தக்காளியில் எர்லி பிளைட் 94% நம்பகத்தன்மையுடன் கண்டறியப்பட்டது. '
        'பாதிக்கப்பட்ட இலைகளை உடனடியாக அகற்றவும். '
        'காலையில் செம்பு அடிப்படையிலான பூஞ்சைக்கொல்லி தெளிக்கவும்.',
    'gu':
        'ટામેટામાં અર્લી બ્લાઇટ 94% વિશ્વાસ સાથે ઓળખાઈ. '
        'સંક્રમિત નીચેના પાંદડા તરત દૂર કરો. '
        'સવારે વહેલા તાંબા-આધારિત ફૂગનાશક છાંટો.',
    'kn':
        'ಟೊಮೇಟೊದಲ್ಲಿ ಅರ್ಲಿ ಬ್ಲೈಟ್ 94% ವಿಶ್ವಾಸದಿಂದ ಪತ್ತೆಯಾಗಿದೆ. '
        'ಸೋಂಕಿತ ಎಲೆಗಳನ್ನು ತಕ್ಷಣ ತೆಗೆದುಹಾಕಿ. '
        'ಬೆಳಿಗ್ಗೆ ತಾಮ್ರ ಆಧಾರಿತ ಶಿಲೀಂಧ್ರನಾಶಕ ಸಿಂಪಡಿಸಿ.',
    'ml':
        'തക്കാളിയിൽ എർലി ബ്ലൈറ്റ് 94% ഉറപ്പോടെ കണ്ടെത്തി. '
        'ബാധിക്കപ്പെട്ട ഇലകൾ ഉടൻ നീക്കം ചെയ്യുക. '
        'രാവിലെ ചെമ്പ് അടിസ്ഥാനമാക്കിയ കുമിൾനാശിനി തളിക്കുക.',
  };

  /// Get advisory for the current app language
  static String getAdvisory(AppLanguage lang) {
    final code = AppTranslations.languageInfo[lang]!.code;
    return _advisories[code] ?? _advisories['en']!;
  }

  /// Get TTS locale for the current app language
  static String getTtsLocale(AppLanguage lang) =>
      AppTranslations.ttsLocale(lang);

  /// Get STT locale for the current app language
  static String getSttLocale(AppLanguage lang) => switch (lang) {
    AppLanguage.marathi => 'mr_IN',
    AppLanguage.hindi => 'hi_IN',
    AppLanguage.bengali => 'bn_IN',
    AppLanguage.punjabi => 'pa_IN',
    AppLanguage.gujarati => 'gu_IN',
    AppLanguage.telugu => 'te_IN',
    AppLanguage.kannada => 'kn_IN',
    AppLanguage.tamil => 'ta_IN',
    AppLanguage.malayalam => 'ml_IN',
    AppLanguage.urdu => 'ur_IN',
    AppLanguage.nepali => 'ne_IN',
    AppLanguage.odia => 'or_IN',
    AppLanguage.assamese => 'as_IN',
    _ => 'en_US',
  };
}

// ─────────────────────────────────────────────────────────────
//  EXPERT SCREEN
// ─────────────────────────────────────────────────────────────

class ExpertScreen extends StatefulWidget {
  const ExpertScreen({super.key});
  @override
  State<ExpertScreen> createState() => _ExpertScreenState();
}

class _ExpertScreenState extends State<ExpertScreen> {
  static const _green = Color(0xFF2F7F34);
  static const _blue = Color(0xFF1565C0);

  final _voice = _VoiceService();

  @override
  void initState() {
    super.initState();
    _voice.init().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  // ── Called when farmer stops speaking ──────────────────────
  Future<void> _handleTranscript(String text, AppLanguage lang) async {
    if (text.trim().isEmpty) return;

    // 1. Store query + trigger auto-navigation to Chat tab
    ChatBridge.sendFromExpert(text.trim());

    // 2. Navigate to Chat tab immediately
    ChatBridge.onNavigateToChat?.call();

    // 3. Speak the advisory in the farmer's language (after nav)
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final advisory = _AdvisoryEngine.getAdvisory(lang);
    final ttsLocale = _AdvisoryEngine.getTtsLocale(lang);
    await _voice.speak(advisory, ttsLocale);
  }

  @override
  Widget build(BuildContext context) {
    final provider = LanguageProvider.of(context);
    final t = provider.t;
    final lang = provider.currentLanguage;
    final langInfo = AppTranslations.languageInfo[lang]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: Column(
        children: [
          _buildHeader(t, langInfo),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildSpecimen(t),
                  const SizedBox(height: 12),
                  _buildDetectionCard(t),
                  const SizedBox(height: 4),
                  _buildTreatmentSection(t),
                  _buildActionButtons(t, lang, langInfo),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader(String Function(String) t, LanguageInfo langInfo) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2F7F34), Color(0xFF43A047)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.eco_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t('expert_advisory'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Language badge — shows STT language
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(langInfo.flag, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    Text(
                      langInfo.nativeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Specimen thumbnail ───────────────────────────────────────
  Widget _buildSpecimen(String Function(String) t) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                color: const Color(0xFF2D5E1E),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: const Color(0xFF1B4D1F),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Color(0xFF81C784),
                    size: 44,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -6,
              right: -6,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          t('scanned_specimen'),
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  // ── Detection card ───────────────────────────────────────────
  Widget _buildDetectionCard(String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _green.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            // Hero image
            Container(
              width: double.infinity,
              height: 170,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _LeafPainter())),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.yard_rounded,
                          color: Colors.white,
                          size: 60,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t('tomato_plant'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Disease info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t('disease_name'),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          t('disease'),
                          style: const TextStyle(
                            color: _green,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: const LinearProgressIndicator(
                            value: 0.94,
                            minHeight: 8,
                            backgroundColor: Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(_green),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '94% ${t('confidence')}',
                        style: const TextStyle(
                          color: _green,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Treatment section ────────────────────────────────────────
  Widget _buildTreatmentSection(String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.medical_services_rounded,
                color: _green,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                t('treatment'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TreatmentItem(text: t('treatment_1')),
          _TreatmentItem(text: t('treatment_2')),
          _TreatmentItem(text: t('treatment_3')),
        ],
      ),
    );
  }

  // ── Action buttons ───────────────────────────────────────────
  Widget _buildActionButtons(
    String Function(String) t,
    AppLanguage lang,
    LanguageInfo langInfo,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ValueListenableBuilder<_VoiceState>(
        valueListenable: _voice.state,
        builder: (ctx, vs, _) {
          final speaking = vs == _VoiceState.speaking;
          final listening = vs == _VoiceState.listening;

          return Column(
            children: [
              // ── 1. Listen Advisory ─────────────────────────
              _GradBtn(
                icon: speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                label: speaking ? t('stop_advisory') : t('listen_advisory'),
                isActive: speaking,
                onTap: () {
                  if (speaking) {
                    _voice.stopSpeaking();
                  } else {
                    final advisory = _AdvisoryEngine.getAdvisory(lang);
                    final ttsLocale = _AdvisoryEngine.getTtsLocale(lang);
                    _voice.speak(advisory, ttsLocale);
                  }
                },
              ),

              const SizedBox(height: 12),

              // ── 2. Speak Advisory ──────────────────────────
              _SpeakBtn(
                isListening: listening,
                isAvailable: _voice.sttAvailable,
                listenLabel: t('listening'),
                speakLabel: t('speak_advisory'),
                hintText: '${t('speak_hint')} (${langInfo.nativeName})',
                transcript: _voice.transcript,
                onTap: listening
                    ? () async {
                        // Farmer tapped to finish — process transcript
                        await _voice.stopListening();
                        final captured = _voice.transcript.value;
                        await _handleTranscript(captured, lang);
                      }
                    : () {
                        // Start listening in farmer's selected language
                        final sttLocale = _AdvisoryEngine.getSttLocale(lang);
                        _voice.startListening(sttLocale);
                      },
              ),

              const SizedBox(height: 12),

              // ── 3. Scan Another ────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.center_focus_strong_rounded,
                    color: _green,
                    size: 20,
                  ),
                  label: Text(
                    t('scan_another'),
                    style: const TextStyle(
                      color: _green,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _green, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── 4. Go to Chat button ───────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton.icon(
                  onPressed: () => ChatBridge.onNavigateToChat?.call(),
                  icon: const Icon(Icons.chat_rounded, color: _blue, size: 20),
                  label: const Text(
                    'View Chat Answer',
                    style: TextStyle(
                      color: _blue,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: _blue.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  GRADIENT BUTTON
// ─────────────────────────────────────────────

class _GradBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _GradBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFFE53935), const Color(0xFFB71C1C)]
              : [const Color(0xFF34D399), const Color(0xFF2F7F34)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:
                (isActive ? const Color(0xFFE53935) : const Color(0xFF2F7F34))
                    .withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SPEAK BUTTON  (animated mic + live transcript)
// ─────────────────────────────────────────────

class _SpeakBtn extends StatelessWidget {
  final bool isListening, isAvailable;
  final String listenLabel, speakLabel, hintText;
  final VoidCallback onTap;
  final ValueNotifier<String> transcript;

  static const _green = Color(0xFF2F7F34);
  static const _blue = Color(0xFF1565C0);

  const _SpeakBtn({
    required this.isListening,
    required this.isAvailable,
    required this.listenLabel,
    required this.speakLabel,
    required this.hintText,
    required this.onTap,
    required this.transcript,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main button
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 56,
          decoration: BoxDecoration(
            color: isListening ? _blue : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isListening ? _blue : _green, width: 2),
            boxShadow: isListening
                ? [
                    BoxShadow(
                      color: _blue.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: isAvailable ? onTap : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mic icon — pulses when listening
                  isListening
                      ? _PulsingMic()
                      : Icon(
                          Icons.mic_rounded,
                          color: isAvailable ? _green : Colors.grey.shade400,
                          size: 24,
                        ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      isListening ? listenLabel : speakLabel,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isListening
                            ? Colors.white
                            : isAvailable
                            ? _green
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  // Tap-to-finish hint when listening
                  if (isListening) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'TAP TO FINISH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Live transcript chip
        if (isListening)
          ValueListenableBuilder<String>(
            valueListenable: transcript,
            builder: (_, txt, __) {
              if (txt.isEmpty) {
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _blue.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _blue.withOpacity(0.20)),
                  ),
                  child: Row(
                    children: [
                      _PulsingDot(color: _blue),
                      const SizedBox(width: 10),
                      Text(
                        'Listening in ${_getCurrentLangName(context)}…',
                        style: const TextStyle(
                          color: _blue,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _blue.withOpacity(0.30)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.record_voice_over_rounded,
                      color: _blue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        txt,
                        style: const TextStyle(
                          color: Color(0xFF0D47A1),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

        // Hint text when idle
        if (!isListening && isAvailable)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              hintText,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),

        // Mic unavailable message
        if (!isAvailable)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: Colors.orange.shade600,
                  size: 14,
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Microphone unavailable. Check app permissions in device Settings.',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _getCurrentLangName(BuildContext context) {
    try {
      final lang = LanguageProvider.of(context).currentLanguage;
      return AppTranslations.languageInfo[lang]!.nativeName;
    } catch (_) {
      return 'selected language';
    }
  }
}

// ─────────────────────────────────────────────
//  PULSING MIC
// ─────────────────────────────────────────────

class _PulsingMic extends StatefulWidget {
  @override
  State<_PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<_PulsingMic>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _s = Tween<double>(
      begin: 0.85,
      end: 1.20,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _s,
    child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
  );
}

// ─────────────────────────────────────────────
//  PULSING DOT
// ─────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _s = Tween<double>(
      begin: 0.5,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _s,
    child: Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}

// ─────────────────────────────────────────────
//  TREATMENT ITEM
// ─────────────────────────────────────────────

class _TreatmentItem extends StatelessWidget {
  final String text;
  const _TreatmentItem({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.radio_button_checked_rounded,
              color: Color(0xFF2F7F34),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  LEAF BACKGROUND PAINTER
// ─────────────────────────────────────────────

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      final path = Path();
      final x = (size.width / 5) * i;
      final y = size.height * 0.3 + (i % 2 == 0 ? -20.0 : 20.0);
      path.moveTo(x, y + 40);
      path.quadraticBezierTo(x - 30, y, x + 10, y - 40);
      path.quadraticBezierTo(x + 50, y, x, y + 40);
      path.close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
