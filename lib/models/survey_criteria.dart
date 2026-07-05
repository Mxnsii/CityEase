class SurveyCriteria {
  final String budget;
  final String officeArea;
  final String officeLocation;
  final double officeLat;
  final double officeLng;
  final String lifestyle;
  final String commute;
  final String gender;          // 'Male Only', 'Female Only', 'Co-living'
  final bool foodIncluded;      // true, false
  final String distancePref;    // 'Walking distance (<1km)', 'Short drive (<4km)', 'Any (<10km)'
  final bool acRequired;        // true, false

  const SurveyCriteria({
    required this.budget,
    required this.officeArea,
    required this.officeLocation,
    required this.officeLat,
    required this.officeLng,
    required this.lifestyle,
    required this.commute,
    required this.gender,
    required this.foodIncluded,
    required this.distancePref,
    required this.acRequired,
  });

  String get summary => '$officeLocation · $budget · $gender · ${foodIncluded ? "Food Incl." : "No Food"} · ${acRequired ? "AC Required" : "No AC"}';
}
