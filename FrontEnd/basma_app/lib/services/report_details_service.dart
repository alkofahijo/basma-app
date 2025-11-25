import 'package:basma_app/models/report_models.dart';
import 'package:basma_app/services/api_service.dart';
// pagination helpers removed (comments/attachments paging reverted)
import 'package:basma_app/services/upload_service.dart';

/// Thin service for report-detail specific operations. Keeps UI code
/// decoupled from `ApiService` so we can add retries, transforms or
/// caching later.
class ReportDetailsService {
  /// Fetch detailed report by id.
  static Future<ReportDetail> getReport(int reportId) async {
    return await ApiService.getReport(reportId);
  }

  /// Adopt a report as the given account.
  static Future<ReportDetail> adoptReport({
    required int reportId,
    required int accountId,
  }) async {
    return await ApiService.adopt(reportId: reportId, accountId: accountId);
  }

  /// Complete a report by uploading the after-image and calling the
  /// complete endpoint. Returns the updated `ReportDetail`.
  static Future<ReportDetail> completeReportWithImage({
    required int reportId,
    required List<int> imageBytes,
    required String filename,
    String? note,
  }) async {
    // 1) upload image via central UploadService
    final imageUrl = await UploadService.uploadImage(imageBytes, filename);

    // 2) call complete endpoint
    return await ApiService.completeReport(
      reportId: reportId,
      imageAfterUrl: imageUrl,
      note: note,
    );
  }

  // comments/attachments pagers removed — not used in current UI.
}
