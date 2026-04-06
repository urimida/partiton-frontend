import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partition_app/features/partition/models/shared_expense_table_item.dart';

/// 공과금 추가하기 — 항목 다중 선택 + 매월 납부일 선택 후 표에 반영
class UtilityBillAddModal extends StatefulWidget {
  final Set<String> existingItemNames;
  final void Function(List<SharedExpenseTableItem> items) onConfirm;

  const UtilityBillAddModal({
    super.key,
    required this.existingItemNames,
    required this.onConfirm,
  });

  @override
  State<UtilityBillAddModal> createState() => _UtilityBillAddModalState();
}

class _UtilityBillAddModalState extends State<UtilityBillAddModal> {
  static const _categories = <String>[
    '수도세',
    '전기세',
    '가스비',
    '인터넷',
    '월세',
    '대출 이자',
    '기타',
  ];

  final Set<String> _selected = {};
  int _paymentDay = 1;
  final TextEditingController _otherCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _remarkCtrl = TextEditingController();

  @override
  void dispose() {
    _otherCtrl.dispose();
    _amountCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  /// 표 금액 열과 동일하게 천 단위 콤마 + 원
  static String _formatWonForTable(int won) {
    final n = won < 0 ? 0 : won;
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()}원';
  }

  /// AI 영수증 모달 제목과 동일 (18 / w800)
  static const _titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w900,
    fontFamily: 'Pretendard Variable',
    height: 1.15,
  );

  void _toggleCategory(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else {
        _selected.add(label);
      }
    });
  }

  void _submit() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('항목을 하나 이상 선택해 주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (_selected.contains('기타')) {
      final other = _otherCtrl.text.trim();
      if (other.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기타 항목 이름을 입력해 주세요.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    final amountDigits =
        _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
    if (amountDigits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('금액을 정수로 입력해 주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final amountInt = int.tryParse(amountDigits);
    if (amountInt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('금액을 올바른 숫자로 입력해 주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final amountStr = _formatWonForTable(amountInt);
    final remarkTrim = _remarkCtrl.text.trim();
    final remarkForTable = remarkTrim.isEmpty ? '—' : remarkTrim;

    final added = <SharedExpenseTableItem>[];
    final skipped = <String>[];

    for (final label in _selected) {
      final name = label == '기타' ? _otherCtrl.text.trim() : label;
      if (widget.existingItemNames.contains(name) ||
          added.any((e) => e.name == name)) {
        skipped.add(name);
        continue;
      }
      added.add(
        SharedExpenseTableItem(
          name: name,
          date: '매월 $_paymentDay일',
          amount: amountStr,
          quantity: remarkForTable,
        ),
      );
    }

    if (added.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            skipped.isEmpty
                ? '추가할 항목이 없어요.'
                : '선택한 항목은 이미 표에 있어요.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    widget.onConfirm(added);
    if (!mounted) return;
    if (skipped.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            skipped.length == 1
                ? '${skipped.first}은(는) 이미 있어 제외했어요.'
                : '이미 있는 항목은 제외하고 추가했어요.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final screenH = MediaQuery.sizeOf(context).height;
    final dialogW = (screenW - 40).clamp(300.0, 350.0);
    final maxDialogH = (screenH * 0.62).clamp(320.0, 520.0);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: dialogW,
            height: maxDialogH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.55), width: 0.5),
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
                  color: Color.fromRGBO(255, 255, 255, 0.2),
                  offset: Offset(4, 4),
                  blurRadius: 24,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '공과금 추가하기',
                        textAlign: TextAlign.center,
                        style: _titleStyle,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: _categories.map((label) {
                                  final on = _selected.contains(label);
                                  return _CategoryChip(
                                    label: label,
                                    selected: on,
                                    onTap: () => _toggleCategory(label),
                                  );
                                }).toList(),
                              ),
                              if (_selected.contains('기타')) ...[
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.45),
                                        ),
                                        color: Colors.white.withOpacity(0.08),
                                      ),
                                      child: TextField(
                                        controller: _otherCtrl,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontFamily: 'Pretendard Variable',
                                        ),
                                        decoration: InputDecoration(
                                          hintText: '기타 항목 이름',
                                          hintStyle: TextStyle(
                                            color: Colors.white.withOpacity(0.45),
                                            fontSize: 13,
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Text(
                                '매달 납부일',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Pretendard Variable',
                                ),
                              ),
                              const SizedBox(height: 6),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.45),
                                    ),
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _paymentDay,
                                      dropdownColor: const Color(0xE6282835),
                                      iconEnabledColor: Colors.white70,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontFamily: 'Pretendard Variable',
                                      ),
                                      items: List.generate(
                                        31,
                                        (i) => DropdownMenuItem(
                                          value: i + 1,
                                          child: Text('매월 ${i + 1}일'),
                                        ),
                                      ),
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => _paymentDay = v);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '금액',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Pretendard Variable',
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.45),
                                      ),
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                    child: TextField(
                                      controller: _amountCtrl,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontFamily: 'Pretendard Variable',
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '정수만 입력 (원)',
                                        hintStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.45),
                                          fontSize: 13,
                                        ),
                                        suffixText: '원',
                                        suffixStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.55),
                                          fontSize: 13,
                                          fontFamily: 'Pretendard Variable',
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '비고',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Pretendard Variable',
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.45),
                                      ),
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                    child: TextField(
                                      controller: _remarkCtrl,
                                      maxLines: 2,
                                      minLines: 1,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontFamily: 'Pretendard Variable',
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '예: 자동이체, 고정, 후불',
                                        hintStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.45),
                                          fontSize: 13,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 46,
                        child: GestureDetector(
                          onTap: _submit,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(23),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(23),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.18),
                                      Colors.white.withOpacity(0.10),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.35),
                                  ),
                                ),
                                child: const Text(
                                  '추가하기',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Pretendard Variable',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? Colors.white.withOpacity(0.85)
                  : Colors.white.withOpacity(0.35),
              width: selected ? 1.0 : 0.5,
            ),
            color: selected
                ? Colors.white.withOpacity(0.22)
                : Colors.white.withOpacity(0.10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(selected ? 1.0 : 0.88),
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontFamily: 'Pretendard Variable',
            ),
          ),
        ),
      ),
    );
  }
}
