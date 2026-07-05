class Neighborhood {
  final String name;
  final String region;
  final String tagline;
  final int averageRent;
  final int commuteMinutes;
  final double safetyScore;
  final String vibe;
  final int matchScore;
  final String brief;
  final List<String> reasons;

  const Neighborhood({
    required this.name,
    required this.region,
    required this.tagline,
    required this.averageRent,
    required this.commuteMinutes,
    required this.safetyScore,
    required this.vibe,
    required this.matchScore,
    required this.brief,
    required this.reasons,
  });
}
