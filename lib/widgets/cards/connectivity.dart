
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper>
    with SingleTickerProviderStateMixin {
  // ✅ SENSOR: Connectivity listener
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  bool _isOnline = true;
  bool _showBanner = false;

  // Animasi banner naik/turun
  late AnimationController _bannerController;
  late Animation<Offset> _bannerSlide;

  @override
  void initState() {
    super.initState();

    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _bannerSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _bannerController, curve: Curves.easeOut));

    // ✅ SENSOR: Cek koneksi awal saat widget pertama dibuat
    _checkInitialConnectivity();

    // ✅ SENSOR: Subscribe ke stream perubahan koneksi secara realtime
    _subscription = _connectivity.onConnectivityChanged
        .listen(_onConnectivityChanged);
  }

  @override
  void dispose() {
    _subscription.cancel(); // ✅ Penting: cancel stream saat widget dispose
    _bannerController.dispose();
    super.dispose();
  }

  // ✅ SENSOR: Cek koneksi pertama kali
  Future<void> _checkInitialConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    if (!mounted) return;
    _updateConnectionStatus(results);
  }

  // ✅ SENSOR: Dipanggil otomatis setiap koneksi berubah
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (!mounted) return;
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Online jika ada salah satu dari: wifi, mobile, ethernet
    final isOnline = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);

    if (isOnline == _isOnline) return; // Tidak ada perubahan

    setState(() {
      _isOnline = isOnline;
      _showBanner = true;
    });

    if (isOnline) {
      // Kembali online: tampilkan banner hijau, lalu sembunyikan setelah 2 detik
      _bannerController.forward();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _bannerController.reverse().then((_) {
            if (mounted) setState(() => _showBanner = false);
          });
        }
      });
    } else {
      // Offline: tampilkan banner merah permanen selama offline
      _bannerController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Konten utama halaman
        widget.child,

        // ✅ SENSOR OUTPUT: Banner status koneksi
        if (_showBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _bannerSlide,
              child: _buildBanner(theme, isDark),
            ),
          ),
      ],
    );
  }

  Widget _buildBanner(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.green.shade600 : Colors.redAccent.shade700,
        boxShadow: [
          BoxShadow(
            color: (_isOnline ? Colors.green : Colors.redAccent)
                .withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: Icon(
                _isOnline ? Icons.wifi : Icons.wifi_off_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isOnline ? "Koneksi Pulih" : "Tidak Ada Koneksi",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _isOnline
                        ? "Kamu kembali online"
                        : "Periksa koneksi internet kamu",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Loading dot animasi saat offline
            if (!_isOnline)
              _PulsingDot(),
          ],
        ),
      ),
    );
  }
}

// Dot berkedip saat offline
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ============================================================
// WIDGET 2: ConnectivityIndicator
// Widget kecil untuk ditampilkan di navbar/appbar
// Menunjukkan status koneksi secara realtime
//
// Cara pakai:
//   Row(children: [
//     ...,
//     ConnectivityIndicator(),
//   ])
// ============================================================
class ConnectivityIndicator extends StatefulWidget {
  const ConnectivityIndicator({super.key});

  @override
  State<ConnectivityIndicator> createState() =>
      _ConnectivityIndicatorState();
}

class _ConnectivityIndicatorState extends State<ConnectivityIndicator> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkInitial();
    _subscription =
        _connectivity.onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(() {
        _isOnline = results.any((r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.ethernet);
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _checkInitial() async {
    final results = await _connectivity.checkConnectivity();
    if (!mounted) return;
    setState(() {
      _isOnline = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: (_isOnline ? Colors.green : Colors.redAccent)
            .withValues(alpha: 0.15),
        border: Border.all(
          color: (_isOnline ? Colors.green : Colors.redAccent)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isOnline ? Colors.green : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _isOnline ? "Online" : "Offline",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _isOnline ? Colors.green : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CONTOH PENGGUNAAN DI HOME PAGE:
//
// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     body: ConnectivityWrapper(   // ← bungkus di sini
//       child: Container(
//         ...your existing body...
//       ),
//     ),
//   );
// }
//
// ATAU tambahkan ConnectivityIndicator di navbar:
//
// Row(
//   children: [
//     Icon(Icons.blur_on, ...),
//     Text("INIARNN.APPREM"),
//     const Spacer(),
//     const ConnectivityIndicator(),  // ← tambahkan di sini
//     const SizedBox(width: 8),
//     // refresh button...
//   ],
// )
// ============================================================