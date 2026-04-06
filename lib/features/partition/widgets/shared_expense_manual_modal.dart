import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:partition_app/features/partition/models/shared_expense_table_item.dart';
import 'package:partition_app/features/partition/models/supply_category_model.dart';
import 'package:partition_app/shared/widgets/glassmorphism_widget.dart';

/// 공용 소비·공과금 내역 관리 모달 (홈 집안일 자동 배정 모달과 동일 글래스 톤)
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
  /// 물품: 앱 고정 트리 [kDefaultSupplyCategoryGroups]. 공과금: 사용 안 함.
  List<SupplyCategoryGroup> _categories = const [];

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
    if (!widget.isUtility) {
      _categories = kDefaultSupplyCategoryGroups;
    }
  }

  SupplyCategoryGroup? _groupForCategoryName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final c in _categories) {
      if (c.categoryName == name) return c;
    }
    return null;
  }

  /// API 대분류 이름 목록. 수정 중인 행이 예전 데이터면 맨 앞에 임시로 포함
  List<String> _majorNamesForPicker() {
    final api = _categories.map((c) => c.categoryName).toList();
    if (_isForm && _editIndex != null) {
      final m = _items[_editIndex!].majorCategory?.trim();
      if (m != null && m.isNotEmpty && !api.contains(m)) {
        return [m, ...api];
      }
    }
    return api;
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
    if (major == null || major.isEmpty) return const [];
    final g = _groupForCategoryName(major);
    if (g != null) {
      return g.subCategories.map((s) => s.subCategoryName).toList();
    }
    if (_isForm && _editIndex != null) {
      final e = _items[_editIndex!];
      if (e.majorCategory == major &&
          e.minorCategory != null &&
          e.minorCategory!.trim().isNotEmpty) {
        return [e.minorCategory!.trim()];
      }
    }
    return const [];
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

  /// 모달 제목 (18 / 블랙에 가까운 굵기로 통일)
  static const _titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w900,
    fontFamily: 'Pretendard Variable',
    height: 1.15,
  );

  static const _subtitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    fontFamily: 'Pretendard Variable',
    height: 1.08,
  );

  /// 텍스트 필드·카테고리 행 공통 — 카테고리만 넓던 것·텍스트만 낮던 것의 중간 높이로 통일
  static const EdgeInsets _kGlassFieldPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 6);

  static const double _kFormFieldInnerHeight = 38.0;

  /// 내역 목록 항목 제목 — 모달 제목(18)보다 작게 두어 위계 유지
  static const TextStyle _listItemTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard Variable',
    height: 1.1,
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
    // 고정 높이(_kFormFieldInnerHeight) 안에서 한 줄 입력이 세로 가운데 오도록 대칭 패딩
    final vPad = ((_kFormFieldInnerHeight - 13 * 1.35) / 2).clamp(8.0, 14.0);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.45),
        fontSize: 13,
        fontFamily: 'Pretendard Variable',
        height: 1.35,
      ),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: vPad),
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
              padding: const EdgeInsets.fromLTRB(20, 34, 20, 30),
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
          widget.isUtility ? '공과금 내역 관리' : '공용 소비 내역 관리',
          textAlign: TextAlign.center,
          style: _titleStyle,
        ),
        const SizedBox(height: 8),
        Text(
          widget.isUtility
              ? '항목을 직접 입력·수정·삭제하며 공과금 내역을 관리해요'
              : 'AI 영수증 없이 물품 내역을\n직접 입력·수정·삭제하며 관리해요',
          textAlign: TextAlign.center,
          style: _subtitleStyle,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _items.isEmpty
              ? Center(
                  child: Text(
                    '등록된 내역이 없어요.\n아래에서 내역을 추가해 관리해 보세요.',
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
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.white.withOpacity(0.38),
                  ),
                  itemBuilder: (context, i) {
                    final e = _items[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                                const SizedBox(height: 1),
                                Text(
                                  '${e.date} · ${e.amount}'
                                  '${e.quantity != null && e.quantity!.isNotEmpty ? ' · ${e.quantity}' : ''}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 11,
                                    height: 1.2,
                                    fontFamily: 'Pretendard Variable',
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
                              foreground: Colors.white,
                            ),
                            child: const Text(
                              '삭제',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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
          label: '저장',
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
          _editIndex == null
              ? (widget.isUtility ? '공과금 내역 추가' : '공용 소비 내역 추가')
              : '내역 수정',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: _titleStyle.copyWith(height: 1.15),
        ),
        const SizedBox(height: 4),
        Text(
          '저장하면 목록에 반영되어 함께 관리돼요',
          textAlign: TextAlign.center,
          style: _subtitleStyle,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
                if (widget.isUtility) ...[
                  _glassFormField(
                    child: TextField(
                      controller: _nameCtrl,
                      style: _inputStyle,
                      textAlignVertical: TextAlignVertical.center,
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
                      final opts = _majorNamesForPicker();
                      if (opts.isEmpty) return;
                        final picked = await _showGlassCategoryPickerModal(
                          title: '대분류',
                          options: opts,
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
                        final picked = await _showGlassCategoryPickerModal(
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
                  _glassFormField(
                    child: TextField(
                      controller: _detailCtrl,
                      style: _inputStyle,
                      textAlignVertical: TextAlignVertical.center,
                      decoration:
                          _fieldDecoration('제목 (예: 콘프라이트 500g)'),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _glassFormField(
                  child: TextField(
                    controller: _dateCtrl,
                    style: _inputStyle,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: _fieldDecoration('날짜 (예: 25.05.04. 또는 3일 뒤)'),
                  ),
                ),
                const SizedBox(height: 10),
                _glassFormField(
                  child: TextField(
                    controller: _amountCtrl,
                    style: _inputStyle,
                    textAlignVertical: TextAlignVertical.center,
                    keyboardType: TextInputType.text,
                    decoration: _fieldDecoration('금액 (예: 5,980원)'),
                  ),
                ),
                const SizedBox(height: 10),
                _glassFormField(
                  child: TextField(
                    controller: _qtyCtrl,
                    style: _inputStyle,
                    textAlignVertical: TextAlignVertical.center,
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

  /// 대분류·소분류 탭 시 중앙 글래스모피즘 모달
  Future<String?> _showGlassCategoryPickerModal({
    required String title,
    required List<String> options,
    String? current,
  }) async {
    if (options.isEmpty) return null;
    final mq = MediaQuery.of(context);
    final dialogW = (mq.size.width - 48).clamp(280.0, 360.0);
    final dialogH = (mq.size.height * 0.58).clamp(320.0, 520.0);

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.52),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: dialogW,
                height: dialogH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.55),
                    width: 0.5,
                  ),
                  gradient: const RadialGradient(
                    center: Alignment(-0.1212, -0.1178),
                    radius: 1.7145,
                    colors: [
                      Color.fromRGBO(255, 255, 255, 0.10),
                      Color.fromRGBO(255, 255, 255, 0.16),
                    ],
                    stops: [0.0, 1.0],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(255, 255, 255, 0.2),
                      offset: Offset(4, 4),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Pretendard Variable',
                                height: 1.2,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Colors.white.withOpacity(0.22),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 12),
                        physics: const BouncingScrollPhysics(),
                        itemCount: options.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.white.withOpacity(0.08),
                        ),
                        itemBuilder: (c, i) {
                          final o = options[i];
                          final sel = o == current;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(ctx, o),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        o,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: sel
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          fontFamily: 'Pretendard Variable',
                                          fontSize: 15,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                    if (sel)
                                      const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white70,
                                        size: 22,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
    return _glassFormField(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Align(
            alignment: Alignment.centerLeft,
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

  /// 폼 입력·카테고리 선택 줄 — 동일 내부 높이로 시각적 통일
  Widget _glassFormField({required Widget child}) {
    return _glassField(
      child: SizedBox(
        height: _kFormFieldInnerHeight,
        child: child,
      ),
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
