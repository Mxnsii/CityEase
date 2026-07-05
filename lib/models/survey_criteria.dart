class SurveyCriteria {
  final String budget;
  final String officeArea;
  final String officeLocation;
  final double officeLat;
  final double officeLng;
  final String lifestyle;
  final String commute;

  const SurveyCriteria({
    required this.budget,
    required this.officeArea,
    required this.officeLocation,
    required this.officeLat,
    required this.officeLng,
    required this.lifestyle,
    required this.commute,
  });

  String get summary => '$officeLocation · $budget · $commute';
}
