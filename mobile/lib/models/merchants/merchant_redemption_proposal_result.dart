class MerchantRedemptionProposalResult {
  const MerchantRedemptionProposalResult({
    required this.redemptionRequestId,
    required this.merchantId,
    required this.code,
    required this.proposedPoints,
    required this.status,
    required this.merchantProposedAtUtc,
  });

  final String redemptionRequestId;
  final String merchantId;
  final String code;
  final int proposedPoints;
  final String status;
  final DateTime merchantProposedAtUtc;

  factory MerchantRedemptionProposalResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return MerchantRedemptionProposalResult(
      redemptionRequestId:
          json['redemptionRequestId'] as String? ?? '',
      merchantId: json['merchantId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      proposedPoints:
          (json['proposedPoints'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      merchantProposedAtUtc:
          DateTime.parse(json['merchantProposedAtUtc'] as String),
    );
  }
}
