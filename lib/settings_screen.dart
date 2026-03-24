// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:agrivoice/app_translations.dart';

// ─────────────────────────────────────────────────────────────
//  OFFLINE PROFILE STORE  (no packages — uses static state)
// ─────────────────────────────────────────────────────────────

class _ProfileStore {
  static String name     = 'Rajesh Kumar';
  static String phone    = '+91 98765 43210';
  static String location = 'Pune, Maharashtra';
  static String land     = '4.5 acres';
  static String crops    = 'Wheat, Tomato, Onion';
  static String plan     = 'Agri Plus';
}

// ─────────────────────────────────────────────────────────────
//  SETTINGS SCREEN
// ─────────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _green = Color(0xFF2F7F34);

  bool _weatherAlerts = true;
  bool _pestWarnings  = true;
  bool _dropdownOpen  = false;

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = LanguageProvider.of(context);
    final t = provider.t;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: Column(children: [
        _header(t),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _profileCard(context, t),
            const SizedBox(height: 24),
            _languageSection(context, provider, t),
            const SizedBox(height: 24),
            _farmSection(context, t),
            const SizedBox(height: 24),
            _notificationsSection(t),
            const SizedBox(height: 24),
            _supportSection(t),
            const SizedBox(height: 24),
            _aboutSection(t),
            const SizedBox(height: 24),
            _logoutButton(context, t),
            const SizedBox(height: 32),
          ]),
        )),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _header(String Function(String) t) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
          colors: [Color(0xFF2F7F34), Color(0xFF4CA152)],
          begin: Alignment.centerLeft, end: Alignment.centerRight),
      borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
    ),
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t('settings'), style: const TextStyle(color: Colors.white,
            fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        const SizedBox(height: 2),
        Text(t('empowering'),
            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
      ]),
    )),
  );

  // ── Profile Card ─────────────────────────────────────────
  Widget _profileCard(BuildContext context, String Function(String) t) =>
      Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFF2F7F34), Color(0xFF1B5E20)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(
          color: const Color(0xFF2F7F34).withOpacity(0.35),
          blurRadius: 20, offset: const Offset(0, 6))],
    ),
    child: Row(children: [
      // Avatar circle
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.20),
          border: Border.all(color: Colors.white.withOpacity(0.50), width: 2),
        ),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_ProfileStore.name, style: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Row(children: [
          const Icon(Icons.location_on_rounded, color: Colors.white70, size: 13),
          const SizedBox(width: 3),
          Flexible(child: Text(_ProfileStore.location,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 3),
        Row(children: [
          const Icon(Icons.agriculture_rounded, color: Colors.white70, size: 13),
          const SizedBox(width: 3),
          Flexible(child: Text('${_ProfileStore.land} • ${_ProfileStore.crops}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(20)),
          child: Text(_ProfileStore.plan,
              style: const TextStyle(color: Colors.white,
                  fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ])),
      const SizedBox(width: 8),
      // ── EDIT BUTTON ── now calls _openEditProfile ──────
      GestureDetector(
        onTap: () => _openEditProfile(context, t),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.edit_rounded, color: _green, size: 14),
            const SizedBox(width: 4),
            Text(t('edit_profile'),
                style: const TextStyle(color: _green,
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    ]),
  );

  // ─────────────────────────────────────────────────────────
  //  EDIT PROFILE BOTTOM SHEET  (fully offline)
  // ─────────────────────────────────────────────────────────
  void _openEditProfile(BuildContext context, String Function(String) t) {
    // Temp controllers pre-filled with current data
    final nameCtrl     = TextEditingController(text: _ProfileStore.name);
    final phoneCtrl    = TextEditingController(text: _ProfileStore.phone);
    final locationCtrl = TextEditingController(text: _ProfileStore.location);
    final landCtrl     = TextEditingController(text: _ProfileStore.land);
    final cropsCtrl    = TextEditingController(text: _ProfileStore.crops);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Handle bar
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 16),
              // Title row
              Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                      color: _green.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.edit_rounded, color: _green, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t('edit_profile'), style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
                  Text(t('farmer_profile_sub'),
                      style: const TextStyle(fontSize: 12,
                          color: Color(0xFF94A3B8))),
                ])),
              ]),
              const SizedBox(height: 24),

              // ── Name ──
              _editField(
                ctrl: nameCtrl,
                label: t('full_name'),
                icon: Icons.person_rounded,
                hint: 'e.g. Rajesh Kumar',
              ),
              const SizedBox(height: 14),

              // ── Phone ──
              _editField(
                ctrl: phoneCtrl,
                label: t('phone_number'),
                icon: Icons.phone_rounded,
                hint: '+91 XXXXX XXXXX',
                type: TextInputType.phone,
              ),
              const SizedBox(height: 14),

              // ── Location ──
              _editField(
                ctrl: locationCtrl,
                label: t('location'),
                icon: Icons.location_on_rounded,
                hint: 'e.g. Pune, Maharashtra',
              ),
              const SizedBox(height: 14),

              // ── Land Size ──
              _editField(
                ctrl: landCtrl,
                label: t('land_size'),
                icon: Icons.landscape_rounded,
                hint: 'e.g. 4.5 acres',
                type: TextInputType.text,
              ),
              const SizedBox(height: 14),

              // ── Crops ──
              _editField(
                ctrl: cropsCtrl,
                label: t('crop_history'),
                icon: Icons.grass_rounded,
                hint: 'e.g. Wheat, Tomato, Onion',
              ),
              const SizedBox(height: 28),

              // ── Save button ──
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 20),
                  label: Text(t('save_changes'),
                      style: const TextStyle(color: Colors.white,
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    // Save to offline store
                    _ProfileStore.name     = nameCtrl.text.trim().isEmpty
                        ? _ProfileStore.name : nameCtrl.text.trim();
                    _ProfileStore.phone    = phoneCtrl.text.trim().isEmpty
                        ? _ProfileStore.phone : phoneCtrl.text.trim();
                    _ProfileStore.location = locationCtrl.text.trim().isEmpty
                        ? _ProfileStore.location : locationCtrl.text.trim();
                    _ProfileStore.land     = landCtrl.text.trim().isEmpty
                        ? _ProfileStore.land : landCtrl.text.trim();
                    _ProfileStore.crops    = cropsCtrl.text.trim().isEmpty
                        ? _ProfileStore.crops : cropsCtrl.text.trim();

                    Navigator.pop(ctx);
                    // Rebuild profile card with new data
                    setState(() {});
                    // Success snackbar
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Row(children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(t('profile_updated'),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ]),
                      backgroundColor: _green,
                      duration: const Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ));
                  },
                ),
              ),

              // ── Cancel ──
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity, height: 46,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(t('cancel'),
                      style: const TextStyle(color: Color(0xFF94A3B8),
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
        ),
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      locationCtrl.dispose();
      landCtrl.dispose();
      cropsCtrl.dispose();
    });
  }

  // Helper: single text field for edit sheet
  Widget _editField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType type = TextInputType.text,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
          fontSize: 12, color: Colors.grey.shade600,
          fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _green, size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 2)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
        ),
      ),
    ]);
  }

  // ── Language Dropdown ─────────────────────────────────────
  Widget _languageSection(BuildContext ctx,
      LanguageProvider provider, String Function(String) t) {
    final info = AppTranslations.languageInfo[provider.currentLanguage]!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel(Icons.translate_rounded, t('language')),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: _dropdownOpen
                ? const BorderRadius.only(
                    topLeft: Radius.circular(14), topRight: Radius.circular(14))
                : BorderRadius.circular(14),
            border: Border.all(
                color: _dropdownOpen ? _green : _green.withOpacity(0.25),
                width: _dropdownOpen ? 2 : 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: _green.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(info.flag,
                  style: const TextStyle(fontSize: 22)))),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t('select_language'),
                  style: const TextStyle(fontSize: 12,
                      color: Color(0xFF94A3B8))),
              Text(info.nativeName, style: const TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            ])),
            AnimatedRotation(
              turns: _dropdownOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: _green, size: 28),
            ),
          ]),
        ),
      ),
      AnimatedCrossFade(
        duration: const Duration(milliseconds: 250),
        crossFadeState: _dropdownOpen
            ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: const SizedBox(width: double.infinity),
        secondChild: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14)),
            border: const Border(
                left:   BorderSide(color: _green, width: 2),
                right:  BorderSide(color: _green, width: 2),
                bottom: BorderSide(color: _green, width: 2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07),
                blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12)),
            child: ListView.builder(
              shrinkWrap: true, padding: EdgeInsets.zero,
              itemCount: AppTranslations.allLanguages.length,
              itemBuilder: (_, i) {
                final lang = AppTranslations.allLanguages[i];
                final li = AppTranslations.languageInfo[lang]!;
                final sel = provider.currentLanguage == lang;
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  if (i > 0) Divider(height: 1,
                      color: _green.withOpacity(0.10),
                      indent: 14, endIndent: 14),
                  InkWell(
                    onTap: () {
                      provider.setLanguage(lang);
                      setState(() => _dropdownOpen = false);
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text('${li.flag}  ${li.nativeName}',
                            style: const TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        backgroundColor: _green,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ));
                    },
                    child: Container(
                      color: sel
                          ? _green.withOpacity(0.06) : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      child: Row(children: [
                        Text(li.flag,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(li.nativeName, style: TextStyle(fontSize: 14,
                              fontWeight: sel
                                  ? FontWeight.w700 : FontWeight.w500,
                              color: sel
                                  ? _green : const Color(0xFF1E293B))),
                          Text(li.name, style: const TextStyle(
                              fontSize: 11, color: Color(0xFF94A3B8))),
                        ])),
                        if (sel) Container(width: 26, height: 26,
                          decoration: const BoxDecoration(
                              color: _green, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 15)),
                      ]),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ),
      ),
    ]);
  }

  // ── Farm / Account Section ────────────────────────────────
  Widget _farmSection(BuildContext context, String Function(String) t) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionLabel(Icons.agriculture_rounded, t('account_profile')),
    const SizedBox(height: 10),
    _card([
      _menuItem(Icons.badge_rounded, t('farmer_profile'),
          t('farmer_profile_sub'), true,
          () => _openEditProfile(context, t)),           // ← opens edit sheet
      _menuItem(Icons.landscape_rounded, t('my_farm'),
          t('my_farm_sub'), true, () {}),
      _menuItem(Icons.history_rounded, t('crop_history'),
          t('crop_history_sub'), false, () {}),
    ]),
  ]);

  // ── Notifications ─────────────────────────────────────────
  Widget _notificationsSection(String Function(String) t) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionLabel(Icons.notifications_rounded, t('notifications')),
    const SizedBox(height: 10),
    _card([
      _toggleItem(Icons.cloud_rounded, t('weather_alerts'),
          _weatherAlerts, true,
          (v) => setState(() => _weatherAlerts = v)),
      _toggleItem(Icons.pest_control_rounded, t('pest_warnings'),
          _pestWarnings, false,
          (v) => setState(() => _pestWarnings = v)),
    ]),
  ]);

  // ── Support ───────────────────────────────────────────────
  Widget _supportSection(String Function(String) t) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionLabel(Icons.help_rounded, t('help_support')),
    const SizedBox(height: 10),
    _card([
      _menuItem(Icons.payments_rounded, t('subscription'),
          t('subscription_sub'), true, () {}),
      _menuItem(Icons.help_outline_rounded, t('help_support'),
          t('help_support_sub'), false, () {}),
    ]),
  ]);

  // ── About ─────────────────────────────────────────────────
  Widget _aboutSection(String Function(String) t) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionLabel(Icons.info_rounded, t('about')),
    const SizedBox(height: 10),
    Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withOpacity(0.10)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Container(width: 64, height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF2F7F34), Color(0xFF1B5E20)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 36)),
        const SizedBox(height: 12),
        Text('${t('app_name')} v2.4.0',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(t('empowering'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _outlineBtn(t('privacy_policy'), () {})),
          const SizedBox(width: 10),
          Expanded(child: _outlineBtn(t('terms_of_use'), () {})),
        ]),
      ]),
    ),
  ]);

  // ── Logout ────────────────────────────────────────────────
  Widget _logoutButton(BuildContext context, String Function(String) t) =>
      Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.red.shade200),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Material(
      color: Colors.transparent, borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(t('logout')),
            content: Text(t('logout_sub')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: Text(t('cancel'))),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('confirm'),
                    style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.logout_rounded,
                  color: Colors.red.shade600, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t('logout'), style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: Colors.red.shade700)),
              Text(t('logout_sub'),
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF94A3B8))),
            ])),
            Icon(Icons.chevron_right_rounded,
                color: Colors.red.shade300, size: 22),
          ]),
        ),
      ),
    ),
  );

  // ── Shared Helpers ────────────────────────────────────────
  Widget _sectionLabel(IconData icon, String label) => Row(children: [
    Icon(icon, color: _green, size: 20),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
  ]);

  Widget _card(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _green.withOpacity(0.10)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(children: children),
  );

  Widget _menuItem(IconData icon, String title, String subtitle,
      bool divider, VoidCallback onTap) =>
      Column(children: [
    InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(
                color: _green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _green, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700)),
            Text(subtitle, style: const TextStyle(
                fontSize: 11, color: Color(0xFF94A3B8))),
          ])),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8), size: 22),
        ]),
      )),
    if (divider) Divider(height: 1,
        color: _green.withOpacity(0.10), indent: 14, endIndent: 14),
  ]);

  Widget _toggleItem(IconData icon, String label, bool value,
      bool divider, ValueChanged<bool> onChanged) =>
      Column(children: [
    Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF94A3B8), size: 24),
        const SizedBox(width: 14),
        Expanded(child: Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600))),
        Transform.scale(scale: 0.9, child: Switch(
          value: value, onChanged: onChanged,
          activeThumbColor: Colors.white, activeTrackColor: _green,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFE2E8F0),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        )),
      ])),
    if (divider) Divider(height: 1,
        color: _green.withOpacity(0.10), indent: 14, endIndent: 14),
  ]);

  Widget _outlineBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
          color: _green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(label, style: const TextStyle(
          color: _green, fontSize: 13, fontWeight: FontWeight.w700))),
    ),
  );
}