import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/reimbursement.dart';
import 'api_exception.dart';

class ReimbursementApiService {
  ReimbursementApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<List<Reimbursement>> getMyReimbursements(String employeeName) async {
    final uri = Uri.parse(ApiConfig.baseUrl)
        .replace(queryParameters: {'employeeName': employeeName});

    final response = await _send(() => _client.get(uri, headers: _jsonHeaders));
    final body = _decode(response);

    if (body is! List) {
      throw const ApiException('El servidor devolvió una respuesta inesperada.');
    }
    try {
      return body
          .map((e) => Reimbursement.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const ApiException('No se pudo interpretar la respuesta del servidor.');
    }
  }

  Future<Reimbursement> createReimbursement({
    required String employeeName,
    required int amount,
    required String category,
    required String description,
  }) async {
    final payload = jsonEncode({
      'employeeName': employeeName,
      'amount': amount,
      'category': category,
      'description': description,
    });

    final response = await _send(() => _client.post(
          Uri.parse(ApiConfig.baseUrl),
          headers: _jsonHeaders,
          body: payload,
        ));
    final body = _decode(response);

    try {
      return Reimbursement.fromJson(body as Map<String, dynamic>);
    } catch (_) {
      throw const ApiException('No se pudo interpretar la respuesta del servidor.');
    }
  }

  /// Ejecuta la petición traduciendo fallos de red/timeout a [ApiException].
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(ApiConfig.requestTimeout);
    } on TimeoutException {
      throw const ApiException(
        'El servidor tardó demasiado en responder.',
        isConnectionError: true,
      );
    } on http.ClientException {
      throw const ApiException(
        'No se pudo conectar con el servidor. Verifica que la API esté encendida.',
        isConnectionError: true,
      );
    } catch (_) {
      throw const ApiException(
        'No se pudo conectar con el servidor.',
        isConnectionError: true,
      );
    }
  }

  /// Decodifica el JSON y convierte códigos no exitosos en [ApiException] con el mensaje del backend.
  dynamic _decode(http.Response response) {
    dynamic body;
    try {
      body = response.body.isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      body = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body == null) {
        throw const ApiException('El servidor devolvió una respuesta vacía o inválida.');
      }
      return body;
    }

    final serverMessage = body is Map<String, dynamic> ? body['message'] as String? : null;
    if (response.statusCode >= 500) {
      throw ApiException(
        'El servidor tuvo un problema. Intenta de nuevo en unos minutos.',
        statusCode: response.statusCode,
      );
    }
    throw ApiException(
      serverMessage ?? 'La solicitud no pudo procesarse (código ${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }
}
