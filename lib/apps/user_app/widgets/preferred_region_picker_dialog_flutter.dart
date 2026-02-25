import 'package:flutter/material.dart';

import '../data/region_code_catalog.dart';

Future<String?> showPreferredRegionPickerDialog(
  BuildContext context, {
  Iterable<String> excludedCodes = const [],
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _PreferredRegionPickerSheet(excludedCodes: excludedCodes.toSet()),
  );
}

class _PreferredRegionPickerSheet extends StatefulWidget {
  const _PreferredRegionPickerSheet({required this.excludedCodes});

  final Set<String> excludedCodes;

  @override
  State<_PreferredRegionPickerSheet> createState() =>
      _PreferredRegionPickerSheetState();
}

class _PreferredRegionPickerSheetState
    extends State<_PreferredRegionPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PreferredRegionOption> get _filteredOptions {
    final normalizedExcluded = widget.excludedCodes
        .map((e) => extractPreferredRegionCode(e) ?? e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    return preferredRegionCatalog.where((option) {
      if (normalizedExcluded.contains(option.code)) return false;
      return option.matches(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final options = _filteredOptions;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: 520,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '선호 지역 선택 (지역코드 기준)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: '지역명 또는 코드 검색',
                    hintText: '예: 강남구, 11680',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                  ),
                  onChanged: (value) => setState(() => _query = value.trim()),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '선택하면 우선순위 목록에 코드로 저장됩니다.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
              ),
              Expanded(
                child: options.isEmpty
                    ? const Center(
                        child: Text(
                          '검색 결과가 없습니다.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: options.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return ListTile(
                            title: Text(option.name),
                            subtitle: Text('지역코드 ${option.code}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).pop(option.code),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
