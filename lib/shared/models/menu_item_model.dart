import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_item_model.freezed.dart';
part 'menu_item_model.g.dart';

@freezed
class MenuItem with _$MenuItem {
  const factory MenuItem({
    required String itemId,
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required String categoryId,
    required bool isAvailable,
  }) = _MenuItem;

  factory MenuItem.fromJson(Map<String, dynamic> json) =>
      _$MenuItemFromJson(json);
}


