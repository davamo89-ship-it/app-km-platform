class MerchantProfile {
  const MerchantProfile({
    required this.merchantId,
    required this.userId,
    required this.businessName,
    required this.status,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String merchantId;
  final String userId;
  final String businessName;
  final String status;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory MerchantProfile.fromJson(
    Map<String, dynamic> json,
  ) {
    return MerchantProfile(
      merchantId: json['merchantId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      businessName:
          json['businessName'] as String? ?? 'Comercio',
      status: json['status'] as String? ?? '',
      createdAtUtc:
          DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc: json['updatedAtUtc'] == null
          ? null
          : DateTime.parse(json['updatedAtUtc'] as String),
    );
  }
}
