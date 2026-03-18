import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

// ─────────────────────────────────────────────────────────────
//  LANGUAGE DETECTOR  (pure Unicode, no package)
// ─────────────────────────────────────────────────────────────

String _detectLang(String text) {
  final devanagari = RegExp(r'[\u0900-\u097F]');
  if (!devanagari.hasMatch(text)) return 'en';
  const marathiWords = ['आहे', 'नाही', 'आणि', 'हे', 'ते', 'मी', 'तू', 'काय', 'कसे'];
  for (final w in marathiWords) {
    if (text.contains(w)) return 'mr';
  }
  return 'hi';
}

// ─────────────────────────────────────────────────────────────
//  ADVISORY ENGINE
// ─────────────────────────────────────────────────────────────

class _AdvisoryEngine {
  static const Map<String, List<String>> _advisories = {
    'en': [
      'Tomato Early Blight detected with 94 percent confidence.',
      'Prune and remove infected lower leaves to prevent spore splash-back from the soil.',
      'Apply copper-based fungicides or bio-pesticides early in the morning for best results.',
      'Improve air circulation by spacing plants at least 24 inches apart.',
    ],
    'hi': [
      'टमाटर की अर्ली ब्लाइट 94 प्रतिशत आत्मविश्वास के साथ पहचानी गई।',
      'मिट्टी से बीजाणु उछलने से बचाने के लिए संक्रमित निचली पत्तियाँ काटें और हटाएँ।',
      'सर्वोत्तम परिणामों के लिए सुबह जल्दी कॉपर-आधारित फफूंदनाशक या जैव-कीटनाशक लगाएँ।',
      'पौधों को कम से कम 24 इंच की दूरी पर रखकर वायु संचार में सुधार करें।',
    ],
    'mr': [
      'टोमॅटो अर्ली ब्लाइट 94 टक्के आत्मविश्वासाने ओळखली गेली.',
      'मातीतून बीजाणू उडू नयेत म्हणून संक्रमित खालच्या पानांची छाटणी करा व काढून टाका.',
      'सर्वोत्तम परिणामांसाठी सकाळी लवकर तांबे-आधारित बुरशीनाशके किंवा जैव-कीटकनाशके वापरा.',
      'झाडांमध्ये किमान 24 इंच अंतर ठेवून हवा खेळती करा.',
    ],
  };

  static String getAdvisoryText(String langCode) {
    final lines = _advisories[langCode] ?? _advisories['en']!;
    return lines.join('. ');
  }
}

// ─────────────────────────────────────────────────────────────
//  VOICE SERVICE  (speech_to_text + flutter_tts)
// ─────────────────────────────────────────────────────────────

enum _VoiceState { idle, speaking, listening }

class _VoiceService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  final ValueNotifier<_VoiceState> state = ValueNotifier(_VoiceState.idle);
  final ValueNotifier<String> transcript = ValueNotifier('');

  bool _sttAvailable = false;

  Future<void> init() async {
    await _tts.setSharedInstance(true);
    _tts.setCompletionHandler(() => state.value = _VoiceState.idle);
    _sttAvailable = await _stt.initialize(
      onError: (_) => state.value = _VoiceState.idle,
    );
  }

  bool get sttAvailable => _sttAvailable;

  Future<void> speak(String text, String langCode) async {
    if (state.value == _VoiceState.speaking) {
      await _tts.stop();
      state.value = _VoiceState.idle;
      return;
    }
    await stopListening();
    await _tts.setLanguage(_ttsLocale(langCode));
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    state.value = _VoiceState.speaking;
    await _tts.speak(text);
  }

  Future<void> startListening() async {
    if (!_sttAvailable) return;
    transcript.value = '';
    state.value = _VoiceState.listening;
    await _stt.listen(
      onResult: (result) {
        transcript.value = result.recognizedWords;
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      localeId: 'hi_IN', // accepts Hindi, Marathi, English
      onSoundLevelChange: null,
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
    if (state.value == _VoiceState.listening) state.value = _VoiceState.idle;
  }

  Future<void> dispose() async {
    await _tts.stop();
    await _stt.stop();
  }

  static String _ttsLocale(String code) => switch (code) {
        'hi' => 'hi-IN',
        'mr' => 'mr-IN',
        _ => 'en-US',
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
  static const _primaryGreen = Color(0xFF2F7F34);

  final _voiceService = _VoiceService();
  String _detectedLang = 'en';

  @override
  void initState() {
    super.initState();
    _voiceService.init().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _handleTranscript(String text) async {
    if (text.isEmpty) return;
    final lang = _detectLang(text);
    setState(() => _detectedLang = lang);
    final advisory = _AdvisoryEngine.getAdvisoryText(lang);
    await _voiceService.speak(advisory, lang);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildScannedSpecimen(),
                  const SizedBox(height: 12),
                  _buildDetectionCard(),
                  const SizedBox(height: 4),
                  _buildTreatmentSection(),
                  _buildActionButtons(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Expert Advisory',
                    style: TextStyle(color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              ),
              const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
              const SizedBox(width: 16),
              const Icon(Icons.account_circle_outlined, color: Colors.white, size: 26),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannedSpecimen() {
    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 4),
                  // ignore: deprecated_member_use
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 4))],
                  color: const Color(0xFF2D5E1E),
                ),
                child: ClipRRect(borderRadius: BorderRadius.circular(12), child: _PlantThumbnail()),
              ),
              Positioned(
                bottom: -6, right: -6,
                child: Container(
                  width: 26, height: 26,
                  decoration: const BoxDecoration(color: _primaryGreen, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('SCANNED SPECIMEN',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10,
                  fontWeight: FontWeight.w600, letterSpacing: 2.0)),
        ],
      ),
    );
  }

  Widget _buildDetectionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // ignore: deprecated_member_use
          border: Border.all(color: _primaryGreen.withOpacity(0.10), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: double.infinity, height: 190,
                color: const Color(0xFF3D6B2C), child: const _TomatoHeroImage()),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: Text('Tomato Early Blight',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                              letterSpacing: -0.3, color: Color(0xFF0F172A)))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _primaryGreen.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999)),
                        child: const Text('DISEASE', style: TextStyle(color: _primaryGreen,
                            fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(value: 0.94, minHeight: 8,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: const AlwaysStoppedAnimation<Color>(_primaryGreen)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('94% Confidence',
                          style: TextStyle(color: _primaryGreen, fontSize: 13, fontWeight: FontWeight.w700)),
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

  Widget _buildTreatmentSection() {
    const treatments = [
      'Prune and remove infected lower leaves to prevent spore splash-back from the soil.',
      'Apply copper-based fungicides or bio-pesticides early in the morning for best results.',
      'Improve air circulation by spacing plants at least 24 inches apart.',
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.medical_services_rounded, color: _primaryGreen, size: 22),
            SizedBox(width: 8),
            Text('Treatment Recommendation',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          ]),
          const SizedBox(height: 14),
          ...treatments.map((t) => _TreatmentItem(text: t)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ValueListenableBuilder<_VoiceState>(
        valueListenable: _voiceService.state,
        builder: (context, voiceState, _) {
          final isSpeaking = voiceState == _VoiceState.speaking;
          final isListening = voiceState == _VoiceState.listening;
          return Column(
            children: [
              // ── Listen Advisory ──
              _GradientButton(
                icon: isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                label: isSpeaking ? 'Stop Advisory' : 'Listen Advisory',
                isActive: isSpeaking,
                onTap: () => _voiceService.speak(
                    _AdvisoryEngine.getAdvisoryText(_detectedLang), _detectedLang),
              ),
              const SizedBox(height: 12),
              // ── Speak Advisory ──
              _SpeakAdvisoryButton(
                isListening: isListening,
                isAvailable: _voiceService.sttAvailable,
                onTap: isListening
                    ? () async {
                        await _voiceService.stopListening();
                        await _handleTranscript(_voiceService.transcript.value);
                      }
                    : () => _voiceService.startListening(),
                transcript: _voiceService.transcript,
              ),
              const SizedBox(height: 12),
              // ── Scan Another Leaf ──
              SizedBox(
                width: double.infinity, height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.center_focus_strong_rounded, color: _primaryGreen, size: 22),
                  label: const Text('Scan Another Leaf',
                      style: TextStyle(color: _primaryGreen, fontSize: 17, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _primaryGreen, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: Colors.white,
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

// ─────────────────────────────────────────────────────────────
//  GRADIENT BUTTON
// ─────────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _GradientButton({required this.icon, required this.label,
      required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFFE53935), const Color(0xFFB71C1C)]
              : [const Color(0xFF34D399), const Color(0xFF2F7F34)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: (isActive ? const Color(0xFFE53935) : const Color(0xFF2F7F34)).withOpacity(0.30),
            blurRadius: 16, offset: const Offset(0, 6))],
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
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SPEAK ADVISORY BUTTON
// ─────────────────────────────────────────────────────────────

class _SpeakAdvisoryButton extends StatelessWidget {
  final bool isListening;
  final bool isAvailable;
  final VoidCallback onTap;
  final ValueNotifier<String> transcript;

  const _SpeakAdvisoryButton({required this.isListening, required this.isAvailable,
      required this.onTap, required this.transcript});

  static const _primaryGreen = Color(0xFF2F7F34);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 56,
          decoration: BoxDecoration(
            color: isListening ? const Color(0xFF1565C0) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isListening ? const Color(0xFF1565C0) : _primaryGreen, width: 2),
            boxShadow: isListening
                ? [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.30), blurRadius: 16, offset: const Offset(0, 6))]
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
                  isListening
                      ? _PulsingMic()
                      : Icon(Icons.mic_rounded,
                          color: isAvailable ? _primaryGreen : Colors.grey.shade400, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    isListening ? 'Listening… Tap to finish'
                        : isAvailable ? 'Speak Advisory' : 'Speak Advisory (unavailable)',
                    style: TextStyle(
                      color: isListening ? Colors.white : isAvailable ? _primaryGreen : Colors.grey.shade400,
                      fontSize: 17, fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isListening)
          ValueListenableBuilder<String>(
            valueListenable: transcript,
            builder: (_, text, __) {
              if (text.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over_rounded, color: Color(0xFF1565C0), size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(text,
                        style: const TextStyle(color: Color(0xFF0D47A1), fontSize: 13, height: 1.5))),
                  ],
                ),
              );
            },
          ),
        if (!isListening && isAvailable)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text('Speak in your language — advisory plays back in Hindi, Marathi or English.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11, height: 1.4)),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PULSING MIC
// ─────────────────────────────────────────────────────────────

class _PulsingMic extends StatefulWidget {
  @override
  State<_PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<_PulsingMic> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.9, end: 1.15)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24));
}

// ─────────────────────────────────────────────────────────────
//  TREATMENT ITEM
// ─────────────────────────────────────────────────────────────

class _TreatmentItem extends StatelessWidget {
  final String text;
  const _TreatmentItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.radio_button_checked_rounded, color: Color(0xFF2F7F34), size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF334155), fontSize: 13, height: 1.6))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PLACEHOLDER IMAGES
// ─────────────────────────────────────────────────────────────

class _PlantThumbnail extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF1B4D1F),
    child: const Center(child: Icon(Icons.eco_rounded, color: Color(0xFF81C784), size: 44)),
  );
}

class _TomatoHeroImage extends StatelessWidget {
  const _TomatoHeroImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _LeafPatternPainter())),
          const Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.yard_rounded, color: Color(0xFFFFFFFF), size: 64),
              SizedBox(height: 6),
              Text('Tomato Plant', style: TextStyle(color: Colors.white70, fontSize: 12,
                  fontWeight: FontWeight.w500, letterSpacing: 0.5)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _LeafPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05)..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      final path = Path();
      final x = (size.width / 5) * i;
      final y = size.height * 0.3 + (i % 2 == 0 ? -20.0 : 20.0);
      path.moveTo(x, y + 40);
      path.quadraticBezierTo(x - 30, y, x + 10, y - 40);
      path.quadraticBezierTo(x + 50, y, x, y + 40);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}