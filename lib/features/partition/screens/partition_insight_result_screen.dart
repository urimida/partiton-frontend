import 'package:flutter/material.dart';
import 'package:partition_app/features/partition/models/insight_query_models.dart';

/// 인사이트 질의 성공 후 표시하는 답변·컨텍스트 요약 화면
class PartitionInsightResultScreen extends StatelessWidget {
  const PartitionInsightResultScreen({
    super.key,
    required this.result,
  });

  final InsightQueryResult result;

  static const Color _cream = Color(0xFFFFFDCB);
  static const Color _bg = Color(0xFF0D1820);
  static const Color _card = Color(0xFF152535);

  @override
  Widget build(BuildContext context) {
    final dr = result.contextSummary.dateRange;
    final blocks = result.contextSummary.blocks;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          '파티션 AI 답변',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (result.transcribedQuestion != null &&
              result.transcribedQuestion!.trim().isNotEmpty) ...[
            _sectionTitle('음성에서 인식한 질문'),
            const SizedBox(height: 8),
            _cardBox(
              child: Text(
                result.transcribedQuestion!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],
          _sectionTitle('답변'),
          const SizedBox(height: 8),
          _cardBox(
            child: Text(
              result.answer.isEmpty ? '(내용 없음)' : result.answer,
              style: TextStyle(
                color: Colors.white.withOpacity(0.94),
                fontSize: 15,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('참고한 데이터'),
          const SizedBox(height: 8),
          if (dr != null && (dr.start != null || dr.end != null))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${dr.start ?? '?'} ~ ${dr.end ?? '?'}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 13,
                ),
              ),
            ),
          if (blocks.isEmpty)
            Text(
              '블록 요약이 비어 있습니다.',
              style: TextStyle(color: Colors.white.withOpacity(0.45)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: blocks.entries.map((e) {
                return _blockChip(e.key, e.value);
              }).toList(),
            ),
          const SizedBox(height: 24),
          _sectionTitle('메타'),
          const SizedBox(height: 8),
          _metaRow('입력 방식', result.inputMode),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Text(
      t,
      style: TextStyle(
        color: _cream.withOpacity(0.95),
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
    );
  }

  Widget _cardBox({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }

  Widget _blockChip(String key, dynamic value) {
    final label = _blockLabelKo(key);
    final status = value?.toString() ?? '';
    Color bg;
    Color fg = Colors.white;
    if (status == 'ok') {
      bg = const Color(0xFF1B3D2F);
      fg = const Color(0xFF8FE0C0);
    } else if (status == 'error') {
      bg = const Color(0xFF3D1B1B);
      fg = const Color(0xFFFFB4B4);
    } else if (status == 'empty') {
      bg = const Color(0xFF2A2A35);
      fg = Colors.white70;
    } else {
      bg = const Color(0xFF243040);
      fg = _cream.withOpacity(0.85);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        '$label · $status',
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _metaRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              k,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                color: Colors.white.withOpacity(0.88),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _blockLabelKo(String key) {
    const map = <String, String>{
      'suppliesPurchases': '공용 구매',
      'bills': '공과금',
      'supplySettlementPurchases': '공용 정산 구매',
      'supplyCategories': '공용 카테고리',
      'billCategories': '공과금 카테고리',
      'reports': '리포트',
      'reportsSettlement': '정산 리포트',
      'reservations': '예약',
      'reservationItems': '예약 항목',
      'alarms': '알림',
      'calendarsMonthly': '월간 캘린더',
      'calendarsDailyFetched': '일간 캘린더(건수)',
    };
    return map[key] ?? key;
  }
}
