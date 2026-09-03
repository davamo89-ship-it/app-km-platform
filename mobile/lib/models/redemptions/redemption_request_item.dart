class RedemptionRequestItem {
  const RedemptionRequestItem({
    required this.redemptionRequestId,
    required this.code,
    required this.requestedPoints,
    required this.status,
    required this.createdAtUtc,
    required this.expiresAtUtc,
    this.completedAtUtc,
    this.merchantId,
    this.merchantName,
  });

  final String redemptionRequestId;
  final String code;
  final int requestedPoints;
  final String status;
  final DateTime createdAtUtc;
  final DateTime expiresAtUtc;
  final DateTime? completedAtUtc;
  final String? merchantId;
  final String? merchantName;

  factory RedemptionRequestItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return RedemptionRequestItem(
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
      completedAtUtc: json['completedAtUtc'] == null
          ? null
          : DateTime.parse(json['completedAtUtc'] as String),
      merchantId: json['merchantId'] as String?,
      merchantName: json['merchantName'] as String?,
    );
  }

  bool get isPending =>
      status.toLowerCase() == 'pending';

  bool get isCompleted =>
      status.toLowerCase() == 'completed';

  bool get isExpired =>
      status.toLowerCase() == 'expired';

  bool get isCancelled {
    final value = status.toLowerCase();
    return value == 'cancelled' || value == 'canceled';
  }
}
