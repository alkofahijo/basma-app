// lib/models/network_error.dart
class NetworkError {
  final String message;
  final int? statusCode;
  final dynamic raw;

  NetworkError(this.message, {this.statusCode, this.raw});

  @override
  String toString() => 'NetworkError(status: $statusCode, message: $message)';
}
