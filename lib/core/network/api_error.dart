import 'dart:convert';
import 'package:http/http.dart' as http;
import '../error/failures.dart';

Failure failureFromResponse(http.Response response, String fallbackMessage) {
  try {
    final payload = jsonDecode(response.body);
    if (payload is Map<String, dynamic>) {
      final message = payload['message']?.toString() ?? fallbackMessage;
      if (response.statusCode == 403 &&
          payload['code'] == 'CAPABILITY_DISABLED') {
        return CapabilityDisabledFailure(
          payload['capability']?.toString() ?? '',
          message,
        );
      }
      return ServerFailure(message);
    }
  } catch (_) {}
  return ServerFailure(fallbackMessage);
}
