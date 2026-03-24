// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:agrivoice/app_translations.dart';

// ═══════════════════════════════════════════════════════════════
//  CHAT BRIDGE  — Expert Screen → Chat Screen
// ═══════════════════════════════════════════════════════════════
class ChatBridge {
  static VoidCallback? onNavigateToChat;
  static final ValueNotifier<String?> _pendingMessage = ValueNotifier(null);

  static void sendFromExpert(String text) {
    _pendingMessage.value = null;
    Future.microtask(() => _pendingMessage.value = text);
  }

  static String? consume() {
    final msg = _pendingMessage.value;
    _pendingMessage.value = null;
    return msg;
  }

  static ValueNotifier<String?> get stream => _pendingMessage;
}

// ═══════════════════════════════════════════════════════════════
//  LANGUAGE DETECTION  — detects script from user input
// ═══════════════════════════════════════════════════════════════
class LangDetect {
  static bool _hasDevanagari(String s) =>
      s.runes.any((r) => r >= 0x0900 && r <= 0x097F);
  static bool _hasBengali(String s) =>
      s.runes.any((r) => r >= 0x0980 && r <= 0x09FF);
  static bool _hasGurmukhi(String s) =>
      s.runes.any((r) => r >= 0x0A00 && r <= 0x0A7F);
  static bool _hasGujarati(String s) =>
      s.runes.any((r) => r >= 0x0A80 && r <= 0x0AFF);
  static bool _hasOriya(String s) =>
      s.runes.any((r) => r >= 0x0B00 && r <= 0x0B7F);
  static bool _hasTamil(String s) =>
      s.runes.any((r) => r >= 0x0B80 && r <= 0x0BFF);
  static bool _hasTelugu(String s) =>
      s.runes.any((r) => r >= 0x0C00 && r <= 0x0C7F);
  static bool _hasKannada(String s) =>
      s.runes.any((r) => r >= 0x0C80 && r <= 0x0CFF);
  static bool _hasMalayalam(String s) =>
      s.runes.any((r) => r >= 0x0D00 && r <= 0x0D7F);
  static bool _hasArabic(String s) =>
      s.runes.any((r) => r >= 0x0600 && r <= 0x06FF);

  static String detect(String input) {
    if (_hasBengali(input)) return 'bn';
    if (_hasGurmukhi(input)) return 'pa';
    if (_hasGujarati(input)) return 'gu';
    if (_hasOriya(input)) return 'or';
    if (_hasTamil(input)) return 'ta';
    if (_hasTelugu(input)) return 'te';
    if (_hasKannada(input)) return 'kn';
    if (_hasMalayalam(input)) return 'ml';
    if (_hasArabic(input)) return 'ur';
    if (_hasDevanagari(input)) {
      final lower = input.toLowerCase();
      if (lower.contains('मराठी') ||
          lower.contains('शेत') ||
          lower.contains('पिक'))
        return 'mr';
      if (lower.contains('नेपाल') || lower.contains('नेपाली')) return 'ne';
      return 'hi';
    }
    return 'en';
  }
}

// ═══════════════════════════════════════════════════════════════
//  DISEASE CONTEXT  — Holds active plant + disease
// ═══════════════════════════════════════════════════════════════
class DiseaseContext {
  static String? plant;
  static String? disease;

  static void set(String p, String d) {
    plant = p;
    disease = d;
  }

  static void clear() {
    plant = null;
    disease = null;
  }

  static bool get hasContext => plant != null && disease != null;
}

// ═══════════════════════════════════════════════════════════════
//  INTENT DETECTION  — What is the user asking?
// ═══════════════════════════════════════════════════════════════
enum ChatIntent {
  greeting,
  symptom,
  treatment,
  prevention,
  fertilizer,
  watering,
  pest,
  cropInfo,
  unknown,
}

class IntentDetector {
  static const _symptomKeys = [
    'symptom',
    'sign',
    'look like',
    'what is',
    'identify',
    'how to know',
    'लक्षण',
    'पहचान',
    'कैसे पता',
    'लक्षणे',
    'ओळख',
    'அறிகுறி',
    'లక్షణం',
    'ರೋಗಲಕ್ಷಣ',
    'ലക്ഷണം',
    'yellow',
    'spot',
    'curl',
    'wilt',
    'rot',
    'mold',
    'lesion',
    'पीला',
    'धब्बा',
    'झुलसा',
    'पिवळा',
    'डाग',
  ];

  static const _treatmentKeys = [
    'treat',
    'cure',
    'fix',
    'control',
    'kill',
    'spray',
    'apply',
    'medicine',
    'उपचार',
    'दवाई',
    'इलाज',
    'कैसे ठीक',
    'छिड़काव',
    'उपाय',
    'उपचार करा',
    'औषध',
    'how to stop',
    'fungicide',
    'pesticide',
    'neem',
    'இலாக்கு',
    'చికిత్స',
    'ಚಿಕಿತ್ಸೆ',
    'ചികിത്സ',
  ];

  static const _preventionKeys = [
    'prevent',
    'avoid',
    'protect',
    'stop',
    'before',
    'precaution',
    'रोकथाम',
    'बचाव',
    'कैसे बचें',
    'प्रतिबंध',
    'सावधानी',
    'प्रतिबंध',
    'how to avoid',
    'proactive',
    'தடுக்க',
    'నివారణ',
    'ತಡೆಗಟ್ಟುವಿಕೆ',
    'തടയാൻ',
  ];

  static const _fertilizerKeys = [
    'fertilizer',
    'fertilise',
    'nutrient',
    'npk',
    'urea',
    'compost',
    'खाद',
    'उर्वरक',
    'खत',
    'पोषण',
    'कंपोस्ट',
    'உரம்',
    'ఎరువు',
    'ಗೊಬ್ಬರ',
    'വളം',
  ];

  static const _wateringKeys = [
    'water',
    'irrigat',
    'moisture',
    'drip',
    'flood',
    'पानी',
    'सिंचाई',
    'पाणी',
    'जल',
    'தண்ணீர்',
    'నీరు',
    'ನೀರು',
    'വെള്ളം',
  ];

  static const _pestKeys = [
    'pest',
    'insect',
    'bug',
    'aphid',
    'mite',
    'whitefly',
    'caterpillar',
    'कीट',
    'कीड़ा',
    'कीड',
    'माहू',
    'பூச்சி',
    'చీడ',
    'ಕೀಟ',
    'കീടം',
  ];

  static const _cropKeys = [
    'tomato',
    'potato',
    'wheat',
    'rice',
    'corn',
    'maize',
    'onion',
    'chili',
    'brinjal',
    'okra',
    'cucumber',
    'cotton',
    'sugarcane',
    'टमाटर',
    'आलू',
    'गेहूं',
    'चावल',
    'मक्का',
    'प्याज',
    'टोमॅटो',
    'बटाटा',
    'कांदा',
    'தக்காளி',
    'நெல்',
    'கோதுமை',
    'టమాటా',
    'వరి',
    'గోధుమ',
  ];

  static const _greetingKeys = [
    'hello',
    'hi',
    'help',
    'start',
    'hey',
    'नमस्ते',
    'नमस्कार',
    'हेलो',
    'मदद',
    'నమస్కారం',
    'ನಮಸ್ಕಾರ',
    'வணக்கம்',
    'നമസ്കാരം',
    'হ্যালো',
    'নমস্কার',
    'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ',
  ];

  static ChatIntent detect(String input) {
    final lower = input.toLowerCase();
    if (_greetingKeys.any((k) => lower.contains(k))) return ChatIntent.greeting;
    if (_symptomKeys.any((k) => lower.contains(k))) return ChatIntent.symptom;
    if (_treatmentKeys.any((k) => lower.contains(k)))
      return ChatIntent.treatment;
    if (_preventionKeys.any((k) => lower.contains(k)))
      return ChatIntent.prevention;
    if (_fertilizerKeys.any((k) => lower.contains(k)))
      return ChatIntent.fertilizer;
    if (_wateringKeys.any((k) => lower.contains(k))) return ChatIntent.watering;
    if (_pestKeys.any((k) => lower.contains(k))) return ChatIntent.pest;
    if (_cropKeys.any((k) => lower.contains(k))) return ChatIntent.cropInfo;
    return ChatIntent.unknown;
  }
}

// ═══════════════════════════════════════════════════════════════
//  DISEASE DATASET  — The "brain" — plant × disease × intent
// ═══════════════════════════════════════════════════════════════
class DiseaseDataset {
  // Structure: plant → disease → intent → answer
  static const Map<String, Map<String, Map<String, String>>> _data = {
    // ── TOMATO ──────────────────────────────────────────────────
    'tomato': {
      'early_blight': {
        'symptoms':
            '🍅 Early Blight (Alternaria solani) — Symptoms:\n\n'
            '• Dark brown spots with concentric rings (like a target)\n'
            '• Yellow halo surrounding the spots\n'
            '• Starts on OLDER/lower leaves first\n'
            '• Spreads upward as disease progresses\n'
            '• In severe cases: defoliation + fruit infection\n\n'
            '📍 First look at: leaf undersides, older bottom leaves',

        'treatment':
            '🍅 Early Blight — Treatment Plan:\n\n'
            'Step 1 — Immediate:\n'
            '• Remove ALL infected leaves (bag and dispose, do NOT compost)\n'
            '• Sanitize pruning tools with 70% alcohol\n\n'
            'Step 2 — Fungicide:\n'
            '• Mancozeb 75WP → 2.5g per litre water\n'
            '• OR Copper Oxychloride 50WP → 3g per litre\n'
            '• Spray every 7–10 days\n\n'
            'Step 3 — Cultural:\n'
            '• Water at BASE only — never on leaves\n'
            '• Apply mulch to prevent spore splash\n'
            '• Improve air circulation between plants',

        'prevention':
            '🍅 Early Blight — Prevention:\n\n'
            '✅ Before planting:\n'
            '• Use certified disease-free seeds\n'
            '• Choose resistant varieties (eg. Pusa Ruby)\n'
            '• Rotate crops — avoid planting tomato/potato in same spot for 2+ years\n\n'
            '✅ During growing:\n'
            '• Space plants 45–60 cm apart (good airflow)\n'
            '• Stake/cage plants to keep off ground\n'
            '• Apply preventive Mancozeb spray before rains\n'
            '• Remove fallen leaves from soil immediately',
      },
      'late_blight': {
        'symptoms':
            '⚠️ Late Blight (Phytophthora infestans) — Symptoms:\n\n'
            '• Water-soaked, greasy-looking patches on leaves\n'
            '• Patches turn brown-black rapidly\n'
            '• White/grey mold visible on UNDERSIDE of leaves in humid weather\n'
            '• Brown patches on stems\n'
            '• Fruit shows firm brown rot\n\n'
            '🚨 URGENT: Late blight spreads extremely fast — act within 24 hours',

        'treatment':
            '⚠️ Late Blight — EMERGENCY Treatment:\n\n'
            '🚨 URGENT — DO THIS TODAY:\n'
            '• Remove and DESTROY all infected plants/leaves immediately\n'
            '• Do NOT compost — burn or deep-bury\n'
            '• Isolate infected plants from healthy ones\n\n'
            'Fungicide (apply immediately):\n'
            '• Chlorothalonil 75WP → 2g per litre\n'
            '• OR Metalaxyl + Mancozeb (Ridomil Gold) → 2g per litre\n'
            '• Spray every 5–7 days\n\n'
            '⚠️ Spray early morning — allows leaves to dry before evening',

        'prevention':
            '⚠️ Late Blight — Prevention:\n\n'
            '✅ Key actions:\n'
            '• Never water overhead — use drip irrigation\n'
            '• Avoid working in field when plants are wet\n'
            '• Apply Copper hydroxide spray BEFORE monsoon\n'
            '• Remove and destroy plant debris after harvest\n'
            '• Use resistant varieties where available\n'
            '• Monitor weather — high risk when temp 15–20°C + high humidity',
      },
      'mosaic_virus': {
        'symptoms':
            '🦠 Tomato Mosaic Virus — Symptoms:\n\n'
            '• Irregular yellow-green mottling/mosaic on leaves\n'
            '• Leaves may be distorted, crinkled, or cupped\n'
            '• Stunted plant growth\n'
            '• Fruit may show yellow streaks or browning inside\n'
            '• New growth is most visibly affected',

        'treatment':
            '🦠 Mosaic Virus — Treatment:\n\n'
            '⚠️ There is NO chemical cure for mosaic virus.\n\n'
            'What to do:\n'
            '• Remove and DESTROY infected plants to prevent spread\n'
            '• Control aphids immediately (they carry the virus)\n'
            '  → Neem oil 5ml + soap 1ml + 1L water — spray weekly\n'
            '  → Yellow sticky traps to catch aphids\n'
            '• Wash hands and tools before handling healthy plants\n'
            '• Do NOT smoke near plants (tobacco mosaic spreads by touch)',

        'prevention':
            '🦠 Mosaic Virus — Prevention:\n\n'
            '✅ Key actions:\n'
            '• Use virus-resistant/tolerant varieties (look for TMV-resistant on seed packet)\n'
            '• Control aphid populations before they explode\n'
            '• Remove weeds around field (virus reservoir)\n'
            '• Disinfect tools with soap before and after use\n'
            '• Avoid working in wet fields — spreads virus',
      },
      'fusarium_wilt': {
        'symptoms':
            '😵 Fusarium Wilt — Symptoms:\n\n'
            '• Lower leaves turn yellow and droop on ONE side of plant\n'
            '• Wilting despite adequate water\n'
            '• Brown/dark streaks inside stem when cut lengthwise\n'
            '• Plant slowly dies from bottom up',

        'treatment':
            '😵 Fusarium Wilt — Treatment:\n\n'
            '⚠️ There is NO effective cure once severe.\n\n'
            'Early stage:\n'
            '• Apply Trichoderma viride (bio-fungicide) to soil — 5g per litre\n'
            '• Drench soil with Carbendazim 50WP — 1g per litre\n\n'
            'Severe:\n'
            '• Remove and destroy infected plants\n'
            '• Do NOT replant tomato/potato in that soil for 3 years',

        'prevention':
            '😵 Fusarium Wilt — Prevention:\n\n'
            '✅ Most important:\n'
            '• Use Fusarium-resistant varieties (look for "F" resistance symbol)\n'
            '• Solarise soil before planting (cover with clear plastic for 4–6 weeks in summer)\n'
            '• Add Trichoderma to soil at planting time\n'
            '• Rotate crops strictly — no tomato/potato family for 3 years\n'
            '• Avoid waterlogged soil — improves natural disease resistance',
      },
    },

    // ── POTATO ──────────────────────────────────────────────────
    'potato': {
      'late_blight': {
        'symptoms':
            '🥔 Potato Late Blight — Symptoms:\n\n'
            '• Water-soaked dark patches on leaves — turn brown/black fast\n'
            '• White mold on leaf undersides in humid weather\n'
            '• Stem turns black and collapses\n'
            '• Tubers: reddish-brown rot under skin, spreads inward\n\n'
            '🚨 Most destructive potato disease — caused the Irish Famine of 1840s',

        'treatment':
            '🥔 Potato Late Blight — Treatment:\n\n'
            '🚨 Act immediately:\n'
            '• Remove all visibly infected haulm (leaves+stems)\n'
            '• Apply Metalaxyl + Mancozeb (Ridomil Gold) → 2.5g/L — every 7 days\n'
            '• OR Cymoxanil + Mancozeb → 3g/L\n'
            '• Stop overhead irrigation\n'
            '• Earth up potato rows to protect tubers',

        'prevention':
            '🥔 Potato Late Blight — Prevention:\n\n'
            '✅ Actions:\n'
            '• Use certified disease-free seed tubers\n'
            '• Use blight-resistant varieties (Kufri Jyoti, Kufri Bahar)\n'
            '• Spray preventive Copper fungicide before monsoon\n'
            '• Ensure good drainage — avoid waterlogging\n'
            '• Destroy all crop debris after harvest',
      },
      'scab': {
        'symptoms':
            '🥔 Potato Scab — Symptoms:\n\n'
            '• Rough, corky, raised or pitted patches on tuber skin\n'
            '• Brown to dark brown colour\n'
            '• Does NOT affect inside of tuber — mainly cosmetic\n'
            '• Worse in alkaline or dry soils',

        'treatment':
            '🥔 Potato Scab — Treatment:\n\n'
            '• Lower soil pH below 5.5 (add sulfur)\n'
            '• Avoid fresh/uncomposted manure before planting\n'
            '• Keep soil consistently moist during tuber formation\n'
            '• Dip seed tubers in Captan solution before planting',

        'prevention':
            '🥔 Potato Scab — Prevention:\n\n'
            '✅ Key actions:\n'
            '• Rotate crops — avoid potato in same field for 3 years\n'
            '• Maintain soil pH at 5.0–5.5 for potato\n'
            '• Use certified scab-free seed tubers\n'
            '• Avoid applying lime to potato fields',
      },
    },

    // ── WHEAT ────────────────────────────────────────────────────
    'wheat': {
      'rust': {
        'symptoms':
            '🌾 Wheat Rust — Symptoms:\n\n'
            '• Orange-red (stem rust) or yellow (stripe rust) or brown (leaf rust) pustules\n'
            '• Powdery, dusty spores that rub off on fingers\n'
            '• Pustules on leaves, stems, and sometimes glumes\n'
            '• Leaves turn yellow and wither\n'
            '• Heavy infection causes significant yield loss',

        'treatment':
            '🌾 Wheat Rust — Treatment:\n\n'
            '• Apply Propiconazole 25EC → 0.1% at first sign\n'
            '• OR Tebuconazole → 1ml per litre\n'
            '• Repeat spray after 15 days if needed\n'
            '• Apply at Flag Leaf stage for best protection',

        'prevention':
            '🌾 Wheat Rust — Prevention:\n\n'
            '✅ Best protection:\n'
            '• Use rust-resistant varieties (HD-2967, HD-3086, WH-1105)\n'
            '• Timely sowing (avoid late sowing — increases rust risk)\n'
            '• Apply preventive fungicide at tillering stage\n'
            '• Monitor crop weekly from February onwards',
      },
      'powdery_mildew': {
        'symptoms':
            '🌾 Wheat Powdery Mildew — Symptoms:\n\n'
            '• White to grey powdery patches on leaves and stems\n'
            '• Initially on upper leaf surface\n'
            '• Patches enlarge and merge\n'
            '• Leaves turn yellow and die\n'
            '• More severe in cool, humid, cloudy weather',

        'treatment':
            '🌾 Wheat Powdery Mildew — Treatment:\n\n'
            '• Apply Triadimefon 25WP → 0.1% spray\n'
            '• OR Carbendazim 50WP → 1g/L\n'
            '• Spray at first sign — repeat after 10–14 days',

        'prevention':
            '🌾 Wheat Powdery Mildew — Prevention:\n\n'
            '✅ Actions:\n'
            '• Use resistant varieties\n'
            '• Avoid excessive nitrogen (promotes soft growth = higher susceptibility)\n'
            '• Ensure good plant spacing for airflow\n'
            '• Preventive sulfur dust or spray at tillering',
      },
    },

    // ── RICE ─────────────────────────────────────────────────────
    'rice': {
      'blast': {
        'symptoms':
            '🌾 Rice Blast — Symptoms:\n\n'
            '• Diamond/spindle-shaped lesions with grey centre + brown border\n'
            '• On leaves: "blast spots"\n'
            '• On neck of panicle: "neck blast" — panicle breaks off\n'
            '• Severe neck blast = empty grains\n'
            '• High risk: night temperatures 20–25°C + heavy dew/rain',

        'treatment':
            '🌾 Rice Blast — Treatment:\n\n'
            '• Apply Tricyclazole 75WP → 0.6g/L at first sign\n'
            '• OR Isoprothiolane 40EC → 1.5ml/L\n'
            '• Spray at tillering stage + again at panicle initiation\n'
            '• Drain standing water temporarily to slow spread',

        'prevention':
            '🌾 Rice Blast — Prevention:\n\n'
            '✅ Key actions:\n'
            '• Use blast-resistant varieties (IR-64, Pusa Basmati-1)\n'
            '• Avoid excess nitrogen — makes plants more susceptible\n'
            '• Seed treatment with Tricyclazole before sowing\n'
            '• Preventive spray at tillering in blast-prone areas',
      },
      'sheath_blight': {
        'symptoms':
            '🌾 Sheath Blight — Symptoms:\n\n'
            '• Oval/irregular greenish-grey lesions on leaf sheaths\n'
            '• Lesions have dark brown border\n'
            '• In severe cases: lesions reach leaf blade\n'
            '• Infected sheaths rot and leaves die\n'
            '• Worst in humid weather + dense crop stands',

        'treatment':
            '🌾 Sheath Blight — Treatment:\n\n'
            '• Apply Hexaconazole 5EC → 2ml/L\n'
            '• OR Propiconazole 25EC → 1ml/L\n'
            '• Focus spray at base of plant/sheath level\n'
            '• Apply at tillering when disease first appears',

        'prevention':
            '🌾 Sheath Blight — Prevention:\n\n'
            '✅ Actions:\n'
            '• Reduce plant density — do not over-transplant\n'
            '• Avoid excessive nitrogen application\n'
            '• Drain and dry field intermittently\n'
            '• Apply Trichoderma to nursery soil before transplanting',
      },
    },
  };

  // ── Plant name aliases ────────────────────────────────────────
  static const Map<String, String> _plantAliases = {
    // English
    'tomato': 'tomato', 'potato': 'potato', 'wheat': 'wheat',
    'rice': 'rice', 'paddy': 'rice',
    // Hindi
    'टमाटर': 'tomato', 'टमाटा': 'tomato',
    'आलू': 'potato', 'गेहूं': 'wheat', 'धान': 'rice', 'चावल': 'rice',
    // Marathi
    'टोमॅटो': 'tomato', 'बटाटा': 'potato', 'गहू': 'wheat', 'भात': 'rice',
    // Tamil
    'தக்காளி': 'tomato', 'நெல்': 'rice', 'கோதுமை': 'wheat',
    // Telugu
    'టమాటా': 'tomato', 'వరి': 'rice', 'గోధుమ': 'wheat',
    // Kannada
    'ಟೊಮೇಟೊ': 'tomato', 'ಭತ್ತ': 'rice', 'ಗೋಧಿ': 'wheat',
    // Malayalam
    'തക്കാളി': 'tomato', 'നെല്ല്': 'rice', 'ഗോതമ്പ്': 'wheat',
    // Bengali
    'টমেটো': 'tomato', 'আলু': 'potato', 'ধান': 'rice', 'গম': 'wheat',
    // Gujarati
    'ટામેટા': 'tomato', 'ઘઉં': 'wheat', 'ડાંગર': 'rice',
    // Punjabi
    'ਟਮਾਟਰ': 'tomato', 'ਕਣਕ': 'wheat', 'ਝੋਨਾ': 'rice',
    // Urdu
    'ٹماٹر': 'tomato', 'آلو': 'potato', 'گندم': 'wheat', 'چاول': 'rice',
  };

  // ── Disease aliases ───────────────────────────────────────────
  static const Map<String, String> _diseaseAliases = {
    // English
    'early blight': 'early_blight', 'early_blight': 'early_blight',
    'late blight': 'late_blight', 'late_blight': 'late_blight',
    'blight': 'late_blight',
    'mosaic': 'mosaic_virus', 'mosaic virus': 'mosaic_virus',
    'fusarium': 'fusarium_wilt', 'wilt': 'fusarium_wilt',
    'scab': 'scab',
    'rust': 'rust', 'leaf rust': 'rust', 'stem rust': 'rust',
    'powdery mildew': 'powdery_mildew', 'powdery': 'powdery_mildew',
    'blast': 'blast',
    'sheath blight': 'sheath_blight', 'sheath': 'sheath_blight',
    // Hindi
    'झुलसा': 'late_blight', 'अगेती झुलसा': 'early_blight',
    'पछेती झुलसा': 'late_blight', 'मोजेक': 'mosaic_virus',
    'जंग': 'rust', 'करपा (धान)': 'blast',
    // Marathi
    'करपा': 'late_blight', 'लवकर करपा': 'early_blight',
    // Tamil
    'கருகல்': 'blast',
    // Telugu
    'తుప్పు': 'rust',
    // Kannada
    'ತುಕ್ಕು': 'rust',
  };

  /// Resolve plant name from input
  static String? resolvePlant(String input) {
    final lower = input.toLowerCase();
    for (final entry in _plantAliases.entries) {
      if (lower.contains(entry.key.toLowerCase())) return entry.value;
    }
    return null;
  }

  /// Resolve disease name from input
  static String? resolveDisease(String input) {
    final lower = input.toLowerCase();
    // Multi-word first
    final sorted = _diseaseAliases.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in sorted) {
      if (lower.contains(key.toLowerCase())) return _diseaseAliases[key];
    }
    return null;
  }

  /// Get answer for given plant + disease + intent
  static String? getAnswer(String plant, String disease, String intent) {
    return _data[plant]?[disease]?[intent];
  }

  /// Get all diseases available for a plant
  static List<String> diseasesFor(String plant) {
    return _data[plant]?.keys.toList() ?? [];
  }

  /// Pretty disease name
  static String prettyDisease(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return '${w[0].toUpperCase()}${w.substring(1)}';
        })
        .join(' ');
  }
}

// ═══════════════════════════════════════════════════════════════
//  CHAT ENGINE  — The unified brain
// ═══════════════════════════════════════════════════════════════
class ChatEngine {
  /// Returns [reply, suggestedQuestions]
  static (String, List<String>) process(String input) {
    final intent = IntentDetector.detect(input);
    final detectedPlant = DiseaseDataset.resolvePlant(input);
    final detectedDisease = DiseaseDataset.resolveDisease(input);

    // Update context if new plant/disease found
    if (detectedPlant != null) DiseaseContext.plant = detectedPlant;
    if (detectedDisease != null) DiseaseContext.disease = detectedDisease;

    // ── Greeting ────────────────────────────────────────────────
    if (intent == ChatIntent.greeting) {
      DiseaseContext.clear();
      return (
        '🌱 Hello! I am your Agri Expert.\n\n'
            'Tell me:\n'
            '• Which crop are you growing?\n'
            '• What problem are you seeing?\n\n'
            'Example: "tomato early blight symptoms"\n'
            'Or just say: "tomato" to get started!\n\n'
            '✅ Works offline in 23 Indian languages.',
        ['Tomato', 'Potato', 'Wheat', 'Rice', 'Help'],
      );
    }

    // ── Has full context + intent ────────────────────────────────
    if (DiseaseContext.hasContext) {
      final plant = DiseaseContext.plant!;
      final disease = DiseaseContext.disease!;
      final intentKey = _intentToKey(intent);

      if (intentKey != null) {
        final answer = DiseaseDataset.getAnswer(plant, disease, intentKey);
        if (answer != null) {
          return (answer, _suggestionsAfter(intent, plant, disease));
        }
      }

      // Has context but unclear intent — guide them
      return (
        '🌿 I know you\'re asking about '
            '${DiseaseDataset.prettyDisease(disease)} on ${_prettyPlant(plant)}.\n\n'
            'What would you like to know?',
        ['What are symptoms?', 'How to treat?', 'How to prevent?'],
      );
    }

    // ── Has plant but no disease ─────────────────────────────────
    if (DiseaseContext.plant != null) {
      final plant = DiseaseContext.plant!;
      final diseases = DiseaseDataset.diseasesFor(plant);
      final diseaseNames = diseases.map(DiseaseDataset.prettyDisease).toList();
      return (
        '🌱 ${_prettyPlant(plant)} selected!\n\n'
            'Common diseases I can help with:\n'
            '${diseaseNames.map((d) => '• $d').join('\n')}\n\n'
            'Which disease do you want to know about?',
        diseaseNames.take(4).toList(),
      );
    }

    // ── Has disease but no plant — ask for plant ─────────────────
    if (detectedDisease != null && DiseaseContext.plant == null) {
      return (
        '🌿 I see you\'re asking about ${DiseaseDataset.prettyDisease(detectedDisease)}.\n\n'
            'Which crop has this problem?',
        ['Tomato', 'Potato', 'Wheat', 'Rice'],
      );
    }

    // ── Fertilizer (general) ─────────────────────────────────────
    if (intent == ChatIntent.fertilizer) {
      return (
        '🌿 Fertilizer Guide (NPK):\n\n'
            '• N (Nitrogen) → leafy green growth\n'
            '  Sources: Urea (46%), DAP, FYM\n\n'
            '• P (Phosphorus) → root development + flowering\n'
            '  Sources: DAP, Single Superphosphate (SSP)\n\n'
            '• K (Potassium) → fruit quality + disease resistance\n'
            '  Sources: MOP (Muriate of Potash), SOP\n\n'
            '📌 Soil test first — ideal pH 6.0–7.0 for most crops\n'
            '📌 Compost + Vermicompost improve any soil.',
        [
          'Nitrogen deficiency',
          'Phosphorus deficiency',
          'Potassium deficiency',
        ],
      );
    }

    // ── Watering (general) ───────────────────────────────────────
    if (intent == ChatIntent.watering) {
      return (
        '💧 Watering / Irrigation Guide:\n\n'
            '• Water DEEPLY and INFREQUENTLY\n'
            '• Best time: early morning (7–9 AM)\n'
            '• Most vegetables: 1–2 inches per week\n'
            '• Check: push finger 2 inches into soil — water only if dry\n\n'
            '🚿 Drip irrigation saves 30–50% water\n'
            '🌱 Mulch (3–4 inches) retains moisture\n\n'
            '⚠️ Overwatering causes root rot\n'
            '⚠️ Evening watering increases fungal disease risk',
        ['Tomato watering', 'Rice irrigation', 'Wheat watering'],
      );
    }

    // ── Pest (general) ───────────────────────────────────────────
    if (intent == ChatIntent.pest) {
      return (
        '🐛 Common Pest Control:\n\n'
            '🌿 Neem Oil (Universal organic pesticide):\n'
            '5ml neem oil + 1ml dish soap + 1L water\n'
            'Spray in EVENING. Repeat every 7 days.\n\n'
            'Specific pests:\n'
            '• Aphids → strong water spray + neem oil + yellow sticky traps\n'
            '• Whitefly → silver reflective mulch + neem oil + yellow traps\n'
            '• Spider Mites → increase humidity + neem oil spray\n'
            '• Caterpillars → Bt spray (Bacillus thuringiensis) — safe organic\n'
            '• Thrips → blue sticky traps + spinosad spray',
        ['Aphid treatment', 'Whitefly control', 'Caterpillar spray'],
      );
    }

    // ── Crop info (no disease mentioned) ────────────────────────
    if (intent == ChatIntent.cropInfo && DiseaseContext.plant != null) {
      return _getCropGeneralInfo(DiseaseContext.plant!);
    }

    // ── Unknown / fallback ────────────────────────────────────────
    final lang = LangDetect.detect(input);
    return (
      _fallbackByLang(lang),
      ['Tomato disease', 'Wheat rust', 'Rice blast', 'Pest control'],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  static String? _intentToKey(ChatIntent intent) => switch (intent) {
    ChatIntent.symptom => 'symptoms',
    ChatIntent.treatment => 'treatment',
    ChatIntent.prevention => 'prevention',
    _ => null,
  };

  static List<String> _suggestionsAfter(
    ChatIntent intent,
    String plant,
    String disease,
  ) {
    final pretty = DiseaseDataset.prettyDisease(disease);
    return switch (intent) {
      ChatIntent.symptom => [
        'How to treat $pretty?',
        'How to prevent $pretty?',
      ],
      ChatIntent.treatment => [
        'How to prevent $pretty?',
        'What are symptoms of $pretty?',
      ],
      ChatIntent.prevention => [
        'How to treat $pretty?',
        'Other ${_prettyPlant(plant)} diseases',
      ],
      _ => ['How to treat?', 'How to prevent?'],
    };
  }

  static (String, List<String>) _getCropGeneralInfo(String plant) {
    const info = {
      'tomato':
          '🍅 Tomato — Overview:\n\n'
          '• Temperature: 20–27°C (day), 15–20°C (night)\n'
          '• Sun: 6–8 hours daily\n'
          '• Water: 2–3x per week, at base only\n'
          '• Soil pH: 6.0–6.8\n\n'
          'Common diseases:\n'
          '• Early Blight • Late Blight • Mosaic Virus • Fusarium Wilt\n\n'
          'Which disease do you want to know about?',
      'potato':
          '🥔 Potato — Overview:\n\n'
          '• Temperature: 15–20°C ideal\n'
          '• Soil: loose, well-drained, slightly acidic (pH 5.0–5.5)\n'
          '• Water: consistent moisture during tuber formation\n'
          '• Harvest: when leaves yellow and die\n\n'
          'Common diseases:\n'
          '• Late Blight • Scab • Viral Diseases\n\n'
          'Which disease do you want to know about?',
      'wheat':
          '🌾 Wheat — Overview:\n\n'
          '• Season: Rabi (Oct–Nov sowing, Mar–Apr harvest)\n'
          '• Temperature: 10–25°C\n'
          '• Rainfall: 30–100cm\n\n'
          'Common diseases:\n'
          '• Rust (Brown/Yellow/Stem) • Powdery Mildew • Smut\n\n'
          'Which disease do you want to know about?',
      'rice':
          '🌾 Rice — Overview:\n\n'
          '• Season: Kharif (monsoon)\n'
          '• Requires: flooded or consistently moist soil\n'
          '• Temperature: 20–35°C\n\n'
          'Common diseases:\n'
          '• Blast • Sheath Blight • Brown Planthopper\n\n'
          'Which disease do you want to know about?',
    };
    return (
      info[plant] ??
          '🌱 Tell me which disease is affecting your ${_prettyPlant(plant)}.',
      DiseaseDataset.diseasesFor(
        plant,
      ).map(DiseaseDataset.prettyDisease).take(4).toList(),
    );
  }

  static String _prettyPlant(String key) {
    return '${key[0].toUpperCase()}${key.substring(1)}';
  }

  static String _fallbackByLang(String lang) => switch (lang) {
    'hi' =>
      '🤔 मुझे समझ नहीं आया।\n\n'
          'कृपया बताएं:\n'
          '• कौनसी फसल है? (टमाटर, आलू, गेहूं, धान)\n'
          '• क्या समस्या है? (झुलसा, जंग, कीट, पीले पत्ते)\n\n'
          'उदाहरण: "टमाटर पर काले धब्बे"',
    'mr' =>
      '🤔 मला समजले नाही।\n\n'
          'सांगा:\n'
          '• कोणते पीक? (टोमॅटो, बटाटा, गहू, भात)\n'
          '• काय समस्या? (करपा, जंग, कीड)\n\n'
          'उदाहरण: "टोमॅटोवर काळे डाग"',
    'ta' =>
      '🤔 புரியவில்லை.\n\n'
          'சொல்லுங்கள்:\n'
          '• எந்த பயிர்? (தக்காளி, நெல், கோதுமை)\n'
          '• என்ன பிரச்சினை? (Blight, மஞ்சள் இலை, பூச்சி)',
    'te' =>
      '🤔 అర్థం కాలేదు.\n\n'
          'చెప్పండి:\n'
          '• ఏ పంట? (టమాటా, వరి, గోధుమ)\n'
          '• ఏ సమస్య? (Blight, తుప్పు, పసుపు ఆకులు)',
    'kn' =>
      '🤔 ಅರ್ಥವಾಗಲಿಲ್ಲ.\n\n'
          'ಹೇಳಿ:\n'
          '• ಯಾವ ಬೆಳೆ? (ಟೊಮೇಟೊ, ಭತ್ತ, ಗೋಧಿ)\n'
          '• ಯಾವ ಸಮಸ್ಯೆ? (Blight, ತುಕ್ಕು, ಹಳದಿ ಎಲೆ)',
    'ml' =>
      '🤔 മനസ്സിലായില്ല.\n\n'
          'പറയൂ:\n'
          '• ഏത് വിള? (തക്കാളി, നെല്ല്, ഗോതമ്പ്)\n'
          '• എന്ത് പ്രശ്നം? (Blight, തുരുമ്പ്, മഞ്ഞ ഇലകൾ)',
    'bn' =>
      '🤔 বুঝতে পারিনি।\n\n'
          'বলুন:\n'
          '• কোন ফসল? (টমেটো, আলু, ধান, গম)\n'
          '• কী সমস্যা? (Blight, জং, পোকা)',
    _ =>
      '🤔 I didn\'t understand that.\n\n'
          'Please tell me:\n'
          '• Which crop? (tomato, potato, wheat, rice)\n'
          '• What problem? (blight, rust, yellow leaves, pest)\n\n'
          'Example: "tomato early blight symptoms"',
  };
}

// ═══════════════════════════════════════════════════════════════
//  CHAT SCREEN
// ═══════════════════════════════════════════════════════════════

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
  bool _ttsEnabled = true;

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          '🌱 Hello! I am your Agri Expert.\n\n'
          'I can help diagnose crop diseases with:\n'
          '• Symptoms • Treatment • Prevention\n\n'
          'Crops: Tomato • Potato • Wheat • Rice\n'
          'Diseases: Blight • Rust • Blast • Mosaic • Scab\n\n'
          '💬 Type in any Indian language — I detect it automatically!\n'
          '🎤 Use mic to speak • 📎 Share crop photo\n\n'
          '✅ 100% Offline!',
      isUser: false,
      type: _MessageType.text,
    ),
  ];

  // Suggested quick-reply chips
  List<String> _suggestions = [
    'Tomato disease',
    'Wheat rust',
    'Rice blast',
    'Pest control',
    'Fertilizer guide',
  ];

  @override
  void initState() {
    super.initState();
    _initStt();
    _initTts();
    ChatBridge.stream.addListener(_onExpertMessage);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingMessage());
  }

  void _onExpertMessage() {
    final msg = ChatBridge.stream.value;
    if (msg != null && msg.isNotEmpty && mounted) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        _showExpertBanner(msg);
        _submitMessage(msg, isFromExpert: true);
        ChatBridge.stream.value = null;
      });
    }
  }

  void _showExpertBanner(String text) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🎤 "$text"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1565C0),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _checkPendingMessage() {
    final pending = ChatBridge.consume();
    if (pending != null && pending.isNotEmpty) {
      _showExpertBanner(pending);
      _submitMessage(pending, isFromExpert: true);
    }
  }

  Future<void> _initTts() async {
    await _tts.setSharedInstance(true);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  Future<void> _speakReply(String text, String lang) async {
    if (!_ttsEnabled) return;
    final locale = _ttsLocale(lang);
    await _tts.setLanguage(locale);
    final clean = text.replaceAll(
      RegExp(
        r'[^\x00-\x7F\u0900-\u097F\u0980-\u09FF'
        r'\u0A00-\u0A7F\u0A80-\u0AFF\u0B00-\u0B7F\u0C00-\u0C7F'
        r'\u0C80-\u0CFF\u0D00-\u0D7F]',
      ),
      ' ',
    );
    await _tts.speak(clean);
  }

  String _ttsLocale(String lang) => switch (lang) {
    'hi' => 'hi-IN',
    'mr' => 'mr-IN',
    'bn' => 'bn-IN',
    'gu' => 'gu-IN',
    'pa' => 'pa-IN',
    'ta' => 'ta-IN',
    'te' => 'te-IN',
    'kn' => 'kn-IN',
    'ml' => 'ml-IN',
    'ur' => 'ur-IN',
    'or' => 'or-IN',
    _ => 'en-US',
  };

  Future<void> _stopTts() async => await _tts.stop();

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
    setState(() {
      _isListening = true;
      _controller.clear();
    });
    await _stt.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      localeId: _getSttLocale(),
    );
  }

  String _getSttLocale() {
    final lang = LanguageProvider.of(context).currentLanguage;
    return switch (lang) {
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
      _ => 'en_US',
    };
  }

  // ── Core messaging ────────────────────────────────────────────

  void _submitMessage(String text, {bool isFromExpert = false}) {
    if (text.trim().isEmpty) return;

    final detectedLang = LangDetect.detect(text);

    setState(() {
      _messages.add(
        _ChatMessage(
          text: isFromExpert ? '🎤 $text' : text,
          isUser: true,
          type: _MessageType.text,
          fromExpert: isFromExpert,
        ),
      );
      _isTyping = true;
      _suggestions = [];
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      // ── THE BRAIN ──────────────────────────────────────────────
      final (reply, newSuggestions) = ChatEngine.process(text);
      // ──────────────────────────────────────────────────────────

      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(text: reply, isUser: false, type: _MessageType.text),
        );
        _suggestions = newSuggestions;
      });
      _scrollToBottom();
      _speakReply(reply, detectedLang);
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_isListening) {
      _stt.stop();
      setState(() => _isListening = false);
    }
    _controller.clear();
    _submitMessage(text);
  }

  void _sendBotMessage(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add(
        _ChatMessage(text: text, isUser: false, type: _MessageType.text),
      );
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

  // ── Image picker ──────────────────────────────────────────────

  void _showAttachMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Share with Expert',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AttachOption(
                    icon: Icons.photo_camera_rounded,
                    label: 'Camera',
                    color: _primaryGreen,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _AttachOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: const Color(0xFF1565C0),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  _AttachOption(
                    icon: Icons.description_rounded,
                    label: 'Document',
                    color: const Color(0xFFE65100),
                    onTap: () {
                      Navigator.pop(context);
                      _sendBotMessage(
                        'Document sharing coming soon.\n'
                        'Please describe your crop issue in text.',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (file == null) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            isUser: true,
            type: _MessageType.image,
            imagePath: file.path,
          ),
        );
        _suggestions = [];
      });
      _scrollToBottom();
      Future.delayed(const Duration(milliseconds: 800), () {
        _sendBotMessage(
          '📸 Photo received!\n\n'
          'Please also tell me:\n'
          '• Which crop is this?\n'
          '• How long have you seen these symptoms?\n'
          '• Describe what you see (spots, color, shape)\n\n'
          'Example: "tomato — dark spots with yellow ring for 3 days"',
        );
        setState(
          () => _suggestions = [
            'Tomato symptoms',
            'Potato symptoms',
            'Wheat symptoms',
          ],
        );
      });
    } catch (_) {
      _sendBotMessage(
        'Could not access camera/gallery. Check app permissions.',
      );
    }
  }

  // ── Menu ─────────────────────────────────────────────────────

  void _showMenu() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 8, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                _ttsEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: _primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(_ttsEnabled ? 'Mute Bot Voice' : 'Unmute Bot Voice'),
            ],
          ),
          onTap: () => Future.delayed(Duration.zero, () {
            setState(() => _ttsEnabled = !_ttsEnabled);
            if (!_ttsEnabled) _stopTts();
          }),
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.refresh_rounded, color: Color(0xFFE65100), size: 20),
              SizedBox(width: 12),
              Text('New Topic'),
            ],
          ),
          onTap: () => Future.delayed(Duration.zero, () {
            DiseaseContext.clear();
            _sendBotMessage(
              '🔄 Context cleared! Let\'s start fresh.\n\n'
              'Which crop and disease do you want to know about?',
            );
            setState(
              () => _suggestions = [
                'Tomato disease',
                'Wheat rust',
                'Rice blast',
                'Pest control',
              ],
            );
          }),
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
              SizedBox(width: 12),
              Text('Clear Chat'),
            ],
          ),
          onTap: () => Future.delayed(Duration.zero, _confirmClearChat),
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(
                Icons.tips_and_updates_rounded,
                color: Color(0xFFE65100),
                size: 20,
              ),
              SizedBox(width: 12),
              Text('Quick Tips'),
            ],
          ),
          onTap: () => Future.delayed(Duration.zero, _showQuickTips),
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                color: Color(0xFF1565C0),
                size: 20,
              ),
              SizedBox(width: 12),
              Text('Help'),
            ],
          ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              DiseaseContext.clear();
              setState(() {
                _messages.clear();
                _messages.add(
                  const _ChatMessage(
                    text: 'Chat cleared. Which crop do you need help with? 🌱',
                    isUser: false,
                    type: _MessageType.text,
                  ),
                );
                _suggestions = ['Tomato', 'Potato', 'Wheat', 'Rice'];
              });
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showQuickTips() {
    _sendBotMessage(
      '🌿 Quick Farming Tips:\n\n'
      '1. Water in the morning — reduces fungal risk\n'
      '2. Mulch 3–4 inches — retains moisture\n'
      '3. Rotate crops every season — prevents soil diseases\n'
      '4. Inspect plants weekly — catch pests early\n'
      '5. Soil pH 6.0–7.0 — ideal for most vegetables\n'
      '6. Neem oil spray weekly — prevents most pests\n'
      '7. Add compost — improves any soil type\n'
      '8. Plant marigolds near vegetables — repels pests naturally',
    );
  }

  void _showHelp() {
    _sendBotMessage(
      '💡 How to use Agri Expert:\n\n'
      '• Type crop + disease: "tomato blight"\n'
      '• Add intent: "tomato blight symptoms"\n'
      '• Or: "how to treat wheat rust"\n'
      '• Tap 🎤 to speak your question\n'
      '• Tap 📎 to share a crop photo\n'
      '• Tap chips below for quick questions\n\n'
      '🌾 Supported:\n'
      'Crops: Tomato, Potato, Wheat, Rice\n'
      'Intents: Symptoms, Treatment, Prevention\n\n'
      '💬 Works in 23 Indian languages + English\n'
      '✅ 100% Offline!',
    );
  }

  @override
  void dispose() {
    ChatBridge.stream.removeListener(_onExpertMessage);
    _controller.dispose();
    _scrollController.dispose();
    _stt.stop();
    _tts.stop();
    super.dispose();
  }

  // ═════════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final t = LanguageProvider.of(context).t;
    return Scaffold(
      backgroundColor: _bgColor,
      body: Column(
        children: [
          _buildHeader(context, t),
          if (DiseaseContext.hasContext) _buildContextBanner(),
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
          if (_suggestions.isNotEmpty) _buildSuggestions(),
          _buildInputBar(t),
        ],
      ),
    );
  }

  // ── Context banner (shows active plant + disease) ─────────────
  Widget _buildContextBanner() {
    return Container(
      color: const Color(0xFF1B5E20).withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.eco_rounded, color: Color(0xFF2F7F34), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Context: ${_capFirst(DiseaseContext.plant ?? '')} — '
              '${DiseaseDataset.prettyDisease(DiseaseContext.disease ?? '')}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2F7F34),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              DiseaseContext.clear();
              setState(() {
                _suggestions = ['Tomato', 'Potato', 'Wheat', 'Rice'];
              });
            },
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: Color(0xFF2F7F34),
            ),
          ),
        ],
      ),
    );
  }

  String _capFirst(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  // ── Suggestion chips ──────────────────────────────────────────
  Widget _buildSuggestions() {
    return Container(
      color: _bgColor,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _suggestions.map((s) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(s, style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF2F7F34), width: 1),
                labelStyle: const TextStyle(color: Color(0xFF2F7F34)),
                onPressed: () => _submitMessage(s),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String Function(String) t) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2F7F34)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('agri_expert'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF69F0AE),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Offline • Disease Expert',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _ttsEnabled = !_ttsEnabled);
                  if (!_ttsEnabled) _stopTts();
                },
                icon: Icon(
                  _ttsEnabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: _ttsEnabled ? Colors.white : Colors.white38,
                  size: 22,
                ),
              ),
              IconButton(
                onPressed: _showMenu,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip(String label) => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE8DD),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: Color(0xFF3A6B3A),
        ),
      ),
    ),
  );

  Widget _buildMessageItem(_ChatMessage msg, String Function(String) t) =>
      msg.isUser
      ? _UserMessage(message: msg, t: t)
      : _AgentMessage(message: msg, t: t);

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE8DD),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Color(0xFF3A7A3A),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
              ],
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(String Function(String) t) {
    return Container(
      color: _bgColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isListening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF1565C0).withOpacity(0.08),
              child: Row(
                children: [
                  _PulsingDot(),
                  const SizedBox(width: 8),
                  const Text(
                    'Listening… speak now',
                    style: TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      await _stt.stop();
                      setState(() => _isListening = false);
                      if (_controller.text.trim().isNotEmpty) _sendMessage();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Send',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _showAttachMenu,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDDE8DD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.attach_file_rounded,
                      color: Color(0xFF4A7A4A),
                      size: 22,
                    ),
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
                            ? const Color(0xFF1565C0)
                            : Colors.grey.shade200,
                        width: _isListening ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(fontSize: 14),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: _isListening
                                  ? t('listening_now')
                                  : t('type_message'),
                              hintStyle: TextStyle(
                                color: _isListening
                                    ? const Color(0xFF1565C0)
                                    : const Color(0xFFAAAFAA),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.send_rounded,
                              color: _primaryGreen,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleMic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _isListening
                          ? const Color(0xFF1565C0)
                          : _sttAvailable
                          ? _primaryGreen
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1565C0).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _isListening ? t('tap_stop') : t('hold_speak'),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
              color: Color(0xFFAAAAAA),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
//  WIDGETS
// ═════════════════════════════════════════════════════════════════

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
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
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final scale = offset < 0.5 ? offset * 2 : (1 - offset) * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Color.lerp(
                  Colors.grey.shade300,
                  const Color(0xFF2F7F34),
                  scale,
                ),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.6,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFF1565C0),
        shape: BoxShape.circle,
      ),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════
//  MESSAGE MODEL
// ═════════════════════════════════════════════════════════════════

enum _MessageType { text, voice, image }

class _ChatMessage {
  final String? text;
  final String? duration;
  final String? imagePath;
  final bool isUser;
  final _MessageType type;
  final bool fromExpert;

  const _ChatMessage({
    this.text,
    this.duration,
    this.imagePath,
    required this.isUser,
    required this.type,
    this.fromExpert = false,
  });
}

// ═════════════════════════════════════════════════════════════════
//  AGENT MESSAGE
// ═════════════════════════════════════════════════════════════════

class _AgentMessage extends StatelessWidget {
  final _ChatMessage message;
  final String Function(String) t;
  const _AgentMessage({required this.message, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 54, bottom: 4),
            child: Text(
              t('agri_expert'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A7A3A),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE8DD),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Color(0xFF3A7A3A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
//  USER MESSAGE
// ═════════════════════════════════════════════════════════════════

class _UserMessage extends StatelessWidget {
  final _ChatMessage message;
  final String Function(String) t;
  const _UserMessage({required this.message, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 54, bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.fromExpert) ...[
                  const Icon(
                    Icons.mic_rounded,
                    color: Color(0xFF1565C0),
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    t('nav_expert'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ] else
                  Text(
                    t('you'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3A7A3A),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(width: 40),
              Flexible(child: _buildBubble()),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: message.fromExpert
                      ? const Color(0xFF1565C0).withOpacity(0.15)
                      : const Color(0xFFDDE8DD),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  message.fromExpert
                      ? Icons.record_voice_over_rounded
                      : Icons.person_rounded,
                  color: message.fromExpert
                      ? const Color(0xFF1565C0)
                      : const Color(0xFF8DAF8D),
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBubble() {
    if (message.type == _MessageType.image && message.imagePath != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(4),
        ),
        child: Image.file(
          File(message.imagePath!),
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    }
    if (message.fromExpert) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: Color(0xFF1565C0),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.mic_rounded, color: Colors.white70, size: 15),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                message.text?.replaceFirst('🎤 ', '') ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF2F7F34),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Text(
        message.text ?? '',
        style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5),
      ),
    );
  }
}
