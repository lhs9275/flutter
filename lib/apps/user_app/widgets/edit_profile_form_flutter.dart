import 'package:flutter/material.dart';

class EditProfileFormFlutter extends StatelessWidget {
  const EditProfileFormFlutter({
    super.key,
    required this.onCancel,
    required this.onSave,
    required this.preferredRegions,
    required this.regionInputController,
    required this.onAddRegion,
    required this.onRemoveRegion,
    required this.onMoveRegionUp,
    required this.onMoveRegionDown,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;
  final List<String> preferredRegions;
  final TextEditingController regionInputController;
  final bool Function(String region) onAddRegion;
  final ValueChanged<int> onRemoveRegion;
  final ValueChanged<int> onMoveRegionUp;
  final ValueChanged<int> onMoveRegionDown;

  void _tryAddRegion(BuildContext context) {
    final value = regionInputController.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('추가할 지역을 입력해주세요.')),
      );
      return;
    }
    final added = onAddRegion(value);
    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 등록된 지역입니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('프로필 수정', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: '이름', filled: true)),
        const SizedBox(height: 12),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('선호 지역', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: regionInputController,
                decoration: const InputDecoration(labelText: '지역 추가', filled: true),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: () => _tryAddRegion(context), child: const Text('추가')),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          '우선순위는 위에서 아래 순서입니다.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        const SizedBox(height: 10),
        if (preferredRegions.isEmpty)
          const Text('등록된 선호 지역이 없습니다.', style: TextStyle(color: Color(0xFF94A3B8)))
        else
          Column(
            children: List.generate(preferredRegions.length, (index) {
              final region = preferredRegions[index];
              final isFirst = index == 0;
              final isLast = index == preferredRegions.length - 1;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text('${index + 1}. $region')),
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 18),
                      onPressed: isFirst ? null : () => onMoveRegionUp(index),
                      tooltip: '위로',
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 18),
                      onPressed: isLast ? null : () => onMoveRegionDown(index),
                      tooltip: '아래로',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => onRemoveRegion(index),
                      tooltip: '삭제',
                    ),
                  ],
                ),
              );
            }),
          ),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: '은행', filled: true)),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onSave,
                child: const Text('저장'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
