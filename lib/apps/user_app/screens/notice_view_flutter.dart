import 'package:flutter/material.dart';

import '../../../data/cwmp_api_models.dart';
import '../../../data/cwmp_api_repository.dart';
import '../../../data/cwmp_session_store.dart';

class NoticeViewFlutter extends StatefulWidget {
  const NoticeViewFlutter({super.key});

  @override
  State<NoticeViewFlutter> createState() => _NoticeViewFlutterState();
}

class _NoticeViewFlutterState extends State<NoticeViewFlutter> {
  bool _isLoading = true;
  String? _error;
  int? _sessionUserId;
  bool _loadedFromUserEndpoint = false;
  List<_NoticeItem> _notices = const [];

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final session = await CwmpSessionStore.read();
      final userId = session?.userId ?? 0;
      List<CwmpNotificationResponse> responses;
      var loadedFromUserEndpoint = false;
      if (userId > 0) {
        try {
          responses = await CwmpApiRepository.instance.getNotificationsForUser(
            userId,
          );
          loadedFromUserEndpoint = true;
        } on CwmpApiException catch (_) {
          responses = await CwmpApiRepository.instance.getNotifications();
        }
      } else {
        responses = await CwmpApiRepository.instance.getNotifications();
      }
      if (!mounted) return;
      setState(() {
        _sessionUserId = userId > 0 ? userId : null;
        _loadedFromUserEndpoint = loadedFromUserEndpoint;
        _notices = responses.map(_NoticeItem.fromApi).toList();
      });
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '알림을 불러오지 못했습니다: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openNoticeDetail(_NoticeItem notice) async {
    if (notice.id <= 0) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: SizedBox(
          height: 72,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
    try {
      final detail = await CwmpApiRepository.instance.getNotification(
        notice.id,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(detail.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (detail.isEmergency)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: const Text(
                      '긴급 공지',
                      style: TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Text(
                  detail.content,
                  style: const TextStyle(color: Color(0xFF334155)),
                ),
                const SizedBox(height: 10),
                Text(
                  '작성자 ID: ${detail.userId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('공지 상세 조회 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final notices = _notices.isNotEmpty
        ? _notices
        : const [
            _NoticeItem(id: 0, userId: 0, title: '안전 수칙 안내', body: '안전화 필수 착용'),
            _NoticeItem(id: 0, userId: 0, title: '급여 정산 일정', body: '매주 금요일 지급'),
            _NoticeItem(
              id: 0,
              userId: 0,
              title: '우천 시 작업 안내',
              body: '기상 상황에 따라 일정이 조정될 수 있습니다.',
            ),
          ];

    final children = <Widget>[
      _HeaderState(
        isLoading: _isLoading,
        error: _error,
        onRetry: _loadNotices,
        infoText: _loadedFromUserEndpoint && (_sessionUserId ?? 0) > 0
            ? '내 알림 기준 (userId=${_sessionUserId!})'
            : '전체 알림 기준',
      ),
      ...notices.map(
        (notice) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _NoticeCard(
            notice: notice,
            onTap: () => _openNoticeDetail(notice),
          ),
        ),
      ),
    ];

    return RefreshIndicator(
      onRefresh: _loadNotices,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: children,
      ),
    );
  }
}

class _NoticeItem {
  const _NoticeItem({
    required this.id,
    required this.title,
    required this.body,
    required this.userId,
    this.isEmergency = false,
    this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final int userId;
  final bool isEmergency;
  final DateTime? createdAt;

  factory _NoticeItem.fromApi(CwmpNotificationResponse response) {
    return _NoticeItem(
      id: response.id,
      title: response.title,
      body: response.content,
      userId: response.userId,
      isEmergency: response.isEmergency,
      createdAt: response.createdAt,
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice, required this.onTap});

  final _NoticeItem notice;
  final VoidCallback onTap;

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final accent = notice.isEmergency
        ? const Color(0xFFDC2626)
        : const Color(0xFF6366F1);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: notice.isEmergency
                  ? const Color(0xFFFECACA)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: notice.isEmergency
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.campaign, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notice.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (notice.isEmergency)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFFCA5A5),
                              ),
                            ),
                            child: const Text(
                              '긴급',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFB91C1C),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notice.body,
                      style: const TextStyle(color: Color(0xFF475569)),
                    ),
                    if (notice.createdAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(notice.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderState extends StatelessWidget {
  const _HeaderState({
    required this.isLoading,
    required this.error,
    required this.onRetry,
    this.infoText,
  });

  final bool isLoading;
  final String? error;
  final Future<void> Function() onRetry;
  final String? infoText;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if ((error ?? '').isEmpty) {
      final info = (infoText ?? '').trim();
      if (info.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          info,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '알림 불러오기 실패',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF991B1B),
              ),
            ),
          ),
          TextButton(onPressed: () => onRetry(), child: const Text('다시시도')),
        ],
      ),
    );
  }
}
