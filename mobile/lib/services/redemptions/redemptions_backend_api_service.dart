import 'dart:convert';

import '../../core/config/api_config.dart';
import '../../models/redemptions/create_redemption_result.dart';
import '../../models/redemptions/pending_redemption_confirmation.dart';
import '../../models/redemptions/redemption_action_result.dart';
import '../../models/redemptions/redemption_request_item.dart';
import '../api/authenticated_api_client.dart';

class RedemptionsBackendApiException implements Exception {
  const RedemptionsBackendApiException(
    this.message, {
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class RedemptionsBackendApiService {
  RedemptionsBackendApiService({
    AuthenticatedApiClient? apiClient,
  }) : _apiClient = apiClient ?? AuthenticatedApiClient();

  final AuthenticatedApiClient _apiClient;

  Future<CreateRedemptionResult> create({
    required int requestedPoints,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.athletesUri(
        '/api/v1/athletes/redemptions',
      ),
      body: {
        'requestedPoints': requestedPoints,
      },
    );

    final json = _decodeObject(
      response.statusCode,
      response.bodyBytes,
    );

    return CreateRedemptionResult.fromJson(json);
  }

  Future<List<RedemptionRequestItem>> getAll() async {
    final response = await _apiClient.get(
      ApiConfig.athletesUri(
        '/api/v1/athletes/redemptions',
      ),
    );

    final json = _decodeList(
      response.statusCode,
      response.bodyBytes,
    );

    return json
        .map(
          (item) => RedemptionRequestItem.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<PendingRedemptionConfirmation?>
      getPendingConfirmation() async {
    final response = await _apiClient.get(
      ApiConfig.athletesUri(
        '/api/v1/athletes/redemptions/pending-confirmation',
      ),
    );

    if (response.statusCode == 204) {
      return null;
    }

    final json = _decodeObject(
      response.statusCode,
      response.bodyBytes,
    );

    return PendingRedemptionConfirmation.fromJson(json);
  }

  Future<RedemptionActionResult> cancel({
    required String code,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.athletesUri(
        '/api/v1/athletes/redemptions/cancel',
      ),
      body: {
        'code': code,
      },
    );

    final json = _decodeObject(
      response.statusCode,
      response.bodyBytes,
    );

    return RedemptionActionResult.fromJson(json);
  }

  Future<RedemptionActionResult> confirm({
    required String code,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.athletesUri(
        '/api/v1/athletes/redemptions/$code/confirm',
      ),
    );

    final json = _decodeObject(
      response.statusCode,
      response.bodyBytes,
    );

    return RedemptionActionResult.fromJson(json);
  }

  Future<RedemptionActionResult> reject({
    required String code,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.athletesUri(
        '/api/v1/athletes/redemptions/$code/reject',
      ),
    );

    final json = _decodeObject(
      response.statusCode,
      response.bodyBytes,
    );

    return RedemptionActionResult.fromJson(json);
  }

  Map<String, dynamic> _decodeObject(
    int statusCode,
    List<int> bodyBytes,
  ) {
    final decoded = _decodeResponse(
      statusCode,
      bodyBytes,
    );

    if (decoded is! Map<String, dynamic>) {
      throw const RedemptionsBackendApiException(
        'La respuesta del servidor no tiene el formato esperado.',
      );
    }

    return decoded;
  }

  List<dynamic> _decodeList(
    int statusCode,
    List<int> bodyBytes,
  ) {
    final decoded = _decodeResponse(
      statusCode,
      bodyBytes,
    );

    if (decoded is! List<dynamic>) {
      throw const RedemptionsBackendApiException(
        'La respuesta del servidor no tiene el formato esperado.',
      );
    }

    return decoded;
  }

  dynamic _decodeResponse(
    int statusCode,
    List<int> bodyBytes,
  ) {
    final body = utf8.decode(bodyBytes);

    dynamic decoded;

    if (body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } on FormatException {
        if (statusCode >= 200 && statusCode < 300) {
          throw const RedemptionsBackendApiException(
            'La respuesta del servidor no es válida.',
          );
        }
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decoded;
    }

    var message =
        'No fue posible procesar el canje.';
    String? code;

    if (decoded is Map<String, dynamic>) {
      final serverMessage = decoded['message'];
      final serverCode = decoded['code'];

      if (serverMessage is String &&
          serverMessage.trim().isNotEmpty) {
        message = serverMessage;
      }

      if (serverCode is String &&
          serverCode.trim().isNotEmpty) {
        code = serverCode;
      }
    }

    throw RedemptionsBackendApiException(
      message,
      statusCode: statusCode,
      code: code,
    );
  }

  void dispose() {
    _apiClient.dispose();
  }
}
