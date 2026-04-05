import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:partition_app/features/partition/models/shared_expense_table_item.dart';
import 'package:partition_app/shared/widgets/glassmorphism_widget.dart';

/// 공용 소비 내역 수동 추가·수정 (홈 집안일 자동 배정 모달과 동일 글래스 톤)
class SharedExpenseManualModal extends StatefulWidget {
  final bool isUtility;
  final List<SharedExpenseTableItem> initialItems;
  final void Function(List<SharedExpenseTableItem> items) onApply;

  const SharedExpenseManualModal({
    super.key,
    required this.isUtility,
    required this.initialItems,
    required this.onApply,
  });

  @override
  State<SharedExpenseManualModal> createState() =>
      _SharedExpenseManualModalState();
}

class _SharedExpenseManualModalState extends State<SharedExpenseManualModal> {
  /// 물품: 대분류 → 소분류 옵션
  static const Map<String, List<String>> _goodsCategoryMinors = {
    '식품': [
      '유제품',
      '육류·계란',
      '채소·과일',
      '시리얼·간식',
      '조미료·양념',
      '냉동·즉석',
      '음료',
      '기타',
    ],
    '생활용품': ['세제', '화장지·물티슈', '청소용품', '욕실용품', '기타'],
    '주방': ['조리도구', '용기·보관', '일회용품', '기타'],
    '문구·가전': ['문구', '소형가전', '케이블·어댑터', '기타'],
    '기타': ['일반'],
  };

  late List<SharedExpenseTableItem> _items;
  bool _isForm = false;
  int? _editIndex; // null = 새 추가

  /// 공과금 항목명
  late final TextEditingController _nameCtrl;
  /// 물품 구체 표기 (예: 콘프라이트 500g)
  late final TextEditingController _detailCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _qtyCtrl;

  String? _selectedMajor;
  String? _selectedMinor;

  @override
  void initState() {
    super.initState();
    _items = List<SharedExpenseTableItem>.from(widget.initialItems);
    _nameCtrl = TextEditingController();
    _detailCtrl = TextEditingController();
    _dateCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
    _qtyCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _detailCtrl.dispose();
    _dateCtrl.dispose();
    _amountCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  List<String> _minorOptionsFor(String? major) {
    if (major == null || !_goodsCategoryMinors.containsKey(major)) {
      return const [];
    }
    return _goodsCategoryMinors[major]!;
  }

  void _onMajorChanged(String? value) {
    setState(() {
      _selectedMajor = value;
      _selectedMinor = null;
      final minors = _minorOptionsFor(value);
      if (minors.length == 1) {
        _selectedMinor = minors.first;
      }
    });
  }

  void _openAddForm() {
    setState(() {
      _isForm = true;
      _editIndex = null;
      _nameCtrl.clear();
      _detailCtrl.clear();
      _dateCtrl.clear();
      _amountCtrl.clear();
      _qtyCtrl.clear();
      _selectedMajor = null;
      _selectedMinor = null;
    });
  }

  void _openEditForm(int index) {
    final e = _items[index];
    setState(() {
      _isForm = true;
      _editIndex = index;
      _dateCtrl.text = e.date;
      _amountCtrl.text = e.amount;
      _qtyCtrl.text = e.quantity ?? '';
      if (widget.isUtility) {
        _nameCtrl.text = e.name;
        _detailCtrl.clear();
        _selectedMajor = null;
        _selectedMinor = null;
      } else {
        _nameCtrl.clear();
        _selectedMajor = e.majorCategory;
        final minors = _minorOptionsFor(e.majorCategory);
        if (e.minorCategory != null && minors.contains(e.minorCategory)) {
          _selectedMinor = e.minorCategory;
        } else if (minors.length == 1) {
          _selectedMinor = minors.first;
        } else {
          _selectedMinor = null;
        }
        final hasStructured = e.majorCategory != null ||
            e.minorCategory != null ||
            (e.detail != null && e.detail!.trim().isNotEmpty);
        if (hasStructured) {
          _detailCtrl.text = (e.detail ?? '').trim();
        } else {
          _detailCtrl.text = e.name;
        }
      }
    });
  }

  void _saveForm() {
    final date = _dateCtrl.text.trim();
    final amount = _amountCtrl.text.trim();
    final qty = _qtyCtrl.text.trim();

    if (widget.isUtility) {
      final name = _nameCtrl.text.trim();
      if (name.isEmpty || date.isEmpty || amount.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('항목명, 날짜, 금액은 필수예요.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      final row = SharedExpenseTableItem(
        name: name,
        date: date,
        amount: amount,
        quantity: qty.isEmpty ? null : qty,
      );
      _commitRow(row);
      return;
    }

    final major = _selectedMajor?.trim();
    final minor = _selectedMinor?.trim();
    final detail = _detailCtrl.text.trim();
    if (major == null ||
        major.isEmpty ||
        minor == null ||
        minor.isEmpty ||
        detail.isEmpty ||
        date.isEmpty ||
        amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('대분류, 소분류, 내용, 날짜, 금액은 필수예요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final composedName = [major, minor, detail].join(' · ');
    final row = SharedExpenseTableItem(
      name: composedName,
      date: date,
      amount: amount,
      quantity: qty.isEmpty ? null : qty,
      majorCategory: major,
      minorCategory: minor,
      detail: detail,
    );
    _commitRow(row);
  }

  void _commitRow(SharedExpenseTableItem row) {
    setState(() {
      if (_editIndex == null) {
        _items.add(row);
      } else {
        _items[_editIndex!] = row;
      }
      _isForm = false;
      _editIndex = null;
    });
  }

  void _deleteAt(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _applyAndClose() {
    widget.onApply(List<SharedExpenseTableItem>.from(_items));
    Navigator.of(context).pop(true);
  }

  static const _titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard Variable',
    height: 0.7,
  );

  static const _subtitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    fontFamily: 'Pretendard Variable',
    height: 1.08,
  );

  /// 텍스트 필드·드롭다운 행의 글래스 안쪽 여백
  static const EdgeInsets _kGlassFieldPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  /// 내역 목록에서 항목 이름(제목) — 기본 13의 약 1.2배 + 볼드
  static const TextStyle _listItemTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    fontFamily: 'Pretendard Variable',
    height: 1.2,
  );

  static ButtonStyle _listOutlineButtonStyle({required Color foreground}) {
    return OutlinedButton.styleFrom(
      foregroundColor: foreground,
      side: BorderSide(color: Colors.white.withOpacity(0.9), width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minimumSize: const Size(48, 30),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.45),
        fontSize: 13,
        fontFamily: 'Pretendard Variable',
      ),
      isDense: true,
      contentPadding: EdgeInsets.zero,
      border: InputBorder.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final screenH = MediaQuery.sizeOf(context).height;
    final dialogW = (screenW - 40).clamp(300.0, 350.0);
    // 집안일 모달(고정 323) · 날짜 선택 등과 비슷한 비율로 제한, 내용은 스크롤
    final maxDialogH = (screenH * 0.52).clamp(300.0, 480.0);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(255, 255, 255, 0.25),
                  offset: Offset(4, 4),
                  blurRadius: 30,
                ),
              ],
            ),
            child: GlassmorphismWidget(
              width: dialogW,
              height: maxDialogH,
              borderRadius: BorderRadius.circular(20),
              backgroundOpacity: 0.12,
              borderColor: Colors.white.withOpacity(0.5),
              strokeGradient: const RadialGradient(
                center: Alignment(-0.1212, -0.1178),
                radius: 1.7145,
                colors: [
                  Color.fromRGBO(255, 255, 255, 0.10),
                  Color.fromRGBO(255, 255, 255, 0.15),
                ],
                stops: [0.0, 1.0],
              ),
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
              child: _isForm ? _buildForm() : _buildList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.isUtility ? '공과금 내역 추가·수정' : '공용 소비 내역 추가·수정',
          textAlign: TextAlign.center,
          style: _titleStyle,
        ),
        const SizedBox(height: 8),
        Text(
          widget.isUtility
              ? '항목을 직접 입력해 표에 반영할 수 있어요'
              : 'AI 영수증 없이 물품 내역을 직접 추가·수정해요',
          textAlign: TextAlign.center,
          style: _subtitleStyle,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _items.isEmpty
              ? Center(
                  child: Text(
                    '등록된 내역이 없어요.\n아래에서 추가해 보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final e = _items[i];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.45),
                                width: 0.5),
                            gradient: const RadialGradient(
                              center: Alignment(-0.1212, -0.1178),
                              radius: 1.7145,
                              colors: [
                                Color.fromRGBO(255, 255, 255, 0.12),
                                Color.fromRGBO(255, 255, 255, 0.22),
                              ],
                              stops: [0.0, 1.0],
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.displayLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _listItemTitleStyle,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${e.date} · ${e.amount}'
                                      '${e.quantity != null && e.quantity!.isNotEmpty ? ' · ${e.quantity}' : ''}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.75),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () => _openEditForm(i),
                                style: _listOutlineButtonStyle(
                                  foreground: Colors.white,
                                ),
                                child: const Text(
                                  '수정',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              OutlinedButton(
                                onPressed: () => _deleteAt(i),
                                style: _listOutlineButtonStyle(
                                  foreground: Colors.red.shade200,
                                ),
                                child: Text(
                                  '삭제',
                                  style: TextStyle(
                                    color: Colors.red.shade200,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 14),
        _glassPillButton(
          label: '내역 추가',
          onTap: _openAddForm,
        ),
        const SizedBox(height: 10),
        _glassPillButton(
          label: '표에 반영하기',
          onTap: _applyAndClose,
        ),
      ],
    );
  }

  Widget _buildForm() {
    final qtyLabel = widget.isUtility ? '비고' : '수량';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _editIndex == null ? '공용소비내역 추가' : '내역 수정',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: _titleStyle.copyWith(height: 1.15, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          '입력 후 저장하면 목록에 반영돼요',
          textAlign: TextAlign.center,
          style: _subtitleStyle,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
                if (widget.isUtility) ...[
                  _glassField(
                    child: TextField(
                      controller: _nameCtrl,
                      style: _inputStyle,
                      decoration:
                          _fieldDecoration('항목명 (예: 수도세)'),
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  _buildCategoryPickerField(
                    hint: '대분류 선택',
                    value: _selectedMajor,
                    enabled: true,
                    onTap: () async {
                      final picked = await _showCategoryPickerSheet(
                        title: '대분류',
                        options: _goodsCategoryMinors.keys.toList(),
                        current: _selectedMajor,
                      );
                      if (picked != null && mounted) _onMajorChanged(picked);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildCategoryPickerField(
                    hint: '소분류 선택',
                    value: _selectedMinor,
                    enabled: _selectedMajor != null &&
                        _minorOptionsFor(_selectedMajor).isNotEmpty,
                    onTap: () async {
                      final opts = _minorOptionsFor(_selectedMajor);
                      if (opts.isEmpty) return;
                      final picked = await _showCategoryPickerSheet(
                        title: '소분류',
                        options: opts,
                        current: _selectedMinor,
                      );
                      if (picked != null && mounted) {
                        setState(() => _selectedMinor = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _glassField(
                    child: TextField(
                      controller: _detailCtrl,
                      style: _inputStyle,
                      decoration: _fieldDecoration('내용 (예: 콘프라이트 500g)'),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _glassField(
                  child: TextField(
                    controller: _dateCtrl,
                    style: _inputStyle,
                    decoration: _fieldDecoration('날짜 (예: 25.05.04. 또는 3일 뒤)'),
                  ),
                ),
                const SizedBox(height: 10),
                _glassField(
                  child: TextField(
                    controller: _amountCtrl,
                    style: _inputStyle,
                    keyboardType: TextInputType.text,
                    decoration: _fieldDecoration('금액 (예: 5,980원)'),
                  ),
                ),
                const SizedBox(height: 10),
                _glassField(
                  child: TextField(
                    controller: _qtyCtrl,
                    style: _inputStyle,
                    decoration: _fieldDecoration(
                        '$qtyLabel (선택, 예: 3개 또는 후불)'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _glassPillButton(label: '저장', onTap: _saveForm),
      ],
    );
  }

  /// 드롭다운 대신 바텀시트로 선택 — 글래스 Clip·dense 조합으로 글자 잘림·겹침 방지
  Future<String?> _showCategoryPickerSheet({
    required String title,
    required List<String> options,
    String? current,
  }) async {
    if (options.isEmpty) return null;
    final h = MediaQuery.sizeOf(context).height * 0.42;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        // width·height 둘 다 있어야 Glassmorphism이 StackFit.expand로 자식에 유한 제약 전달
        final sheetW = MediaQuery.sizeOf(ctx).width - 24;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(255, 255, 255, 0.2),
                    offset: Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: GlassmorphismWidget(
                width: sheetW,
                height: h,
                borderRadius: BorderRadius.circular(20),
                backgroundOpacity: 0.12,
                borderColor: Colors.white.withOpacity(0.45),
                strokeGradient: const RadialGradient(
                  center: Alignment(-0.1212, -0.1178),
                  radius: 1.7145,
                  colors: [
                    Color.fromRGBO(255, 255, 255, 0.10),
                    Color.fromRGBO(255, 255, 255, 0.15),
                  ],
                  stops: [0.0, 1.0],
                ),
                padding: EdgeInsets.zero,
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 6, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Pretendard Variable',
                                  height: 1.25,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1, color: Colors.white24),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: options.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Colors.white12,
                          ),
                          itemBuilder: (c, i) {
                            final o = options[i];
                            final sel = o == current;
                            return ListTile(
                              title: Text(
                                o,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      sel ? FontWeight.w700 : FontWeight.w500,
                                  fontFamily: 'Pretendard Variable',
                                  fontSize: 15,
                                  height: 1.35,
                                ),
                              ),
                              trailing: sel
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white70,
                                      size: 22,
                                    )
                                  : null,
                              onTap: () => Navigator.pop(ctx, o),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryPickerField({
    required String hint,
    required String? value,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return _glassField(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: value != null ? _inputStyle : _hintStyle,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withOpacity(
                    enabled ? 0.85 : 0.35,
                  ),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _inputStyle = TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontFamily: 'Pretendard Variable',
    height: 1.35,
  );

  static final _hintStyle = TextStyle(
    color: Colors.white.withOpacity(0.45),
    fontSize: 13,
    fontFamily: 'Pretendard Variable',
    height: 1.35,
  );

  Widget _glassField({required Widget child}) {
    return GlassmorphismWidget(
      borderRadius: BorderRadius.circular(20),
      backgroundOpacity: 0.1,
      borderColor: Colors.white.withOpacity(0.5),
      strokeGradient: const RadialGradient(
        center: Alignment(-0.1212, -0.1178),
        radius: 1.7145,
        colors: [
          Color.fromRGBO(255, 255, 255, 0.10),
          Color.fromRGBO(255, 255, 255, 0.15),
        ],
        stops: [0.0, 1.0],
      ),
      padding: _kGlassFieldPadding,
      child: child,
    );
  }

  Widget _glassPillButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 46,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(23),
                gradient: const RadialGradient(
                  center: Alignment(-0.1212, -0.1178),
                  radius: 1.7145,
                  colors: [
                    Color.fromRGBO(255, 255, 255, 0.10),
                    Color.fromRGBO(255, 255, 255, 0.15),
                  ],
                  stops: [0.0, 1.0],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(255, 255, 255, 0.25),
                    offset: Offset(4, 4),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
