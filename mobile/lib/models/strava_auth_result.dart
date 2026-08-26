import 'strava_token.dart';

class StravaAthlete {
  const StravaAthlete({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileImageUrl,
    this.city,
    this.country,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String? profileImageUrl;
  final String? city;
  final String? country;

  String get fullName {
    return '$firstName $lastName'.trim();
  }

  factory StravaAthlete.fromJson(Map<String, dynamic> json) {
    return StravaAthlete(
      id: _readRequiredInt(json, 'id'),
      firstName: json['firstname']?.toString() ?? '',
      lastName: json['lastname']?.toString() ?? '',
      profileImageUrl: json['profile']?.toString(),
      city: json['city']?.toString(),
      country: json['country']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstname': firstName,
      'lastname': lastName,
      'profile': profileImageUrl,
      'city': city,
      'country': country,
    };
  }

  static int _readRequiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is int) {
      return value;
    }

    final parsed = int.tryParse(value?.toString() ?? '');

    if (parsed == null) {
      throw FormatException('El campo "$key" no contiene un número válido.');
    }

    return parsed;
  }
}

class StravaAuthResult {
  const StravaAuthResult({
    required this.token,
    required this.athlete,
    required this.grantedScopes,
  });

  final StravaToken token;
  final StravaAthlete athlete;

  /// Permisos aceptados realmente por el atleta.
  final Set<String> grantedScopes;

  bool hasScope(String scope) {
    return grantedScopes.contains(scope);
  }

  bool get canReadActivities {
    return hasScope('activity:read') || hasScope('activity:read_all');
  }

  factory StravaAuthResult.fromJson(Map<String, dynamic> json) {
    final athleteJson = json['athlete'];

    if (athleteJson is! Map) {
      throw const FormatException(
        'La respuesta no contiene información válida del atleta.',
      );
    }

    return StravaAuthResult(
      token: StravaToken.fromJson(json),
      athlete: StravaAthlete.fromJson(Map<String, dynamic>.from(athleteJson)),
      grantedScopes: _parseScopes(json['scope']),
    );
  }

  static Set<String> _parseScopes(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet();
    }

    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return <String>{};
    }

    return text
        .split(RegExp(r'[\s,]+'))
        .map((scope) => scope.trim())
        .where((scope) => scope.isNotEmpty)
        .toSet();
  }
}
