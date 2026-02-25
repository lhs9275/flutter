import 'package:flutter/material.dart';

class NoticeManagementFlutter extends StatefulWidget {
  const NoticeManagementFlutter({
    super.key,
    this.notices = const [],
    this.onCreate,
    this.onUpdate,
    this.onLoadDetail,
    this.onDelete,
    this.onRefresh,
    this.isLoading = false,
    this.error,
  });

  final List<Map<String, dynamic>> notices;
  final Future<void> Function(String title, String content, bool emergency)?
  onCreate;
  final Future<void> Function(
    String id,
    String title,
    String content,
    bool emergency,
  )?
  onUpdate;
  final Future<Map<String, dynamic>> Function(String id)? onLoadDetail;
  final Future<void> Function(String id)? onDelete;
  final Future<void> Function()? onRefresh;
  final bool isLoading;
  final String? error;

  @override
  State<NoticeManagementFlutter> createState() =>
      _NoticeManagementFlutterState();
}

class _NoticeManagementFlutterState extends State<NoticeManagementFlutter> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _emergency = false;
  bool _isSubmitting = false;
  String? _editingId;
  String? _deletingId;

  static const List<Map<String, dynamic>> _fallbackNotices = [
    {
      'id': 'sample-1',
      'title': '안전 교육 공지',
      'content': '모든 현장 필수',
      'emergency': false,
    },
    {
      'id': 'sample-2',
      'title': '휴무일 안내',
      'content': '광복절 휴무',
      'emergency': false,
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _visibleNotices {
    if (widget.notices.isNotEmpty) return widget.notices;
    final hasRemoteHooks =
        widget.onCreate != null ||
        widget.onUpdate != null ||
        widget.onDelete != null ||
        widget.onRefresh != null;
    if (hasRemoteHooks) return const [];
    return _fallbackNotices;
  }

  Future<void> _submit(BuildContext context) async {
    if (_isSubmitting) return;
    final onCreate = widget.onCreate;
    if (onCreate == null) return;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목과 내용을 입력해주세요.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await onCreate(title, content, _emergency);
      if (!mounted) return;
      _titleController.clear();
      _contentController.clear();
      setState(() => _emergency = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공지 등록이 완료되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('공지 등록 실패: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteNotice(BuildContext context, String id) async {
    final onDelete = widget.onDelete;
    if (onDelete == null || id.isEmpty) return;
    if (_deletingId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공지 삭제'),
        content: const Text('이 공지를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deletingId = id);
    try {
      await onDelete(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공지를 삭제했습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('공지 삭제 실패: $e')));
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  Future<void> _editNotice(
    BuildContext context,
    Map<String, dynamic> notice,
  ) async {
    final onUpdate = widget.onUpdate;
    if (onUpdate == null) return;
    final id = (notice['id']?.toString() ?? '').trim();
    if (id.isEmpty || _editingId != null) return;

    Map<String, dynamic> latestNotice = Map<String, dynamic>.from(notice);
    final onLoadDetail = widget.onLoadDetail;
    if (onLoadDetail != null) {
      try {
        latestNotice = await onLoadDetail(id);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('최신 공지 정보 조회 실패 (기존 값으로 진행): $e')),
        );
      }
    }

    final titleController = TextEditingController(
      text: (latestNotice['title']?.toString() ?? '').trim(),
    );
    final contentController = TextEditingController(
      text: (latestNotice['content']?.toString() ?? '').trim(),
    );
    var emergency = latestNotice['emergency'] == true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('공지 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    filled: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '내용',
                    filled: true,
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: emergency,
                  onChanged: (value) =>
                      setDialogState(() => emergency = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('긴급 공지'),
                  dense: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    final title = titleController.text.trim();
    final content = contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목과 내용을 입력해주세요.')));
      return;
    }

    setState(() => _editingId = id);
    try {
      await onUpdate(id, title, content, emergency);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공지 수정이 완료되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('공지 수정 실패: $e')));
    } finally {
      if (mounted) setState(() => _editingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notices = _visibleNotices;
    final errorText = (widget.error ?? '').trim();
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
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '공지 등록',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.onRefresh != null)
                    TextButton.icon(
                      onPressed: widget.isLoading
                          ? null
                          : () => widget.onRefresh!.call(),
                      icon: widget.isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 16),
                      label: const Text('새로고침'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '내용',
                  filled: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _emergency,
                onChanged: (value) =>
                    setState(() => _emergency = value ?? false),
                contentPadding: EdgeInsets.zero,
                title: const Text('긴급 공지'),
                dense: true,
              ),
              if (errorText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    errorText,
                    style: const TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (widget.onCreate == null || _isSubmitting)
                      ? null
                      : () => _submit(context),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('공지 등록'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (widget.isLoading && notices.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (notices.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text(
              '등록된 공지가 없습니다.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          )
        else
          ...notices.map((notice) {
            final idText = (notice['id']?.toString() ?? '').trim();
            final isEditing = idText.isNotEmpty && _editingId == idText;
            final isDeleting = idText.isNotEmpty && _deletingId == idText;
            final emergency = notice['emergency'] == true;
            final title = notice['title']?.toString() ?? '';
            final content = notice['content']?.toString() ?? '';
            final subtitleParts = <String>[
              if (content.trim().isNotEmpty) content.trim(),
              if ((notice['createdAt']?.toString() ?? '').trim().isNotEmpty)
                (notice['createdAt']?.toString() ?? '').trim(),
            ];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                tileColor: const Color(0xFFFFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(title)),
                    if (emergency)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Text(
                          '긴급',
                          style: TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: subtitleParts.isEmpty
                    ? null
                    : Text(subtitleParts.join(' · ')),
                trailing:
                    ((widget.onDelete == null && widget.onUpdate == null) ||
                        idText.isEmpty)
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onUpdate != null)
                            IconButton(
                              onPressed: (isEditing || isDeleting)
                                  ? null
                                  : () => _editNotice(context, notice),
                              icon: isEditing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.edit_outlined),
                            ),
                          if (widget.onDelete != null)
                            IconButton(
                              onPressed: (isEditing || isDeleting)
                                  ? null
                                  : () => _deleteNotice(context, idText),
                              icon: isDeleting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.delete_outline),
                            ),
                        ],
                      ),
              ),
            );
          }),
      ],
    );
  }
}
