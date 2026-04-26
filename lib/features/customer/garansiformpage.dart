// ============================================================
// SENSOR 1: CAMERA — GaransiFormPage
// Package: image_picker
// Tambahkan di pubspec.yaml:
//   image_picker: ^1.1.2
//
// Android: tambahkan di android/app/src/main/AndroidManifest.xml
//   <uses-permission android:name="android.permission.CAMERA"/>
//
// iOS: tambahkan di ios/Runner/Info.plist
//   <key>NSCameraUsageDescription</key>
//   <string>Diperlukan untuk foto bukti kerusakan</string>
//   <key>NSPhotoLibraryUsageDescription</key>
//   <string>Diperlukan untuk memilih foto bukti kerusakan</string>
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';

class GaransiFormPage extends StatefulWidget {
  const GaransiFormPage({super.key});

  @override
  State<GaransiFormPage> createState() => _GaransiFormPageState();
}

class _GaransiFormPageState extends State<GaransiFormPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  // ✅ SENSOR: ImagePicker untuk akses kamera & galeri
  final ImagePicker _picker = ImagePicker();

  final _descController = TextEditingController();

  // ✅ File gambar yang dipilih dari kamera/galeri
  File? _proofImage;
  String? _uploadedImageUrl;

  bool _isLoading = false;
  bool _isUploading = false;

  bool _didInit = false;

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
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ============================================================
  // SENSOR CAMERA: Ambil foto dari kamera atau galeri
  // ============================================================
  Future<void> _pickImage(ImageSource source) async {
    try {
      // ✅ Akses sensor kamera device
      final XFile? pickedFile = await _picker.pickImage(
        source: source,         // ImageSource.camera atau ImageSource.gallery
        imageQuality: 80,       // Kompres agar tidak terlalu besar
        maxWidth: 1280,
        maxHeight: 1280,
      );

      if (pickedFile == null) return; // User batal

      setState(() => _proofImage = File(pickedFile.path));

      // Auto-upload setelah foto dipilih
      await _uploadImage(File(pickedFile.path));
    } catch (e) {
      _showSnackBar('Gagal mengakses kamera: ${e.toString()}',
          isError: true);
    }
  }

  // ✅ Upload foto ke Supabase Storage
  Future<void> _uploadImage(File imageFile) async {
    setState(() => _isUploading = true);

    try {
      final fileName =
          'garansi_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage
          .from('proof-images')
          .upload(fileName, imageFile);

      final publicUrl = supabase.storage
          .from('proof-images')
          .getPublicUrl(fileName);

      if (!mounted) return;
      setState(() => _uploadedImageUrl = publicUrl);
      _showSnackBar('Foto berhasil diupload', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal upload foto: ${e.toString()}', isError: true);
      setState(() => _proofImage = null);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ✅ Dialog pilih sumber: Kamera atau Galeri
  void _showImageSourceDialog(ThemeData theme, bool isDark) {
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Pilih Sumber Foto",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Ambil foto langsung atau dari galeri",
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // ✅ 
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
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
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.camera_alt_outlined,
                                color: isDark ? Colors.black : Colors.white,
                                size: 28),
                            const SizedBox(height: 6),
                            Text(
                              "Kamera",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol akses galeri
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.gallery);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.grey.shade100,
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.photo_library_outlined,
                                color: theme.colorScheme.primary, size: 28),
                            const SizedBox(height: 6),
                            Text(
                              "Galeri",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
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

  Future<void> _submitClaim(Map data) async {
    if (_descController.text.trim().isEmpty) {
      _showSnackBar('Deskripsi masalah wajib diisi', isError: true);
      return;
    }
    if (_uploadedImageUrl == null) {
      _showSnackBar('Foto bukti kerusakan wajib diupload', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.from('claims').insert({
        'order_id': data['id'],
        'problem_description': _descController.text.trim(),
        'proof_image': _uploadedImageUrl,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      _showSnackBar('Klaim garansi berhasil dikirim!', isError: false);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = ModalRoute.of(context)?.settings.arguments as Map?;

    if (data == null) {
      return const Scaffold(body: Center(child: Text("No Data")));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
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
          child: Column(
            children: [

              // AppBar
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(Icons.arrow_back_ios_new,
                            size: 16, color: theme.colorScheme.primary),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "Form Garansi",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 38),
                  ],
                ),
              ),

              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 30),
                      children: [

                        // Info produk
                        Container(
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
                            ),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : Colors.black.withValues(alpha: 0.04),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                ),
                                child: Icon(Icons.shield_outlined,
                                    color: theme.colorScheme.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['product_name'] ?? '-',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      data['variant_type'] ?? '-',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Form card
                        Container(
                          padding: const EdgeInsets.all(20),
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
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.04),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // Deskripsi masalah
                              _fieldLabel("DESKRIPSI MASALAH", theme),
                              TextField(
                                controller: _descController,
                                maxLines: 4,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface),
                                decoration: InputDecoration(
                                  hintText:
                                      "Jelaskan masalah yang kamu alami...",
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.35),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.black.withValues(alpha: 0.35)
                                      : Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.radius),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.radius),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.all(14),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ══════════════════════════════════════
                              // SENSOR CAMERA: Area upload foto
                              // ══════════════════════════════════════
                              _fieldLabel("FOTO BUKTI KERUSAKAN", theme),

                              GestureDetector(
                                onTap: () =>
                                    _showImageSourceDialog(theme, isDark),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 300),
                                  width: double.infinity,
                                  height: _proofImage != null ? null : 160,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    color: isDark
                                        ? Colors.white
                                            .withValues(alpha: 0.05)
                                        : Colors.grey.shade100,
                                    border: Border.all(
                                      color: _proofImage != null
                                          ? theme.colorScheme.primary
                                              .withValues(alpha: 0.4)
                                          : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.12),
                                      width: _proofImage != null ? 1.5 : 1,
                                      // Dashed border visual
                                    ),
                                  ),
                                  child: _isUploading
                                      // Loading saat upload
                                      ? Center(
                                          child: Column(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(
                                                color: theme
                                                    .colorScheme.primary,
                                                strokeWidth: 2.5,
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                "Mengupload foto...",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: theme
                                                      .colorScheme.onSurface
                                                      .withValues(
                                                          alpha: 0.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : _proofImage != null
                                          // ✅ Preview foto dari kamera
                                          ? Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15),
                                                  child: Image.file(
                                                    _proofImage!,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                // Badge sukses upload
                                                if (_uploadedImageUrl !=
                                                    null)
                                                  Positioned(
                                                    top: 10,
                                                    right: 10,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 10,
                                                              vertical: 6),
                                                      decoration:
                                                          BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        color: Colors.green,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors
                                                                .black
                                                                .withValues(
                                                                    alpha:
                                                                        0.3),
                                                            blurRadius: 8,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: const [
                                                          Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color: Colors
                                                                  .white,
                                                              size: 14),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            "Terupload",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                // Tombol ganti foto
                                                Positioned(
                                                  bottom: 10,
                                                  right: 10,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        _proofImage = null;
                                                        _uploadedImageUrl =
                                                            null;
                                                      });
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .all(8),
                                                      decoration:
                                                          BoxDecoration(
                                                        shape:
                                                            BoxShape.circle,
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.6),
                                                      ),
                                                      child: const Icon(
                                                          Icons.refresh,
                                                          color: Colors.white,
                                                          size: 18),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          // Placeholder sebelum foto dipilih
                                          : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(
                                                          16),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: theme
                                                        .colorScheme.primary
                                                        .withValues(
                                                            alpha: 0.08),
                                                  ),
                                                  child: Icon(
                                                    Icons.camera_alt_outlined,
                                                    size: 32,
                                                    color: theme.colorScheme
                                                        .primary
                                                        .withValues(
                                                            alpha: 0.5),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  "Tap untuk foto bukti kerusakan",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: theme.colorScheme
                                                        .onSurface
                                                        .withValues(
                                                            alpha: 0.5),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Kamera atau galeri",
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: theme.colorScheme
                                                        .onSurface
                                                        .withValues(
                                                            alpha: 0.3),
                                                  ),
                                                ),
                                              ],
                                            ),
                                ),
                              ),
                              // ══════════════════════════════════════

                              const SizedBox(height: 24),

                              // Submit button
                              GestureDetector(
                                onTap: _isLoading || _isUploading
                                    ? null
                                    : () => _submitClaim(data),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.radius),
                                    gradient: (_isLoading || _isUploading)
                                        ? LinearGradient(colors: [
                                            theme.colorScheme.primary
                                                .withValues(alpha: 0.5),
                                            theme.colorScheme.secondary
                                                .withValues(alpha: 0.5),
                                          ])
                                        : LinearGradient(colors: [
                                            theme.colorScheme.primary,
                                            theme.colorScheme.secondary,
                                          ]),
                                    boxShadow:
                                        (_isLoading || _isUploading)
                                            ? []
                                            : [
                                                BoxShadow(
                                                  color: theme
                                                      .colorScheme.primary
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 16,
                                                  offset:
                                                      const Offset(0, 6),
                                                ),
                                              ],
                                  ),
                                  child: Center(
                                    child: _isLoading
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: isDark
                                                  ? Colors.black
                                                  : Colors.white,
                                            ),
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.send_rounded,
                                                  size: 18,
                                                  color: isDark
                                                      ? Colors.black
                                                      : Colors.white),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Kirim Klaim Garansi",
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.black
                                                      : Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text, ThemeData theme) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
            color: theme.colorScheme.primary.withValues(alpha: 0.75),
          ),
        ),
      );
}