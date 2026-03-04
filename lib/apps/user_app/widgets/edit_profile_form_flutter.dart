import 'package:flutter/material.dart';

import '../data/region_code_catalog.dart';
import 'preferred_region_picker_dialog_flutter.dart';

class EditProfileFormFlutter extends StatelessWidget {
  const EditProfileFormFlutter({
    super.key,
    required this.onCancel,
    required this.onSave,
    required this.nameController,
    required this.idNumberController,
    required this.nationalityController,
    required this.addressController,
    required this.preferredRegions,
    required this.regionInputController,
    required this.onAddRegion,
    required this.onRemoveRegion,
    required this.onMoveRegionUp,
    required this.onMoveRegionDown,
    required this.gender,
    required this.onGenderChanged,
    required this.bankController,
    required this.accountController,
    required this.ownerController,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;
  final TextEditingController nameController;
  final TextEditingController idNumberController;
  final TextEditingController nationalityController;
  final TextEditingController addressController;
  final List<String> preferredRegions;
  final TextEditingController regionInputController;
  final bool Function(String region) onAddRegion;
  final ValueChanged<int> onRemoveRegion;
  final ValueChanged<int> onMoveRegionUp;
  final ValueChanged<int> onMoveRegionDown;
  final String gender;
  final ValueChanged<String?> onGenderChanged;
  final TextEditingController bankController;
  final TextEditingController accountController;
  final TextEditingController ownerController;

  void _tryAddRegion(BuildContext context) {
    final value = regionInputController.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('추가할 지역코드를 입력해주세요.')));
      return;
    }
    final added = onAddRegion(value);
    if (!added) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 등록된 지역입니다.')));
    }
  }

  Future<void> _pickRegion(BuildContext context) async {
    final selectedCode = await showPreferredRegionPickerDialog(
      context,
      excludedCodes: preferredRegions,
    );
    if (selectedCode == null || selectedCode.trim().isEmpty) return;
    final added = onAddRegion(selectedCode);
    if (!context.mounted) return;
    if (!added) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 등록된 지역입니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            children: [
              const Text(
                '프로필 수정',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '이름',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: gender,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('남성')),
                  DropdownMenuItem(value: 'female', child: Text('여성')),
                ],
                onChanged: onGenderChanged,
                decoration: const InputDecoration(
                  labelText: '성별',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nationalityController,
                decoration: const InputDecoration(
                  labelText: '국적',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: idNumberController,
                decoration: const InputDecoration(
                  labelText: '주민등록번호',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: '주소',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '선호 지역',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: regionInputController,
                      decoration: const InputDecoration(
                        labelText: '지역코드 직접 입력 (5자리)',
                        hintText: '예: 11680',
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _tryAddRegion(context),
                    child: const Text('추가'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _pickRegion(context),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('지역 선택'),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '지역코드 기준으로 저장되며, 우선순위는 위에서 아래 순서입니다.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 10),
              if (preferredRegions.isEmpty)
                const Text(
                  '등록된 선호 지역이 없습니다.',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                )
              else
                Column(
                  children: List.generate(preferredRegions.length, (index) {
                    final region = preferredRegions[index];
                    final isFirst = index == 0;
                    final isLast = index == preferredRegions.length - 1;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${index + 1}. ${preferredRegionDisplayLabel(region)}',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_upward, size: 18),
                            onPressed: isFirst
                                ? null
                                : () => onMoveRegionUp(index),
                            tooltip: '위로',
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_downward, size: 18),
                            onPressed: isLast
                                ? null
                                : () => onMoveRegionDown(index),
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
              TextField(
                controller: bankController,
                decoration: const InputDecoration(
                  labelText: '은행',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accountController,
                decoration: const InputDecoration(
                  labelText: '계좌번호',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ownerController,
                decoration: const InputDecoration(
                  labelText: '예금주',
                  filled: true,
                ),
              ),
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
          ),
        ),
      ),
    );
  }
}
