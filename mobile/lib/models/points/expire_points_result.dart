class ExpirePointsResult {
  const ExpirePointsResult({
    required this.expiredLots,
    required this.expiredPoints,
  });

  final int expiredLots;
  final int expiredPoints;

  factory ExpirePointsResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return ExpirePointsResult(
      expiredLots: (json['expiredLots'] as num?)?.toInt() ?? 0,
      expiredPoints:
          (json['expiredPoints'] as num?)?.toInt() ?? 0,
    );
  }
}
