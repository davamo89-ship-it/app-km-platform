class StravaSyncResult {
  const StravaSyncResult({
    required this.retrieved,
    required this.saved,
    required this.skippedInvalid,
    required this.skippedDuplicate,
  });

  final int retrieved;
  final int saved;
  final int skippedInvalid;
  final int skippedDuplicate;

  factory StravaSyncResult.fromJson(Map<String, dynamic> json) {
    return StravaSyncResult(
      retrieved: (json['retrieved'] as num).toInt(),
      saved: (json['saved'] as num).toInt(),
      skippedInvalid: (json['skippedInvalid'] as num).toInt(),
      skippedDuplicate: (json['skippedDuplicate'] as num).toInt(),
    );
  }
}