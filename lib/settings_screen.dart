// ignore_for_file: deprecated_member_use
import 'package:agrivoice/app_transalations.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _primaryGreen = Color(0xFF2F7F34);

  bool _weatherAlerts = true;
  bool _pestWarnings = true;
  bool _languageDropdownOpen = false;

  @override
  Widget build(BuildContext context) {
    final provider = LanguageProvider.of(context);
    final t = provider.t;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: Column(
        children: [
          _buildHeader(context, t),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLanguageSection(context, provider, t),
                  const SizedBox(height: 32),
                  _buildAccountSection(),
                  const SizedBox(height: 32),
                  _buildNotificationsSection(t),
                  const SizedBox(height: 32),
                  _buildAboutSection(t),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String Function(String) t) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2F7F34), Color(0xFF4CA152)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 4),
              Text(
                t('settings'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Language Section ─────────────────────────────────────────
  Widget _buildLanguageSection(
      BuildContext context,
      LanguageProvider provider,
      String Function(String) t) {
    final currentInfo =
        AppTranslations.languageInfo[provider.currentLanguage]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(children: [
          const Icon(Icons.translate_rounded, color: _primaryGreen, size: 22),
          const SizedBox(width: 8),
          Text(t('language'),
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),

        // ── Dropdown trigger card ────────────────────────────
        GestureDetector(
          onTap: () =>
              setState(() => _languageDropdownOpen = !_languageDropdownOpen),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: _languageDropdownOpen
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14))
                  : BorderRadius.circular(14),
              border: Border.all(
                color: _languageDropdownOpen
                    ? _primaryGreen
                    : _primaryGreen.withOpacity(0.25),
                width: _languageDropdownOpen ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                // Flag badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _primaryGreen.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(currentInfo.flag,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                // Current language name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t('select_language'),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 2),
                      Text(currentInfo.nativeName,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
                // Animated chevron
                AnimatedRotation(
                  turns: _languageDropdownOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: _primaryGreen, size: 28),
                ),
              ],
            ),
          ),
        ),

        // ── Animated dropdown list ───────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: _languageDropdownOpen
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Container(
            constraints: const BoxConstraints(maxHeight: 340),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: const Border(
                left:   BorderSide(color: _primaryGreen, width: 2),
                right:  BorderSide(color: _primaryGreen, width: 2),
                bottom: BorderSide(color: _primaryGreen, width: 2),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: AppTranslations.allLanguages.length,
                itemBuilder: (ctx, index) {
                  final lang = AppTranslations.allLanguages[index];
                  final info = AppTranslations.languageInfo[lang]!;
                  final selected = provider.currentLanguage == lang;
                  final isLast =
                      index == AppTranslations.allLanguages.length - 1;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index > 0)
                        Divider(
                            height: 1,
                            color: _primaryGreen.withOpacity(0.10),
                            indent: 14,
                            endIndent: 14),
                      InkWell(
                        onTap: () {
                          provider.setLanguage(lang);
                          setState(() => _languageDropdownOpen = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${info.flag}  ${info.nativeName}',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: _primaryGreen,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                        borderRadius: isLast
                            ? const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12))
                            : BorderRadius.zero,
                        child: Container(
                          color: selected
                              ? _primaryGreen.withOpacity(0.06)
                              : Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          child: Row(
                            children: [
                              Text(info.flag,
                                  style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      info.nativeName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: selected
                                            ? _primaryGreen
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(info.name,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8))),
                                  ],
                                ),
                              ),
                              if (selected)
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                      color: _primaryGreen,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 15),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Account Section ──────────────────────────────────────────
  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Icons.person_rounded, 'Account & Profile'),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: _primaryGreen.withOpacity(0.10), width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              _ProfileMenuItem(
                icon: Icons.badge_rounded,
                title: 'Farmer Profile',
                subtitle: 'Edit your land and crop details',
                showDivider: true,
                onTap: () {},
              ),
              _ProfileMenuItem(
                icon: Icons.payments_rounded,
                title: 'Subscription',
                subtitle: 'View your current Agri Plus plan',
                showDivider: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Notifications Section ────────────────────────────────────
  Widget _buildNotificationsSection(String Function(String) t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Icons.notifications_rounded, t('notifications')),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: _primaryGreen.withOpacity(0.10), width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              _ToggleMenuItem(
                icon: Icons.cloud_rounded,
                label: 'Weather Alerts',
                value: _weatherAlerts,
                showDivider: true,
                onChanged: (v) => setState(() => _weatherAlerts = v),
              ),
              _ToggleMenuItem(
                icon: Icons.pest_control_rounded,
                label: 'Pest Warnings',
                value: _pestWarnings,
                showDivider: false,
                onChanged: (v) => setState(() => _pestWarnings = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── About Section ─────────────────────────────────────────────
  Widget _buildAboutSection(String Function(String) t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Icons.info_rounded, '${t('about')} Agri Voice'),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: _primaryGreen.withOpacity(0.10), width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2F7F34), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.eco_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 12),
              Text('${t('app_name')} v2.4.0',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Empowering farmers through technology',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF94A3B8))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _AboutButton(
                          label: 'Privacy Policy', onTap: () {})),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _AboutButton(
                          label: 'Terms of Use', onTap: () {})),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _primaryGreen, size: 22),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  PROFILE MENU ITEM
// ─────────────────────────────────────────────

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showDivider;
  final VoidCallback onTap;
  static const _primaryGreen = Color(0xFF2F7F34);

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _primaryGreen, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8), size: 22),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
              height: 1,
              color: _primaryGreen.withOpacity(0.10),
              indent: 14,
              endIndent: 14),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  TOGGLE MENU ITEM
// ─────────────────────────────────────────────

class _ToggleMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final bool showDivider;
  final ValueChanged<bool> onChanged;
  static const _primaryGreen = Color(0xFF2F7F34);

  const _ToggleMenuItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.showDivider,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF94A3B8), size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: Colors.white,
                  activeTrackColor: _primaryGreen,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE2E8F0),
                  trackOutlineColor:
                      WidgetStateProperty.all(Colors.transparent),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
              height: 1,
              color: _primaryGreen.withOpacity(0.10),
              indent: 14,
              endIndent: 14),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  ABOUT BUTTON
// ─────────────────────────────────────────────

class _AboutButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  static const _primaryGreen = Color(0xFF2F7F34);

  const _AboutButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _primaryGreen.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: _primaryGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}