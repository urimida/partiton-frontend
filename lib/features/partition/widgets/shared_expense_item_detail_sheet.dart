import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:partition_app/features/partition/models/shared_expense_table_item.dart';

/// 공용소비 표 — 항목명 탭 시 상세(분류·AI 더미·정산 여부)
class SharedExpenseItemDetailSheet extends StatefulWidget {
  final SharedExpenseTableItem item;
  final bool isUtility;
  final ValueChanged<bool> onSettlementChanged;

  const SharedExpenseItemDetailSheet({
    super.key,
    required this.item,
    required this.isUtility,
    required this.onSettlementChanged,
  });

  @override
  State<SharedExpenseItemDetailSheet> createState() =>
      _SharedExpenseItemDetailSheetState();
}

class _SharedExpenseItemDetailSheetState
    extends State<SharedExpenseItemDetailSheet> {
  late bool _settled;

  @override
  void initState() {
    super.initState();
    _settled = widget.item.manuallySettled;
  }

  /// 항상 `대분류 > 소분류` 형태 (없으면 `—` 자리 표시)
  String get _categoryLine {
    final m = widget.item.majorCategory?.trim();
    final s = widget.item.minorCategory?.trim();
    final major = (m != null && m.isNotEmpty) ? m : '—';
    final minor = (s != null && s.isNotEmpty) ? s : '—';
    return '$major > $minor';
  }

  String get _amountQtyLine {
    final a = widget.item.amount.trim();
    final q = widget.item.quantity?.trim();
    if (q == null || q.isEmpty) return a;
    return '$a, $q';
  }

  String get _dummyAiBlock {
    if (widget.isUtility) {
      return '이 항목은 공과금 성격의 고정·주기 청구로 추정돼요. (더미 분석)\n'
          '납부 주기와 금액 변동을 다음 달 예산에 반영해 보세요.';
    }
    return '해당 용품은 30일에 한 번 정도 구매하고 있네요!\n'
        '평균 구매 가격은 약 ${widget.item.amount}이고,\n'
        '저번 달에는 특히 빠른 주기로 구매했어요.\n'
        '(실제 연동 전 더미 텍스트입니다.)';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.45), width: 0.5),
            gradient: const RadialGradient(
              center: Alignment(-0.12, -0.12),
              radius: 1.7,
              colors: [
                Color.fromRGBO(255, 255, 255, 0.14),
                Color.fromRGBO(255, 255, 255, 0.08),
              ],
              stops: [0.0, 1.0],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(255, 255, 255, 0.12),
                offset: Offset(0, -4),
                blurRadius: 24,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.item.date,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _amountQtyLine,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!widget.isUtility) ...[
                      Text(
                        _categoryLine,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      'AI 분석',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withOpacity(0.06),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Text(
                        _dummyAiBlock,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '정산여부 관리',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _settled ? '정산 완료로 표시됨' : '정산 전',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: _settled,
                            activeColor: Colors.white,
                            activeTrackColor: Colors.white.withOpacity(0.45),
                            inactiveThumbColor: Colors.white54,
                            inactiveTrackColor: Colors.white.withOpacity(0.2),
                            onChanged: (v) {
                              setState(() => _settled = v);
                              widget.onSettlementChanged(v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
