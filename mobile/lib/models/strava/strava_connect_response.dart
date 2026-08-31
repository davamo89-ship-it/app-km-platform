class StravaConnectResponse {
  const StravaConnectResponse({
    required this.authorizationUrl,
  });

  final String authorizationUrl;

  factory StravaConnectResponse.fromJson(Map<String, dynamic> json) {
    return StravaConnectResponse(
      authorizationUrl: json['authorizationUrl'] as String,
    );
  }
}
