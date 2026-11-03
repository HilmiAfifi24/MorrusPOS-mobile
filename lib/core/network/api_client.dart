import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/storage_service.dart';

class ApiClient {
  final http.Client _client;
  final StorageService _storage;

  ApiClient(this._client, this._storage);

  void Function(String capabilityCode)? onCapabilityDisabled;

  Map<String, String> _headers() {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = _storage.token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    String queryString = '';
    if (queryParams != null && queryParams.isNotEmpty) {
      final parts = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}');
      queryString = '?${parts.join('&')}';
    }
    final uri = Uri.parse('${_storage.baseUrl}$endpoint$queryString');
    return _inspect(await _client.get(uri, headers: _headers()));
  }

  Future<http.Response> post(String endpoint, {Object? body}) async {
    final uri = Uri.parse('${_storage.baseUrl}$endpoint');
    return _inspect(await _client.post(
      uri,
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    ));
  }

  Future<http.Response> put(String endpoint, {Object? body}) async {
    final uri = Uri.parse('${_storage.baseUrl}$endpoint');
    return _inspect(await _client.put(
      uri,
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    ));
  }

  Future<http.Response> delete(String endpoint) async {
    final uri = Uri.parse('${_storage.baseUrl}$endpoint');
    return _inspect(await _client.delete(uri, headers: _headers()));
  }

  http.Response _inspect(http.Response response) {
    if (response.statusCode == 403) {
      try {
        final payload = jsonDecode(response.body);
        if (payload is Map<String, dynamic> && payload['code'] == 'CAPABILITY_DISABLED') {
          onCapabilityDisabled?.call(payload['capability']?.toString() ?? '');
        }
      } catch (_) {}
    }
    return response;
  }
}
