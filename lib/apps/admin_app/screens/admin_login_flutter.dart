import 'package:flutter/material.dart';

class AdminLoginFlutter extends StatelessWidget {
  const AdminLoginFlutter({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('관리자 로그인', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(decoration: const InputDecoration(labelText: '아이디', filled: true)),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: '비밀번호', filled: true),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onLogin, child: const Text('로그인')),
            ],
          ),
        ),
      ),
    );
  }
}
