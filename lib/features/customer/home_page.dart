import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../widgets/navbar/bottom_navbar.dart';
import '../../widgets/shared/section_header.dart';
import '../../services/product_service.dart';
import '../../widgets/cards/connectivity.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final _productService = ProductService();

  String _userName = "User";
  List _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ✅ Animasi konsisten
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _fetchUser();
    _fetchProducts();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchUser() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('users')
          .select('name')
          .eq('id', user.id)
          .single();

      if (!mounted) return;
      setState(() => _userName = data['name'] ?? "User");
    } catch (_) {
      // Gagal fetch nama tidak perlu crash halaman
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _productService.getProducts();
      if (!mounted) return;
      setState(() {
        _products = data;
        _isLoading = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  String _getPrice(Map product) {
    final variants = product['product_variants'] ?? [];
    if (variants.isEmpty) return "N/A";
    return "Rp ${variants[0]['price']}";
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Selamat pagi";
    if (hour < 15) return "Selamat siang";
    if (hour < 18) return "Selamat sore";
    return "Selamat malam";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBg1 : Colors.white,
      extendBody: true,
      bottomNavigationBar: const CustomBottomNavbar(currentIndex: 0),
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
              : _errorMessage != null
                  ? _errorState(theme)
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                          children: [

                            // ─────────────────────────────
                            // NAVBAR
                            // ─────────────────────────────
                            _buildNavbar(theme, isDark),

                            const SizedBox(height: 24),

                            // ─────────────────────────────
                            // HERO GREETING
                            // ─────────────────────────────
                            _buildHeroSection(theme, isDark),

                            const SizedBox(height: 28),

                            // ─────────────────────────────
                            // POPULAR APPS
                            // ─────────────────────────────
                            SectionHeader(
                              title: "Popular Apps",
                              actionText: "Lihat Semua",
                              onTap: () =>
                                  Navigator.pushNamed(context, '/products'),
                            ),

                            const SizedBox(height: 14),

                            _buildPopularApps(theme, isDark),

                            const SizedBox(height: 28),

                            // ─────────────────────────────
                            // BEST SELLERS
                            // ─────────────────────────────
                            SectionHeader(
                              title: "Best Sellers",
                              actionText: "Lihat Semua",
                              onTap: () =>
                                  Navigator.pushNamed(context, '/products'),
                            ),

                            const SizedBox(height: 14),

                            _buildBestSellers(theme, isDark),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // WIDGET BUILDERS
  // ─────────────────────────────────────

  Widget _buildNavbar(ThemeData theme, bool isDark) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 10,
              ),
            ],
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

        const Spacer(),
        const ConnectivityIndicator(),

      ],
    );
  }

  Widget _buildHeroSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status chip
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.green.withValues(alpha: 0.12),
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    "STATUS: ONLINE",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Greeting
        Text(
          _greetingText(),
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),

        const SizedBox(height: 4),

        // Nama user
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "Hello, ",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextSpan(
                text: _userName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              TextSpan(
                text: " 👋",
                style: TextStyle(
                  fontSize: 26,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Your subscription fleet is operating at peak efficiency.",
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),

        const SizedBox(height: 20),

        // ✅ Banner promo
        _buildPromoBanner(theme, isDark),
      ],
    );
  }

  Widget _buildPromoBanner(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/products'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: const Text(
                      "PROMO",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Akses Premium\nSekarang!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.black : Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Cek semua produk tersedia →",
                    style: TextStyle(
                      fontSize: 12,
                      color: (isDark ? Colors.black : Colors.white)
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.workspace_premium_rounded,
              size: 52,
              color: (isDark ? Colors.black : Colors.white)
                  .withValues(alpha: 0.25),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularApps(ThemeData theme, bool isDark) {
    if (_products.isEmpty) {
      return Center(
        child: Text(
          "Belum ada produk",
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _products.take(4).map<Widget>((p) {
        final imageUrl = p['image'];

        return GestureDetector(
          onTap: () =>
              Navigator.pushNamed(context, '/detail', arguments: p),
          child: Column(
            children: [
              // App icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.grey.shade100,
                  border: Border.all(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.image_not_supported_outlined,
                          size: 24,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                      )
                    : Center(
                        child: Text(
                          (p['name'] ?? '?')[0].toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: 64,
                child: Text(
                  p['name'] ?? "-",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBestSellers(ThemeData theme, bool isDark) {
    if (_products.isEmpty) {
      return Center(
        child: Text(
          "Belum ada produk",
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return Column(
      children: _products.take(5).map((product) {
        final imageUrl = product['image'];

        return GestureDetector(
          onTap: () => Navigator.pushNamed(
            context,
            '/detail',
            arguments: product,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
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
                // Thumbnail
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.12),
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_not_supported_outlined,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3),
                          ),
                        )
                      : Center(
                          child: Text(
                            (product['name'] ?? '?')[0].toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                ),

                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategori
                      Text(
                        (product['category'] ?? 'ENTERTAINMENT')
                            .toString()
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.6),
                        ),
                      ),

                      const SizedBox(height: 3),

                      // Nama produk
                      Text(
                        product['name'] ?? "-",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 3),

                      // Harga
                      Text(
                        "Mulai ${_getPrice(product)}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Arrow button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
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
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _errorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.wifi_off_outlined,
                size: 36,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Gagal Memuat Produk",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? "Terjadi kesalahan",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetchProducts,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.radius),
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
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  "Coba Lagi",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}