import 'package:flutter/material.dart';

class MagicIconFlutter extends StatelessWidget {
  const MagicIconFlutter({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome, size: size, color: Colors.amberAccent);
  }
}
