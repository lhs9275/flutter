import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapLauncherCardFlutter extends StatelessWidget {
  const MapLauncherCardFlutter({
    super.key,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.height = 140,
  });

  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final double height;

  static const String _naverAppName = 'kr.clos21.psp2fn';

  bool get _hasCoords => latitude != null && longitude != null;

  String get _displayTitle => name.trim().isEmpty ? address : name;

  Uri _naverSearchUrl(String query) {
    final encoded = Uri.encodeComponent(query.isEmpty ? address : query);
    return Uri.https('map.naver.com', '/v5/search/$encoded');
  }

  Future<void> _launchWithFallback(
    BuildContext context,
    Uri primary,
    Uri? fallback,
  ) async {
    final opened = await launchUrl(primary, mode: LaunchMode.externalApplication);
    if (opened) return;
    if (fallback != null) {
      final fallbackOpened = await launchUrl(
        fallback,
        mode: LaunchMode.externalApplication,
      );
      if (fallbackOpened) return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('지도를 열 수 없습니다. 앱 설치 여부를 확인해주세요.')),
    );
  }

  Future<void> _openNaver(BuildContext context) async {
    final query = _displayTitle.trim().isEmpty ? address : _displayTitle.trim();
    final webFallback = _naverSearchUrl(query);
    if (!_hasCoords) {
      final opened = await launchUrl(webFallback, mode: LaunchMode.externalApplication);
      if (opened) return;
      final store = _platformStoreUrl(
        androidUrl: 'https://play.google.com/store/apps/details?id=com.nhn.android.nmap',
        iosUrl: 'https://apps.apple.com/app/id311867728',
      );
      if (store != null) {
        final storeOpened = await launchUrl(store, mode: LaunchMode.externalApplication);
        if (storeOpened) return;
      }
      _notifyMissingCoords(context);
      return;
    }
    final appUri = Uri(
      scheme: 'nmap',
      host: 'navigation',
      queryParameters: {
        'dlat': latitude!.toString(),
        'dlng': longitude!.toString(),
        'dname': _displayTitle,
        'appname': _naverAppName,
      },
    );

    final fallback = _platformStoreUrl(
      androidUrl: 'https://play.google.com/store/apps/details?id=com.nhn.android.nmap',
      iosUrl: 'https://apps.apple.com/app/id311867728',
    );

    final opened = await launchUrl(appUri, mode: LaunchMode.externalApplication);
    if (opened) return;
    final webOpened = await launchUrl(webFallback, mode: LaunchMode.externalApplication);
    if (webOpened) return;
    if (fallback != null) {
      final storeOpened = await launchUrl(fallback, mode: LaunchMode.externalApplication);
      if (storeOpened) return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('지도를 열 수 없습니다. 앱 설치 여부를 확인해주세요.')),
    );
  }

  Uri? _platformStoreUrl({required String androidUrl, required String iosUrl}) {
    if (kIsWeb) return Uri.parse(androidUrl);
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return Uri.parse(androidUrl);
      case TargetPlatform.iOS:
        return Uri.parse(iosUrl);
      default:
        return Uri.parse(androidUrl);
    }
  }

  void _notifyMissingCoords(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('지도를 열 수 없습니다. 주소 또는 앱 설치 여부를 확인해주세요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtleBorder = const Color(0xFFE2E8F0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('현장 위치', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: subtleBorder),
            gradient: const LinearGradient(
              colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE).withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0).withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place, color: Color(0xFF6366F1), size: 28),
                    const SizedBox(height: 6),
                    Text(
                      _displayTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        address,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MapActionButton(
              label: '네이버 지도로 열기',
              backgroundColor: const Color(0xFF03C75A),
              textColor: Colors.white,
              onPressed: () => _openNaver(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
