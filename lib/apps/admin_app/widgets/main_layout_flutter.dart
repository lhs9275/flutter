import 'package:flutter/material.dart';

class MainLayoutFlutter extends StatelessWidget {
  const MainLayoutFlutter({
    super.key,
    required this.title,
    required this.body,
    this.drawer,
    this.onLogout,
  });

  final String title;
  final Widget body;
  final Widget? drawer;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: onLogout,
            ),
        ],
      ),
      drawer: drawer,
      body: body,
    );
  }
}
