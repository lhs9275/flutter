import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../widgets/attendance_qr_helper.dart';

class AttendanceScanSheetFlutter extends StatefulWidget {
  const AttendanceScanSheetFlutter({
    super.key,
    required this.onConfirmed,
  });

  final ValueChanged<AttendanceQrPayload> onConfirmed;

  @override
  State<AttendanceScanSheetFlutter> createState() => _AttendanceScanSheetFlutterState();
}

class _AttendanceScanSheetFlutterState extends State<AttendanceScanSheetFlutter> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isHandling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isHandling) return;
    final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    final payload = AttendanceQrPayload.tryParse(raw);
    if (payload == null) {
      await _showMessage('유효하지 않은 QR입니다. 다시 스캔해주세요.');
      return;
    }

    _isHandling = true;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      _isHandling = false;
      await _showMessage('네트워크 연결이 필요합니다.');
      return;
    }

    final now = DateTime.now();
    if (!payload.isValidAt(now)) {
      _isHandling = false;
      await _showMessage('유효 시간이 지난 QR입니다.');
      return;
    }

    widget.onConfirmed(payload);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _showMessage(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('출근 QR 스캔'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: MobileScanner(
                controller: _controller,
                onDetect: _handleBarcode,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('안내', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('QR은 당일 10분 동안만 유효합니다.'),
                  Text('네트워크 연결 상태에서만 출근 확인이 가능합니다.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
