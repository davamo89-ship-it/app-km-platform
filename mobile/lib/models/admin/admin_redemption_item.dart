class AdminRedemptionItem {
  const AdminRedemptionItem({
    required this.redemptionRequestId,
    required this.code,
    required this.athleteId,
    required this.athleteDisplayName,
    required this.merchantId,
    required this.merchantName,
    required this.requestedPoints,
    required this.proposedPoints,
    required this.status,
    required this.createdAtUtc,
    required this.expiresAtUtc,
    required this.merchantProposedAtUtc,
    required this.athleteConfirmedAtUtc,
    required this.completedAtUtc,
  });

  final String redemptionRequestId;
  final String code;
  final String athleteId;
  final String athleteDisplayName;
  final String? merchantId;
  final String? merchantName;
  final int requestedPoints;
  final int? proposedPoints;
  final String status;
  final DateTime createdAtUtc;
  final DateTime expiresAtUtc;
  final DateTime? merchantProposedAtUtc;
  final DateTime? athleteConfirmedAtUtc;
  final DateTime? completedAtUtc;

  int get points => proposedPoints ?? requestedPoints;

  factory AdminRedemptionItem.fromJson(Map<String, dynamic> json) {
    return AdminRedemptionItem(
      redemptionRequestId: json['redemptionRequestId'] as String,
      code: json['code'] as String,
      athleteId: json['athleteId'] as String,
      athleteDisplayName: json['athleteDisplayName'] as String,
      merchantId: json['merchantId'] as String?,
      merchantName: json['merchantName'] as String?,
      requestedPoints: json['requestedPoints'] as int,
      proposedPoints: json['proposedPoints'] as int?,
      status: json['status'] as String,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      expiresAtUtc: DateTime.parse(json['expiresAtUtc'] as String),
      merchantProposedAtUtc: json['merchantProposedAtUtc'] == null
          ? null
          : DateTime.parse(json['merchantProposedAtUtc'] as String),
      athleteConfirmedAtUtc: json['athleteConfirmedAtUtc'] == null
          ? null
          : DateTime.parse(json['athleteConfirmedAtUtc'] as String),
      completedAtUtc: json['completedAtUtc'] == null
          ? null
          : DateTime.parse(json['completedAtUtc'] as String),
    );
  }
}
