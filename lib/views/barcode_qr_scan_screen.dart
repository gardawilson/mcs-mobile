import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

import '../view_models/stock_opname_input_view_model.dart';
import '../view_models/scan_processor_view_model.dart';

/// Tahap UI untuk indikator visual
enum UiStage { idle, detected, checking, submitting, success, error }

class BarcodeQrScanScreen extends StatefulWidget {
  final String noSO;

  const BarcodeQrScanScreen({Key? key, required this.noSO}) : super(key: key);

  @override
  State<BarcodeQrScanScreen> createState() => _BarcodeQrScanScreenState();
}

class _BarcodeQrScanScreenState extends State<BarcodeQrScanScreen>
    with SingleTickerProviderStateMixin {

  /// CONTROLLER kamera yang sudah dituning:
  /// - formats: QR only
  /// - detectionSpeed: unrestricted (no throttling)
  /// - detectionTimeoutMs: 0 (jangan jeda internal)
  /// - cameraResolution: coba "high" dulu (fps bagus), kalau QR kecil sulit → "veryHigh"
  final MobileScannerController cameraController = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
    detectionSpeed: DetectionSpeed.unrestricted,
    detectionTimeoutMs: 0,
    formats: const [BarcodeFormat.qrCode],

    // ✅ gunakan Size, bukan Resolution
    // Opsi A: FPS cenderung lebih tinggi, cocok QR medium/besar
    // cameraResolution: const Size(1280, 720),

    // Opsi B: Detail lebih tajam untuk QR kecil/blur (mungkin FPS turun)
    cameraResolution: const Size(1920, 1080),
  );

  final AudioPlayer _audioPlayer = AudioPlayer();

  bool hasCameraPermission = false;
  bool isFlashOn = false;

  String? _lastScannedCode;
  String _statusMessage = '';
  UiStage _stage = UiStage.idle;

  // tidak dipakai lagi untuk debounce panjang, tetap disiapkan bila perlu cooldown singkat
  Timer? _cooldownTimer;
  bool _cooldownActive = false;

  late final AnimationController _laserController;

  @override
  void initState() {
    super.initState();
    _getCameraPermission();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    cameraController.dispose();
    _laserController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() => hasCameraPermission = status == PermissionStatus.granted);

    if (status == PermissionStatus.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Izin kamera ditolak. Buka Pengaturan untuk mengaktifkan.'),
          action: SnackBarAction(
            label: 'Pengaturan',
            onPressed: openAppSettings,
          ),
        ),
      );
    }
  }

  void _onDetect(String code) async {
    // Jangan ganggu kalau lagi proses submit/cek
    if (_stage == UiStage.checking || _stage == UiStage.submitting) return;

    // Cegah duplikasi kode yang sama beruntun
    if (code == _lastScannedCode) return;

    // Cooldown sangat singkat agar tidak "berondong"
    if (_cooldownActive) return;
    _cooldownActive = true;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(milliseconds: 100), () {
      _cooldownActive = false;
    });

    _lastScannedCode = code;
    _setStage(UiStage.detected, msg: 'QR terdeteksi');

    // Feedback instan biar terasa nempel (bunyi pendek optional jika ada asset)
    Vibration.vibrate(duration: 40);

    // LANGSUNG proses (tanpa debounce 250ms)
    _startProcess(code);
  }

  void _startProcess(String rawValue) {
    final vm = Provider.of<ScanProcessorViewModel>(context, listen: false);

    vm.processScannedCode(
      rawValue,
      widget.noSO,
      onStage: (stg) {
        if (stg == ScanStage.checking) {
          _setStage(UiStage.checking, msg: 'Memeriksa data...');
        } else if (stg == ScanStage.submitting) {
          _setStage(UiStage.submitting, msg: 'Menyimpan hasil...');
        }
      },
      onResult: (result) async {
        if (result.success && result.statusCode == 201) {
          await _audioPlayer.play(AssetSource('sounds/accepted.mp3'));
          Vibration.vibrate(duration: 120);
          // refresh list
          Provider.of<StockOpnameInputViewModel>(context, listen: false)
              .fetchAssets(widget.noSO);
          _setStage(UiStage.success, msg: result.message);
        } else {
          await _audioPlayer.play(AssetSource('sounds/denied.mp3'));
          Vibration.vibrate(duration: 600);
          _setStage(
            UiStage.error,
            msg: result.message.isNotEmpty ? result.message : 'Gagal memproses',
          );
        }

        // Kembali ke idle setelah indikator tampil
        Future.delayed(const Duration(milliseconds: 1600), _reset);
      },
    );
  }

  void _reset() {
    if (!mounted) return;
    setState(() {
      _stage = UiStage.idle;
      _statusMessage = '';
      _lastScannedCode = null;
    });
  }

  void _setStage(UiStage s, {String? msg}) {
    if (!mounted) return;
    setState(() {
      _stage = s;
      if (msg != null) _statusMessage = msg;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = Provider.of<StockOpnameInputViewModel>(context).totalAssets;
    final size = MediaQuery.of(context).size;

    // Sedikit lebih kecil dari sebelumnya supaya analisa lebih fokus
    final scanBox = size.width * 0.6;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Total : $total',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: isFlashOn ? 'Matikan flash' : 'Nyalakan flash',
            icon: Icon(isFlashOn ? Icons.flash_off : Icons.flash_on, color: Colors.white),
            onPressed: () async {
              setState(() => isFlashOn = !isFlashOn);
              await cameraController.toggleTorch();
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient (statik, murah)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // PREVIEW KAMERA — dibungkus RepaintBoundary untuk kurangi jank
          if (hasCameraPermission)
            RepaintBoundary(
              child: MobileScanner(
                controller: cameraController,
                fit: BoxFit.cover,
                scanWindow: Rect.fromCenter(
                  center: Offset(size.width / 2, size.height / 2),
                  width: scanBox,
                  height: scanBox,
                ),
                onDetect: (capture) {
                  try {
                    final code = capture.barcodes.isNotEmpty
                        ? capture.barcodes.first.rawValue
                        : null;
                    if (code != null) _onDetect(code);
                  } catch (e) {
                    debugPrint('detect error: $e');
                  }
                },
              ),
            )
          else
            Center(
              child: ElevatedButton(
                onPressed: _getCameraPermission,
                child: const Text('Aktifkan izin kamera'),
              ),
            ),

          // FRAME + LASER — juga RepaintBoundary agar tidak bikin preview repaint
          Align(
            alignment: Alignment.center,
            child: RepaintBoundary(
              child: SizedBox(
                width: scanBox,
                height: scanBox,
                child: Stack(
                  children: [
                    // Kotak border utuh (square)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.95),
                          width: 2.2,
                        ),
                      ),
                    ),
                    // Laser animasi
                    AnimatedBuilder(
                      animation: _laserController,
                      builder: (_, __) {
                        final top = _laserController.value * (scanBox - 2.0);
                        return Positioned(
                          top: top,
                          left: 8,
                          right: 8,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Step indicator (Detected → Checking → Submitting)
          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
            left: 16,
            right: 16,
            child: _buildStepChips(),
          ),

          // Overlay loading per tahap (blur kecil agar murah)
          if (_stage == UiStage.detected ||
              _stage == UiStage.checking ||
              _stage == UiStage.submitting)
            const _StageOverlay(),

          // Ikon hasil
          if (_stage == UiStage.success || _stage == UiStage.error)
            Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: 1.0,
                child: Image.asset(
                  _stage == UiStage.success
                      ? 'assets/images/check.png'
                      : 'assets/images/cross.png',
                  width: 120,
                  height: 120,
                ),
              ),
            ),

          // Toast status bawah
          if (_statusMessage.isNotEmpty)
            Positioned(
              bottom: 28,
              left: 18,
              right: 18,
              child: _GlassToast(
                message: _statusMessage,
                color: _toastColorForStage(_stage),
                icon: _iconForStage(_stage),
              ),
            ),
        ],
      ),
    );
  }

  // ==== Helper UI ==== //

  Color _toastColorForStage(UiStage s) {
    switch (s) {
      case UiStage.detected:
        return Colors.blue;
      case UiStage.checking:
      case UiStage.submitting:
        return Colors.black54;
      case UiStage.success:
        return Colors.green;
      case UiStage.error:
        return Colors.red;
      case UiStage.idle:
      default:
        return Colors.black54;
    }
  }

  IconData _iconForStage(UiStage s) {
    switch (s) {
      case UiStage.detected:
        return Icons.qr_code_scanner;
      case UiStage.checking:
        return Icons.hourglass_top;
      case UiStage.submitting:
        return Icons.cloud_upload;
      case UiStage.success:
        return Icons.check_circle;
      case UiStage.error:
        return Icons.error;
      case UiStage.idle:
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildStepChips() {
    int active = 0;
    if (_stage == UiStage.detected) active = 1;
    if (_stage == UiStage.checking) active = 2;
    if (_stage == UiStage.submitting) active = 3;
    if (_stage == UiStage.success || _stage == UiStage.error) active = 3;

    Widget chip(String label, int step) {
      final isActive = active >= step && active != 0;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.9) : Colors.white24,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: isActive ? Colors.green.shade700 : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black87 : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        chip('Deteksi', 1),
        chip('Cek', 2),
        chip('Simpan', 3),
      ],
    );
  }
}

// Overlay loading per tahap (tanpa ambil state, label statik → murah)
class _StageOverlay extends StatelessWidget {
  const _StageOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                ),
                SizedBox(width: 12),
                _StageTexts(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StageTexts extends StatelessWidget {
  const _StageTexts();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Sedang diproses...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        SizedBox(height: 2),
        Text('Mohon tunggu', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// Toast kaca bawah
class _GlassToast extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;

  const _GlassToast({
    Key? key,
    required this.message,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.72),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
