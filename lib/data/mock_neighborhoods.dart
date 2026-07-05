import '../models/neighborhood.dart';

const List<Neighborhood> topNeighborhoods = [
  Neighborhood(
    name: 'Koramangala',
    region: 'Bangalore',
    tagline: 'Trendy startup hub with vibrant nightlife and coworking energy.',
    averageRent: 31500,
    commuteMinutes: 18,
    safetyScore: 8.5,
    vibe: 'Tech Hub',
    matchScore: 87,
    brief:
        'Koramangala suits your budget and has 3 metro stops within 1.5 km of your office. Perfect for fresh grads seeking convenience and community.',
    reasons: [
      'Short commute to tech parks',
      'Lively social scene and cafes',
      'Balanced affordability with safety',
    ],
  ),
  Neighborhood(
    name: 'Indiranagar',
    region: 'Bangalore',
    tagline: 'Upmarket neighborhood known for boutique shopping, dining, and street culture.',
    averageRent: 33000,
    commuteMinutes: 22,
    safetyScore: 8.8,
    vibe: 'Nightlife & Lifestyle',
    matchScore: 84,
    brief:
        'Indiranagar brings polished lifestyle perks and excellent food options, with a slightly longer commute and strong safety feel.',
    reasons: [
      'Premium cafes and nightlife',
      'Highly rated safety score',
      'Great lifestyle fit for social living',
    ],
  ),
  Neighborhood(
    name: 'Whitefield',
    region: 'Bangalore',
    tagline: 'Campus-style neighborhood with modern residential towers and green lanes.',
    averageRent: 28000,
    commuteMinutes: 34,
    safetyScore: 8.2,
    vibe: 'Modern Comfort',
    matchScore: 78,
    brief:
        'Whitefield offers modern housing with good work-life balance, slightly lower rent, and calm residential value.',
    reasons: [
      'More affordable rent band',
      'Modern apartments and amenities',
      'Quiet environment with good connectivity',
    ],
  ),
];

const List<Neighborhood> goaNeighborhoods = [
  Neighborhood(
    name: 'Vasco da Gama',
    region: 'Goa',
    tagline: 'Coastal port city with a mix of quiet neighborhoods and bustling markets.',
    averageRent: 15000,
    commuteMinutes: 10,
    safetyScore: 8.4,
    vibe: 'Coastal Calm',
    matchScore: 88,
    brief: 'Vasco is highly affordable and extremely close to your office, making it perfect for an easy daily commute and relaxed lifestyle.',
    reasons: [
      'Very close to BITS campus',
      'Affordable rent options',
      'Relaxed coastal vibe',
    ],
  ),
  Neighborhood(
    name: 'Panaji',
    region: 'Goa',
    tagline: 'The capital city with heritage architecture and lively cafes along the river.',
    averageRent: 22000,
    commuteMinutes: 35,
    safetyScore: 8.9,
    vibe: 'Heritage & Cafe Culture',
    matchScore: 82,
    brief: 'Panaji gives you a beautiful heritage feel and excellent amenities, though the commute to campus is a bit longer.',
    reasons: [
      'Vibrant cafe and arts scene',
      'High safety and good infrastructure',
      'Beautiful riverside walks',
    ],
  ),
  Neighborhood(
    name: 'Margao',
    region: 'Goa',
    tagline: 'Commercial and cultural hub with excellent local food and traditional markets.',
    averageRent: 18000,
    commuteMinutes: 25,
    safetyScore: 8.0,
    vibe: 'Traditional Charm',
    matchScore: 75,
    brief: 'Margao is well-connected with a rich cultural vibe, offering balanced rent options with a moderate commute.',
    reasons: [
      'Strong local culture and food',
      'Good connectivity and markets',
      'Reasonable rent prices',
    ],
  ),
];

const List<Neighborhood> puneNeighborhoods = [
  Neighborhood(
    name: 'Koregaon Park',
    region: 'Pune',
    tagline: 'Upscale residential area known for its lush greenery and vibrant cafe culture.',
    averageRent: 28000,
    commuteMinutes: 15,
    safetyScore: 9.0,
    vibe: 'Premium & Green',
    matchScore: 89,
    brief: 'Koregaon Park is a premium choice offering unmatched lifestyle and safety, perfect for young professionals wanting convenience near MG Road.',
    reasons: [
      'Top-tier cafes and restaurants',
      'Very safe and green environment',
      'Close proximity to city center',
    ],
  ),
  Neighborhood(
    name: 'Baner',
    region: 'Pune',
    tagline: 'Fast-growing IT hub with excellent residential complexes and modern amenities.',
    averageRent: 22000,
    commuteMinutes: 30,
    safetyScore: 8.5,
    vibe: 'Modern IT Hub',
    matchScore: 82,
    brief: 'Baner provides great value with modern housing, though the commute to MG Road might be slightly longer during peak hours.',
    reasons: [
      'Affordable modern housing',
      'Growing social infrastructure',
      'Good community vibe for techies',
    ],
  ),
  Neighborhood(
    name: 'Viman Nagar',
    region: 'Pune',
    tagline: 'Lively neighborhood near the airport, popular among students and young pros.',
    averageRent: 24000,
    commuteMinutes: 25,
    safetyScore: 8.3,
    vibe: 'Young & Energetic',
    matchScore: 78,
    brief: 'Viman Nagar is energetic and full of life, offering moderate rents and a very youthful vibe.',
    reasons: [
      'High energy and youthful vibe',
      'Lots of shopping and dining options',
      'Well-connected to public transport',
    ],
  ),
];

List<Neighborhood> getNeighborhoodsForLocation(String location) {
  final loc = location.toLowerCase();
  List<Neighborhood> list = topNeighborhoods;

  if (loc.contains('goa') || loc.contains('vasco') || loc.contains('panaji') || loc.contains('margao') || loc.contains('calangute')) {
    list = List.from(goaNeighborhoods);
  } else if (loc.contains('pune') || loc.contains('koregaon') || loc.contains('baner')) {
    list = List.from(puneNeighborhoods);
  } else {
    list = List.from(topNeighborhoods);
  }

  // Sort so the neighborhood matching the search query is put first
  bool foundExactMatch = false;
  list.sort((a, b) {
    bool aMatch = loc.contains(a.name.toLowerCase());
    bool bMatch = loc.contains(b.name.toLowerCase());
    if (aMatch) foundExactMatch = true;
    if (bMatch) foundExactMatch = true;
    if (aMatch && !bMatch) return -1;
    if (!aMatch && bMatch) return 1;
    return 0;
  });

  // If no exact match, generate a dynamic one
  if (!foundExactMatch) {
    String cleanName = location.replaceAll(RegExp(r'selected location near\s*', caseSensitive: false), '').trim();
    if (cleanName.isEmpty) cleanName = 'this area';
    
    // Capitalize first letter
    cleanName = cleanName[0].toUpperCase() + cleanName.substring(1);

    Neighborhood dynamicNeighborhood = Neighborhood(
      name: cleanName,
      region: list.isNotEmpty ? list[0].region : 'Local',
      tagline: 'A highly convenient area based on your office location.',
      averageRent: list.isNotEmpty ? list[0].averageRent : 12000,
      commuteMinutes: 12,
      safetyScore: 8.2,
      vibe: 'Accessible & Convenient',
      matchScore: 85,
      brief: '$cleanName is perfectly positioned to offer a great balance of commute, budget, and lifestyle for your needs.',
      reasons: [
        'Close proximity to your daily commute',
        'Matches your budget requirements',
        'Good safety score and verified options',
      ],
    );
    list.insert(0, dynamicNeighborhood);
  }

  return list;
}
