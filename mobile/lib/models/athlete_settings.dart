class AthleteSettings {
  const AthleteSettings({
    required this.athleteId,
    required this.displayName,
    required this.profileImageUrl,
    required this.countryCode,
    required this.birthDate,
    required this.preferredSport,
    required this.stravaConnected,
    required this.stravaStatus,
    required this.stravaAthleteId,
    required this.stravaConnectedAtUtc,
  });

  final String athleteId;
  final String displayName;
  final String? profileImageUrl;
  final String? countryCode;
  final DateTime? birthDate;
  final String? preferredSport;

  final bool stravaConnected;
  final String? stravaStatus;
  final int? stravaAthleteId;
  final DateTime? stravaConnectedAtUtc;

  factory AthleteSettings.fromJson(
    Map<String, dynamic> json,
  ) {
    return AthleteSettings(
      athleteId: json['athleteId'] as String,
      displayName: json['displayName'] as String,
      profileImageUrl:
          json['profileImageUrl'] as String?,
      countryCode: json['countryCode'] as String?,
      birthDate: json['birthDate'] == null
          ? null
          : DateTime.parse(
              json['birthDate'] as String,
            ),
      preferredSport:
          json['preferredSport'] as String?,
      stravaConnected:
          json['stravaConnected'] as bool,
      stravaStatus:
          json['stravaStatus'] as String?,
      stravaAthleteId:
          (json['stravaAthleteId'] as num?)?.toInt(),
      stravaConnectedAtUtc:
          json['stravaConnectedAtUtc'] == null
              ? null
              : DateTime.parse(
                  json['stravaConnectedAtUtc']
                      as String,
                ),
    );
  }
}