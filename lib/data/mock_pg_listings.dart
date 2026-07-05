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
    gender: 'Unisex',
    foodIncluded: true,
    hasAc: true,
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
    gender: 'Male',
    foodIncluded: false,
    hasAc: false,
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
    gender: 'Female',
    foodIncluded: true,
    hasAc: true,
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
    gender: 'Unisex',
    foodIncluded: false,
    hasAc: true,
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
    gender: 'Male',
    foodIncluded: true,
    hasAc: false,
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
    gender: 'Female',
    foodIncluded: true,
    hasAc: true,
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
    gender: 'Unisex',
    foodIncluded: false,
    hasAc: true,
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
    gender: 'Male',
    foodIncluded: true,
    hasAc: true,
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
    gender: 'Female',
    foodIncluded: true,
    hasAc: true,
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
    gender: 'Unisex',
    foodIncluded: true,
    hasAc: true,
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
    gender: 'Male',
    foodIncluded: true,
    hasAc: false,
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
    gender: 'Female',
    foodIncluded: true,
    hasAc: true,
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
    gender: 'Unisex',
    foodIncluded: true,
    hasAc: true,
  ),
];

List<PGListing> getPgListingsNearLocation(double lat, double lng, {double radiusKm = 20.0}) {
  return allPgListings;
}

List<PGListing> generateDynamicMockPgs(String areaName, double lat, double lng) {
  final cleanName = areaName.split(',').first.trim();
  
  final pgNames = [
    '$cleanName Girls Luxury Haven',
    'Stanza Living $cleanName Boys House',
    'Zolo $cleanName Co-Living',
    '$cleanName Comfort Stay PG',
    'Saraswati Female Nest',
    'Shiv Shankar PG for Boys',
    '$cleanName Premium Suites',
  ];
  
  final locations = [
    '200m from Hub, $cleanName',
    'Near Metro Station, $cleanName',
    'Tech Park Road, $cleanName',
    'Main Market Street, $cleanName',
    'Greenfield Lane, $cleanName',
    'Opposite City Park, $cleanName',
    'Luxury Lane Sector 2, $cleanName',
  ];
  
  final rents = [8500, 9500, 14500, 18000, 7800, 11000, 24000];
  final ratings = [4.6, 4.2, 4.5, 4.3, 4.4, 4.1, 4.8];
  final safetyScores = [9.2, 8.1, 8.8, 8.0, 8.9, 7.8, 9.4];
  
  final genders = ['Female', 'Male', 'Unisex', 'Female', 'Female', 'Male', 'Unisex'];
  final foodOpts = [true, true, false, true, true, false, true];
  final acOpts = [true, false, true, false, false, false, true];

  final vibes = [
    'Ultra safe stays for women with premium biometrics & gym access',
    'Student-friendly co-working spaces with high-speed internet',
    'Vibrant community spaces, ideal for young IT professionals',
    'Cozy, peaceful residential area, very close to prime transport links',
    'Budget-friendly safe home-stay feel for students and interns',
    'Simple rooms near local colleges, active sports lounge area',
    'Modern executive suites with parking, private lounge, and housekeeping',
  ];
  
  final images = [
    'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1536376072261-38c75010e6c9?auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=500&q=80',
  ];
  
  final allAmenitiesList = [
    ['Wi-Fi', 'AC Rooms', '3-time Meals', '24/7 Security', 'Gym Access'],
    ['Wi-Fi', 'Laundry', 'Lounge Area', 'Daily Housekeeping'],
    ['High-speed Wi-Fi', 'Attached Washroom', 'AC Rooms', 'Biometric Entry'],
    ['Wi-Fi', 'Power Backup', 'Daily Housekeeping'],
    ['3-time Meals', 'Wi-Fi', '24/7 Security', 'Attached Washroom'],
    ['Wi-Fi', 'Power Backup', 'Washing Machine'],
    ['High-speed Wi-Fi', 'AC Rooms', 'Attached Washroom', 'Parking', 'Gym'],
  ];

  final random = math.Random(areaName.hashCode);

  return List.generate(7, (index) {
    // Systematic offsets for distance testing:
    // Index 0: very close (Walking: ~400m)
    // Index 1: moderate (Walking/Drive: ~900m)
    // Index 2: mid-distance (~1.8km)
    // Index 3: far (~3.2km)
    // Index 4: very close budget stay (~500m)
    // Index 5: moderate (~1.4km)
    // Index 6: executive stay (~2.5km)
    double distanceMultiplier = 0.004 * (index + 1);
    if (index == 4) distanceMultiplier = 0.005; // close

    final angle = random.nextDouble() * 2 * math.pi;
    final latOffset = math.sin(angle) * distanceMultiplier;
    final lngOffset = math.cos(angle) * distanceMultiplier;

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
      gender: genders[index],
      foodIncluded: foodOpts[index],
      hasAc: acOpts[index],
    );
  });
}
