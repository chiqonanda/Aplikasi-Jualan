import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../core/theme_provider.dart';
import '../../widgets/navbar/bottom_navbar.dart';
import '../../widgets/cards/connectivity.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  String _name = "User";
  String _email = "email@example.com";
  bool _isLoading = true;

  // ✅ Animasi konsisten
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _fetchUser();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await supabase
          .from('users')
          .select('name, email')
          .eq('id', user.id)
          .single();

      if (!mounted) return;
      setState(() {
        _name = data['name'] ?? "User";
        _email = data['email'] ?? user.email ?? "-";
        _isLoading = false;
      });
      _animController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  // ✅ Logout dengan konfirmasi
  void _logoutDialog(ThemeData theme, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1B1B2F), const Color(0xFF23233A)]
                  : [Colors.white, Colors.grey.shade50],
            ),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 28,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Keluar Akun?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Kamu akan keluar dari akun ini.\nLogin lagi kapan saja.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radius),
                          border: Border.all(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "Batal",
                            style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await supabase.auth.signOut();
                        if (!mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radius),
                          color: Colors.redAccent,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.redAccent.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "Logout",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBg1 : Colors.white,
      extendBody: true,
      bottomNavigationBar: const CustomBottomNavbar(currentIndex: 3),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0A0A14),
                    const Color(0xFF111124),
                    theme.colorScheme.primary.withValues(alpha: 0.18),
                  ]
                : [
                    Colors.white,
                    theme.colorScheme.primary.withValues(alpha: 0.04),
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                    strokeWidth: 2.5,
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(24, 8, 24, 100),
                      children: [

                        // ─────────────────────────────
                        // NAVBAR
                        // ─────────────────────────────
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: Image.asset(
                                'assets/images/profile.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "ARNN.APPREM",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.8,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                                const ConnectivityIndicator(),

                                const SizedBox(width: 50),
                          ],
                        ),


                        const SizedBox(height: 28),

                        // ─────────────────────────────
                        // PROFILE CARD
                        // ─────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFF1B1B2F),
                                      const Color(0xFF23233A),
                                    ]
                                  : [Colors.white, Colors.grey.shade50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : Colors.black.withValues(alpha: 0.04),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.07),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Avatar dengan aura
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          theme.colorScheme.primary
                                              .withValues(alpha: 0.2),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 88,
                                    height: 88,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.4),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.25),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.hardEdge,
                                    child: Image.asset(
                                      'assets/images/profile.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              Text(
                                _name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                _email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ✅ Edit profile button inline
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, '/edit-profile'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 9),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.secondary,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 14,
                                        color: isDark
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Edit Profil",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ─────────────────────────────
                        // DARK MODE TOGGLE — sebagai menu item
                        // ─────────────────────────────
                        _buildToggleItem(
                          icon: isDark
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                          title: "Dark Mode",
                          trailing: Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: themeProvider.isDarkMode,
                              onChanged: (_) => themeProvider.toggleTheme(),
                              activeColor: theme.colorScheme.primary,
                            ),
                          ),
                          theme: theme,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 8),

                        // ─────────────────────────────
                        // MENU ITEMS
                        // ─────────────────────────────
                        _menuGroup(
                          theme: theme,
                          isDark: isDark,
                          items: [
                            _MenuItem(
                              icon: Icons.shopping_bag_outlined,
                              label: "My Orders",
                              route: '/orders',
                              color: Colors.blue,
                            ),
                            _MenuItem(
                              icon: Icons.verified_user_outlined,
                              label: "Garansi",
                              route: '/garansi',
                              color: Colors.green,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _menuGroup(
                          theme: theme,
                          isDark: isDark,
                          items: [
                            _MenuItem(
                              icon: Icons.rule_outlined,
                              label: "Rules & Terms",
                              route: '/rules',
                              color: Colors.orange,
                            ),
                            _MenuItem(
                              icon: Icons.public_outlined,
                              label: "Social Media",
                              route: '/social',
                              color: Colors.purple,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ─────────────────────────────
                        // LOGOUT BUTTON
                        // ─────────────────────────────
                        GestureDetector(
                          onTap: () => _logoutDialog(theme, isDark),
                          child: Container(
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppConstants.radius),
                              color: Colors.redAccent.withValues(alpha: 0.08),
                              border: Border.all(
                                color:
                                    Colors.redAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.logout_rounded,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Logout",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ✅ Version info
                        Center(
                          child: Text(
                            "v1.0.0 • ARNN.APPREM",
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.25),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // WIDGET HELPERS
  // ─────────────────────────────────────

  // ✅ Grup menu dalam satu card
  Widget _menuGroup({
    required ThemeData theme,
    required bool isDark,
    required List<_MenuItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.02),
                ]
              : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;

          return Column(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, item.route),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: item.color.withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          item.icon,
                          size: 18,
                          color: item.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  indent: 64,
                  height: 1,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required Widget trailing,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.02),
                ]
              : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// ✅ Model kecil untuk menu item
class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}