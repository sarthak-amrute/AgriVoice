// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:agrivoice/app_translations.dart';

// ─────────────────────────────────────────────────────────────
//  CHAT BRIDGE  — Expert Screen → Chat Screen
//  Also stores a callback so Expert can trigger nav to Chat tab
// ─────────────────────────────────────────────────────────────

class ChatBridge {
  static String? _pendingMessage;
  // Callback set by MainShell to switch to Chat tab
  static VoidCallback? onNavigateToChat;

  /// Called from ExpertScreen — stores query AND navigates to Chat
  static void sendFromExpert(String message) {
    _pendingMessage = message;
    onNavigateToChat?.call();   // ← auto-switch to Chat tab
  }

  static String? consume() {
    final msg = _pendingMessage;
    _pendingMessage = null;
    return msg;
  }

  static bool get hasPending => _pendingMessage != null;
}

// ─────────────────────────────────────────────────────────────
//  AGRI BOT  — Offline Knowledge Base
// ─────────────────────────────────────────────────────────────

class _AgriBot {
  static const Map<String, String> _kb = {
    // ── Greetings ──
    'hello': 'Hello! I am your offline Agri Expert 🌱\nAsk me about crop diseases, pests, watering, fertilizers, or farming tips.',
    'hi': 'Hi there! How can I help with your crops today?',
    'help': 'I can help with: plant diseases, pest control, watering schedules, fertilizers, soil health, and crop care.',
    'thanks': 'You are welcome! Feel free to ask anything about your crops.',
    'namaste': 'Namaste! Main aapki fasal ke bare mein madad kar sakta hoon.',
    'namaskar': 'Namaskar! Aapki phasal ke baare mein kuch poochhe.',

    // ── Tomato ──
    'tomato': 'Tomatoes need 6-8 hrs sun, deep watering 2-3x/week, well-drained soil.\n\nCommon diseases:\n• Early Blight\n• Late Blight\n• Fusarium Wilt\n• Mosaic Virus\n\nAsk me about any specific disease!',
    'tamatar': 'Tamatar ke liye:\n• Roz 6-8 ghante dhoop chahiye\n• Hafte mein 2-3 baar gehra paani dein\n• Achi nali wali mitti chahiye\n\nSamasya batayein — main sahi upay bataunga.',
    'tomato early blight': '🍅 Early Blight (Alternaria):\n\n• Dark spots with yellow rings on lower leaves\n• Spreads upward in wet weather\n\n✅ Treatment:\n1. Remove infected leaves immediately\n2. Apply Mancozeb or copper fungicide\n3. Mulch soil to prevent spore splash\n4. Space plants 24 inches apart\n5. Water at base only — never on leaves',
    'early blight': '🍅 Early Blight (Alternaria):\n\n• Dark spots with yellow rings on lower leaves\n• Spreads upward in wet weather\n\n✅ Treatment:\n1. Remove infected leaves immediately\n2. Apply Mancozeb or copper fungicide\n3. Mulch soil to prevent spore splash\n4. Space plants 24 inches apart\n5. Water at base only — never on leaves',
    'late blight': '⚠️ Late Blight (Phytophthora) — VERY aggressive:\n\n• Water-soaked spots turning brown\n• White mold under leaves in humidity\n\n✅ Treatment:\n1. Remove ALL infected plants immediately\n2. Apply Chlorothalonil fungicide\n3. Do NOT compost infected material\n4. Avoid overhead watering\n5. Use resistant varieties next season',
    'blight': '🍂 Blight Treatment:\n\n1. Remove infected leaves immediately\n2. Apply copper-based fungicide\n3. Improve air circulation (space plants 2 feet)\n4. Water at soil level only\n5. Apply Mancozeb weekly as preventive\n\nIs it Early Blight or Late Blight? Ask for specific treatment.',
    'mosaic': '🦠 Mosaic Virus:\n\n• Mottled yellow-green leaves\n• Stunted growth, distorted fruit\n• NO cure — spread by aphids\n\n✅ Action:\n1. Remove all infected plants\n2. Control aphids with neem oil\n3. Wash hands before touching healthy plants\n4. Use virus-resistant varieties next season',

    // ── Potato ──
    'potato': 'Potatoes need loose well-drained soil, consistent moisture.\n\nCommon issues:\n• Late Blight\n• Scab\n• Aphids\n• Black Leg\n\nHarvest when leaves yellow. Ask about any specific problem!',
    'aaloo': 'Aalu ki fasal ke liye:\n• Dheeli, achi nali wali mitti chahiye\n• Niyamit paani dein\n• Patte peele hone par kaatein\n\nKoi samasya hai toh batayein.',
    'scab': '🥔 Potato Scab:\n\n• Rough corky patches on potato skin\n• Caused by bacteria in alkaline soil\n\n✅ Treatment:\n1. Lower soil pH below 5.5 (use sulfur)\n2. Avoid fresh manure\n3. Rotate crops every 3 years\n4. Water regularly during tuber formation',

    // ── Diseases ──
    'yellow': '🟡 Yellow Leaves — Causes:\n\n1. Nitrogen deficiency → add balanced fertilizer\n2. Overwatering → check drainage\n3. Viral infection → look for mosaic pattern\n4. Iron deficiency → leaves yellow but veins stay green\n\nCheck soil moisture first — most yellowing is from overwatering.',
    'pata peela': '🟡 Patte Peele Hone Ke Kaaran:\n\n1. Naitrogen ki kami — balanced fertilizer dalein\n2. Zyada paani — drainage check karein\n3. Virus — mosaic pattern dekhe kya\n\nPehle mitti ki nami check karein.',
    'curl': '🌀 Leaf Curl:\n\n• Heat stress → mulch + water more\n• Aphids → check underside of leaves\n• Viral infection → look for color changes\n• Herbicide damage → check nearby chemicals\n\nShare a photo for accurate diagnosis.',
    'spot': '🔴 Leaf Spots (Fungal):\n\n1. Remove all spotted leaves\n2. Avoid wetting foliage when watering\n3. Apply neem oil or copper fungicide\n4. Ensure good air circulation\n5. Spray early morning — never evening',
    'wilt': '😵 Wilting:\n\n• Underwatering → water deeply at root zone\n• Root rot → improve drainage, let soil dry\n• Fusarium Wilt → soil-borne fungus, rotate crops\n• Stem borer → check stem for holes\n\nWilt in morning = root problem. Wilt only in afternoon heat = normal.',
    'rot': '🟤 Root Rot:\n\n• Caused by overwatering + poor drainage\n• Mushy brown roots, yellowing leaves\n\n✅ Fix:\n1. Let soil dry completely before watering\n2. Add perlite to improve drainage\n3. Remove severely affected plants\n4. Use fungicide drench (Metalaxyl)',
    'rust': '🦀 Rust Fungus:\n\n• Orange/brown powdery spots on leaves\n\n✅ Treatment:\n1. Apply sulfur-based fungicide\n2. Remove heavily infected leaves\n3. Avoid overhead watering\n4. Improve air circulation',
    'powdery mildew': '⚪ Powdery Mildew:\n\n• White powder on leaves\n• Thrives in dry weather with high humidity nights\n\n✅ Treatment:\n1. Apply neem oil spray\n2. Mix 1 tsp baking soda + 1L water — spray weekly\n3. Water at base only\n4. Increase plant spacing',
    'mold': '🍄 Mold/Mildew:\n\nImprove ventilation.\nApply baking soda (1 tsp/liter) or potassium bicarbonate.\nReduce humidity around plants.',

    // ── Pests ──
    'pest': '🐛 Common Pests:\n\n• Aphids — cluster on new growth\n• Whiteflies — spread viruses\n• Spider Mites — hot dry conditions\n• Thrips — silvery leaf streaks\n• Caterpillars — chew leaves\n\nUse neem oil for ALL of these. Ask about any specific pest!',
    'kida': '🐛 Keede Ki Samasya:\n\nNeem oil sabse acha organic upay hai.\n5ml neem oil + 1ml dish soap + 1L paani mix karein.\nSham ko spray karein.\nAlag-alag keede ke liye alag upay hain — batayein kaunsa keeda hai.',
    'aphid': '🐜 Aphids:\n\n• Soft-bodied green/black insects on new growth\n• Spread viruses, cause leaf curl\n\n✅ Treatment:\n1. Strong water spray to dislodge\n2. Neem oil spray (evening)\n3. Introduce ladybugs\n4. Yellow sticky traps',
    'whitefly': '🦟 Whiteflies:\n\n• Tiny white flies under leaves\n• Spread viruses, weaken plants\n\n✅ Treatment:\n1. Yellow sticky traps\n2. Neem oil in early morning\n3. Reflective silver mulch repels them\n4. Avoid over-fertilizing nitrogen',
    'mite': '🕷️ Spider Mites:\n\n• Tiny dots on leaves, fine webbing\n• Thrive in hot dry conditions\n\n✅ Treatment:\n1. Increase humidity — mist plants\n2. Neem oil spray\n3. Introduce predatory mites\n4. Keep plants well-watered',
    'caterpillar': '🐛 Caterpillars:\n\n1. Handpick at night (they hide in day)\n2. Bt (Bacillus thuringiensis) spray — safe organic\n3. Neem oil as deterrent\n4. Floating row covers to prevent egg laying',
    'thrip': '🔸 Thrips:\n\nSilvery streaks on leaves.\nRemove infested leaves.\nApply spinosad or neem oil.\nUse blue sticky traps.',
    'locust': '🦗 Locust/Tida Attack:\n\n• Very difficult to control individually\n• Alert local agricultural department\n• Apply Malathion or Chlorpyrifos if recommended\n• Use noise and smoke as deterrents\n• Cover small crops with nets',

    // ── Watering ──
    'water': '💧 Watering Guide:\n\n• Water deeply and INFREQUENTLY\n• Morning is best — reduces fungal risk\n• Most vegetables need 1-2 inches/week\n• Check: push finger 2 inches — if dry, water\n• Drip irrigation saves 30-50% water',
    'paani': '💧 Paani Dene Ka Sahi Tarika:\n\n• Gehra aur kam baar paani dein\n• Subah paani dena sabse acha\n• Zyada paani se jaad sadte hain\n• Ungli 2 inch zameen mein dalo — sukha ho tab paani dein',
    'irrigation': '🚿 Irrigation:\n\nDrip irrigation is most efficient — 30-50% water saving.\nWater at root zone, not on leaves.\nMulch retains moisture and reduces watering by 25%.',
    'drought': '☀️ Drought Stress:\n\nWilting, leaf scorch, premature fruit drop.\n\n✅ Action:\n1. Mulch heavily — 3-4 inch layer\n2. Water deeply at base\n3. Use shade cloth to reduce heat stress\n4. Harvest mature fruit to reduce plant stress',

    // ── Fertilizer ──
    'fertilizer': '🌿 Fertilizer Guide:\n\n• N (Nitrogen) → leafy green growth\n• P (Phosphorus) → roots + flowers\n• K (Potassium) → fruiting + disease resistance\n\nTest soil pH first (ideal: 6.0-7.0)\nApply in morning before watering.',
    'khad': '🌿 Khaad Ki Jankari:\n\n• N (Naitrogen) → patte hare aur bade hote hain\n• P (Phosphorus) → jaad aur phool ke liye\n• K (Potash) → phal aur rog-pratirodh ke liye\n\nCompost sabse badhiya prakratik khaad hai.',
    'nitrogen': '🟢 Nitrogen Deficiency:\n\nPale yellow leaves starting from OLDER leaves.\n\n✅ Fix:\n1. Apply urea (46-0-0)\n2. Ammonium sulfate (21-0-0)\n3. Organic: compost or cow manure\n4. Fish meal for quick results',
    'phosphorus': '🟠 Phosphorus Deficiency:\n\nPurple/reddish leaves, poor roots, delayed maturity.\n\n✅ Fix:\n1. Bone meal (organic)\n2. Single superphosphate\n3. Ensure soil pH 6-7 for best uptake\n4. Avoid over-watering — flushes phosphorus out',
    'potassium': '🟡 Potassium Deficiency:\n\nBrown leaf edges, weak stems, poor fruit quality.\n\n✅ Fix:\n1. Potassium sulfate (SOP)\n2. Wood ash (organic)\n3. Muriate of potash (MOP)\n4. Essential for disease resistance!',
    'compost': '♻️ Compost:\n\nImproves soil structure + nutrients.\nApply 2-3 inch layer on soil.\nMake at home: kitchen scraps + dry leaves.\nVermicompost is excellent — apply 200g/plant.',
    'urea': '⚗️ Urea (46-0-0):\n\nFast nitrogen source.\nApply 5-10g per plant.\nMix with water — do not apply dry on leaves.\nAvoid before rain — nitrogen lost to air.',

    // ── Soil ──
    'soil': '🌱 Healthy Soil:\n\n• pH 6.0-7.0 for most crops\n• Good drainage\n• Organic matter > 3%\n• Earthworms = healthy soil indicator\n\nTest soil every 2-3 years.',
    'mitti': '🌱 Achi Mitti:\n\n• pH 6-7 hona chahiye\n• Paani nikalna chahiye aasaani se\n• Organic matter 3% se zyada\n• Kenchua = mitti ki sehat ka sanket',
    'ph': '⚗️ Soil pH:\n\nMost vegetables: 6.0-7.0\n\n• Too acidic (< 6) → add lime\n• Too alkaline (> 7) → add sulfur\n• Wrong pH blocks nutrient uptake even with fertilizer!',

    // ── Crops ──
    'wheat': '🌾 Wheat:\n\nCool temperatures needed.\nSow Oct-Nov (Rabi).\n\nDiseases: Rust, Powdery Mildew, Smut\n✅ Apply fungicide at flag leaf stage.',
    'gehu': '🌾 Gehun:\n\nRabi fasal — October-November mein boye.\nSinchayee: 5-6 baar.\nRog: Gehun ka jang (rust) — sulfur fungicide use karein.',
    'rice': '🌾 Rice:\n\nFlooded or consistently moist soil.\nCommon issues: Blast, Sheath Blight, Brown Planthopper.\n✅ Use resistant varieties + balanced fertilization.',
    'chawal': '🌾 Chawal/Dhan:\n\nBhari mitti mein paani bhara rakhein.\nKhataarna rog: Blast, Kanda jhulsa.\nSahi beej upchar se 70% rog ruke ja sakte hain.',
    'corn': '🌽 Corn/Maize:\n\nWarm soil (>15°C), full sun, consistent moisture.\nPlant in BLOCKS for good pollination.\nDiseases: Corn Borer, Grey Leaf Spot, Rust.',
    'makka': '🌽 Makka/Bhutta:\n\nGarm mausam mein ugta hai.\nBlock mein lagayein — parikaran ke liye.\nKeede: Corn Borer — Bt spray use karein.',
    'onion': '🧅 Onion:\n\nWell-drained soil + full sun.\nStop watering when tops fall over.\nDiseases: Thrips, Purple Blotch, Downy Mildew.',
    'pyaz': '🧅 Pyaz:\n\nAchi nali wali mitti + poori dhoop.\nJab patte gir jayein tab paani band karein.\nKeede: Thrips — neem oil spray karein.',
    'chili': '🌶️ Chili/Mirch:\n\nWarm + full sun. Prefers slightly dry conditions.\nDiseases: Anthracnose, Bacterial Wilt, Mites.\n✅ Neem oil spray weekly as preventive.',
    'mirch': '🌶️ Mirch:\n\nGarm mausam + poori dhoop.\nThodi sukhi mitti pasand hai.\nAnthracnose: Kale dhabb — copper fungicide lagayein.',
    'brinjal': '🍆 Brinjal/Eggplant:\n\nFull sun + warm weather.\nPests: Shoot Borer, Whitefly, Aphids.\n✅ Neem oil spray weekly as preventive.',
    'baigan': '🍆 Baigan:\n\nPoori dhoop + garm mausam.\nKeede: Shoot Borer — patte band hona iska sanket.\nNeem oil spray hafte mein ek baar karein.',
    'okra': '🥬 Okra/Bhindi:\n\nHot weather + well-drained soil.\nHarvest every 2-3 days — don\'t let pods get old.\nVirus: Yellow Vein Mosaic — control whiteflies!',
    'bhindi': '🥬 Bhindi:\n\nGarm mausam mein acha ugta hai.\nHar 2-3 din mein kaatein.\nPeeli nasi wala rog: safed makhi rokein — pila sticky trap lagayein.',
    'cucumber': '🥒 Cucumber:\n\nConsistent moisture + full sun.\nTrain on trellis for air circulation.\nDiseases: Powdery Mildew, Mosaic Virus, Downy Mildew.',

    // ── Organic ──
    'organic': '🌿 Organic Farming:\n\nPest control: Neem oil, Bt spray, Diatomaceous earth\nFertilizers: Compost, Vermicompost, Bone meal, Fish meal\n\nBeneficial insects: Ladybugs, Lacewings, Parasitic wasps',
    'neem': '🌿 Neem Oil — Universal Organic Pesticide:\n\n• Controls 200+ insects\n• Also works as fungicide\n\n✅ How to use:\n1. Mix 5ml neem oil + 1ml dish soap + 1L water\n2. Shake well\n3. Spray in evening (not midday sun)\n4. Repeat every 7 days\n5. Safe for humans, bees, birds',
    'neem oil': '🌿 Neem Oil:\n5ml + 1ml soap + 1L water.\nEvening spray only.\nRepeat weekly.\nSafe organic treatment for most pests and fungal diseases.',

    // ── Seasons ──
    'kharif': '☔ Kharif Crops (Monsoon):\n\nRice, Maize, Cotton, Sugarcane, Groundnut, Soybean\nSow: June-July\nHarvest: October-November\n\n⚠️ Watch for fungal diseases in monsoon!',
    'rabi': '❄️ Rabi Crops (Winter):\n\nWheat, Barley, Mustard, Peas, Gram, Potato\nSow: October-November\nHarvest: March-April\n\n💧 Needs 4-6 irrigations.',
    'monsoon': '🌧️ Monsoon Tips:\n\n1. Ensure good drainage to prevent root rot\n2. Apply fungicide preventively every 2 weeks\n3. Reduce irrigation — rain provides water\n4. Watch for fungal diseases in humidity\n5. Support heavy-headed plants against wind',

    // ── Weather ──
    'weather': '🌤️ Weather-based advice:\n\nHot & Dry → water more, mulch, watch for mites\nCold → reduce watering, protect from frost\nHumid → apply fungicide, improve air circulation\nAfter rain → check for fungal disease next 48 hours',
    'frost': '🥶 Frost Protection:\n\n1. Cover plants with cloth/newspaper at night\n2. Water soil before frost — moist soil holds heat\n3. Use row covers or plastic tunnels\n4. Avoid fertilizing before frost — tender growth is vulnerable',

    // ── Photo ──
    'photo': '📸 You shared a photo!\n\nFor accurate diagnosis, please describe:\n• Which crop is it?\n• How long have symptoms been visible?\n• What do the spots/lesions look like?\n• Any recent weather changes?\n\nI\'ll give you a detailed treatment plan.',
    'image': '📸 Image received! Please describe the symptoms — I\'ll diagnose and suggest treatment.',
    'picture': '📸 Thanks for the photo! Tell me the crop name and symptoms for a precise diagnosis.',
  };

  static String getReply(String input) {
    final lower = input.toLowerCase().trim();

    // Greeting check
    for (final key in ['namaste', 'namaskar', 'hello', 'hi', 'thanks']) {
      if (lower.startsWith(key) || lower == key) return _kb[key]!;
    }

    // Multi-word first (more specific)
    final multiWord = [
      'neem oil', 'early blight', 'late blight', 'powdery mildew',
      'tomato early blight', 'spider mite',
    ];
    for (final key in multiWord) {
      if (lower.contains(key)) return _kb[key]!;
    }

    // Single keyword
    for (final entry in _kb.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }

    // Hindi fallback check
    if (lower.contains('rog') || lower.contains('bimari')) {
      return '🌿 Rog ke baare mein:\n\nKripya batayein:\n• Kaunsi fasal hai?\n• Patte, tana ya phal mein kya dikh raha hai?\n• Kitne din se yeh samasya hai?\n\nMain sahi upay bataunga.';
    }
    if (lower.contains('paani') || lower.contains('sinchayee')) {
      return _kb['paani']!;
    }
    if (lower.contains('khaad') || lower.contains('fertilizer')) {
      return _kb['khad']!;
    }

    return '🤔 I\'m not sure about that specific issue.\n\nCould you describe:\n• Which crop is affected?\n• What do the symptoms look like? (spots, yellowing, wilting)\n• How long has this been happening?\n\nOr try: blight, yellow leaves, aphid, neem, watering, tomato, potato, wheat 🌾';
  }
}

// ─────────────────────────────────────────────────────────────
//  CHAT SCREEN
// ─────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _primaryGreen = Color(0xFF2F7F34);
  static const _bgColor = Color(0xFFF0F4F0);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _stt = SpeechToText();
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _tts = FlutterTts();

  bool _sttAvailable = false;
  bool _isListening = false;
  bool _isTyping = false;
  bool _ttsEnabled = true;   // user can toggle TTS on/off

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: "Hello! I'm your offline Agri Expert 🌱\n\nI can help with:\n• Crop diseases & treatment\n• Pest identification\n• Watering & fertilizers\n• Seasonal farming tips\n\nType, speak, or send a photo!\n\n💡 Use Speak Advisory on the Expert screen — I'll answer your voice query here automatically!",
      isUser: false,
      type: _MessageType.text,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initStt();
    _initTts();
    // Check for voice query from Expert Screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingMessage();
    });
  }

  Future<void> _initTts() async {
    await _tts.setSharedInstance(true);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  /// Speak bot reply using TTS
  Future<void> _speakReply(String text, AppLanguage lang) async {
    if (!_ttsEnabled) return;
    final locale = AppTranslations.ttsLocale(lang);
    await _tts.setLanguage(locale);
    // Remove emojis for cleaner TTS
    final clean = text.replaceAll(RegExp(r'[^\x00-\x7F\u0900-\u097F\u0980-\u09FF\u0A00-\u0A7F\u0A80-\u0AFF\u0B00-\u0B7F\u0C00-\u0C7F\u0C80-\u0CFF\u0D00-\u0D7F]'), ' ');
    await _tts.speak(clean);
  }

  Future<void> _stopTts() async => await _tts.stop();

  void _checkPendingMessage() {
    final pending = ChatBridge.consume();
    if (pending != null && pending.isNotEmpty) {
      // Show blue banner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              '🎤 "$pending"',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            )),
          ]),
          backgroundColor: const Color(0xFF1565C0),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      // Auto-submit to bot
      _submitMessage(pending, isFromExpert: true);
    }
  }

  Future<void> _initStt() async {
    final available = await _stt.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() => _sttAvailable = available);
  }

  Future<void> _toggleMic() async {
  if (!_sttAvailable) return;
  if (_isListening) {
    await _stt.stop();
    setState(() => _isListening = false);
    return;
  }
  setState(() { _isListening = true; _controller.clear(); });
  await _stt.listen(
    onResult: (result) {
      if (mounted) setState(() {
        _controller.text = result.recognizedWords;
        _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length));
      });
    },
    listenFor: const Duration(seconds: 30),
    pauseFor: const Duration(seconds: 4),
    localeId: _getSttLocale(),   // ← only this line changed
  );
}

// ── Add this helper right below _toggleMic ──
String _getSttLocale() {
  final lang = LanguageProvider.of(context).currentLanguage;
  return switch (lang) {
    AppLanguage.marathi   => 'mr_IN',
    AppLanguage.hindi     => 'hi_IN',
    AppLanguage.bengali   => 'bn_IN',
    AppLanguage.punjabi   => 'pa_IN',
    AppLanguage.gujarati  => 'gu_IN',
    AppLanguage.telugu    => 'te_IN',
    AppLanguage.kannada   => 'kn_IN',
    AppLanguage.tamil     => 'ta_IN',
    AppLanguage.malayalam => 'ml_IN',
    AppLanguage.urdu      => 'ur_IN',
    AppLanguage.nepali    => 'ne_IN',
    _                     => 'en_US',
  };
}
  // ── Core messaging ────────────────────────────────────────

  void _submitMessage(String text, {bool isFromExpert = false}) {
    if (text.isEmpty) return;

    final appLang = LanguageProvider.of(context).currentLanguage;

    setState(() {
      _messages.add(_ChatMessage(
        text: isFromExpert ? '🎤 $text' : text,
        isUser: true,
        type: _MessageType.text,
        fromExpert: isFromExpert,
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    // Bot reply after short delay (feels natural)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final reply = _AgriBot.getReply(text);
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
            text: reply, isUser: false, type: _MessageType.text));
      });
      _scrollToBottom();
      // 🔊 Speak the bot reply automatically
      _speakReply(reply, appLang);
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_isListening) { _stt.stop(); setState(() => _isListening = false); }
    _controller.clear();
    _submitMessage(text);
  }

  void _sendBotMessage(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(
          text: text, isUser: false, type: _MessageType.text));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Image picker ──────────────────────────────────────────

  void _showAttachMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Share with Expert',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _AttachOption(
                icon: Icons.photo_camera_rounded, label: 'Camera',
                color: _primaryGreen,
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              _AttachOption(
                icon: Icons.photo_library_rounded, label: 'Gallery',
                color: const Color(0xFF1565C0),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
              _AttachOption(
                icon: Icons.description_rounded, label: 'Document',
                color: const Color(0xFFE65100),
                onTap: () {
                  Navigator.pop(context);
                  _sendBotMessage('Document sharing is coming soon. Please describe your crop issue in text.');
                },
              ),
            ]),
            const SizedBox(height: 10),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
          source: source, imageQuality: 70, maxWidth: 1024);
      if (file == null) return;
      setState(() {
        _messages.add(_ChatMessage(
            isUser: true, type: _MessageType.image, imagePath: file.path));
      });
      _scrollToBottom();
      Future.delayed(const Duration(milliseconds: 800), () {
        _sendBotMessage(_AgriBot.getReply('photo'));
      });
    } catch (_) {
      _sendBotMessage('Could not access camera/gallery. Check app permissions.');
    }
  }

  // ── Menu ─────────────────────────────────────────────────

  void _showMenu() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 8, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          child: Row(children: [
            Icon(_ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: _primaryGreen, size: 20),
            const SizedBox(width: 12),
            Text(_ttsEnabled ? 'Mute Bot Voice' : 'Unmute Bot Voice'),
          ]),
          onTap: () => Future.delayed(Duration.zero, () {
            setState(() => _ttsEnabled = !_ttsEnabled);
            if (!_ttsEnabled) _stopTts();
          }),
        ),
        PopupMenuItem(
          child: const Row(children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
            SizedBox(width: 12), Text('Clear Chat'),
          ]),
          onTap: () => Future.delayed(Duration.zero, _confirmClearChat),
        ),
        PopupMenuItem(
          child: const Row(children: [
            Icon(Icons.tips_and_updates_rounded,
                color: Color(0xFFE65100), size: 20),
            SizedBox(width: 12), Text('Quick Tips'),
          ]),
          onTap: () => Future.delayed(Duration.zero, _showQuickTips),
        ),
        PopupMenuItem(
          child: const Row(children: [
            Icon(Icons.help_outline_rounded,
                color: Color(0xFF1565C0), size: 20),
            SizedBox(width: 12), Text('Help'),
          ]),
          onTap: () => Future.delayed(Duration.zero, _showHelp),
        ),
      ],
    );
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Chat?'),
        content: const Text('All messages will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _messages.add(_ChatMessage(
                  text: 'Chat cleared. How can I help you today? 🌱',
                  isUser: false, type: _MessageType.text,
                ));
              });
            },
            child: const Text('Clear',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showQuickTips() {
    _sendBotMessage(
      '🌿 Quick Farming Tips:\n\n'
      '1. Water in the morning — reduces fungal risk\n'
      '2. Mulch 3-4 inches around plants — retains moisture\n'
      '3. Rotate crops every season — prevents soil diseases\n'
      '4. Inspect plants weekly — catch pests early\n'
      '5. pH 6.0-7.0 — ideal for most vegetables\n'
      '6. Neem oil spray weekly — prevents most pests\n'
      '7. Compost improves any soil type\n'
      '8. Plant marigolds near vegetables — repels pests naturally',
    );
  }

  void _showHelp() {
    _sendBotMessage(
      '💡 How to use Agri Expert:\n\n'
      '• Type your crop problem\n'
      '• Tap 🎤 mic to speak your question\n'
      '• Tap 📎 to share a crop photo\n'
      '• Use Speak Advisory in Expert screen — query comes here automatically!\n'
      '• Bot reply is spoken aloud — tap speaker icon to mute\n\n'
      '🌾 Try asking:\n'
      '"tomato blight treatment"\n'
      '"yellow leaves"\n'
      '"neem oil how to use"\n'
      '"kharif crops"\n'
      '"potato scab"\n\n'
      '✅ Works 100% offline!',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _stt.stop();
    _tts.stop();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = LanguageProvider.of(context).t;
    return Scaffold(
      backgroundColor: _bgColor,
      body: Column(children: [
        _buildHeader(context, t),
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _buildDateChip(t('today').toUpperCase()),
              const SizedBox(height: 12),
              ..._messages.map((m) => _buildMessageItem(m, t)),
              if (_isTyping) _buildTypingIndicator(),
              const SizedBox(height: 8),
            ],
          ),
        ),
        _buildInputBar(t),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context, String Function(String) t) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2F7F34)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 26),
            ),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t('agri_expert'), style: const TextStyle(
                  color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              Row(children: [
                Container(width: 7, height: 7,
                    decoration: const BoxDecoration(
                        color: Color(0xFF69F0AE), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('Offline • Always available',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            ])),
            // TTS toggle in header
            IconButton(
              onPressed: () {
                setState(() => _ttsEnabled = !_ttsEnabled);
                if (!_ttsEnabled) _stopTts();
              },
              icon: Icon(
                _ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: _ttsEnabled ? Colors.white : Colors.white38, size: 22,
              ),
              tooltip: _ttsEnabled ? 'Mute voice' : 'Unmute voice',
            ),
            IconButton(
              onPressed: _showMenu,
              icon: const Icon(Icons.more_vert_rounded,
                  color: Colors.white, size: 26),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildDateChip(String label) => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xFFDDE8DD),
          borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: const TextStyle(fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 1.5,
          color: Color(0xFF3A6B3A))),
    ),
  );

  Widget _buildMessageItem(_ChatMessage msg, String Function(String) t) =>
      msg.isUser
          ? _UserMessage(message: msg, t: t)
          : _AgentMessage(message: msg, t: t);

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: const Color(0xFFDDE8DD), shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2)),
          child: const Icon(Icons.smart_toy_rounded,
              color: Color(0xFF3A7A3A), size: 20),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
            ),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 6)],
          ),
          child: const _TypingDots(),
        ),
      ]),
    );
  }

  Widget _buildInputBar(String Function(String) t) {
    return Container(
      color: _bgColor,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_isListening)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1565C0).withOpacity(0.08),
            child: Row(children: [
              _PulsingDot(),
              const SizedBox(width: 8),
              const Text('Listening… speak now',
                  style: TextStyle(color: Color(0xFF1565C0),
                      fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  await _stt.stop();
                  setState(() => _isListening = false);
                  if (_controller.text.trim().isNotEmpty) _sendMessage();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Send', style: TextStyle(
                      color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            GestureDetector(
              onTap: _showAttachMenu,
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                    color: Color(0xFFDDE8DD), shape: BoxShape.circle),
                child: const Icon(Icons.attach_file_rounded,
                    color: Color(0xFF4A7A4A), size: 22),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 46),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isListening
                        ? const Color(0xFF1565C0) : Colors.grey.shade200,
                    width: _isListening ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Expanded(child: TextField(
                    controller: _controller,
                    style: const TextStyle(fontSize: 14),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? t('listening_now') : t('type_message'),
                      hintStyle: TextStyle(
                        color: _isListening
                            ? const Color(0xFF1565C0)
                            : const Color(0xFFAAAFAA),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  )),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(Icons.send_rounded,
                          color: _primaryGreen, size: 22),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _toggleMic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: _isListening
                      ? const Color(0xFF1565C0)
                      : _sttAvailable ? _primaryGreen : Colors.grey.shade400,
                  shape: BoxShape.circle,
                  boxShadow: _isListening
                      ? [BoxShadow(
                      color: const Color(0xFF1565C0).withOpacity(0.4),
                      blurRadius: 12, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Icon(
                  _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white, size: 26,
                ),
              ),
            ),
          ]),
        ),
        Text(
          _isListening ? t('tap_stop') : t('hold_speak'),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
              letterSpacing: 2.0, color: Color(0xFFAAAAAA)),
        ),
        const SizedBox(height: 10),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  WIDGETS
// ─────────────────────────────────────────────

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AttachOption({required this.icon, required this.label,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
      child: Column(children: [
        Container(width: 60, height: 60,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 28)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600)),
      ]));
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}
class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..repeat();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _ctrl, builder: (_, __) {
      return Row(mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final offset = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
          final scale = offset < 0.5 ? offset * 2 : (1 - offset) * 2;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: Color.lerp(Colors.grey.shade300,
                  const Color(0xFF2F7F34), scale),
              shape: BoxShape.circle,
            ),
          );
        }));
    });
  }
}

class _PulsingDot extends StatefulWidget {
  @override State<_PulsingDot> createState() => _PulsingDotState();
}
class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.6, end: 1.2)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _scale,
      child: Container(width: 8, height: 8,
          decoration: const BoxDecoration(
              color: Color(0xFF1565C0), shape: BoxShape.circle)));
}

// ─────────────────────────────────────────────
//  MESSAGE MODEL
// ─────────────────────────────────────────────

enum _MessageType { text, voice, image }

class _ChatMessage {
  final String? text;
  final String? duration;
  final String? imagePath;
  final bool isUser;
  final _MessageType type;
  final bool fromExpert;

  const _ChatMessage({
    this.text, this.duration, this.imagePath,
    required this.isUser, required this.type,
    this.fromExpert = false,
  });
}

// ─────────────────────────────────────────────
//  AGENT MESSAGE
// ─────────────────────────────────────────────

class _AgentMessage extends StatelessWidget {
  final _ChatMessage message;
  final String Function(String) t;
  const _AgentMessage({required this.message, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 54, bottom: 4),
          child: Text(t('agri_expert'), style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: Color(0xFF3A7A3A))),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(
                color: const Color(0xFFDDE8DD), shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2)),
            child: const Icon(Icons.smart_toy_rounded,
                color: Color(0xFF3A7A3A), size: 22)),
          const SizedBox(width: 10),
          Flexible(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18),
                bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
              ),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Text(message.text ?? '', style: const TextStyle(
                fontSize: 14, color: Color(0xFF1A1A1A), height: 1.6)),
          )),
          const SizedBox(width: 40),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  USER MESSAGE
// ─────────────────────────────────────────────

class _UserMessage extends StatelessWidget {
  final _ChatMessage message;
  final String Function(String) t;
  const _UserMessage({required this.message, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Padding(
          padding: const EdgeInsets.only(right: 54, bottom: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (message.fromExpert) ...[
              const Icon(Icons.mic_rounded, color: Color(0xFF1565C0), size: 13),
              const SizedBox(width: 4),
              Text(t('nav_expert'), style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: Color(0xFF1565C0))),
            ] else
              Text(t('you'), style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: Color(0xFF3A7A3A))),
          ]),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end, children: [
          const SizedBox(width: 40),
          Flexible(child: _buildBubble()),
          const SizedBox(width: 10),
          Container(width: 40, height: 40,
            decoration: BoxDecoration(
                color: message.fromExpert
                    ? const Color(0xFF1565C0).withOpacity(0.15)
                    : const Color(0xFFDDE8DD),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2)),
            child: Icon(
              message.fromExpert
                  ? Icons.record_voice_over_rounded
                  : Icons.person_rounded,
              color: message.fromExpert
                  ? const Color(0xFF1565C0) : const Color(0xFF8DAF8D),
              size: 22,
            )),
        ]),
      ]),
    );
  }

  Widget _buildBubble() {
    if (message.type == _MessageType.image && message.imagePath != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18), topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4),
        ),
        child: Image.file(File(message.imagePath!),
            width: 200, height: 200, fit: BoxFit.cover),
      );
    }
    if (message.fromExpert) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: Color(0xFF1565C0),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.mic_rounded, color: Colors.white70, size: 15),
          const SizedBox(width: 6),
          Flexible(child: Text(
            message.text?.replaceFirst('🎤 ', '') ?? '',
            style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5),
          )),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF2F7F34),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18), topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4),
        ),
      ),
      child: Text(message.text ?? '', style: const TextStyle(
          fontSize: 14, color: Colors.white, height: 1.5)),
    );
  }
}