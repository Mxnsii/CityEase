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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'neighborhood': neighborhood,
      'rent': rent,
      'verified': verified,
      'safetyScore': safetyScore,
      'rating': rating,
      'source': source,
      'vibe': vibe,
      'lat': lat,
      'lng': lng,
      'imageUrl': imageUrl,
      'amenities': amenities,
      'gender': gender,
      'foodIncluded': foodIncluded,
      'hasAc': hasAc,
      'placeId': placeId,
    };
  }

  factory PGListing.fromJson(Map<String, dynamic> json) {
    return PGListing(
      name: json['name'] as String,
      location: json['location'] as String,
      neighborhood: json['neighborhood'] as String,
      rent: json['rent'] as int,
      verified: json['verified'] as bool,
      safetyScore: (json['safetyScore'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      source: json['source'] as String,
      vibe: json['vibe'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      amenities: List<String>.from(json['amenities'] as List),
      gender: json['gender'] as String,
      foodIncluded: json['foodIncluded'] as bool,
      hasAc: json['hasAc'] as bool,
      placeId: json['placeId'] as String?,
    );
  }
}
