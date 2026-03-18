// ignore_for_file: deprecated_member_use
import 'package:agrivoice/app_transalations.dart';
// ignore: unused_import
import 'package:agrivoice/app_translations.dart';
import 'package:flutter/material.dart';
import 'expert_screen.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

// ─────────────────────────────────────────────
//  ROOT with BOTTOM NAV
// ─────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ExpertScreen(),
    ChatScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BOTTOM NAV
// ─────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = LanguageProvider.of(context).t;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded,        label: t('nav_home'),     selected: currentIndex == 0, onTap: () => onTap(0)),
              _NavItem(icon: Icons.support_agent_rounded, label: t('nav_expert'), selected: currentIndex == 1, onTap: () => onTap(1)),
              _ChatNavItem(label: t('nav_chat'),        selected: currentIndex == 2, onTap: () => onTap(2)),
              _NavItem(icon: Icons.settings_rounded,    label: t('nav_settings'), selected: currentIndex == 3, onTap: () => onTap(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2F7F34) : const Color(0xFF94A3B8);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}

class _ChatNavItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChatNavItem({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2F7F34) : const Color(0xFF94A3B8);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          selected
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F7F34).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chat_rounded, color: Color(0xFF2F7F34), size: 22),
                )
              : Icon(Icons.chat_rounded, color: color, size: 26),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DASHBOARD SCREEN
// ─────────────────────────────────────────────

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _primaryGreen = Color(0xFF2F7F34);

  @override
  Widget build(BuildContext context) {
    final t = LanguageProvider.of(context).t;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: Column(
        children: [
          _buildHeader(context, t),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeroCard(t),
                  const SizedBox(height: 20),
                  _buildScanLeafButton(t),
                  const SizedBox(height: 28),
                  _buildLocalConditions(t),
                  const SizedBox(height: 28),
                  _buildTipsForToday(t),
                  const SizedBox(height: 28),
                  _buildCommonDiseases(t),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String Function(String) t) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(t('app_name'),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              ),
              // Language picker button
              GestureDetector(
                onTap: () => LanguagePickerSheet.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.language_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        AppTranslations.languageInfo[LanguageProvider.of(context).currentLanguage]!.nativeName,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(String Function(String) t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2F7F34).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8, bottom: -8,
            child: Icon(Icons.nature_people_rounded, size: 110, color: Colors.white.withOpacity(0.10)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('welcome_back'),
                  style: TextStyle(color: Colors.white.withOpacity(0.80), fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(t('hello_farmer'),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(t('crops_healthy'),
                  style: TextStyle(color: Colors.white.withOpacity(0.90), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanLeafButton(String Function(String) t) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2F7F34).withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 38),
                ),
                const SizedBox(height: 12),
                Text(t('scan_leaf'),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(t('scan_leaf_sub'),
                    style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalConditions(String Function(String) t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.cloud_rounded, color: _primaryGreen, size: 22),
          const SizedBox(width: 8),
          Text(t('local_conditions'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _WeatherCard(icon: Icons.thermostat_rounded, iconColor: _primaryGreen,     label: t('temp'),     value: '28°C',      valueLarge: true)),
            const SizedBox(width: 10),
            Expanded(child: _WeatherCard(icon: Icons.cloud_rounded,       iconColor: const Color(0xFF94A3B8), label: t('sky'),  value: t('cloudy'), valueLarge: false)),
            const SizedBox(width: 10),
            Expanded(child: _WeatherCard(icon: Icons.water_drop_rounded,  iconColor: _primaryGreen,     label: t('humidity'), value: '60%',        valueLarge: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildTipsForToday(String Function(String) t) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryGreen.withOpacity(0.30), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lightbulb_rounded, color: _primaryGreen, size: 20),
            const SizedBox(width: 8),
            Text(t('tips_today'),
                style: const TextStyle(color: _primaryGreen, fontWeight: FontWeight.w700, fontSize: 15)),
          ]),
          const SizedBox(height: 10),
          Text(t('tips_text'),
              style: const TextStyle(color: Color(0xFF334155), fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildCommonDiseases(String Function(String) t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.grid_view_rounded, color: _primaryGreen, size: 22),
          const SizedBox(width: 8),
          Text(t('common_diseases'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _DiseaseItem(icon: Icons.yard_rounded,        iconColor: Colors.red.shade600,   label: t('tomato')),
            _DiseaseItem(icon: Icons.agriculture_rounded, iconColor: Colors.amber.shade700, label: t('potato')),
            _DiseaseItem(icon: Icons.eco_rounded,         iconColor: Colors.green.shade700, label: t('pepper')),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────

class _WeatherCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool valueLarge;

  const _WeatherCard({required this.icon, required this.iconColor, required this.label, required this.value, required this.valueLarge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2F7F34).withOpacity(0.18), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: valueLarge ? const Color(0xFF2F7F34) : const Color(0xFF1E293B),
                  fontSize: valueLarge ? 18 : 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DiseaseItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _DiseaseItem({required this.icon, required this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2F7F34).withOpacity(0.18), width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, color: iconColor, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}