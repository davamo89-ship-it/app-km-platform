class PendingRedemptionConfirmation {
  const PendingRedemptionConfirmation({
    required this.redemptionRequestId,
    required this.code,
    required this.merchantId,
    required this.merchantName,
    required this.proposedPoints,
    required this.status,
    required this.merchantProposedAtUtc,
    required this.expiresAtUtc,
  });

  final String redemptionRequestId;
  final String code;
  final String merchantId;
  final String merchantName;
  final int proposedPoints;
  final String status;
  final DateTime merchantProposedAtUtc;
  final DateTime expiresAtUtc;

  factory PendingRedemptionConfirmation.fromJson(
    Map<String, dynamic> json,
  ) {
    return PendingRedemptionConfirmation(
      redemptionRequestId:
          json['redemptionRequestId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      merchantId: json['merchantId'] as String? ?? '',
      merchantName:
          json['merchantName'] as String? ?? 'Comercio',
      proposedPoints:
          (json['proposedPoints'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      merchantProposedAtUtc:
          DateTime.parse(json['merchantProposedAtUtc'] as String),
      expiresAtUtc:
          DateTime.parse(json['expiresAtUtc'] as String),
    );
  }
}
