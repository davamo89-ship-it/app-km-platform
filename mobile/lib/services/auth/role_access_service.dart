import '../../core/config/api_config.dart';
import '../api/authenticated_api_client.dart';

enum AppUserRole {
  athlete,
  merchant,
  admin,
  unknown,
}

class RoleAccessException implements Exception {
  const RoleAccessException(
    this.message, {
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class RoleAccessService {
  RoleAccessService({
    AuthenticatedApiClient? apiClient,
  }) : _apiClient =
            apiClient ?? AuthenticatedApiClient();

  final AuthenticatedApiClient _apiClient;

  Future<AppUserRole> resolveCurrentRole() async {
    final merchantStatus =
        await _checkAccess('merchant');

    if (merchantStatus == 200) {
      return AppUserRole.merchant;
    }

    _throwIfAuthenticationFailed(merchantStatus);

    final athleteStatus =
        await _checkAccess('athlete');

    if (athleteStatus == 200) {
      return AppUserRole.athlete;
    }

    _throwIfAuthenticationFailed(athleteStatus);

    final adminStatus =
        await _checkAccess('admin');

    if (adminStatus == 200) {
      return AppUserRole.admin;
    }

    _throwIfAuthenticationFailed(adminStatus);

    return AppUserRole.unknown;
  }

  Future<int> _checkAccess(String role) async {
    final response = await _apiClient.get(
      ApiConfig.identityUri(
        '/api/v1/identity/access/$role',
      ),
    );

    return response.statusCode;
  }

  void _throwIfAuthenticationFailed(
    int statusCode,
  ) {
    if (statusCode == 401) {
      throw const RoleAccessException(
        'La sesión ha expirado.',
        statusCode: 401,
      );
    }

    if (statusCode >= 500) {
      throw RoleAccessException(
        'No fue posible validar el tipo de usuario.',
        statusCode: statusCode,
      );
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}
