import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/storage_service.dart';

class ApiClient {
  final http.Client _client;
  final StorageService _storage;

  ApiClient(this._client, this._storage);

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
      queryString = '?' + parts.join('&');
    }
    final uri = Uri.parse('${_storage.baseUrl}$endpoint$queryString');
    return await _client.get(uri, headers: _headers());
  }

  Future<http.Response> post(String endpoint, {Object? body}) async {
    final uri = Uri.parse('${_storage.baseUrl}$endpoint');
    return await _client.post(
      uri,
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> put(String endpoint, {Object? body}) async {
    final uri = Uri.parse('${_storage.baseUrl}$endpoint');
    return await _client.put(
      uri,
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String endpoint) async {
    final uri = Uri.parse('${_storage.baseUrl}$endpoint');
    return await _client.delete(uri, headers: _headers());
  }
}
