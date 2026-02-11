import 'package:flutter/material.dart';

class UserInfoViewFlutter extends StatelessWidget {
  const UserInfoViewFlutter({
    super.key,
    required this.name,
    required this.phone,
    required this.regions,
    required this.onEditProfile,
  });

  final String name;
  final String phone;
  final List<String> regions;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('내 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('이름: $name'),
                    Text('휴대폰: $phone'),
                    Text('선호 지역: ${regions.isEmpty ? '-' : regions.join(', ')}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onEditProfile,
                  child: const Text('프로필 수정'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
