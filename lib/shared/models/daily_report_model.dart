import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_report_model.freezed.dart';
part 'daily_report_model.g.dart';

@freezed
class DailyReport with _$DailyReport {
  const factory DailyReport({
    required String date, // YYYY-MM-DD
    required double totalRevenue,
    required int totalOrders,
    required Map<String, int> itemSalesCount,
    required Map<String, double> hourlyRevenue,
  }) = _DailyReport;

  factory DailyReport.fromJson(Map<String, dynamic> json) =>
      _$DailyReportFromJson(json);
}


