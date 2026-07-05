import 'package:google_place/google_place.dart';

class GooglePlacesService {
  final GooglePlace _googlePlace;

  GooglePlacesService(String apiKey) : _googlePlace = GooglePlace(apiKey);

  Future<List<AutocompletePrediction>> autocomplete(String input) async {
    final result = await _googlePlace.autocomplete.get(
      input,
      types: 'geocode',
      components: [Component('country', 'in')],
    );
    return result?.predictions ?? [];
  }

  Future<DetailsResult?> getPlaceDetails(String placeId) async {
    final response = await _googlePlace.details.get(placeId);
    return response?.result;
  }

  Future<List<SearchResult>> searchNearby(double lat, double lng,
      {int radius = 3000, String keyword = 'PG'}) async {
    final response = await _googlePlace.search.getNearBySearch(
      Location(lat: lat, lng: lng),
      radius,
      keyword: keyword,
      type: 'lodging',
    );
    return response?.results ?? [];
  }

  Future<List<SearchResult>> searchNearbyAmenities(double lat, double lng, {int radius = 1500}) async {
    // If API key is not configured, generate smart dynamic mocks to prevent an empty map
    if (_googlePlace.apiKEY == 'YOUR_GOOGLE_MAPS_API_KEY') {
      return [
        SearchResult(
          name: 'The Local Brew',
          types: ['cafe'],
          geometry: Geometry(location: Location(lat: lat + 0.0015, lng: lng + 0.002)),
        ),
        SearchResult(
          name: 'Urban Coffee Co.',
          types: ['cafe'],
          geometry: Geometry(location: Location(lat: lat - 0.002, lng: lng - 0.0015)),
        ),
        SearchResult(
          name: 'Sunset Roasters',
          types: ['cafe'],
          geometry: Geometry(location: Location(lat: lat + 0.003, lng: lng - 0.0025)),
        ),
      ];
    }

    final response = await _googlePlace.search.getNearBySearch(
      Location(lat: lat, lng: lng),
      radius,
      type: 'cafe',
    );
    return response?.results ?? [];
  }
}
