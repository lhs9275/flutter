import 'package:flutter/material.dart';

class RemoteStatusBannerFlutter extends StatelessWidget {
  const RemoteStatusBannerFlutter({
    super.key,
    this.isLoading = false,
    this.error,
    this.infoMessage,
    this.onRefresh,
    this.showLoadingBar = true,
    this.showInfoOnlyWhenNoError = false,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  final bool isLoading;
  final String? error;
  final String? infoMessage;
  final Future<void> Function()? onRefresh;
  final bool showLoadingBar;
  final bool showInfoOnlyWhenNoError;
  final EdgeInsetsGeometry margin;

  bool get _hasError => (error ?? '').trim().isNotEmpty;
  bool get _hasInfo => (infoMessage ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final showInfo = _hasInfo && (!showInfoOnlyWhenNoError || !_hasError);
    if (!isLoading && !_hasError && !showInfo) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        if (showLoadingBar && isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_hasError)
          Container(
            width: double.infinity,
            margin: margin,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Text(
              error!.trim(),
              style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12),
            ),
          ),
        if (showInfo)
          Container(
            width: double.infinity,
            margin: margin,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    infoMessage!.trim(),
                    style: const TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onRefresh != null)
                  TextButton.icon(
                    onPressed: () {
                      onRefresh!.call();
                    },
                    icon: isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 16),
                    label: const Text('새로고침'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
