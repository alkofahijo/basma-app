import 'package:basma_app/services/api_service.dart';

/// UploadService: central place for file/image uploads. Currently a thin
/// wrapper over `ApiService.uploadImage` but can be extended to add
/// retries, progress reporting, or alternate upload endpoints.
class UploadService {
  /// Upload bytes and return the public URL.
  static Future<String> uploadImage(List<int> bytes, String filename) async {
    // Potential place for retry/backoff or selecting mirror endpoints.
    return await ApiService.uploadImage(bytes, filename);
  }
}
