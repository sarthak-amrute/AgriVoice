// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:agrivoice/app_translations.dart';
import 'package:agrivoice/chat_screen.dart';

// ─────────────────────────────────────────────────────────────
//  LANG DETECTOR
// ─────────────────────────────────────────────────────────────
String _detectLang(String text) {
  final dev = RegExp(r'[\u0900-\u097F]');
  if (!dev.hasMatch(text)) return 'en';
  const mr = ['आहे','नाही','आणि','हे','ते','मी','काय','कसे'];
  for (final w in mr) { if (text.contains(w)) return 'mr'; }
  return 'hi';
}

// ─────────────────────────────────────────────────────────────
//  ADVISORY ENGINE
// ─────────────────────────────────────────────────────────────
class _AdvisoryEngine {
  static String getText(String langCode, String Function(String) t) {
    return '${t('disease_name')}. ${t('treatment_1')} ${t('treatment_2')} ${t('treatment_3')}';
  }
}

// ─────────────────────────────────────────────────────────────
//  VOICE SERVICE
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
  // Guard: don't initialize if already done or in progress
  if (_sttAvailable || _stt.isAvailable) return;
  await _tts.setSharedInstance(true);
  _tts.setCompletionHandler(() => state.value = _VoiceState.idle);
  try {
    _sttAvailable = await _stt.initialize(
      onError: (_) => state.value = _VoiceState.idle,
    );
  } catch (_) {
    _sttAvailable = false;
  }
}

  Future<void> speak(String text, String langCode) async {
    if (state.value == _VoiceState.speaking) {
      await _tts.stop(); state.value = _VoiceState.idle; return;
    }
    await stopListening();
    await _tts.setLanguage(_locale(langCode));
    await _tts.setSpeechRate(0.45);
    state.value = _VoiceState.speaking;
    await _tts.speak(text);
  }

  Future<void> startListening() async {
    if (!_sttAvailable) return;
    transcript.value = ''; state.value = _VoiceState.listening;
    await _stt.listen(
      onResult: (r) => transcript.value = r.recognizedWords,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      localeId: 'hi_IN',
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
    if (state.value == _VoiceState.listening) state.value = _VoiceState.idle;
  }

  Future<void> dispose() async { await _tts.stop(); await stopListening(); }

  static String _locale(String c) => switch (c) {
    'hi' => 'hi-IN', 'mr' => 'mr-IN', _ => 'en-US',
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
  final _voice = _VoiceService();
  String _detectedLang = 'en';

  @override
  void initState() { super.initState(); _voice.init().then((_) => setState(() {})); }

  @override
  void dispose() { _voice.dispose(); super.dispose(); }

  Future<void> _handleTranscript(String text) async {
    if (text.isEmpty) return;
    _detectedLang = _detectLang(text);
    ChatBridge.sendFromExpert(text);
    final t = LanguageProvider.of(context).t;
    await _voice.speak(_AdvisoryEngine.getText(_detectedLang, t), _detectedLang);
  }

  @override
  Widget build(BuildContext context) {
    final t = LanguageProvider.of(context).t;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: Column(children: [
        _header(t),
        Expanded(child: SingleChildScrollView(child: Column(children: [
          const SizedBox(height: 20),
          _specimen(t),
          const SizedBox(height: 12),
          _detectionCard(t),
          const SizedBox(height: 4),
          _treatmentSection(t),
          _actionButtons(t),
          const SizedBox(height: 32),
        ]))),
      ]),
    );
  }

  Widget _header(String Function(String) t) => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(
      colors: [Color(0xFF2F7F34), Color(0xFF43A047)],
      begin: Alignment.centerLeft, end: Alignment.centerRight,
    )),
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        const Icon(Icons.eco_rounded, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Text(t('expert_advisory'),
            style: const TextStyle(color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.w700))),
        const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
      ]),
    )),
  );

  Widget _specimen(String Function(String) t) => Column(children: [
    Stack(clipBehavior: Clip.none, children: [
      Container(width: 90, height: 90,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16, offset: const Offset(0,4))],
          color: const Color(0xFF2D5E1E)),
        child: ClipRRect(borderRadius: BorderRadius.circular(12),
          child: Container(color: const Color(0xFF1B4D1F),
            child: const Center(child: Icon(Icons.eco_rounded, color: Color(0xFF81C784), size: 44))))),
      Positioned(bottom: -6, right: -6, child: Container(width: 26, height: 26,
        decoration: const BoxDecoration(color: _green, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
        child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18))),
    ]),
    const SizedBox(height: 12),
    Text(t('scanned_specimen'), style: TextStyle(color: Colors.grey.shade500,
        fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 2.0)),
  ]);

  Widget _detectionCard(String Function(String) t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withOpacity(0.10)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0,3))]),
      clipBehavior: Clip.hardEdge,
      child: Column(children: [
        Container(width: double.infinity, height: 190,
          decoration: const BoxDecoration(gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _LeafPainter())),
            Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.yard_rounded, color: Colors.white, size: 64),
              const SizedBox(height: 6),
              Text(t('tomato_plant'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ])),
        Padding(padding: const EdgeInsets.all(18), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(t('disease_name'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999)),
              child: Text(t('disease'), style: const TextStyle(color: _green,
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(value: 0.94, minHeight: 8,
                backgroundColor: Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(_green)))),
            const SizedBox(width: 12),
            Text('94% ${t('confidence')}',
                style: const TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ])),
      ]),
    ),
  );

  Widget _treatmentSection(String Function(String) t) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.medical_services_rounded, color: _green, size: 22),
        const SizedBox(width: 8),
        Text(t('treatment'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 14),
      _TreatmentItem(text: t('treatment_1')),
      _TreatmentItem(text: t('treatment_2')),
      _TreatmentItem(text: t('treatment_3')),
    ]),
  );

  Widget _actionButtons(String Function(String) t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: ValueListenableBuilder<_VoiceState>(
      valueListenable: _voice.state,
      builder: (_, vs, __) {
        final speaking = vs == _VoiceState.speaking;
        final listening = vs == _VoiceState.listening;
        return Column(children: [
          // Listen Advisory
          _GradBtn(
            icon: speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
            label: speaking ? t('stop_advisory') : t('listen_advisory'),
            isActive: speaking,
            onTap: () => _voice.speak(
                _AdvisoryEngine.getText(_detectedLang, t), _detectedLang),
          ),
          const SizedBox(height: 12),
          // Speak Advisory
          _SpeakBtn(
            isListening: listening,
            isAvailable: _voice.sttAvailable,
            listenLabel: t('listening'),
            speakLabel: t('speak_advisory'),
            hintText: t('speak_hint'),
            transcript: _voice.transcript,
            onTap: listening
                ? () async {
                    await _voice.stopListening();
                    await _handleTranscript(_voice.transcript.value);
                  }
                : _voice.startListening,
          ),
          const SizedBox(height: 12),
          // Scan Another
          SizedBox(width: double.infinity, height: 56,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.center_focus_strong_rounded, color: _green, size: 22),
              label: Text(t('scan_another'), style: const TextStyle(color: _green,
                  fontSize: 17, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _green, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: Colors.white,
              ),
            )),
        ]);
      },
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  GRADIENT BUTTON
// ─────────────────────────────────────────────────────────────
class _GradBtn extends StatelessWidget {
  final IconData icon; final String label;
  final bool isActive; final VoidCallback onTap;
  const _GradBtn({required this.icon, required this.label,
      required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, height: 56,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: isActive
          ? [const Color(0xFFE53935), const Color(0xFFB71C1C)]
          : [const Color(0xFF34D399), const Color(0xFF2F7F34)]),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(
        color: (isActive ? const Color(0xFFE53935) : const Color(0xFF2F7F34)).withOpacity(0.30),
        blurRadius: 16, offset: const Offset(0,6))],
    ),
    child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(14),
      child: InkWell(borderRadius: BorderRadius.circular(14), onTap: onTap,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        ]))),
  );
}

// ─────────────────────────────────────────────────────────────
//  SPEAK BUTTON
// ─────────────────────────────────────────────────────────────
class _SpeakBtn extends StatelessWidget {
  final bool isListening, isAvailable;
  final String listenLabel, speakLabel, hintText;
  final VoidCallback onTap;
  final ValueNotifier<String> transcript;
  static const _green = Color(0xFF2F7F34);
  static const _blue = Color(0xFF1565C0);

  const _SpeakBtn({required this.isListening, required this.isAvailable,
      required this.listenLabel, required this.speakLabel, required this.hintText,
      required this.onTap, required this.transcript});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    AnimatedContainer(duration: const Duration(milliseconds: 300), height: 56,
      decoration: BoxDecoration(
        color: isListening ? _blue : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isListening ? _blue : _green, width: 2),
        boxShadow: isListening ? [BoxShadow(color: _blue.withOpacity(0.30),
            blurRadius: 16, offset: const Offset(0,6))] : [],
      ),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(14),
        child: InkWell(borderRadius: BorderRadius.circular(14),
          onTap: isAvailable ? onTap : null,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            isListening ? _PulsingMic() : Icon(Icons.mic_rounded,
                color: isAvailable ? _green : Colors.grey.shade400, size: 22),
            const SizedBox(width: 10),
            Text(isListening ? listenLabel : speakLabel,
                style: TextStyle(
                  color: isListening ? Colors.white : isAvailable ? _green : Colors.grey.shade400,
                  fontSize: 17, fontWeight: FontWeight.w700)),
          ])))),
    if (isListening)
      ValueListenableBuilder<String>(
        valueListenable: transcript,
        builder: (_, txt, __) => txt.isEmpty ? const SizedBox.shrink()
            : Container(margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _blue.withOpacity(0.25))),
                child: Row(children: [
                  const Icon(Icons.record_voice_over_rounded, color: _blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(txt, style: const TextStyle(
                      color: Color(0xFF0D47A1), fontSize: 13, height: 1.5))),
                ])),
      ),
    if (!isListening && isAvailable)
      Padding(padding: const EdgeInsets.only(top: 6, left: 4),
        child: Text(hintText, style: TextStyle(color: Colors.grey.shade500, fontSize: 11))),
  ]);
}

class _PulsingMic extends StatefulWidget {
  @override State<_PulsingMic> createState() => _PulsingMicState();
}
class _PulsingMicState extends State<_PulsingMic> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _s;
  @override void initState() { super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _s = Tween<double>(begin: 0.9, end: 1.15).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ScaleTransition(scale: _s,
      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24));
}

class _TreatmentItem extends StatelessWidget {
  final String text;
  const _TreatmentItem({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0,2))]),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.only(top: 1),
        child: Icon(Icons.radio_button_checked_rounded, color: Color(0xFF2F7F34), size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF334155), fontSize: 13, height: 1.6))),
    ]),
  );
}

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.05)..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      final path = Path();
      final x = (size.width / 5) * i; final y = size.height * 0.3 + (i % 2 == 0 ? -20.0 : 20.0);
      path.moveTo(x, y + 40); path.quadraticBezierTo(x - 30, y, x + 10, y - 40);
      path.quadraticBezierTo(x + 50, y, x, y + 40); path.close();
      canvas.drawPath(path, p);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}