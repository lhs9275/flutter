import 'package:flutter/material.dart';

class NoticeManagementFlutter extends StatelessWidget {
  const NoticeManagementFlutter({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
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
              const Text('공지 등록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: '제목', filled: true)),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: '내용', filled: true),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () {}, child: const Text('공지 등록')),
              )
            ],
          ),
        ),
        const SizedBox(height: 12),
        const ListTile(
          tileColor: Color(0xFFFFFFFF),
          title: Text('안전 교육 공지'),
          subtitle: Text('모든 현장 필수'),
        ),
        const SizedBox(height: 12),
        const ListTile(
          tileColor: Color(0xFFFFFFFF),
          title: Text('휴무일 안내'),
          subtitle: Text('광복절 휴무'),
        ),
      ],
    );
  }
}
