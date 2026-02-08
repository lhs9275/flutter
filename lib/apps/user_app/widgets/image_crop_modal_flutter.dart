import 'package:flutter/material.dart';

class ImageCropModalFlutter extends StatelessWidget {
  const ImageCropModalFlutter({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('이미지 자르기'),
      content: Container(
        height: 200,
        width: 200,
        color: const Color(0xFFFFFFFF),
        child: const Center(child: Text('이미지 크롭 영역')),
      ),
      actions: [
        TextButton(onPressed: onClose, child: const Text('닫기')),
        ElevatedButton(onPressed: onClose, child: const Text('확인')),
      ],
    );
  }
}
