import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/app_theme.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isScanned = false;
  bool _isTorchOn = false;
  bool _hasPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
      _isLoading = false;
    });

    if (!status.isGranted) {
      if (mounted) {
        _showPermissionDeniedDialog();
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Camera permission is required to scan barcodes. Please grant camera permission in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() => _isScanned = true);

        // Show success feedback
        _showSuccessDialog(code);
      }
    }
  }

  void _showSuccessDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Barcode Scanned'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scanned Value:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.successColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _isScanned = false);
              },
              child: const Text('Scan Again'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(code);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
              ),
              child: const Text('Use This'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Meter Barcode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: _hasPermission
            ? [
                IconButton(
                  icon: Icon(
                    _isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: _isTorchOn ? Colors.yellow : Colors.grey,
                  ),
                  onPressed: () async {
                    await cameraController.toggleTorch();
                    setState(() {
                      _isTorchOn = !_isTorchOn;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cameraswitch),
                  onPressed: () => cameraController.switchCamera(),
                ),
              ]
            : [],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : !_hasPermission
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 80,
                        color: AppTheme.textHint,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Camera Permission Required',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please grant camera permission to scan barcodes',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await openAppSettings();
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Open Settings'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // Camera Preview
                    MobileScanner(
                      controller: cameraController,
                      onDetect: _onDetect,
                    ),

                    // Overlay with scanning frame
                    CustomPaint(
                      painter: ScannerOverlay(),
                      child: Container(),
                    ),

                    // Instructions
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Position the barcode within the frame',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'The scanner will automatically detect the barcode',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// Custom painter for the scanner overlay
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width * 0.8,
            height: size.height * 0.4,
          ),
          const Radius.circular(16),
        ),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5);

    final path = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(path, backgroundPaint);

    // Draw frame corners
    final framePaint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.4,
    );

    final cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      frameRect.topLeft,
      frameRect.topLeft + Offset(cornerLength, 0),
      framePaint,
    );
    canvas.drawLine(
      frameRect.topLeft,
      frameRect.topLeft + Offset(0, cornerLength),
      framePaint,
    );

    // Top-right corner
    canvas.drawLine(
      frameRect.topRight,
      frameRect.topRight + Offset(-cornerLength, 0),
      framePaint,
    );
    canvas.drawLine(
      frameRect.topRight,
      frameRect.topRight + Offset(0, cornerLength),
      framePaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      frameRect.bottomLeft,
      frameRect.bottomLeft + Offset(cornerLength, 0),
      framePaint,
    );
    canvas.drawLine(
      frameRect.bottomLeft,
      frameRect.bottomLeft + Offset(0, -cornerLength),
      framePaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      frameRect.bottomRight,
      frameRect.bottomRight + Offset(-cornerLength, 0),
      framePaint,
    );
    canvas.drawLine(
      frameRect.bottomRight,
      frameRect.bottomRight + Offset(0, -cornerLength),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
