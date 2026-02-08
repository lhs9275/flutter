import 'package:flutter/material.dart';

class UserHeaderFlutter extends StatelessWidget implements PreferredSizeWidget {
  const UserHeaderFlutter({
    super.key,
    required this.title,
    this.subtitle,
    this.onLogout,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onLogout;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.groups, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(fontSize: 12, color: Colors.amberAccent)),
            ],
          ),
        ],
      ),
      actions: [
        if (onLogout != null)
          TextButton(
            onPressed: onLogout,
            child: const Text('로그아웃', style: TextStyle(color: Colors.white70)),
          ),
      ],
    );
  }
}
