class MerchantLatestRedemption {
  const MerchantLatestRedemption({
    required this.redemptionRequestId,
    required this.code,
    required this.athleteId,
    required this.athleteDisplayName,
    required this.points,
    required this.status,
    required this.createdAtUtc,
    required this.merchantProposedAtUtc,
    required this.completedAtUtc,
  });

  final String redemptionRequestId;
  final String code;
  final String athleteId;
  final String athleteDisplayName;
  final int points;
  final String status;
  final DateTime createdAtUtc;
  final DateTime? merchantProposedAtUtc;
  final DateTime? completedAtUtc;

  factory MerchantLatestRedemption.fromJson(
    Map<String, dynamic> json,
  ) {
    DateTime? parseNullableDate(dynamic value) {
      if (value is! String || value.trim().isEmpty) {
        return null;
      }

      return DateTime.tryParse(value);
    }

    return MerchantLatestRedemption(
      redemptionRequestId:
          json['redemptionRequestId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      athleteId: json['athleteId'] as String? ?? '',
      athleteDisplayName:
          json['athleteDisplayName'] as String? ?? 'Atleta',
      points: (json['points'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      createdAtUtc: DateTime.parse(
        json['createdAtUtc'] as String,
      ),
      merchantProposedAtUtc: parseNullableDate(
        json['merchantProposedAtUtc'],
      ),
      completedAtUtc: parseNullableDate(
        json['completedAtUtc'],
      ),
    );
  }
}
