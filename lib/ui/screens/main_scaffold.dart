import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../main.dart';
import 'home_screen.dart';
import 'openings_list_screen.dart';
import 'puzzle_screen.dart';
import 'analysis_screen.dart';
import 'profile_screen.dart';
import '../../core/constants.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    OpeningsListScreen(),
    PuzzleScreen(),
    AnalysisScreen(),
    ProfileScreen(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'HOME'),
    _NavItem(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: 'OPENINGS'),
    _NavItem(icon: Icons.extension_outlined, activeIcon: Icons.extension, label: 'PUZZLES'),
    _NavItem(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'ANALYSIS'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'STATS'),
  ];

  void _onTabTapped(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _GrowAppBar(
          isDark: isDark,
          onThemeToggle: () {
            themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
          },
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _GrowBottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: _onTabTapped,
      ),
    );
  }
}

// ============================================================
// Grow App Bar
// ============================================================
class _GrowAppBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onThemeToggle;
  const _GrowAppBar({required this.isDark, required this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightHeader,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.eco, color: Color(0xFF2A2118), size: 20),
          ),
          const SizedBox(width: 10),
          // Title
          Text(
            'Grow Openings',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          // Theme toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: AppColors.primary,
            ),
            onPressed: onThemeToggle,
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
          ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: AppColors.surface(context),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (context) {
                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setModalState) {
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary(context))),
                            const SizedBox(height: 24),
                            ListTile(
                              leading: const Icon(Icons.speed, color: AppColors.primary),
                              title: Text('Engine Depth: ${AppConstants.engineDepth}', style: TextStyle(color: AppColors.textPrimary(context))),
                              subtitle: Slider(
                                value: AppConstants.engineDepth.toDouble(),
                                min: 4,
                                max: 14,
                                divisions: 10,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setModalState(() {
                                    AppConstants.engineDepth = val.toInt();
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.style, color: AppColors.primary),
                              title: Text('Board Style', style: TextStyle(color: AppColors.textPrimary(context))),
                              trailing: const Text('Nature', style: TextStyle(color: Colors.grey)),
                            ),
                            ListTile(
                              leading: const Icon(Icons.info_outline, color: AppColors.primary),
                              title: Text('About', style: TextStyle(color: AppColors.textPrimary(context))),
                              trailing: const Text('v1.0.0', style: TextStyle(color: Colors.grey)),
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Grow Openings v1.0.0 by Magnus Forest'), backgroundColor: AppColors.primary),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    }
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Bottom Navigation
// ============================================================
class _GrowBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _GrowBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary(context),
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary(context),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
