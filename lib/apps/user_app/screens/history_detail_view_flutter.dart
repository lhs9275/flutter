import 'package:flutter/material.dart';

class HistoryDetailViewFlutter extends StatelessWidget {
  const HistoryDetailViewFlutter({super.key});

  static const List<_HistoryItem> _items = [
    _HistoryItem(
      date: '2024-07-20',
      site: '강남 오피스텔',
      role: '보통인부',
      pay: '150,000원',
      status: '정산 완료',
    ),
    _HistoryItem(
      date: '2024-07-22',
      site: '홍대 리모델링',
      role: '조공',
      pay: '170,000원',
      status: '지급 대기',
    ),
    _HistoryItem(
      date: '2024-07-25',
      site: '성수동 카페 공사',
      role: '기공',
      pay: '220,000원',
      status: '정산 완료',
    ),
  ];

  Widget _buildStatusLabel(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildHistoryCard(_HistoryItem item) {
    final statusColor = item.status == '정산 완료' ? const Color(0xFF34D399) : const Color(0xFFF59E0B);
    final borderColor = statusColor.withOpacity(0.35);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.date,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.site,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: item.role,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const TextSpan(text: ' · ', style: TextStyle(color: Color(0xFF64748B))),
                          TextSpan(
                            text: item.pay,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusLabel(item.status, statusColor),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildHistoryCard(item),
            ),
          )
          .toList(),
    );
  }
}

class _HistoryItem {
  const _HistoryItem({
    required this.date,
    required this.site,
    required this.role,
    required this.pay,
    required this.status,
  });

  final String date;
  final String site;
  final String role;
  final String pay;
  final String status;
}
