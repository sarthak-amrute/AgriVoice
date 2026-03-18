// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

// ─────────────────────────────────────────────────────────────
//  GLOBAL CHAT BRIDGE  (connects Expert Screen → Chat Screen)
// ─────────────────────────────────────────────────────────────

class ChatBridge {
  static String? _pendingMessage;

  /// Called from ExpertScreen after voice recognition completes
  static void sendFromExpert(String message) {
    _pendingMessage = message;
  }

  /// Called from ChatScreen on init to consume pending message
  static String? consume() {
    final msg = _pendingMessage;
    _pendingMessage = null;
    return msg;
  }

  static bool get hasPending => _pendingMessage != null;
}

// ─────────────────────────────────────────────────────────────
//  OFFLINE AGRICULTURE CHATBOT ENGINE
// ─────────────────────────────────────────────────────────────

class _AgriBot {
  static const Map<String, String> _kb = {
    // Greetings
    'hello': 'Hello! I am your offline Agri Expert. Ask me about crop diseases, pests, watering, or farming tips.',
    'hi': 'Hi there! How can I help with your crops today?',
    'help': 'I can help with: plant diseases, pest control, watering schedules, fertilizers, soil health, and general crop care.',
    'thanks': 'You are welcome! Feel free to ask anything about your crops.',

    // Tomato
    'tomato': 'Tomatoes need full sun (6-8 hrs), deep watering 2-3x/week, and well-drained soil. Common diseases: early blight, late blight, fusarium wilt, mosaic virus.',
    'blight': 'Blight is caused by fungus/oomycete. Remove infected leaves immediately. Apply copper-based fungicide. Avoid overhead watering. Improve air circulation by spacing plants 24 inches apart.',
    'early blight': 'Early blight (Alternaria) shows dark spots with yellow rings on lower leaves. Prune infected leaves, apply mancozeb or copper fungicide, and mulch soil to prevent spore splash.',
    'late blight': 'Late blight (Phytophthora) is very aggressive — water-soaked spots that turn brown. Remove all infected plants. Apply chlorothalonil fungicide immediately. Do not compost infected material.',
    'mosaic': 'Mosaic virus causes mottled yellow-green leaves. No cure — remove infected plants. Control aphids which spread it. Use virus-resistant varieties next season.',

    // Potato
    'potato': 'Potatoes need loose, well-drained soil and consistent moisture. Harvest when leaves yellow. Common issues: blight, scab, aphids, and black leg disease.',
    'scab': 'Potato scab is caused by bacteria in alkaline soil. Lower soil pH below 5.5 using sulfur. Avoid fresh manure. Rotate crops every 3 years.',

    // General diseases
    'yellow': 'Yellowing leaves indicate: nitrogen deficiency (add balanced fertilizer), overwatering (check drainage), or viral infection. Check roots for rot and soil moisture first.',
    'curl': 'Leaf curling causes: heat stress (mulch and water more), aphid infestation (check underside of leaves), viral infection (check for mosaic pattern), or herbicide damage.',
    'spot': 'Leaf spots are usually fungal. Remove affected leaves. Avoid wetting foliage. Apply neem oil or copper fungicide. Ensure good air circulation between plants.',
    'wilt': 'Wilting causes: underwatering (water deeply), root rot (improve drainage), fusarium/verticillium wilt (soil-borne fungus — rotate crops), or stem borer damage.',
    'rot': 'Root rot is caused by overwatering and poor drainage. Let soil dry between waterings. Add perlite to improve drainage. Remove severely affected plants to prevent spread.',
    'rust': 'Rust fungus shows as orange/brown powdery spots. Apply sulfur-based fungicide. Remove heavily infected leaves. Avoid overhead irrigation.',
    'mold': 'Mold/mildew thrives in humid conditions. Improve ventilation. Apply baking soda solution (1 tsp per liter) or potassium bicarbonate as organic treatment.',
    'powdery mildew': 'Powdery mildew appears as white powder on leaves. Apply neem oil or sulfur spray. Water at base of plant. Ensure good air circulation.',
    'damping off': 'Damping off kills seedlings at soil level. Use sterile potting mix. Avoid overwatering. Apply cinnamon powder as natural fungicide on soil surface.',

    // Pests
    'pest': 'Common pests: aphids, whiteflies, spider mites, thrips, caterpillars. Use neem oil for organic control. Introduce beneficial insects like ladybugs. Inspect plants weekly.',
    'aphid': 'Aphids cluster under leaves and on new growth. Spray with neem oil or insecticidal soap. Introduce ladybugs. Strong water spray can dislodge them.',
    'whitefly': 'Whiteflies spread viruses. Use yellow sticky traps. Apply neem oil in early morning. Reflective mulch repels them. Avoid over-fertilizing with nitrogen.',
    'mite': 'Spider mites thrive in hot dry conditions. Increase humidity. Apply neem oil or miticide. Introduce predatory mites. Keep plants well-watered.',
    'caterpillar': 'Caterpillars chew leaves and fruit. Handpick at night. Apply Bt (Bacillus thuringiensis) spray — safe organic option. Use neem oil as deterrent.',
    'thrip': 'Thrips cause silvery streaks on leaves. Remove heavily infested leaves. Apply spinosad or neem oil. Use blue sticky traps. Avoid over-fertilizing.',
    'nematode': 'Root nematodes cause stunted growth and root galls. Rotate crops. Add marigolds as companion plants. Soil solarization helps. Use neem cake in soil.',

    // Watering
    'water': 'General watering rules: water deeply and infrequently. Morning watering is best. Most vegetables need 1-2 inches per week. Check soil moisture 2 inches deep before watering.',
    'irrigation': 'Drip irrigation is most efficient — reduces disease and water usage by 30-50%. Water at root zone, not on leaves. Use mulch to retain moisture.',
    'overwater': 'Signs of overwatering: yellowing leaves, mushy stems, root rot, fungal growth. Allow soil to dry 2-3 inches deep before next watering.',
    'drought': 'Drought stress signs: wilting, leaf scorch, premature fruit drop. Mulch heavily, water deeply at base. Shade cloth can reduce heat stress by 30%.',

    // Fertilizer
    'fertilizer': 'Use NPK: high nitrogen (N) for leafy growth, high phosphorus (P) for roots and flowers, high potassium (K) during fruiting. Test soil pH before applying.',
    'nitrogen': 'Nitrogen deficiency: pale yellow leaves starting from older leaves. Apply urea or ammonium sulfate. Compost and manure are excellent organic nitrogen sources.',
    'phosphorus': 'Phosphorus deficiency: purple/reddish leaves, poor root development. Apply bone meal or superphosphate. Ensure soil pH 6-7 for best phosphorus availability.',
    'potassium': 'Potassium deficiency: brown leaf edges, weak stems, poor fruit quality. Apply potash or wood ash. Essential for disease resistance and fruit development.',
    'compost': 'Compost improves soil structure, water retention, and provides slow-release nutrients. Apply 2-3 inches on soil surface. Make at home with kitchen scraps and dry leaves.',
    'manure': 'Use aged/composted manure only — fresh manure can burn plants and spread pathogens. Apply 2-4 weeks before planting. Excellent source of NPK and micronutrients.',

    // Soil
    'soil': 'Healthy soil has: pH 6.0-7.0 for most crops, good drainage, organic matter > 3%, and abundant earthworms. Test soil every 2-3 years for best results.',
    'ph': 'Soil pH affects nutrient availability. Most vegetables prefer 6.0-7.0. Add lime to raise pH, sulfur to lower it. Test before amending.',
    'clay': 'Clay soil drains poorly. Add compost, sand, and perlite to improve drainage. Raised beds are excellent for clay soil areas.',
    'sandy': 'Sandy soil drains too fast. Add compost and organic matter to improve water retention. Mulch heavily. Water more frequently with smaller amounts.',

    // Crops
    'wheat': 'Wheat needs cool temperatures during growth. Common diseases: wheat rust, powdery mildew, smut. Apply fungicide at flag leaf stage for best protection.',
    'rice': 'Rice needs flooded fields or consistently moist soil. Common issues: blast, sheath blight, brown plant hopper. Use resistant varieties and balanced fertilization.',
    'corn': 'Corn needs warm soil (>15°C to plant), full sun, and consistent moisture. Common issues: corn borer, grey leaf spot, rust. Plant in blocks for good pollination.',
    'onion': 'Onions need well-drained soil and full sun. Stop watering when tops fall over. Common issues: thrips, purple blotch, downy mildew.',
    'garlic': 'Plant garlic in autumn. Needs well-drained soil. Common issues: rust and white rot. Harvest when lower leaves turn yellow.',
    'chili': 'Chilies need warm temperatures and full sun. Common issues: anthracnose, bacterial wilt, and mites. Avoid overwatering — prefers slightly dry conditions.',
    'pepper': 'Bell peppers need consistent moisture and warm temperatures. Common issues: bacterial spot, Phytophthora blight, aphids. Calcium deficiency causes blossom end rot.',
    'brinjal': 'Brinjal (eggplant) needs full sun and warm weather. Common pests: shoot borer, whitefly, aphids. Apply neem oil weekly as preventive measure.',
    'okra': 'Okra thrives in hot weather and well-drained soil. Common issues: yellow vein mosaic virus (spread by whiteflies), root rot. Harvest every 2-3 days.',
    'cucumber': 'Cucumbers need consistent moisture and full sun. Common issues: powdery mildew, cucumber mosaic virus, downy mildew. Train on trellis for better air circulation.',

    // Photo analysis
    'photo': 'You have shared an image. For best disease detection, please also describe: which crop it is, how long symptoms have been present, and weather conditions recently.',
    'image': 'Image received. I can see the crop. Please describe the symptoms you are observing for a more accurate diagnosis.',
    'picture': 'Thanks for sharing the photo. Describe the symptoms and I can give detailed treatment advice.',

    // Expert screen queries
    'advisory': 'I can help explain the advisory in more detail. Which crop are you concerned about — tomato, potato, pepper, or another crop?',
    'treatment': 'For treatment advice: 1) Remove all infected leaves immediately. 2) Apply copper-based fungicide. 3) Improve air circulation. 4) Water at soil level only. Which crop needs treatment?',
    'scan': 'After scanning a leaf, you get the disease name and confidence score. You can ask me about that specific disease here for detailed treatment steps.',
    'disease': 'To help with disease treatment, please tell me: the crop name, the disease detected, and what symptoms you see (spots, yellowing, wilting, etc.).',

    // Seasons
    'summer': 'Summer crops: tomato, pepper, cucumber, okra, corn, watermelon. Protect from heat stress with mulching and adequate watering. Watch for spider mites in hot dry weather.',
    'winter': 'Winter crops: wheat, mustard, peas, potato, spinach, carrot. Protect from frost with row covers. Reduce watering frequency in cold weather.',
    'monsoon': 'Monsoon tips: ensure good drainage to prevent root rot. Watch for fungal diseases in high humidity. Reduce irrigation. Apply fungicide preventively.',
    'kharif': 'Kharif crops (monsoon season): rice, maize, cotton, sugarcane, groundnut, soybean. Sown in June-July, harvested in October-November.',
    'rabi': 'Rabi crops (winter season): wheat, barley, mustard, peas, gram. Sown in October-November, harvested in March-April.',

    // Organic farming
    'organic': 'Organic pest control: neem oil, insecticidal soap, Bt spray, diatomaceous earth, companion planting. Organic fertilizers: compost, vermicompost, bone meal, fish meal.',
    'neem': 'Neem oil is a versatile organic pesticide and fungicide. Mix 5ml neem oil + 1ml dish soap per liter of water. Spray in evening. Effective against 200+ pests.',
    'companion': 'Companion planting: marigolds repel nematodes and whiteflies. Basil repels aphids near tomatoes. Garlic deters many pests. Nasturtiums attract aphids away from main crops.',
  };

  static String getReply(String input) {
    final lower = input.toLowerCase();

    // Greetings first
    for (final key in ['hello', 'hi ', 'thanks']) {
      if (lower.startsWith(key) || lower == key.trim()) {
        return _kb[key.trim()]!;
      }
    }

    // Multi-word matches first
    final multiWord = ['early blight', 'late blight', 'powdery mildew',
        'damping off', 'spider mite', 'overwater'];
    for (final key in multiWord) {
      if (lower.contains(key)) return _kb[key]!;
    }

    // Single keyword match
    for (final entry in _kb.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }

    // Fallback
    return 'I am not sure about that specific issue. Could you describe:\n\n'
        '• Which crop is affected?\n'
        '• What do the symptoms look like?\n'
        '• How long has this been happening?\n\n'
        'Or try keywords like: blight, yellow leaves, pest, watering, fertilizer.';
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

  bool _sttAvailable = false;
  bool _isListening = false;
  bool _isTyping = false;

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: "Hello! I'm your offline Agri Expert 🌱\n\nI can help with crop diseases, pests, watering, fertilizers, and more — all offline.\n\nYou can type, speak, or share a photo!\n\n💡 Tip: Use the Speak Advisory in Expert screen to send your voice query here automatically.",
      isUser: false,
      type: _MessageType.text,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initStt();
    // Check for pending message from Expert Screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingMessage();
    });
  }

  /// Consume any message sent from ExpertScreen via ChatBridge
  void _checkPendingMessage() {
    final pending = ChatBridge.consume();
    if (pending != null && pending.isNotEmpty) {
      // Show a banner notifying the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Voice query from Expert: "$pending"',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            )),
          ]),
          backgroundColor: const Color(0xFF1565C0),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      // Auto-submit the message
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
        if (mounted) {
          setState(() {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length));
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      localeId: 'hi_IN',
    );
  }

  // ── Attachment picker ─────────────────────────────────────────
  void _showAttachMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Share with Expert',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
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
                      _sendBotMessage('Document sharing is coming soon. Please describe your crop issue in text for now.');
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
          source: source, imageQuality: 70, maxWidth: 1024);
      if (file == null) return;
      setState(() {
        _messages.add(_ChatMessage(
          isUser: true, type: _MessageType.image, imagePath: file.path,
        ));
      });
      _scrollToBottom();
      Future.delayed(const Duration(milliseconds: 800), () {
        _sendBotMessage(_AgriBot.getReply('photo'));
      });
    } catch (_) {
      _sendBotMessage('Could not access camera or gallery. Please check app permissions.');
    }
  }

  // ── Core messaging ────────────────────────────────────────────

  /// Used by both manual send and ChatBridge
  void _submitMessage(String text, {bool isFromExpert = false}) {
    if (text.isEmpty) return;

    setState(() {
      if (isFromExpert) {
        // Show a special "from Expert" user bubble
        _messages.add(_ChatMessage(
          text: '🎤 $text',
          isUser: true,
          type: _MessageType.text,
          fromExpert: true,
        ));
      } else {
        _messages.add(_ChatMessage(text: text, isUser: true, type: _MessageType.text));
      }
      _isTyping = true;
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final reply = _AgriBot.getReply(text);
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
            text: reply, isUser: false, type: _MessageType.text));
      });
      _scrollToBottom();
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
      _messages.add(_ChatMessage(text: text, isUser: false, type: _MessageType.text));
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

  // ── Three-dot menu ────────────────────────────────────────────
  void _showMenu() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 8, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          child: const Row(children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
            SizedBox(width: 12), Text('Clear Chat'),
          ]),
          onTap: () => Future.delayed(Duration.zero, _confirmClearChat),
        ),
        PopupMenuItem(
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF2F7F34), size: 20),
            SizedBox(width: 12), Text('About Bot'),
          ]),
          onTap: () => Future.delayed(Duration.zero, _showAbout),
        ),
        PopupMenuItem(
          child: const Row(children: [
            Icon(Icons.tips_and_updates_rounded, color: Color(0xFFE65100), size: 20),
            SizedBox(width: 12), Text('Quick Tips'),
          ]),
          onTap: () => Future.delayed(Duration.zero, _showQuickTips),
        ),
        PopupMenuItem(
          child: const Row(children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFF1565C0), size: 20),
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
        content: const Text('All messages will be deleted. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.smart_toy_rounded, color: Color(0xFF2F7F34)),
          SizedBox(width: 8), Text('About Agri Expert'),
        ]),
        content: const Text(
          'Agri Expert is a fully offline AI chatbot trained on agricultural knowledge.\n\n'
          '• 50+ crop disease responses\n'
          '• Pest identification & control\n'
          '• Watering & fertilizer advice\n'
          '• Supports voice input from Expert screen\n'
          '• Photo-based consultation\n\n'
          'Version 1.0.0 • No internet required',
          style: TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF2F7F34))),
          ),
        ],
      ),
    );
  }

  void _showQuickTips() {
    _sendBotMessage(
      '🌿 Quick Tips:\n\n'
      '1. Water in the morning to reduce fungal risk\n'
      '2. Mulch around plants to retain moisture\n'
      '3. Rotate crops every season to prevent soil diseases\n'
      '4. Inspect plants weekly for early pest detection\n'
      '5. Maintain soil pH 6.0-7.0 for best nutrient uptake\n'
      '6. Use neem oil as a safe all-purpose pesticide',
    );
  }

  void _showHelp() {
    _sendBotMessage(
      '💡 How to use:\n\n'
      '• Type your crop problem in the text box\n'
      '• Tap the 🎤 mic button to speak your question\n'
      '• Tap 📎 to share a photo of your crop\n'
      '• Use Speak Advisory in Expert screen — your voice query is sent here automatically!\n'
      '• Try keywords: blight, yellow leaves, aphid, water, fertilizer, tomato, potato\n\n'
      'Works 100% offline!',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _stt.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildDateChip('TODAY'),
                const SizedBox(height: 12),
                ..._messages.map((m) => _buildMessageItem(m)),
                if (_isTyping) _buildTypingIndicator(),
                const SizedBox(height: 8),
              ],
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
              ),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20), shape: BoxShape.circle),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Agri Expert',
                        style: TextStyle(color: Colors.white, fontSize: 17,
                            fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                    Text('Offline • Always available',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
                child: const Center(
                  child: Text('i', style: TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _showMenu,
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip(String label) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0xFFDDE8DD),
            borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            letterSpacing: 1.5, color: Color(0xFF3A6B3A))),
      ),
    );
  }

  Widget _buildMessageItem(_ChatMessage msg) =>
      msg.isUser ? _UserMessage(message: msg) : _AgentMessage(message: msg);

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFFDDE8DD), shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2)),
            child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF3A7A3A), size: 20),
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          borderRadius: BorderRadius.circular(20)),
                      child: const Text('Send',
                          style: TextStyle(color: Colors.white,
                              fontSize: 12, fontWeight: FontWeight.w700)),
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
                                  ? 'Listening...' : 'Ask about your crops...',
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
                          ),
                        ),
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(Icons.send_rounded,
                                color: _primaryGreen, size: 22),
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
              ],
            ),
          ),
          Text(
            _isListening ? 'TAP TO STOP' : 'TAP MIC TO SPEAK',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                letterSpacing: 2.0, color: Color(0xFFAAAAAA)),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ATTACH OPTION
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TYPING DOTS
// ─────────────────────────────────────────────

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
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

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
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: Color.lerp(
                    Colors.grey.shade300, const Color(0xFF2F7F34), scale),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  PULSING DOT
// ─────────────────────────────────────────────

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
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.6, end: 1.2)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(width: 8, height: 8,
          decoration: const BoxDecoration(
              color: Color(0xFF1565C0), shape: BoxShape.circle)),
    );
  }
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
    this.text,
    this.imagePath,
    required this.isUser,
    required this.type,
    this.fromExpert = false, this.duration,
  });
}

// ─────────────────────────────────────────────
//  AGENT MESSAGE
// ─────────────────────────────────────────────

class _AgentMessage extends StatelessWidget {
  final _ChatMessage message;
  const _AgentMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 54, bottom: 4),
            child: Text('Agri Expert',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: Color(0xFF3A7A3A))),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: const Color(0xFFDDE8DD), shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Color(0xFF3A7A3A), size: 22),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
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
                  child: Text(message.text ?? '',
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF1A1A1A), height: 1.6)),
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

// ─────────────────────────────────────────────
//  USER MESSAGE
// ─────────────────────────────────────────────

class _UserMessage extends StatelessWidget {
  final _ChatMessage message;
  const _UserMessage({required this.message});

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
                  const Icon(Icons.mic_rounded,
                      color: Color(0xFF1565C0), size: 13),
                  const SizedBox(width: 4),
                  const Text('From Expert',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0))),
                ] else
                  const Text('You',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: Color(0xFF3A7A3A))),
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
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: const Color(0xFFDDE8DD), shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
                child: ClipOval(child: Container(
                  color: message.fromExpert
                      ? const Color(0xFF1565C0).withOpacity(0.7)
                      : const Color(0xFF8DAF8D),
                  child: Icon(
                    message.fromExpert
                        ? Icons.record_voice_over_rounded
                        : Icons.person_rounded,
                    color: Colors.white, size: 26,
                  ),
                )),
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
          topLeft: Radius.circular(18), topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4),
        ),
        child: Image.file(File(message.imagePath!),
            width: 200, height: 200, fit: BoxFit.cover),
      );
    }
    if (message.type == _MessageType.voice) {
      return _VoiceBubble(duration: message.duration ?? '0:00');
    }
    // Expert-sourced messages get a blue tint
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.mic_rounded, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                message.text?.replaceFirst('🎤 ', '') ?? '',
                style: const TextStyle(
                    fontSize: 15, color: Colors.white, height: 1.5),
              ),
            ),
          ],
        ),
      );
    }
    return _TextBubble(text: message.text ?? '');
  }
}

// ─────────────────────────────────────────────
//  TEXT BUBBLE
// ─────────────────────────────────────────────

class _TextBubble extends StatelessWidget {
  final String text;
  const _TextBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF2F7F34),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18), topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4),
        ),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.5)),
    );
  }
}

// ─────────────────────────────────────────────
//  VOICE BUBBLE
// ─────────────────────────────────────────────

class _VoiceBubble extends StatefulWidget {
  final String duration;
  const _VoiceBubble({required this.duration});

  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<_VoiceBubble> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF2F7F34),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18), topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _playing = !_playing),
            child: Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: const Color(0xFF2F7F34), size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.55, minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.30),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )),
          const SizedBox(width: 10),
          Text(widget.duration,
              style: const TextStyle(color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}