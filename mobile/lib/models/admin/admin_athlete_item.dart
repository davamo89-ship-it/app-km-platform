class AdminAthleteItem {
  const AdminAthleteItem({
    required this.athleteId,
    required this.userId,
    required this.displayName,
    required this.profileImageUrl,
    required this.countryCode,
    required this.birthDate,
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
  final DateTime? birthDate;
  final String? preferredSport;
  final String status;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory AdminAthleteItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminAthleteItem(
      athleteId: json['athleteId'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      profileImageUrl:
          json['profileImageUrl'] as String?,
      countryCode:
          json['countryCode'] as String?,
      birthDate: json['birthDate'] == null
          ? null
          : DateTime.parse(
              json['birthDate'] as String,
            ),
      preferredSport:
          json['preferredSport'] as String?,
      status: json['status'] as String,
      createdAtUtc: DateTime.parse(
        json['createdAtUtc'] as String,
      ),
      updatedAtUtc: json['updatedAtUtc'] == null
          ? null
          : DateTime.parse(
              json['updatedAtUtc'] as String,
            ),
    );
  }
}
