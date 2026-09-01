class CreateRedemptionResult {
  const CreateRedemptionResult({
    required this.redemptionRequestId,
    required this.code,
    required this.requestedPoints,
    required this.status,
    required this.createdAtUtc,
    required this.expiresAtUtc,
  });

  final String redemptionRequestId;
  final String code;
  final int requestedPoints;
  final String status;
  final DateTime createdAtUtc;
  final DateTime expiresAtUtc;

  factory CreateRedemptionResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return CreateRedemptionResult(
      redemptionRequestId:
          json['redemptionRequestId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      requestedPoints:
          (json['requestedPoints'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      createdAtUtc:
          DateTime.parse(json['createdAtUtc'] as String),
      expiresAtUtc:
          DateTime.parse(json['expiresAtUtc'] as String),
    );
  }
}
