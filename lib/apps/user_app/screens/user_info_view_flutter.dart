import 'package:flutter/material.dart';

class UserInfoViewFlutter extends StatelessWidget {
  const UserInfoViewFlutter({
    super.key,
    required this.onEditProfile,
  });

  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF374151)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('내 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('이름: 김테스트'),
              Text('휴대폰: 010-1111-2222'),
              Text('선호 지역: 서울 강남구'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onEditProfile,
            child: const Text('프로필 수정'),
          ),
        ),
      ],
    );
  }
}
