import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_category_model.freezed.dart';
part 'menu_category_model.g.dart';

@freezed
class MenuCategory with _$MenuCategory {
  const factory MenuCategory({
    required String categoryId,
    required String name,
    required int priority,
  }) = _MenuCategory;

  factory MenuCategory.fromJson(Map<String, dynamic> json) =>
      _$MenuCategoryFromJson(json);
}


