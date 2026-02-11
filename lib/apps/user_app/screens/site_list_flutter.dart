import 'package:flutter/material.dart';
import '../models/application_record.dart';

class SiteListFlutter extends StatelessWidget {
  const SiteListFlutter({
    super.key,
    required this.sites,
    required this.preferredRegions,
    required this.selectedRegion,
    required this.availableRegions,
    required this.showAllRegions,
    required this.onToggleShowAll,
    required this.onRegionSelected,
    required this.onViewDetail,
    required this.onApply,
    required this.onCancel,
    required this.applications,
  });

  final List<Map<String, dynamic>> sites;
  final List<String> preferredRegions;
  final String? selectedRegion;
  final List<String> availableRegions;
  final bool showAllRegions;
  final ValueChanged<bool> onToggleShowAll;
  final ValueChanged<String?> onRegionSelected;
  final ValueChanged<Map<String, dynamic>> onViewDetail;
  final ValueChanged<Map<String, dynamic>> onApply;
  final ValueChanged<Map<String, dynamic>> onCancel;
  final Map<String, ApplicationRecord> applications;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RegionFilterBar(
          preferredRegions: preferredRegions,
          selectedRegion: selectedRegion,
          regions: availableRegions,
          showAllRegions: showAllRegions,
          onToggleShowAll: onToggleShowAll,
          onSelected: onRegionSelected,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: sites.isEmpty
              ? _EmptyState(
                  preferredRegions: preferredRegions,
                  selectedRegion: selectedRegion,
                  showAllRegions: showAllRegions,
                )
              : ListView.separated(
                  itemCount: sites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final site = sites[index];
                    final name = site['name'] ?? '';
                    final address = site['address'] ?? '';
                    final type = site['type'] ?? '';
                    final pay = site['pay'] ?? '-';
                    final date = site['date'] ?? '-';
                    final region = site['region'] ?? '';
                    final id = site['id']?.toString();
                    final application = id == null ? null : applications[id];
                    final status = application?.status;
                    final statusLabel = status == ApplicationStatus.confirmed
                        ? '확정'
                        : status == ApplicationStatus.applied
                            ? '지원 완료'
                            : '모집중';
                    final statusColor = status == ApplicationStatus.confirmed
                        ? const Color(0xFF16A34A)
                        : status == ApplicationStatus.applied
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF64748B);
                    final statusBg = status == ApplicationStatus.confirmed
                        ? const Color(0xFFDCFCE7)
                        : status == ApplicationStatus.applied
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFF1F5F9);
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: statusBg),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('일급 $pay원', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.place, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(address, style: const TextStyle(color: Color(0xFF475569))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (region.toString().isNotEmpty) _InfoChip(label: '지역', value: region.toString()),
                              _InfoChip(label: '직종', value: type),
                              _InfoChip(label: '근무일', value: date),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 96,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onPressed: () => onViewDetail(site),
                                  child: const Text('상세보기'),
                                ),
                              ),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 96,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onPressed: status == ApplicationStatus.confirmed
                                      ? null
                                      : status == ApplicationStatus.applied
                                          ? () => onCancel(site)
                                          : () => onApply(site),
                                  child: Text(
                                    status == ApplicationStatus.confirmed
                                        ? '확정됨'
                                        : status == ApplicationStatus.applied
                                            ? '지원취소'
                                            : '지원하기',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _RegionFilterBar extends StatelessWidget {
  const _RegionFilterBar({
    required this.preferredRegions,
    required this.selectedRegion,
    required this.regions,
    required this.showAllRegions,
    required this.onToggleShowAll,
    required this.onSelected,
  });

  final List<String> preferredRegions;
  final String? selectedRegion;
  final List<String> regions;
  final bool showAllRegions;
  final ValueChanged<bool> onToggleShowAll;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final hasPreferred = preferredRegions.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('지역 필터', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            if (hasPreferred)
              Text(
                '선호 지역: ${preferredRegions.join(', ')}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              )
            else
              const Text(
                '회원가입에서 선호 지역을 입력하세요.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            const Spacer(),
            Text(
              showAllRegions ? '전체 보기' : '선호 지역만',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            Switch(
              value: showAllRegions,
              onChanged: hasPreferred ? onToggleShowAll : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('전체'),
              selected: selectedRegion == null,
              onSelected: (_) => onSelected(null),
              selectedColor: const Color(0xFFDBEAFE),
              labelStyle: TextStyle(
                color: selectedRegion == null ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
              ),
            ),
            ...regions.map((region) {
              final isSelected = selectedRegion == region;
              final isPreferred = hasPreferred && preferredRegions.contains(region);
              return ChoiceChip(
                label: Text(isPreferred ? '$region · 선호' : region),
                selected: isSelected,
                onSelected: (_) => onSelected(region),
                selectedColor: const Color(0xFFDBEAFE),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.preferredRegions,
    required this.selectedRegion,
    required this.showAllRegions,
  });

  final List<String> preferredRegions;
  final String? selectedRegion;
  final bool showAllRegions;

  @override
  Widget build(BuildContext context) {
    final regionLabel =
        selectedRegion ?? (preferredRegions.isNotEmpty ? preferredRegions.join(', ') : '선택된 지역');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 40, color: Color(0xFFCBD5F5)),
          const SizedBox(height: 12),
          Text(
            showAllRegions ? '현재 모집 중인 현장이 없습니다.' : '$regionLabel 현장이 없습니다.',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          const Text('다른 지역을 선택해보세요.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label · $value',
        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
      ),
    );
  }
}
