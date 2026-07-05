import '../models/map_pin.dart';

List<MapPin> getMapPinsForArea(String area) {
  final query = area.toLowerCase();

  if (query.contains('koramangala')) {
    return const [
      MapPin(
        name: '7th Block Office',
        description: 'Near Forum Mall',
        x: 0.22,
        y: 0.28,
      ),
      MapPin(
        name: 'Hosur Road Office',
        description: 'Near Sujana Forum',
        x: 0.56,
        y: 0.45,
      ),
      MapPin(
        name: 'Sony World Office',
        description: 'Near 5th Block',
        x: 0.71,
        y: 0.18,
      ),
    ];
  }

  if (query.contains('indiranagar')) {
    return const [
      MapPin(
        name: '100 Feet Rd Office',
        description: 'Near St. John\'s Church',
        x: 0.25,
        y: 0.3,
      ),
      MapPin(
        name: 'Hosur Rd Gate Office',
        description: 'Near Mekhri Circle',
        x: 0.58,
        y: 0.62,
      ),
      MapPin(
        name: 'Indiranagar Tech Office',
        description: 'Near Domlur Flyover',
        x: 0.74,
        y: 0.32,
      ),
    ];
  }

  if (query.contains('whitefield')) {
    return const [
      MapPin(
        name: 'Whitefield Main Rd Office',
        description: 'Near VR Mall',
        x: 0.28,
        y: 0.2,
      ),
      MapPin(
        name: 'ITPL Office',
        description: 'Near ITPL Gate',
        x: 0.6,
        y: 0.55,
      ),
      MapPin(
        name: 'Phoenix Mall Office',
        description: 'Near Phoenix Marketcity',
        x: 0.78,
        y: 0.4,
      ),
    ];
  }

  if (query.contains('electronic city') || query.contains('ecity') || query.contains('electronic')) {
    return const [
      MapPin(
        name: 'Phase 1 Office',
        description: 'Near Infosys Gate',
        x: 0.18,
        y: 0.3,
      ),
      MapPin(
        name: 'Phase 2 Office',
        description: 'Near Wipro Circle',
        x: 0.55,
        y: 0.5,
      ),
      MapPin(
        name: 'Neeladri Office',
        description: 'Near Stellar IT Park',
        x: 0.75,
        y: 0.22,
      ),
    ];
  }

  return const [
    MapPin(
      name: 'City Centre Office',
      description: 'Central business district',
      x: 0.4,
      y: 0.35,
    ),
    MapPin(
      name: 'Transit Hub Office',
      description: 'Near main metro station',
      x: 0.65,
      y: 0.55,
    ),
    MapPin(
      name: 'Tech Park Office',
      description: 'Office campus edge',
      x: 0.8,
      y: 0.22,
    ),
  ];
}
