import 'dart:typed_data';

import 'package:basma_app/models/report_models.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/services/upload_service.dart';
import 'package:basma_app/services/pagination_manager.dart';

/// ReportsService: a thin repository layer around `ApiService` for
/// report-related operations. Keeps calling code testable and easier to
/// migrate later (caching, transforms, retries, etc.).
class ReportsService {
  /// Returns a page of reports using ApiService under the hood.
  ///
  /// `mine == true` calls `ApiService.listMyReports`, otherwise
  /// `ApiService.listPublicReports`.
  static Future<List<ReportPublicSummary>> listReports({
    required bool mine,
    required int statusId,
    int? governmentId,
    int? districtId,
    int? areaId,
    int? reportTypeId,
    required int limit,
    required int offset,
  }) async {
    if (mine) {
      return await ApiService.listMyReports(
        statusId: statusId,
        governmentId: governmentId,
        districtId: districtId,
        areaId: areaId,
        reportTypeId: reportTypeId,
        limit: limit,
        offset: offset,
      );
    }

    return await ApiService.listPublicReports(
      statusId: statusId,
      governmentId: governmentId,
      districtId: districtId,
      areaId: areaId,
      reportTypeId: reportTypeId,
      limit: limit,
      offset: offset,
    );
  }

  /// Helper that maps a (page,pageSize) request to a PaginatedResult
  /// using `listReports`. Kept as a helper to plug into
  /// `PaginationController` easily from UI code.
  static Future<PaginatedResult<ReportPublicSummary>> pageFetcher(
    int page,
    int pageSize, {
    required bool mine,
    required int statusId,
    int? governmentId,
    int? districtId,
    int? areaId,
    int? reportTypeId,
  }) async {
    final offset = (page - 1) * pageSize;
    final items = await listReports(
      mine: mine,
      statusId: statusId,
      governmentId: governmentId,
      districtId: districtId,
      areaId: areaId,
      reportTypeId: reportTypeId,
      limit: pageSize,
      offset: offset,
    );

    final int total = (items.length < pageSize) ? (offset + items.length) : -1;
    return PaginatedResult<ReportPublicSummary>(items, total);
  }

  /// Upload image bytes using the central ApiService helper.
  static Future<String> uploadImage(List<int> bytes, String filename) async {
    return await UploadService.uploadImage(bytes, filename);
  }

  /// Create a new report using ApiService.
  static Future<ReportDetail> createReport(Map<String, dynamic> payload) async {
    return await ApiService.createReport(payload);
  }

  /// Analyze an image using the AI endpoint.
  static Future<AiSuggestion> analyzeImage({
    required List<int> bytes,
    required String filename,
    required int governmentId,
    required int districtId,
    required int areaId,
  }) async {
    return await ApiService.analyzeReportImage(
      bytes: Uint8List.fromList(bytes),
      filename: filename,
      governmentId: governmentId,
      districtId: districtId,
      areaId: areaId,
    );
  }

  /// Resolve location by lat/lng using AI endpoint (delegates to ApiService).
  static Future<ResolvedLocation> resolveLocationByLatLng(
    double lat,
    double lng,
  ) async {
    return await ApiService.resolveLocationByLatLng(lat, lng);
  }

  /// List report types (delegates to ApiService).
  static Future<List<ReportTypeOption>> listReportTypes() async {
    return await ApiService.listReportTypes();
  }
}
