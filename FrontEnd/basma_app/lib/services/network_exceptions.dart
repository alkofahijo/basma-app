// lib/services/network_exceptions.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:basma_app/models/network_error.dart';
import 'package:http/http.dart' as http;

class NetworkException implements Exception {
  final NetworkError error;
  NetworkException(this.error);

  @override
  String toString() => error.toString();
}

NetworkException mapHttpResponse(
  http.Response res, {
  String fallback = 'Request failed',
}) {
  String msg = '$fallback (${res.statusCode})';
  final raw = res.body;

  try {
    final body = jsonDecode(raw);
    if (body is Map && body['detail'] != null) {
      msg = body['detail'].toString();
    } else if (raw.isNotEmpty) {
      msg = '$msg: $raw';
    }
  } catch (_) {
    if (raw.isNotEmpty) msg = '$msg: $raw';
  }

  return NetworkException(
    NetworkError(msg, statusCode: res.statusCode, raw: raw),
  );
}

NetworkException mapException(Object e) {
  if (e is SocketException) {
    return NetworkException(
      NetworkError('لا يوجد اتصال بالإنترنت. الرجاء التحقق من الشبكة.'),
    );
  }
  if (e is TimeoutException) {
    return NetworkException(
      NetworkError('انتهت مهلة الاتصال بالخادم. حاول مرة أخرى.'),
    );
  }
  if (e is NetworkException) return e;

  return NetworkException(
    NetworkError(
      'حدث خطأ أثناء التواصل مع الخادم. الرجاء المحاولة لاحقاً.',
      raw: e,
    ),
  );
}
