class RedemptionActionResult {
  const RedemptionActionResult({
    required this.redemptionRequestId,
    required this.code,
    required this.status,
    this.redeemedPoints,
    this.athleteConfirmedAtUtc,
    this.completedAtUtc,
    this.rejectedAtUtc,
  });

  final String redemptionRequestId;
  final String code;
  final String status;
  final int? redeemedPoints;
  final DateTime? athleteConfirmedAtUtc;
  final DateTime? completedAtUtc;
  final DateTime? rejectedAtUtc;

  factory RedemptionActionResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return RedemptionActionResult(
      redemptionRequestId:
          json['redemptionRequestId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      status: json['status'] as String? ?? '',
      redeemedPoints:
          (json['redeemedPoints'] as num?)?.toInt(),
      athleteConfirmedAtUtc:
          _parseNullable(json['athleteConfirmedAtUtc']),
      completedAtUtc:
          _parseNullable(json['completedAtUtc']),
      rejectedAtUtc:
          _parseNullable(json['rejectedAtUtc']),
    );
  }

  static DateTime? _parseNullable(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.parse(value);
  }
}
