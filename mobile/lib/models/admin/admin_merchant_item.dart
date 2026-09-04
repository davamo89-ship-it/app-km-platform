class AdminMerchantItem {
  const AdminMerchantItem({
    required this.athleteId,
    required this.userId,
    required this.displayName,
    required this.profileImageUrl,
    required this.countryCode,
    required this.preferredSport,
    required this.status,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  final String athleteId;
  final String userId;
  final String displayName;
  final String? profileImageUrl;
  final String? countryCode;
  final String? preferredSport;
  final String status;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory AdminMerchantItem.fromJson(Map<String, dynamic> json) {
    return AdminMerchantItem(
      athleteId: json['athleteId'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      countryCode: json['countryCode'] as String?,
      preferredSport: json['preferredSport'] as String?,
      status: json['status'] as String,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc: json['updatedAtUtc'] == null
          ? null
          : DateTime.parse(json['updatedAtUtc'] as String),
    );
  }
}
