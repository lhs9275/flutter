import 'package:flutter/material.dart';

class LoadingSpinnerFlutter extends StatelessWidget {
  const LoadingSpinnerFlutter({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
