/// GET `/api/reservations/items` `result[]` 항목
class ReservationItem {
  final int itemId;
  final String name;

  const ReservationItem({
    required this.itemId,
    required this.name,
  });

  factory ReservationItem.fromJson(Map<String, dynamic> json) {
    return ReservationItem(
      itemId: (json['itemId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

/// POST `/api/reservations/items` 성공 시 `result`
class ReservationItemCreated {
  final int itemId;
  final String name;
  final String? createdAt;

  const ReservationItemCreated({
    required this.itemId,
    required this.name,
    this.createdAt,
  });

  factory ReservationItemCreated.fromJson(Map<String, dynamic> json) {
    return ReservationItemCreated(
      itemId: (json['itemId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
    );
  }
}

/// PATCH `/api/reservations/items/{itemId}` 성공 시 `result`
class ReservationItemUpdated {
  final int itemId;
  final String name;
  final String? updatedAt;

  const ReservationItemUpdated({
    required this.itemId,
    required this.name,
    this.updatedAt,
  });

  factory ReservationItemUpdated.fromJson(Map<String, dynamic> json) {
    return ReservationItemUpdated(
      itemId: (json['itemId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      updatedAt: json['updatedAt'] as String?,
    );
  }
}
