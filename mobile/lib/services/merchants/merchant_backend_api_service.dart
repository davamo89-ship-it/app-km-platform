import 'dart:convert';

import '../../core/config/api_config.dart';
import '../../models/merchants/merchant_latest_redemption.dart';
import '../../models/merchants/merchant_profile.dart';
import '../../models/merchants/merchant_redemption_proposal_result.dart';
import '../../models/merchants/merchant_redemption_validation.dart';
import '../api/authenticated_api_client.dart';

class MerchantBackendApiException implements Exception {
  const MerchantBackendApiException(
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

class MerchantBackendApiService {
  MerchantBackendApiService({
    AuthenticatedApiClient? apiClient,
  }) : _apiClient = apiClient ?? AuthenticatedApiClient();

  final AuthenticatedApiClient _apiClient;

  Future<MerchantProfile> getCurrentMerchant() async {
    final response = await _apiClient.get(
      ApiConfig.athletesUri('/api/v1/merchants/me'),
    );

    return MerchantProfile.fromJson(
      _decodeObject(
        response.statusCode,
        response.bodyBytes,
      ),
    );
  }

  Future<MerchantLatestRedemption?>
      getLatestRedemption() async {
    final response = await _apiClient.get(
      ApiConfig.athletesUri(
        '/api/v1/merchants/redemptions/latest',
      ),
    );

    if (response.statusCode == 204) {
      return null;
    }

    return MerchantLatestRedemption.fromJson(
      _decodeObject(
        response.statusCode,
        response.bodyBytes,
      ),
    );
  }

  Future<List<MerchantLatestRedemption>>
      getRedemptionHistory() async {
    final response = await _apiClient.get(
      ApiConfig.athletesUri(
        '/api/v1/merchants/redemptions/history',
      ),
    );

    final items = _decodeList(
      response.statusCode,
      response.bodyBytes,
    );

    return items
        .map(
          (item) => MerchantLatestRedemption.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<MerchantRedemptionValidation> validateRedemption({
    required String code,
  }) async {
    final normalizedCode = code.trim();

    final response = await _apiClient.get(
      ApiConfig.athletesUri(
        '/api/v1/merchants/redemptions/'
        '${Uri.encodeComponent(normalizedCode)}',
      ),
    );

    return MerchantRedemptionValidation.fromJson(
      _decodeObject(
        response.statusCode,
        response.bodyBytes,
      ),
    );
  }

  Future<MerchantRedemptionProposalResult> proposeRedemption({
    required String code,
    required int proposedPoints,
  }) async {
    final normalizedCode = code.trim();

    final response = await _apiClient.post(
      ApiConfig.athletesUri(
        '/api/v1/merchants/redemptions/'
        '${Uri.encodeComponent(normalizedCode)}/proposal',
      ),
      body: {
        'proposedPoints': proposedPoints,
      },
    );

    return MerchantRedemptionProposalResult.fromJson(
      _decodeObject(
        response.statusCode,
        response.bodyBytes,
      ),
    );
  }

  List<dynamic> _decodeList(
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
          throw const MerchantBackendApiException(
            'La respuesta del servidor no es válida.',
          );
        }
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      if (decoded is List<dynamic>) {
        return decoded;
      }

      throw const MerchantBackendApiException(
        'La respuesta del servidor no tiene el formato esperado.',
      );
    }

    var message =
        'No fue posible cargar el historial de canjes.';
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

    throw MerchantBackendApiException(
      message,
      statusCode: statusCode,
      code: code,
    );
  }

  Map<String, dynamic> _decodeObject(
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
          throw const MerchantBackendApiException(
            'La respuesta del servidor no es válida.',
          );
        }
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw const MerchantBackendApiException(
        'La respuesta del servidor no tiene el formato esperado.',
      );
    }

    var message =
        'No fue posible procesar la solicitud del comercio.';
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

    throw MerchantBackendApiException(
      message,
      statusCode: statusCode,
      code: code,
    );
  }

  void dispose() {
    _apiClient.dispose();
  }
}
