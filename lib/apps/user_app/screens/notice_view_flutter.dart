import 'package:flutter/material.dart';

class NoticeViewFlutter extends StatelessWidget {
  const NoticeViewFlutter({super.key});

  @override
  Widget build(BuildContext context) {
    const notices = [
      _NoticeItem(title: '안전 수칙 안내', body: '안전화 필수 착용'),
      _NoticeItem(title: '급여 정산 일정', body: '매주 금요일 지급'),
      _NoticeItem(title: '우천 시 작업 안내', body: '기상 상황에 따라 일정이 조정될 수 있습니다.'),
    ];

    return Column(
      children: notices
          .map(
            (notice) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NoticeCard(notice: notice),
            ),
          )
          .toList(),
    );
  }
}

class _NoticeItem {
  const _NoticeItem({required this.title, required this.body});

  final String title;
  final String body;
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});

  final _NoticeItem notice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.campaign, size: 18, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(notice.body, style: const TextStyle(color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
