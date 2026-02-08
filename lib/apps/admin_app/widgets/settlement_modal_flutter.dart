import 'package:flutter/material.dart';

class SettlementModalFlutter extends StatelessWidget {
  const SettlementModalFlutter({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('정산 상세'),
      content: const Text('정산 상세 정보 영역'),
      actions: [
        TextButton(onPressed: onClose, child: const Text('닫기')),
      ],
    );
  }
}
