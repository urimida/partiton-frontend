/// GET `/reports` 응답 (`result` 객체)
class PartitionReportResult {
  final List<ChoreReportEntry> chores;
  final ReportSupplies supplies;
  final List<ReportBillDelta> bills;
  final List<ReservationReportEntry> reservations;

  const PartitionReportResult({
    required this.chores,
    required this.supplies,
    required this.bills,
    required this.reservations,
  });

  factory PartitionReportResult.fromJson(Map<String, dynamic> json) {
    final choresRaw = json['chores'];
    final billsRaw = json['bills'];
    final resRaw = json['reservations'];
    final suppliesRaw = json['supplies'];
    return PartitionReportResult(
      chores: choresRaw is List
          ? choresRaw
              .map((e) =>
                  ChoreReportEntry.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      supplies: suppliesRaw is Map<String, dynamic>
          ? ReportSupplies.fromJson(suppliesRaw)
          : ReportSupplies.empty,
      bills: billsRaw is List
          ? billsRaw
              .map((e) => ReportBillDelta.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      reservations: resRaw is List
          ? resRaw
              .map((e) =>
                  ReservationReportEntry.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class ReportPerformer {
  final int userId;
  final String userName;
  final int count;

  const ReportPerformer({
    required this.userId,
    required this.userName,
    required this.count,
  });

  factory ReportPerformer.fromJson(Map<String, dynamic> json) {
    return ReportPerformer(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      userName: json['userName']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChoreReportEntry {
  final String choreType;
  final String choreName;
  final int totalCount;
  final double avgDifficulty;
  final ReportPerformer? topPerformer;
  final ReportPerformer? bottomPerformer;
  final int? lastPerformedDaysAgo;

  const ChoreReportEntry({
    required this.choreType,
    required this.choreName,
    required this.totalCount,
    required this.avgDifficulty,
    this.topPerformer,
    this.bottomPerformer,
    this.lastPerformedDaysAgo,
  });

  factory ChoreReportEntry.fromJson(Map<String, dynamic> json) {
    ReportPerformer? perf(Map<String, dynamic>? m) =>
        m == null ? null : ReportPerformer.fromJson(m);

    final top = json['topPerformer'];
    final bottom = json['bottomPerformer'];
    final daysRaw = json['lastPerformedDaysAgo'];

    return ChoreReportEntry(
      choreType: json['choreType']?.toString() ?? '',
      choreName: json['choreName']?.toString() ?? '',
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      avgDifficulty: (json['avgDifficulty'] as num?)?.toDouble() ?? 1.0,
      topPerformer: top is Map<String, dynamic> ? perf(top) : null,
      bottomPerformer: bottom is Map<String, dynamic> ? perf(bottom) : null,
      lastPerformedDaysAgo:
          daysRaw == null ? null : (daysRaw as num?)?.toInt(),
    );
  }
}

class ReportSupplies {
  final ReportSupplyHighlight? highestAmountItem;
  final ReportMostPurchased? mostPurchasedItem;

  const ReportSupplies({
    this.highestAmountItem,
    this.mostPurchasedItem,
  });

  static const ReportSupplies empty =
      ReportSupplies(highestAmountItem: null, mostPurchasedItem: null);

  factory ReportSupplies.fromJson(Map<String, dynamic> json) {
    final h = json['highestAmountItem'];
    final m = json['mostPurchasedItem'];
    return ReportSupplies(
      highestAmountItem:
          h is Map<String, dynamic> ? ReportSupplyHighlight.fromJson(h) : null,
      mostPurchasedItem:
          m is Map<String, dynamic> ? ReportMostPurchased.fromJson(m) : null,
    );
  }

  bool get isEmpty =>
      highestAmountItem == null && mostPurchasedItem == null;
}

class ReportSupplyHighlight {
  final String itemName;
  final int amount;

  const ReportSupplyHighlight({
    required this.itemName,
    required this.amount,
  });

  factory ReportSupplyHighlight.fromJson(Map<String, dynamic> json) {
    return ReportSupplyHighlight(
      itemName: json['itemName']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReportMostPurchased {
  final String itemName;
  final int purchaseCount;

  const ReportMostPurchased({
    required this.itemName,
    required this.purchaseCount,
  });

  factory ReportMostPurchased.fromJson(Map<String, dynamic> json) {
    return ReportMostPurchased(
      itemName: json['itemName']?.toString() ?? '',
      purchaseCount: (json['purchaseCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReportBillDelta {
  final String utilityType;
  final String utilityTypeName;
  final int previousAmount;
  final int currentAmount;
  final double changeRate;

  const ReportBillDelta({
    required this.utilityType,
    required this.utilityTypeName,
    required this.previousAmount,
    required this.currentAmount,
    required this.changeRate,
  });

  factory ReportBillDelta.fromJson(Map<String, dynamic> json) {
    return ReportBillDelta(
      utilityType: json['utilityType']?.toString() ?? '',
      utilityTypeName: json['utilityTypeName']?.toString() ?? '',
      previousAmount: (json['previousAmount'] as num?)?.toInt() ?? 0,
      currentAmount: (json['currentAmount'] as num?)?.toInt() ?? 0,
      changeRate: (json['changeRate'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// GET `/reports/settlement` 응답 (`result`)
class SettlementReportResult {
  final List<SettlementReportSupplyRow> supplies;
  final List<SettlementReportBillRow> bills;

  const SettlementReportResult({
    required this.supplies,
    required this.bills,
  });

  factory SettlementReportResult.fromJson(Map<String, dynamic> json) {
    final sRaw = json['supplies'];
    final bRaw = json['bills'];
    return SettlementReportResult(
      supplies: sRaw is List
          ? sRaw
              .map((e) =>
                  SettlementReportSupplyRow.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      bills: bRaw is List
          ? bRaw
              .map((e) =>
                  SettlementReportBillRow.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  static const SettlementReportResult empty = SettlementReportResult(
    supplies: [],
    bills: [],
  );
}

/// 정산 완료 공용물품 한 줄
class SettlementReportSupplyRow {
  final String itemName;
  final String purchaseDate;
  final int amount;
  final int quantity;

  const SettlementReportSupplyRow({
    required this.itemName,
    required this.purchaseDate,
    required this.amount,
    required this.quantity,
  });

  factory SettlementReportSupplyRow.fromJson(Map<String, dynamic> json) {
    return SettlementReportSupplyRow(
      itemName: json['itemName']?.toString() ?? '',
      purchaseDate: json['purchaseDate']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 정산 완료 공과금 한 줄
class SettlementReportBillRow {
  final String utilityType;
  final String utilityTypeName;
  final String billingMonth;
  final int amount;

  const SettlementReportBillRow({
    required this.utilityType,
    required this.utilityTypeName,
    required this.billingMonth,
    required this.amount,
  });

  factory SettlementReportBillRow.fromJson(Map<String, dynamic> json) {
    return SettlementReportBillRow(
      utilityType: json['utilityType']?.toString() ?? '',
      utilityTypeName: json['utilityTypeName']?.toString() ?? '',
      billingMonth: json['billingMonth']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReservationReportEntry {
  final String itemName;
  final ReportPerformer? topPerformer;
  final ReportPerformer? bottomPerformer;
  final int? avgDurationMinutes;

  const ReservationReportEntry({
    required this.itemName,
    this.topPerformer,
    this.bottomPerformer,
    this.avgDurationMinutes,
  });

  factory ReservationReportEntry.fromJson(Map<String, dynamic> json) {
    final top = json['topPerformer'];
    final bottom = json['bottomPerformer'];
    final dur = json['avgDurationMinutes'];
    return ReservationReportEntry(
      itemName: json['itemName']?.toString() ?? '',
      topPerformer: top is Map<String, dynamic>
          ? ReportPerformer.fromJson(top)
          : null,
      bottomPerformer: bottom is Map<String, dynamic>
          ? ReportPerformer.fromJson(bottom)
          : null,
      avgDurationMinutes: dur == null ? null : (dur as num?)?.toInt(),
    );
  }
}
