import 'dart:math' as math;
import '../models/pg_listing.dart';

const List<PGListing> allPgListings = [
  // GOA - Vasco da Gama (Near BITS)
  PGListing(
    name: 'Goa Shores PG',
    location: 'Zuarinagar, Sancoale',
    neighborhood: 'Vasco da Gama',
    rent: 12500,
    verified: true,
    safetyScore: 8.4,
    rating: 4.5,
    source: 'Google Places',
    vibe: 'Beachside coworking and calm stay',
    lat: 15.3855,
    lng: 73.8760,
    imageUrl: 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=500&q=80',
    amenities: ['Wi-Fi', 'AC Rooms', 'Daily Housekeeping', 'Power Backup'],
  ),
  PGListing(
    name: 'BITS Enclave',
    location: 'Airport Road, Chicalim',
    neighborhood: 'Vasco da Gama',
    rent: 11000,
    verified: true,
    safetyScore: 8.0,
    rating: 4.2,
    source: 'Google Places',
    vibe: 'Student-friendly vibe',
    lat: 15.3940,
    lng: 73.8500,
    imageUrl: 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=500&q=80',
    amenities: ['High-speed Wi-Fi', 'Attached Bathroom', 'Lounge Area', 'Washing Machine'],
  ),
  // GOA - Panaji
  PGListing(
    name: 'Heritage Stay Panjim',
    location: 'Fontainhas, Panaji',
    neighborhood: 'Panaji',
    rent: 22000,
    verified: true,
    safetyScore: 9.0,
    rating: 4.8,
    source: 'Google Places',
    vibe: 'Heritage and culture',
    lat: 15.4989,
    lng: 73.8278,
    imageUrl: 'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=500&q=80',
    amenities: ['AC Rooms', 'Gym Access', 'Personal Wardrobe', '3-time Meals'],
  ),
  PGListing(
    name: 'Miramar Comfort',
    location: 'Miramar Beach Road',
    neighborhood: 'Panaji',
    rent: 20000,
    verified: false,
    safetyScore: 8.5,
    rating: 4.4,
    source: 'Google Places',
    vibe: 'Ocean breeze and morning walks',
    lat: 15.4856,
    lng: 73.8123,
    imageUrl: 'https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=500&q=80',
    amenities: ['High-speed Wi-Fi', 'Biometric Entry', 'Smart TV', 'AC Rooms'],
  ),
  // GOA - Margao
  PGListing(
    name: 'Colva Link PG',
    location: 'Borda, Margao',
    neighborhood: 'Margao',
    rent: 18000,
    verified: true,
    safetyScore: 8.1,
    rating: 4.3,
    source: 'Google Places',
    vibe: 'City center access',
    lat: 15.2832,
    lng: 73.9644,
    imageUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=500&q=80',
    amenities: ['Wi-Fi', 'AC Rooms', 'Daily Housekeeping', 'Power Backup'],
  ),

  // PUNE - Koregaon Park
  PGListing(
    name: 'Osho Valley Stay',
    location: 'Lane 2, Koregaon Park',
    neighborhood: 'Koregaon Park',
    rent: 28000,
    verified: true,
    safetyScore: 9.1,
    rating: 4.7,
    source: 'Google Places',
    vibe: 'Premium cafe culture',
    lat: 18.5362,
    lng: 73.8939,
    imageUrl: 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=500&q=80',
    amenities: ['High-speed Wi-Fi', 'AC Rooms', '3-time Meals', '24/7 Security'],
  ),
  PGListing(
    name: 'KP Premium Homes',
    location: 'North Main Road',
    neighborhood: 'Koregaon Park',
    rent: 29500,
    verified: true,
    safetyScore: 8.8,
    rating: 4.5,
    source: 'Google Places',
    vibe: 'Quiet and upscale',
    lat: 18.5385,
    lng: 73.8966,
    imageUrl: 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=500&q=80',
    amenities: ['Wi-Fi', 'AC Rooms', 'Daily Housekeeping', 'Power Backup'],
  ),
  // PUNE - Baner
  PGListing(
    name: 'IT Nest Baner',
    location: 'Baner Balewadi Road',
    neighborhood: 'Baner',
    rent: 22000,
    verified: true,
    safetyScore: 8.5,
    rating: 4.3,
    source: 'Google Places',
    vibe: 'Tech crowd community',
    lat: 18.5590,
    lng: 73.7868,
    imageUrl: 'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=500&q=80',
    amenities: ['High-speed Wi-Fi', 'Attached Bathroom', 'Lounge Area', 'Washing Machine'],
  ),
  PGListing(
    name: 'Highstreet PG',
    location: 'Near Balewadi High Street',
    neighborhood: 'Baner',
    rent: 24000,
    verified: true,
    safetyScore: 8.6,
    rating: 4.6,
    source: 'Google Places',
    vibe: 'Modern lifestyle',
    lat: 18.5620,
    lng: 73.7800,
    imageUrl: 'https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=500&q=80',
    amenities: ['AC Rooms', 'Gym Access', 'Personal Wardrobe', '3-time Meals'],
  ),

  // BANGALORE - Koramangala
  PGListing(
    name: 'Startup Homes PG',
    location: 'Near 7th Block',
    neighborhood: 'Koramangala',
    rent: 32000,
    verified: true,
    safetyScore: 8.5,
    rating: 4.6,
    source: 'Google Places',
    vibe: 'Community living with tech crowd',
    lat: 12.9352,
    lng: 77.6245,
    imageUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=500&q=80',
    amenities: ['High-speed Wi-Fi', 'AC Rooms', '3-time Meals', '24/7 Security'],
  ),
  PGListing(
    name: 'Cafe Lane PG',
    location: 'Near Forum Mall',
    neighborhood: 'Koramangala',
    rent: 30000,
    verified: true,
    safetyScore: 8.0,
    rating: 4.4,
    source: 'Google Places',
    vibe: 'Active lifestyle, social spaces',
    lat: 12.9380,
    lng: 77.6110,
    imageUrl: 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=500&q=80',
    amenities: ['Wi-Fi', 'AC Rooms', 'Daily Housekeeping', 'Power Backup'],
  ),
  // BANGALORE - Indiranagar
  PGListing(
    name: 'Boutique PG',
    location: 'Near 100 Feet Road',
    neighborhood: 'Indiranagar',
    rent: 35000,
    verified: true,
    safetyScore: 8.3,
    rating: 4.7,
    source: 'Google Places',
    vibe: 'Premium shared rooms with cafe access',
    lat: 12.9784,
    lng: 77.6408,
    imageUrl: 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=500&q=80',
    amenities: ['High-speed Wi-Fi', 'Attached Bathroom', 'Lounge Area', 'Washing Machine'],
  ),
  PGListing(
    name: 'Green Lane PG',
    location: 'Inner Ring Road',
    neighborhood: 'Indiranagar',
    rent: 33000,
    verified: false,
    safetyScore: 7.7,
    rating: 4.2,
    source: 'Google Places',
    vibe: 'Comfortable stay with greenery',
    lat: 12.9719,
    lng: 77.6412,
    imageUrl: 'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=500&q=80',
    amenities: ['AC Rooms', 'Gym Access', 'Personal Wardrobe', '3-time Meals'],
  ),
];

List<PGListing> getPgListingsNearLocation(double lat, double lng, {double radiusKm = 20.0}) {
  return allPgListings;
}

List<PGListing> generateDynamicMockPgs(String areaName, double lat, double lng) {
  // Generate 5 dynamic PGs centered around this custom area
  final cleanName = areaName.split(',').first.trim();
  
  final pgNames = [
    '$cleanName Elite Co-Living',
    '$cleanName Nest PG',
    'Zolo $cleanName Premium',
    'Stanza Living $cleanName House',
    'The $cleanName Luxury Stays',
  ];
  
  final locations = [
    'Near Main Market, $cleanName',
    'Opposite City Park, $cleanName',
    'Tech Hub Street, $cleanName',
    'Metro Station Road, $cleanName',
    'Premium Enclave, $cleanName',
  ];
  
  final rents = [14500, 18000, 22500, 26000, 31000];
  final ratings = [4.3, 4.5, 4.2, 4.7, 4.6];
  final safetyScores = [8.2, 8.8, 8.0, 9.2, 9.0];
  final vibes = [
    'Student friendly with active study lounges and co-working areas',
    'Calm residential environment, ideal for quiet professionals',
    'Vibrant nightlife nearby, active social community spaces',
    'Luxury amenities with housekeeping and personal chef services',
    'Modern tech-enabled spaces, biometric entry, and smart rooms',
  ];
  
  final images = [
    'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=500&q=80',
  ];
  
  final allAmenitiesList = [
    ['High-speed Wi-Fi', 'AC Rooms', '3-time Meals', '24/7 Security'],
    ['Wi-Fi', 'AC Rooms', 'Daily Housekeeping', 'Power Backup'],
    ['High-speed Wi-Fi', 'Attached Bathroom', 'Lounge Area', 'Washing Machine'],
    ['AC Rooms', 'Gym Access', 'Personal Wardrobe', '3-time Meals'],
    ['High-speed Wi-Fi', 'Biometric Entry', 'Smart TV', 'AC Rooms'],
  ];

  final random = math.Random(areaName.hashCode); // Seeded for consistency

  return List.generate(5, (index) {
    // Generate slight offset for coordinates within 1-2km (0.009 degree is approx 1km)
    final latOffset = (random.nextDouble() - 0.5) * 0.025;
    final lngOffset = (random.nextDouble() - 0.5) * 0.025;

    return PGListing(
      name: pgNames[index],
      location: locations[index],
      neighborhood: cleanName,
      rent: rents[index],
      verified: index % 2 == 0,
      safetyScore: safetyScores[index],
      rating: ratings[index],
      source: 'Google Places',
      vibe: vibes[index],
      lat: lat + latOffset,
      lng: lng + lngOffset,
      imageUrl: images[index],
      amenities: allAmenitiesList[index],
    );
  });
}
