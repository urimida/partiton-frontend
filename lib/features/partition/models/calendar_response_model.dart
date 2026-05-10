import 'package:json_annotation/json_annotation.dart';

part 'calendar_response_model.g.dart';

/// 월간·일반 응답에서 숫자/문자 혼합
String calendarResponseApiString(dynamic value) => value?.toString() ?? '';

@JsonSerializable()
class CalendarResponseModel {
  final bool isSuccess;
  @JsonKey(fromJson: calendarResponseApiString)
  final String code;
  final String message;
  final List<CalendarDayItem>? result;
  final String? error;

  CalendarResponseModel({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
    this.error,
  });

  factory CalendarResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CalendarResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CalendarResponseModelToJson(this);
}

int _calendarDayCount(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? 0;
  return 0;
}

/// 여러 필드 이름으로 공과금 일정 수 인식 (`utilityBillCount`, snake_case 등).
/// 같은 응답에 여러 키가 있으면 최댓값을 사용합니다.
int calendarDayUtilityBillCount(Map<String, dynamic> json) {
  const candidateKeys = <String>[
    'utilityBillsCount',
    'utilityBillCount',
    'utility_bills_count',
    'utilityBillCounts',
    'billsCount',
    'billCount',
    'bills_count',
  ];
  var maxSeen = 0;
  for (final key in candidateKeys) {
    if (!json.containsKey(key)) continue;
    final n = _calendarDayCount(json[key]);
    if (n > maxSeen) maxSeen = n;
  }
  return maxSeen;
}

@JsonSerializable(createFactory: false)
class CalendarDayItem {
  final String date;
  final int choreCount;
  final int scheduleCount;
  final int utilityBillsCount;

  CalendarDayItem({
    required this.date,
    required this.choreCount,
    required this.scheduleCount,
    required this.utilityBillsCount,
  });

  factory CalendarDayItem.fromJson(Map<String, dynamic> json) {
    return CalendarDayItem(
      date: json['date']?.toString() ?? '',
      choreCount: _calendarDayCount(json['choreCount']),
      scheduleCount: _calendarDayCount(json['scheduleCount']),
      utilityBillsCount: calendarDayUtilityBillCount(json),
    );
  }

  Map<String, dynamic> toJson() => _$CalendarDayItemToJson(this);
}

















