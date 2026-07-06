class PGListing {
  final String name;
  final String location;
  final String neighborhood;
  final int rent;
  final bool verified;
  final double safetyScore;
  final double rating;
  final String source;
  final String vibe;
  final double lat;
  final double lng;
  final String imageUrl;
  final List<String> amenities;
  final String gender;          // 'Male', 'Female', 'Unisex'
  final bool foodIncluded;
  final bool hasAc;
  final String? placeId;

  const PGListing({
    required this.name,
    required this.location,
    required this.neighborhood,
    required this.rent,
    required this.verified,
    required this.safetyScore,
    required this.rating,
    required this.source,
    required this.vibe,
    required this.lat,
    required this.lng,
    required this.imageUrl,
    required this.amenities,
    required this.gender,
    required this.foodIncluded,
    required this.hasAc,
    this.placeId,
  });
}
