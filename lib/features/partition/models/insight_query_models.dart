/// FastAPI `POST /api/insights/query` · `POST /api/insights/query-voice` 성공 본문
class InsightQueryResult {
  const InsightQueryResult({
    required this.answer,
    required this.model,
    required this.contextSummary,
    required this.inputMode,
    this.whisperModel,
    this.multimodalModel,
    this.transcribedQuestion,
  });

  final String answer;
  final String model;
  final InsightContextSummary contextSummary;
  final String inputMode;
  final String? whisperModel;
  final String? multimodalModel;
  final String? transcribedQuestion;

  factory InsightQueryResult.fromJson(Map<String, dynamic> json) {
    final cs = json['contextSummary'];
    return InsightQueryResult(
      answer: json['answer']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      contextSummary: cs is Map<String, dynamic>
          ? InsightContextSummary.fromJson(cs)
          : const InsightContextSummary.empty(),
      inputMode: json['inputMode']?.toString() ?? 'text',
      whisperModel: json['whisperModel']?.toString(),
      multimodalModel: json['multimodalModel']?.toString(),
      transcribedQuestion: json['transcribedQuestion']?.toString(),
    );
  }
}

class InsightDateRange {
  const InsightDateRange({this.start, this.end});

  final String? start;
  final String? end;

  factory InsightDateRange.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const InsightDateRange();
    return InsightDateRange(
      start: json['start']?.toString(),
      end: json['end']?.toString(),
    );
  }
}

/// `blocks` 값은 `ok` / `error` / `empty` 문자열 또는 건수(int) 등 혼합
class InsightContextSummary {
  const InsightContextSummary({
    this.dateRange,
    this.blocks = const {},
  });

  const InsightContextSummary.empty()
      : dateRange = null,
        blocks = const {};

  final InsightDateRange? dateRange;
  final Map<String, dynamic> blocks;

  factory InsightContextSummary.fromJson(Map<String, dynamic> json) {
    final dr = json['dateRange'];
    final rawBlocks = json['blocks'];
    return InsightContextSummary(
      dateRange: dr is Map<String, dynamic>
          ? InsightDateRange.fromJson(dr)
          : null,
      blocks: rawBlocks is Map<String, dynamic>
          ? Map<String, dynamic>.from(rawBlocks)
          : const {},
    );
  }
}
