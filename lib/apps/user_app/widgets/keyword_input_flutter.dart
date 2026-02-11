import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegistrationFormFlutter extends StatefulWidget {
  const RegistrationFormFlutter({
    super.key,
    required this.phoneController,
    required this.nameController,
    required this.idNumberController,
    required this.nationalityController,
    required this.regionInputController,
    required this.preferredRegions,
    required this.onAddRegion,
    required this.onRemoveRegion,
    required this.onMoveRegionUp,
    required this.onMoveRegionDown,
    required this.bankController,
    required this.accountController,
    required this.ownerController,
    required this.gender,
    required this.onGenderChanged,
    required this.onSubmit,
  });

  final TextEditingController phoneController;
  final TextEditingController nameController;
  final TextEditingController idNumberController;
  final TextEditingController nationalityController;
  final TextEditingController regionInputController;
  final List<String> preferredRegions;
  final bool Function(String region) onAddRegion;
  final ValueChanged<int> onRemoveRegion;
  final ValueChanged<int> onMoveRegionUp;
  final ValueChanged<int> onMoveRegionDown;
  final TextEditingController bankController;
  final TextEditingController accountController;
  final TextEditingController ownerController;
  final String gender;
  final ValueChanged<String?> onGenderChanged;
  final VoidCallback onSubmit;

  @override
  State<RegistrationFormFlutter> createState() => _RegistrationFormFlutterState();
}

class _RegistrationFormFlutterState extends State<RegistrationFormFlutter> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _idFile;
  XFile? _safetyFile;
  XFile? _bankFile;
  XFile? _extraPendingFile;
  final TextEditingController _extraDocController = TextEditingController();
  final List<_ExtraDoc> _extraDocs = [];
  late final VoidCallback _identityListener;

  @override
  void initState() {
    super.initState();
    _identityListener = () => setState(() {});
    widget.nameController.addListener(_identityListener);
    widget.ownerController.addListener(_identityListener);
  }

  @override
  void dispose() {
    widget.nameController.removeListener(_identityListener);
    widget.ownerController.removeListener(_identityListener);
    _extraDocController.dispose();
    super.dispose();
  }

  bool get _needsRelationshipDoc {
    final name = widget.nameController.text.trim();
    final owner = widget.ownerController.text.trim();
    if (name.isEmpty || owner.isEmpty) return false;
    return name != owner;
  }

  Future<XFile?> _pickFile() async {
    return _imagePicker.pickImage(source: ImageSource.gallery);
  }

  Future<void> _pickRequiredDoc(_RequiredDocType type) async {
    final file = await _pickFile();
    if (file == null) return;
    setState(() {
      switch (type) {
        case _RequiredDocType.id:
          _idFile = file;
          break;
        case _RequiredDocType.safety:
          _safetyFile = file;
          break;
        case _RequiredDocType.bank:
          _bankFile = file;
          break;
      }
    });
  }

  void _removeRequiredDoc(_RequiredDocType type) {
    setState(() {
      switch (type) {
        case _RequiredDocType.id:
          _idFile = null;
          break;
        case _RequiredDocType.safety:
          _safetyFile = null;
          break;
        case _RequiredDocType.bank:
          _bankFile = null;
          break;
      }
    });
  }

  Future<void> _pickExtraDocFile() async {
    final file = await _pickFile();
    if (file == null) return;
    setState(() => _extraPendingFile = file);
  }

  void _addExtraDoc() {
    final label = _extraDocController.text.trim();
    if (label.isEmpty || _extraPendingFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서류 설명과 사진을 모두 선택해주세요.')),
      );
      return;
    }
    setState(() {
      _extraDocs.add(_ExtraDoc(label: label, file: _extraPendingFile!));
      _extraPendingFile = null;
      _extraDocController.clear();
    });
  }

  void _removeExtraDoc(int index) {
    setState(() {
      _extraDocs.removeAt(index);
    });
  }

  void _submit() {
    if (!(_idFile != null && _safetyFile != null && _bankFile != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 서류 3종을 모두 첨부해주세요.')),
      );
      return;
    }
    if (widget.preferredRegions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선호 지역을 최소 1개 이상 등록해주세요.')),
      );
      return;
    }
    widget.onSubmit();
  }

  void _tryAddRegion() {
    final value = widget.regionInputController.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('추가할 지역을 입력해주세요.')),
      );
      return;
    }
    final added = widget.onAddRegion(value);
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
        const Text('회원가입', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: widget.phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: '휴대폰 번호', filled: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.nameController,
          decoration: const InputDecoration(labelText: '이름', filled: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.idNumberController,
          decoration: const InputDecoration(labelText: '주민등록번호', filled: true),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: widget.gender,
          items: const [
            DropdownMenuItem(value: 'male', child: Text('남성')),
            DropdownMenuItem(value: 'female', child: Text('여성')),
          ],
          onChanged: widget.onGenderChanged,
          decoration: const InputDecoration(labelText: '성별', filled: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.nationalityController,
          decoration: const InputDecoration(labelText: '국적', filled: true),
        ),
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
                controller: widget.regionInputController,
                decoration: const InputDecoration(labelText: '지역 추가', filled: true),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _tryAddRegion, child: const Text('추가')),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          '우선순위는 위에서 아래 순서입니다.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        const SizedBox(height: 10),
        if (widget.preferredRegions.isEmpty)
          const Text('등록된 선호 지역이 없습니다.', style: TextStyle(color: Color(0xFF94A3B8)))
        else
          Column(
            children: List.generate(widget.preferredRegions.length, (index) {
              final region = widget.preferredRegions[index];
              final isFirst = index == 0;
              final isLast = index == widget.preferredRegions.length - 1;
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
                    Expanded(
                      child: Text('${index + 1}. $region'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 18),
                      onPressed: isFirst ? null : () => widget.onMoveRegionUp(index),
                      tooltip: '위로',
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 18),
                      onPressed: isLast ? null : () => widget.onMoveRegionDown(index),
                      tooltip: '아래로',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => widget.onRemoveRegion(index),
                      tooltip: '삭제',
                    ),
                  ],
                ),
              );
            }),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.bankController,
          decoration: const InputDecoration(labelText: '은행', filled: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.accountController,
          decoration: const InputDecoration(labelText: '계좌번호', filled: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.ownerController,
          decoration: const InputDecoration(labelText: '예금주', filled: true),
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          title: '필수 서류',
          subtitle: '근로자 등록을 위해 아래 3종 첨부가 필요합니다.',
        ),
        const SizedBox(height: 10),
        _AttachmentTile(
          title: '신분증',
          description: '주민등록증/운전면허증 사진',
          fileName: _idFile?.name,
          onSelect: () => _pickRequiredDoc(_RequiredDocType.id),
          onRemove: _idFile == null ? null : () => _removeRequiredDoc(_RequiredDocType.id),
        ),
        const SizedBox(height: 8),
        _AttachmentTile(
          title: '건설업 기초안전보건교육 이수증',
          description: '이수증 사진',
          fileName: _safetyFile?.name,
          onSelect: () => _pickRequiredDoc(_RequiredDocType.safety),
          onRemove: _safetyFile == null ? null : () => _removeRequiredDoc(_RequiredDocType.safety),
        ),
        const SizedBox(height: 8),
        _AttachmentTile(
          title: '은행계좌 사본',
          description: '통장 사본 사진',
          fileName: _bankFile?.name,
          onSelect: () => _pickRequiredDoc(_RequiredDocType.bank),
          onRemove: _bankFile == null ? null : () => _removeRequiredDoc(_RequiredDocType.bank),
        ),
        const SizedBox(height: 16),
        _SectionHeader(
          title: '기타 서류',
          subtitle: _needsRelationshipDoc
              ? '예금주가 본인이 아닌 경우 가족관계증명 등 추가 서류를 첨부해주세요.'
              : '선택 사항 (필요 시 추가 첨부)',
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _extraDocController,
          decoration: const InputDecoration(
            labelText: '서류 설명 (예: 가족관계증명서)',
            filled: true,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton(
              onPressed: _pickExtraDocFile,
              child: Text(_extraPendingFile == null ? '사진 선택' : '사진 변경'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addExtraDoc,
              child: const Text('추가'),
            ),
          ],
        ),
        if (_extraPendingFile != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '선택된 사진: ${_extraPendingFile!.name}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (_extraDocs.isEmpty)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('추가 서류 없음', style: TextStyle(color: Color(0xFF64748B))),
          ),
        if (_extraDocs.isNotEmpty)
          Column(
            children: _extraDocs
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ExtraDocItem(
                      label: entry.value.label,
                      fileName: entry.value.file.name,
                      onRemove: () => _removeExtraDoc(entry.key),
                    ),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submit,
            child: const Text('가입 완료'),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
      ],
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.title,
    required this.description,
    required this.fileName,
    required this.onSelect,
    this.onRemove,
  });

  final String title;
  final String description;
  final String? fileName;
  final VoidCallback onSelect;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onSelect,
                child: Text(fileName == null ? '사진 첨부' : '사진 변경'),
              ),
              if (fileName != null && onRemove != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onRemove,
                  child: const Text('삭제'),
                ),
              ],
            ],
          ),
          if (fileName != null) ...[
            const SizedBox(height: 6),
            Text('사진: $fileName', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ],
      ),
    );
  }
}

class _ExtraDocItem extends StatelessWidget {
  const _ExtraDocItem({required this.label, required this.fileName, required this.onRemove});

  final String label;
  final String fileName;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label · $fileName',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ExtraDoc {
  const _ExtraDoc({required this.label, required this.file});

  final String label;
  final XFile file;
}

enum _RequiredDocType { id, safety, bank }
