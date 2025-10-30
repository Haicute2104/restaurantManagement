import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_report_model.freezed.dart';
part 'item_report_model.g.dart';

@freezed
class ItemReport with _$ItemReport {
  const factory ItemReport({
    required String itemId,
    required int totalSoldAllTime,
    required double totalRevenueAllTime,
  }) = _ItemReport;

  factory ItemReport.fromJson(Map<String, dynamic> json) =>
      _$ItemReportFromJson(json);
}


