import 'package:json_annotation/json_annotation.dart';

part 'preference_response_model.g.dart';

@JsonSerializable()
class PreferenceResponseModel {
  final bool isSuccess;
  final String code;
  final String message;
  final List<PreferenceItem>? result;
  final String? error;

  PreferenceResponseModel({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
    this.error,
  });

  factory PreferenceResponseModel.fromJson(Map<String, dynamic> json) =>
      _$PreferenceResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$PreferenceResponseModelToJson(this);
}

@JsonSerializable()
class PreferenceItem {
  final String choreType;
  final int score;

  PreferenceItem({
    required this.choreType,
    required this.score,
  });

  factory PreferenceItem.fromJson(Map<String, dynamic> json) =>
      _$PreferenceItemFromJson(json);

  Map<String, dynamic> toJson() => _$PreferenceItemToJson(this);
}

// 집안일 타입 enum
enum ChoreType {
  @JsonValue('DISH_WASHING')
  dishWashing,
  @JsonValue('COOKING')
  cooking,
  @JsonValue('LAUNDRY')
  laundry,
  @JsonValue('FOODTRASH')
  foodTrash,
  @JsonValue('TRASH')
  trash,
  @JsonValue('RECYCLING')
  recycling,
  @JsonValue('VACUUM')
  vacuum,
  @JsonValue('MOPPING')
  mopping,
  @JsonValue('WINDOW')
  window,
  @JsonValue('BATHROOM')
  bathroom,
  @JsonValue('FRIDGE')
  fridge,
}

extension ChoreTypeExtension on ChoreType {
  String get value {
    switch (this) {
      case ChoreType.dishWashing:
        return 'DISH_WASHING';
      case ChoreType.cooking:
        return 'COOKING';
      case ChoreType.laundry:
        return 'LAUNDRY';
      case ChoreType.foodTrash:
        return 'FOODTRASH';
      case ChoreType.trash:
        return 'TRASH';
      case ChoreType.recycling:
        return 'RECYCLING';
      case ChoreType.vacuum:
        return 'VACUUM';
      case ChoreType.mopping:
        return 'MOPPING';
      case ChoreType.window:
        return 'WINDOW';
      case ChoreType.bathroom:
        return 'BATHROOM';
      case ChoreType.fridge:
        return 'FRIDGE';
    }
  }
}

