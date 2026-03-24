// ignore_for_file: deprecated_member_use
import 'package:agrivoice/app_translations.dart';
import 'package:agrivoice/scan_history_screen.dart';
import 'package:flutter/material.dart';
import 'expert_screen.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

// ─────────────────────────────────────────────
//  MAIN SHELL
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
  void initState() {
    super.initState();
    // Expert screen sends voice query → auto-switch to Chat tab
    ChatBridge.onNavigateToChat = () {
      if (mounted) setState(() => _currentIndex = 2);
    };
  }

  @override
  void dispose() {
    ChatBridge.onNavigateToChat = null;
    super.dispose();
  }

  // Called by drawer items to switch tabs from inside DashboardScreen
  void switchTab(int index) => setState(() => _currentIndex = index);

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
        border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                  icon: Icons.home_rounded,
                  label: t('nav_home'),
                  selected: currentIndex == 0,
                  onTap: () => onTap(0)),
              _NavItem(
                  icon: Icons.support_agent_rounded,
                  label: t('nav_expert'),
                  selected: currentIndex == 1,
                  onTap: () => onTap(1)),
              _ChatNavItem(
                  label: t('nav_chat'),
                  selected: currentIndex == 2,
                  onTap: () => onTap(2)),
              _NavItem(
                  icon: Icons.settings_rounded,
                  label: t('nav_settings'),
                  selected: currentIndex == 3,
                  onTap: () => onTap(3)),
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
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? const Color(0xFF2F7F34) : const Color(0xFF94A3B8);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: color)),
      ]),
    );
  }
}

class _ChatNavItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChatNavItem(
      {required this.label,
      required this.selected,
      required this.onTap});

  
  @override
  Widget build(BuildContext context) {
    final color =
        selected ? const Color(0xFF2F7F34) : const Color(0xFF94A3B8);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        selected
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F7F34).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chat_rounded,
                    color: Color(0xFF2F7F34), size: 22))
            : Icon(Icons.chat_rounded, color: color, size: 26),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: color)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  DASHBOARD SCREEN
// ─────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _primaryGreen = Color(0xFF2F7F34);

  // Key to open drawer programmatically
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Controls red badge on bell
  bool _hasNewNotification = true;

  // ── Helper: find MainShell ancestor to switch tabs ──
  void _switchTab(int index) {
    // Close drawer first, then switch tab
    Navigator.of(context).pop();
    final shell = context.findAncestorStateOfType<_MainShellState>();
    shell?.switchTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final t = LanguageProvider.of(context).t;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F8F6),
      drawer: _buildDrawer(context, t),
      body: Column(children: [
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
                ]),
          ),
        ),
      ]),
    );
  }

  // ── DRAWER ──────────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context, String Function(String) t) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header with farmer info
          DrawerHeader(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_rounded,
                      color: Color(0xFF2F7F34), size: 34),
                ),
                const SizedBox(height: 10),
                Text(t('hello_farmer'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                Text('Pune, Maharashtra',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12)),
              ],
            ),
          ),

          // ── Home ──
          _DrawerItem(
            icon: Icons.home_rounded,
            label: t('nav_home'),
            onTap: () {
              Navigator.pop(context); // just close drawer, already on home
            },
          ),

          // ── Expert ── navigates to tab 1
          _DrawerItem(
            icon: Icons.support_agent_rounded,
            label: t('nav_expert'),
            onTap: () => _switchTab(1),
          ),

          // ── Chat ── navigates to tab 2
          _DrawerItem(
            icon: Icons.chat_rounded,
            label: t('nav_chat'),
            onTap: () => _switchTab(2),
          ),

          // ── Scan History ──
          _DrawerItem(
          icon: Icons.history_rounded,
          label: 'Scan History',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScanHistoryScreen(),  // ← no const
              ),
            );
          },
        ),

          // ── Market Prices ──
          _DrawerItem(
            icon: Icons.bar_chart_rounded,
            label: 'Market Prices',
            onTap: () {
              Navigator.pop(context);
              _showComingSoon('Market Prices');
            },
          ),

          // ── My Farm ──
          _DrawerItem(
            icon: Icons.grass_rounded,
            label: t('my_farm'),
            onTap: () {
              Navigator.pop(context);
              _showComingSoon(t('my_farm'));
            },
          ),

          // In main_dashboard_screen.dart drawer:
        _DrawerItem(
          icon: Icons.history_rounded,
          label: 'Scan History',
          onTap: () {
            Navigator.pop(context);
            var push = Navigator.push(context, MaterialPageRoute(
                builder: (_) => ScanHistoryScreen(),
            ));
          },

        ),
          const Divider(indent: 16, endIndent: 16),

          // ── Settings ── navigates to tab 3
          _DrawerItem(
            icon: Icons.settings_rounded,
            label: t('nav_settings'),
            onTap: () => _switchTab(3),
          ),

          // ── Logout ──
          _DrawerItem(
            icon: Icons.logout_rounded,
            label: t('logout'),
            color: Colors.red,
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context, t);
            },
          ),
        ],
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String Function(String) t) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            // ── Hamburger — opens Drawer ──
            GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: const Icon(Icons.menu_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Text(t('app_name'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3)),
            ),

            // ── Language picker ──
            GestureDetector(
              onTap: () => LanguagePickerSheet.show(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  const Icon(Icons.language_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    AppTranslations
                        .languageInfo[LanguageProvider.of(context)
                            .currentLanguage]!
                        .nativeName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),

            // ── Notification Bell with red badge ──
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () {
                    if (_hasNewNotification) {
                      setState(() => _hasNewNotification = false);
                    }
                    _showNotificationsSheet(context, t);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 22),
                  ),
                ),
                if (_hasNewNotification)
                  Positioned(
                    right: 7,
                    top: 7,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  // ── NOTIFICATIONS SHEET ──────────────────────────────────────────
  void _showNotificationsSheet(
      BuildContext context, String Function(String) t) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Notifications',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('3 alerts for your farm',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            // ── Tapping a notification navigates to relevant tab ──
            _NotifTile(
              icon: Icons.warning_amber_rounded,
              color: Colors.orange,
              title: 'Blight Risk Alert',
              subtitle:
                  'High humidity detected — check potato leaves today.',
              time: '2 hrs ago',
              onTap: () {
                Navigator.pop(context); // close sheet
                // Navigate to Expert tab
                final shell = context
                    .findAncestorStateOfType<_MainShellState>();
                shell?.switchTab(1);
              },
            ),
            _NotifTile(
              icon: Icons.wb_sunny_rounded,
              color: Colors.amber,
              title: 'Weather Update',
              subtitle: 'Rain expected tomorrow morning in your area.',
              time: '5 hrs ago',
              onTap: () => Navigator.pop(context),
            ),
            _NotifTile(
              icon: Icons.check_circle_rounded,
              color: Colors.green,
              title: 'Scan Complete',
              subtitle:
                  'Your tomato leaf scan was analyzed successfully.',
              time: 'Yesterday',
              onTap: () {
                Navigator.pop(context);
                // Navigate to Chat tab to see result
                final shell = context
                    .findAncestorStateOfType<_MainShellState>();
                shell?.switchTab(2);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── COMING SOON SNACKBAR ─────────────────────────────────────────
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature — Coming soon!'),
      backgroundColor: _primaryGreen,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── LOGOUT DIALOG ────────────────────────────────────────────────
  void _showLogoutDialog(
      BuildContext context, String Function(String) t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(t('logout')),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Logout',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── HERO CARD ────────────────────────────────────────────────────
  Widget _buildHeroCard(String Function(String) t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF2F7F34).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ],
      ),
      child: Stack(children: [
        Positioned(
          right: -8,
          bottom: -8,
          child: Icon(Icons.nature_people_rounded,
              size: 110,
              color: Colors.white.withOpacity(0.10)),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t('welcome_back'),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.80),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(t('hello_farmer'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(t('crops_healthy'),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.90),
                  fontSize: 13)),
        ]),
      ]),
    );
  }

  // ── SCAN LEAF BUTTON ─────────────────────────────────────────────
  Widget _buildScanLeafButton(String Function(String) t) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF2F7F34).withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          // Tapping Scan Leaf → goes to Expert tab (tab 1)
          onTap: () {
            final shell =
                context.findAncestorStateOfType<_MainShellState>();
            shell?.switchTab(1);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    shape: BoxShape.circle),
                child: const Icon(Icons.photo_camera_rounded,
                    color: Colors.white, size: 38),
              ),
              const SizedBox(height: 12),
              Text(t('scan_leaf'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(t('scan_leaf_sub'),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.70),
                      fontSize: 13)),
            ]),
          ),
        ),
      ),
    );
  }

  // ── LOCAL CONDITIONS ─────────────────────────────────────────────
  Widget _buildLocalConditions(String Function(String) t) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.cloud_rounded,
                color: _primaryGreen, size: 22),
            const SizedBox(width: 8),
            Text(t('local_conditions'),
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _WeatherCard(
                    icon: Icons.thermostat_rounded,
                    iconColor: _primaryGreen,
                    label: t('temp'),
                    value: '28°C',
                    valueLarge: true)),
            const SizedBox(width: 10),
            Expanded(
                child: _WeatherCard(
                    icon: Icons.cloud_rounded,
                    iconColor: const Color(0xFF94A3B8),
                    label: t('sky'),
                    value: t('cloudy'),
                    valueLarge: false)),
            const SizedBox(width: 10),
            Expanded(
                child: _WeatherCard(
                    icon: Icons.water_drop_rounded,
                    iconColor: _primaryGreen,
                    label: t('humidity'),
                    value: '60%',
                    valueLarge: true)),
          ]),
        ]);
  }

  // ── TIPS FOR TODAY ───────────────────────────────────────────────
  Widget _buildTipsForToday(String Function(String) t) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _primaryGreen.withOpacity(0.30), width: 1),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.lightbulb_rounded,
                  color: _primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(t('tips_today'),
                  style: const TextStyle(
                      color: _primaryGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ]),
            const SizedBox(height: 10),
            Text(t('tips_text'),
                style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 13,
                    height: 1.6)),
          ]),
    );
  }
  // Add in _DashboardScreenState, call inside build after _buildTipsForToday:
  Widget _buildHealthSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryGreen.withOpacity(0.15)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.monitor_heart_rounded,
              color: Color(0xFF2F7F34), size: 20),
          SizedBox(width: 8),
          Text('Crop Health Summary',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _HealthChip(label: 'Tomato', status: 'At Risk',
              color: Colors.orange),
          const SizedBox(width: 8),
          _HealthChip(label: 'Potato', status: 'Healthy',
              color: Colors.green),
          const SizedBox(width: 8),
          _HealthChip(label: 'Wheat', status: 'Healthy',
              color: Colors.green),
        ]),
      ]),
    );
  }

  // ── COMMON DISEASES ──────────────────────────────────────────────
  Widget _buildCommonDiseases(String Function(String) t) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.grid_view_rounded,
                color: _primaryGreen, size: 22),
            const SizedBox(width: 8),
            Text(t('common_diseases'),
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Each disease taps → Expert tab
                GestureDetector(
                  onTap: () {
                    final shell = context
                        .findAncestorStateOfType<_MainShellState>();
                    shell?.switchTab(1);
                  },
                  child: _DiseaseItem(
                      icon: Icons.yard_rounded,
                      iconColor: Colors.red.shade600,
                      label: t('tomato')),
                ),
                GestureDetector(
                  onTap: () {
                    final shell = context
                        .findAncestorStateOfType<_MainShellState>();
                    shell?.switchTab(1);
                  },
                  child: _DiseaseItem(
                      icon: Icons.agriculture_rounded,
                      iconColor: Colors.amber.shade700,
                      label: t('potato')),
                ),
                GestureDetector(
                  onTap: () {
                    final shell = context
                        .findAncestorStateOfType<_MainShellState>();
                    shell?.switchTab(1);
                  },
                  child: _DiseaseItem(
                      icon: Icons.eco_rounded,
                      iconColor: Colors.green.shade700,
                      label: t('pepper')),
                ),
              ]),
        ]);
  }
}

// ─────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _DrawerItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF2F7F34);
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label,
          style: TextStyle(
              color: color ?? const Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
              fontSize: 14)),
      onTap: onTap,
      dense: true,
      horizontalTitleGap: 8,
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final VoidCallback onTap;
  const _NotifTile(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle,
      required this.time,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        Text(time,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400)),
                      ]),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600)),
                ]),
          ),
        ]),
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool valueLarge;
  const _WeatherCard(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.value,
      required this.valueLarge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF2F7F34).withOpacity(0.18),
            width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF94A3B8), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
              color: valueLarge
                  ? const Color(0xFF2F7F34)
                  : const Color(0xFF1E293B),
              fontSize: valueLarge ? 18 : 13,
              fontWeight: FontWeight.w700,
            )),
      ]),
    );
  }
}

class _DiseaseItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _DiseaseItem(
      {required this.icon,
      required this.iconColor,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: const Color(0xFF2F7F34).withOpacity(0.18),
              width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icon, color: iconColor, size: 30),
      ),
      const SizedBox(height: 8),
      Text(label,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500)),
    ]);
  }
}
class _HealthChip extends StatelessWidget {
  final String label;
  final String status;
  final Color color;
  const _HealthChip({required this.label,
      required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.30)),
        ),
        child: Column(children: [
          Icon(
            status == 'Healthy'
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
            color: color, size: 20,
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700)),
          Text(status,
              style: TextStyle(fontSize: 10, color: color,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
