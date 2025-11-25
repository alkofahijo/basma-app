// lib/services/pagination_manager.dart
import 'package:flutter/foundation.dart';
import 'package:basma_app/services/network_exceptions.dart';

typedef PageFetcher<T> =
    Future<PaginatedResult<T>> Function(int page, int pageSize);

class PaginatedResult<T> {
  final List<T> items;

  /// Total may be -1 when the backend doesn't provide a total count
  /// (unknown). Consumers should treat negative total as "unknown".
  final int total;

  PaginatedResult(this.items, this.total);
}

class PaginationController<T> extends ChangeNotifier {
  final int pageSize;
  final PageFetcher<T> fetcher;

  List<T> items = [];
  int page = 1;

  /// total == -1 means unknown/unstated by the server
  int total = -1;
  bool isLoading = false;
  bool isLoadingMore = false;
  String? errorMessage;

  PaginationController({required this.fetcher, this.pageSize = 20});

  Future<void> refresh() async {
    page = 1;
    items = [];
    total = 0;
    errorMessage = null;
    await _load();
  }

  Future<void> _load() async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await fetcher(page, pageSize);
      items = res.items;
      total = res.total;
      errorMessage = null;
    } catch (e) {
      if (e is NetworkException) {
        errorMessage = e.error.message;
      } else {
        errorMessage = e.toString();
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore) return;
    // If total is known (>=0) and we've loaded everything, stop.
    if (total >= 0 && items.length >= total) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final nextPage = page + 1;
      final res = await fetcher(nextPage, pageSize);
      items.addAll(res.items);
      total = res.total;
      page = nextPage;
    } catch (e) {
      if (e is NetworkException) {
        errorMessage = e.error.message;
      } else {
        errorMessage = e.toString();
      }
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadPage(int newPage) async {
    if (newPage < 1) return;
    isLoading = true;
    notifyListeners();
    try {
      final res = await fetcher(newPage, pageSize);
      items = res.items;
      total = res.total;
      page = newPage;
      errorMessage = null;
    } catch (e) {
      if (e is NetworkException) {
        errorMessage = e.error.message;
      } else {
        errorMessage = e.toString();
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
