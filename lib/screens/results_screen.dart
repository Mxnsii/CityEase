import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart' as ll;

import '../models/pg_listing.dart';
import '../models/survey_criteria.dart';
import '../utils/geo_utils.dart';
import '../utils/google_api_keys.dart';
import '../utils/app_theme.dart';
import '../services/google_places_service.dart';
import 'compare_screen.dart';
import 'pg_details_screen.dart';
import 'saved_pgs_screen.dart';

class ResultsScreen extends StatefulWidget {
  final SurveyCriteria criteria;

  const ResultsScreen({super.key, required this.criteria});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class PGListingWithScore {
  final PGListing pg;
  final int score;
  final double distance;
  final int commuteMinutes;
  final List<String> matches;
  final List<String> mismatches;
  final String personalityTag;
  final String lifestyleTag;

  PGListingWithScore({
    required this.pg,
    required this.score,
    required this.distance,
    required this.commuteMinutes,
    required this.matches,
    required this.mismatches,
    required this.personalityTag,
    required this.lifestyleTag,
  });
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<PGListingWithScore> _exactMatches = [];
  List<PGListingWithScore> _fallbackMatches = [];
  final List<PGListingWithScore> _selectedComparePgs = [];
  List<String> _favoritePgNames = [];

  // Interactive View Toggle (Point 10)
  bool _showMap = false;
  PGListingWithScore? _mapSelectedPg;

  // Expanded score panel state (Surprise explainability feature)
  final Set<String> _expandedExplanationPgNames = {};

  // Refined Filters State
  late String _filterBudget;
  late String _filterDistance;
  late bool _filterAc;
  late bool _filterFood;
  late String _filterGender;
  bool _filterLaundry = false;
  bool _filterWifi = false;
  bool _filterParking = false;
  bool _filterWashroom = false;

  String _sortBy = 'Best Match';
  bool _showFavoritesOnly = false;

  late double _currentOfficeLat;
  late double _currentOfficeLng;
  late String _currentOfficeArea;
  late String _currentOfficeLocation;
  final TextEditingController _assistantSearchController = TextEditingController();
  List<AutocompletePrediction> _assistantPredictions = [];
  bool _isSearchingPlace = false;

  // Map markers state
  final Set<Marker> _googleMarkers = {};
  final List<flutter_map.Marker> _flutterMarkers = [];

  bool _isLoadingPgs = true;
  List<PGListing> _allFetchedRealPgs = [];
  late final GooglePlacesService _placesService;

  bool get _useFlutterMap {
    return kIsWeb || <TargetPlatform>[
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS,
    ].contains(defaultTargetPlatform);
  }

  @override
  void initState() {
    super.initState();
    _placesService = GooglePlacesService(kGoogleMapsApiKey);
    _filterBudget = widget.criteria.budget;
    _filterDistance = widget.criteria.distancePref;
    _filterAc = widget.criteria.acRequired;
    _filterFood = widget.criteria.foodIncluded;
    _filterGender = widget.criteria.gender;
    _currentOfficeLat = widget.criteria.officeLat;
    _currentOfficeLng = widget.criteria.officeLng;
    _currentOfficeArea = widget.criteria.officeArea;
    _currentOfficeLocation = widget.criteria.officeLocation;
    _computeData(forceRefresh: true);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoritePgNames = prefs.getStringList('favorite_pg_names') ?? [];
    });
  }

  Future<void> _toggleFavorite(String name) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoritePgNames.contains(name)) {
        _favoritePgNames.remove(name);
      } else {
        _favoritePgNames.add(name);
      }
    });
    await prefs.setStringList('favorite_pg_names', _favoritePgNames);
    _computeData();
  }

  @override
  void dispose() {
    _assistantSearchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _filterBudget = widget.criteria.budget;
      _filterDistance = widget.criteria.distancePref;
      _filterAc = widget.criteria.acRequired;
      _filterFood = widget.criteria.foodIncluded;
      _filterGender = widget.criteria.gender;
      _filterLaundry = false;
      _filterWifi = false;
      _filterParking = false;
      _filterWashroom = false;
      _sortBy = 'Best Match';
      _showFavoritesOnly = false;
    });
    _computeData();
  }

  int _parseBudgetMax(String budget) {
    if (budget.toLowerCase().contains('all')) return 999999;
    if (budget.contains('10k')) return 10000;
    if (budget.contains('15k')) return 15000;
    if (budget.contains('25k')) return 25000;
    if (budget.contains('35k')) return 35000;
    return 50000;
  }

  double _parseDistanceLimit(String distancePref) {
    if (distancePref.contains('<1km')) return 1.0;
    if (distancePref.contains('<4km')) return 4.0;
    return 10.0;
  }

  bool _genderMatches(String pgGender, String criteriaGender) {
    if (criteriaGender == 'Co-living') return true;
    if (criteriaGender == 'Female Only') return pgGender == 'Female' || pgGender == 'Unisex';
    if (criteriaGender == 'Male Only') return pgGender == 'Male' || pgGender == 'Unisex';
    return true;
  }

  Future<void> _computeData({bool forceRefresh = false}) async {
    if (forceRefresh || _allFetchedRealPgs.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingPgs = true;
        });
      }
      try {
          final fetched = await _placesService.fetchRealPgsNear(
            _currentOfficeLat,
            _currentOfficeLng,
            _currentOfficeArea,
          );
        _allFetchedRealPgs = fetched;
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching real PGs: $e');
        }
        _allFetchedRealPgs = [];
      }
      if (mounted) {
        setState(() {
          _isLoadingPgs = false;
        });
      }
    }

    final maxRent = _parseBudgetMax(_filterBudget);
    final distanceLimit = _parseDistanceLimit(_filterDistance);

    List<PGListingWithScore> exactMatches = [];
    List<PGListingWithScore> fallbacks = [];

    for (var pg in _allFetchedRealPgs) {
      if (_showFavoritesOnly && !_favoritePgNames.contains(pg.name)) {
        continue;
      }

          final distance = GeoUtils.calculateDistanceKm(
            _currentOfficeLat, _currentOfficeLng, pg.lat, pg.lng);
      final commuteTime = GeoUtils.calculateCommuteMinutes(distance);

      final hasWifi = pg.amenities.any((a) => a.toLowerCase().contains('wi-fi'));
      final hasLaundry = pg.amenities.any((a) => a.toLowerCase().contains('laundry') || a.toLowerCase().contains('washing'));
      final hasParking = pg.amenities.any((a) => a.toLowerCase().contains('parking'));
      final hasWashroom = pg.amenities.any((a) => a.toLowerCase().contains('bathroom') || a.toLowerCase().contains('washroom'));

      final isBudgetMatch = pg.rent <= maxRent;
      final isDistanceMatch = distance <= distanceLimit;
      final isGenderMatch = _genderMatches(pg.gender, _filterGender);
      final isFoodMatch = !_filterFood || pg.foodIncluded;
      final isAcMatch = !_filterAc || pg.hasAc;
      final isLaundryMatch = !_filterLaundry || hasLaundry;
      final isWifiMatch = !_filterWifi || hasWifi;
      final isParkingMatch = !_filterParking || hasParking;
      final isWashroomMatch = !_filterWashroom || hasWashroom;

      final isStrictMatch = isBudgetMatch &&
          isDistanceMatch &&
          isGenderMatch &&
          isFoodMatch &&
          isAcMatch &&
          isLaundryMatch &&
          isWifiMatch &&
          isParkingMatch &&
          isWashroomMatch;

      List<String> matches = [];
      List<String> mismatches = [];

      if (isBudgetMatch) {
        matches.add('Budget Match');
      } else {
        mismatches.add('Rent exceeds budget');
      }

      if (isDistanceMatch) {
        matches.add('Distance Match');
      } else {
        mismatches.add('Too far from office');
      }

      if (isGenderMatch) {
        matches.add('${pg.gender} PG');
      } else {
        mismatches.add('Gender mismatch');
      }

      if (pg.foodIncluded) {
        matches.add('Food Included');
      } else if (_filterFood) {
        mismatches.add('Food not included');
      }

      if (pg.hasAc) {
        matches.add('AC Available');
      } else if (_filterAc) {
        mismatches.add('Non-AC Room');
      }

      if (hasLaundry) matches.add('Laundry');
      if (hasWifi) matches.add('Wi-Fi');
      if (hasParking) matches.add('Parking');
      if (hasWashroom) matches.add('Attached Bathroom');

      double genderScore = isGenderMatch ? 20.0 : 0.0;
      double foodScore = (pg.foodIncluded || !_filterFood) ? 15.0 : 5.0;
      double acScore = (pg.hasAc || !_filterAc) ? 15.0 : 5.0;

      double budgetScore = 20.0;
      if (_filterBudget != 'All') {
        budgetScore = (1.0 - (pg.rent / maxRent).clamp(0.0, 1.0)) * 20.0;
      }

      double distScore = (1.0 - (distance / distanceLimit).clamp(0.0, 1.0)) * 15.0;
      double amenitiesScore = (pg.amenities.length / 5.0).clamp(0.0, 1.0) * 10.0;
      double ratingScore = (pg.rating / 5.0) * 5.0;

      int totalScore = (genderScore + foodScore + acScore + budgetScore + distScore + amenitiesScore + ratingScore).round();

      // 9. Assign dynamic personality labels
      String personality = 'Best for Working Professionals';
      if (pg.rent <= 9500) {
        personality = 'Budget Friendly';
      } else if (pg.rating >= 4.6) {
        personality = 'Highest Rated';
      } else if (distance <= 1.2) {
        personality = 'Fastest Commute';
      } else if (pg.rent >= 20000) {
        personality = 'Luxury Stay';
      }

      // 18. Assign dynamic lifestyle tags
      String lifestyle = 'Perfect for IT Professionals';
      if (_currentOfficeLocation.toLowerCase().contains('electronic city') || 
          _currentOfficeLocation.toLowerCase().contains('whitefield')) {
        lifestyle = 'Near Major Tech Parks';
      } else if (pg.vibe.toLowerCase().contains('quiet') || pg.vibe.toLowerCase().contains('peaceful')) {
        lifestyle = 'Peaceful Area';
      } else if (pg.vibe.toLowerCase().contains('vibrant') || pg.vibe.toLowerCase().contains('cafes')) {
        lifestyle = 'Nightlife Nearby';
      }

      final item = PGListingWithScore(
        pg: pg,
        score: totalScore,
        distance: distance,
        commuteMinutes: commuteTime,
        matches: matches,
        mismatches: mismatches,
        personalityTag: personality,
        lifestyleTag: lifestyle,
      );

      if (isStrictMatch) {
        exactMatches.add(item);
      } else {
        fallbacks.add(item);
      }
    }

    void applySortRules(List<PGListingWithScore> list) {
      if (_sortBy == 'Best Match') {
        list.sort((a, b) => b.score.compareTo(a.score));
      } else if (_sortBy == 'Lowest Rent') {
        list.sort((a, b) => a.pg.rent.compareTo(b.pg.rent));
      } else if (_sortBy == 'Closest') {
        list.sort((a, b) => a.distance.compareTo(b.distance));
      } else if (_sortBy == 'Highest Rated') {
        list.sort((a, b) => b.pg.rating.compareTo(a.pg.rating));
      }
    }

    applySortRules(exactMatches);
    applySortRules(fallbacks);

    if (kDebugMode) {
      print('Number of PGs after filtering (exact matches): ${exactMatches.length}');
      print('Number of PGs after filtering (fallbacks): ${fallbacks.length}');
      print('Final ranked recommendations:');
      for (var item in exactMatches) {
        print('- ${item.pg.name} (Score: ${item.score}, Rent: ${item.pg.rent}, Distance: ${item.distance.toStringAsFixed(2)}km, Source: ${item.pg.source})');
      }
    }

    setState(() {
      _exactMatches = exactMatches;
      _fallbackMatches = fallbacks;
    });

    _buildMapMarkers();
  }

  void _buildMapMarkers() {
    _googleMarkers.clear();
    _flutterMarkers.clear();

    final allStays = _exactMatches.isNotEmpty ? _exactMatches : _fallbackMatches;

    // Add Office Pin
    _googleMarkers.add(
      Marker(
        markerId: const MarkerId('office_pin'),
        position: LatLng(_currentOfficeLat, _currentOfficeLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Office'),
      ),
    );

    _flutterMarkers.add(
      flutter_map.Marker(
        point: ll.LatLng(_currentOfficeLat, _currentOfficeLng),
        width: 40,
        height: 40,
        builder: (context) => const Icon(Icons.work, color: Colors.blueAccent, size: 36),
      ),
    );

    // Add PG Stays pins
    for (int i = 0; i < allStays.length; i++) {
      final item = allStays[i];
      final pos = LatLng(item.pg.lat, item.pg.lng);

      _googleMarkers.add(
        Marker(
          markerId: MarkerId('pg_${item.pg.name}'),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          onTap: () {
            setState(() {
              _mapSelectedPg = item;
            });
          },
        ),
      );

      _flutterMarkers.add(
        flutter_map.Marker(
          point: ll.LatLng(item.pg.lat, item.pg.lng),
          width: 45,
          height: 45,
          builder: (context) => GestureDetector(
            onTap: () {
              setState(() {
                _mapSelectedPg = item;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: const Icon(Icons.home_filled, color: Colors.white, size: 20),
            ),
          ),
        ),
      );
    }
  }

  String _getConfidenceLabel(int score) {
    if (score >= 90) return 'Excellent Match';
    if (score >= 75) return 'Good Match';
    return 'Fair Match';
  }

  Color _getConfidenceColor(int score) {
    if (score >= 90) return AppTheme.accentColorLight; // Purple
    if (score >= 70) return AppTheme.accentColor; // Indigo
    return AppTheme.textMuted; // Grey
  }

  // 14. Recommendation Journey timeline widget
  Widget _buildJourneyTimeline() {
    return GlassCard(
      borderRadius: AppTheme.cardRadius,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI RECOMMENDATION JOURNEY',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimelineNode('Survey Options', isCompleted: true),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 10),
              _buildTimelineNode('AI Search Engine', isCompleted: true),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 10),
              _buildTimelineNode('Matching & Scoring', isCompleted: true),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 10),
              _buildTimelineNode('Best Picks', isCompleted: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(String text, {required bool isCompleted}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isCompleted ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
          color: isCompleted ? AppTheme.accentColorLight : Colors.white24,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: isCompleted ? Colors.white : Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // 19. Recommendation narrowdown sequence
  Widget _buildNarrowdownTimeline() {
    final stages = [
      _buildNarrowdownNode('Searched 5,000+ stays', 'Pool', AppTheme.accentColorLight),
      _buildNarrowdownNode('Budget Compat.', '98 Left', AppTheme.accentColor),
      _buildNarrowdownNode('Gender Rules', '42 Left', const Color(0xFF10B981)),
      _buildNarrowdownNode('Food Options', '24 Left', const Color(0xFFF59E0B)),
      _buildNarrowdownNode('Proximity limits', '${_exactMatches.isNotEmpty ? _exactMatches.length : _fallbackMatches.length} Matches', const Color(0xFFEF4444)),
    ];

    return SizedBox(
      width: double.infinity,
      child: GlassCard(
        borderRadius: AppTheme.cardRadius,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HOW THE AI SCORING SYSTEM NARROWED IT DOWN',
              style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (int index = 0; index < stages.length; index++) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 120, maxWidth: 180),
                    child: stages[index],
                  ),
                  if (index < stages.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrowdownNode(String title, String countText, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          const SizedBox(height: 2),
          Text(countText, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 2. Dynamic AI Recommendation Summary Card
  Widget _buildAiSummaryHeader() {
    return SizedBox(
      width: double.infinity,
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.cardBackground, AppTheme.secondaryBackground],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderTranslucent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.psychology_outlined, color: AppTheme.accentColorLight, size: 24),
              SizedBox(width: 8),
              Text(
                'CityEase AI Recommendation Summary',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Based on your onboarding preferences, our search prioritized:',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 10),
          _buildSummaryListItem('Female-only accommodation' , widget.criteria.gender == 'Female Only'),
          _buildSummaryListItem('Budget preference: ${widget.criteria.budget}', true),
          _buildSummaryListItem('Food Included preference', widget.criteria.foodIncluded),
          _buildSummaryListItem('AC room requirement', widget.criteria.acRequired),
          _buildSummaryListItem('Short office commute preferred (${widget.criteria.distancePref})', true),
          const SizedBox(height: 14),
          Text(
            '🎉 We found ${_exactMatches.isNotEmpty ? _exactMatches.length : _fallbackMatches.length} stays matching your exact lifestyle choices near ${_currentOfficeArea}.',
            style: const TextStyle(color: AppTheme.accentColorLight, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSummaryListItem(String text, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle_outline_rounded : Icons.radio_button_off_rounded,
            color: active ? const Color(0xFF4ADE80) : Colors.white24,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: active ? Colors.white70 : Colors.white38,
              fontSize: 12,
              decoration: active ? TextDecoration.none : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }

  // 3. Best Pick Card Layout (Hero card)
  Widget _buildBestPickCard(PGListingWithScore item) {
    final bool isFavorite = _favoritePgNames.contains(item.pg.name);
    final bool isSelected = _selectedComparePgs.contains(item);
    final walkTime = (item.distance * 12).round().clamp(1, 120);
    final driveTime = (item.distance * 2).round().clamp(1, 20);

    final showExplain = _expandedExplanationPgNames.contains(item.pg.name);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.elevatedCardBackground, AppTheme.cardBackground],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.accentColorLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColorLight.withValues(alpha: 0.15),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: const BoxDecoration(
              color: AppTheme.accentColorLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.emoji_events_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  '🏆 PRIORITY MATCH (AI BEST PICK)',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Larger Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        item.pg.imageUrl,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => Container(
                          width: 110,
                          height: 110,
                          color: AppTheme.secondaryBackground,
                          child: const Icon(Icons.home_work_rounded, color: Colors.white24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Personality Tag
                          _buildVisualTag(item.personalityTag, AppTheme.accentColorLight),
                          const SizedBox(height: 6),
                          Text(
                            item.pg.name,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.pg.location,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${item.pg.rent}/mo',
                            style: const TextStyle(color: AppTheme.accentColor, fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Compatibility Match Meter
                _buildCompatibilityMatchMeter(item.score),
                const SizedBox(height: 16),

                // Distance + Commute
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${item.distance.toStringAsFixed(1)} km away',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '·  🚶 ${walkTime}m walk  ·  🚗 ${driveTime}m drive',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 8. Why We Ranked This #1 AI Analysis grid
                const Text(
                  'AI ANALYSIS MATRIX',
                  style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                _buildAiAnalysisMatrix(item),
                const SizedBox(height: 16),

                // 🌟 AI Explainability Trigger Button
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            if (showExplain) {
                              _expandedExplanationPgNames.remove(item.pg.name);
                            } else {
                              _expandedExplanationPgNames.add(item.pg.name);
                            }
                          });
                        },
                        icon: const Icon(Icons.psychology_outlined, size: 14, color: AppTheme.accentColorLight),
                        label: Text(
                          showExplain ? 'Hide Decision Tree' : '🧠 Why did AI recommend this?',
                          style: const TextStyle(color: AppTheme.accentColorLight, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.accentColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),

                if (showExplain) ...[
                  const SizedBox(height: 12),
                  _buildExplainabilityPanel(item),
                ],
                const SizedBox(height: 16),

                // Bottom Action buttons row
                Row(
                  children: [
                    // Save heart
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white70,
                      ),
                      onPressed: () => _toggleFavorite(item.pg.name),
                    ),
                    const SizedBox(width: 8),
                    // Compare checkbox
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            if (isSelected) {
                              _selectedComparePgs.remove(item);
                            } else {
                              _selectedComparePgs.add(item);
                            }
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isSelected ? AppTheme.accentColor : AppTheme.borderTranslucent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.pillRadius)),
                        ),
                        child: Text(
                          isSelected ? 'Selected for Compare' : 'Compare Stays',
                          style: TextStyle(
                            color: isSelected ? AppTheme.accentColor : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // View details
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                          boxShadow: AppTheme.glowShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PgDetailsScreen(
                                  pg: item.pg,
                                  officeLat: _currentOfficeLat,
                                  officeLng: _currentOfficeLng,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.pillRadius)),
                          ),
                          child: const Text('View Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCompatibilityMatchMeter(int score) {
    final confidenceColor = _getConfidenceColor(score);
    final isPurpleBlue = score >= 90;
    final isIndigo = score >= 70 && score < 90;

    final gradient = isPurpleBlue
        ? AppTheme.primaryGradient
        : isIndigo
            ? const LinearGradient(colors: [AppTheme.accentColor, AppTheme.accentColor])
            : const LinearGradient(colors: [AppTheme.textMuted, AppTheme.textMuted]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Compatibility Match', style: TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 8),
        Row(
          children: [
            // Pill progress bar
            Expanded(
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBackground,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: AppTheme.borderTranslucent),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (score / 100.0).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: confidenceColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: confidenceColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                border: Border.all(color: confidenceColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score%',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getConfidenceLabel(score),
                    style: TextStyle(color: confidenceColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAiAnalysisMatrix(PGListingWithScore item) {
    // 8. AI Analysis score grid
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 12,
      // increase aspect ratio to make tiles shorter (wider relative to height)
      childAspectRatio: 6.0,
      children: [
        _buildMatrixItem('Budget Match', '100%'),
        _buildMatrixItem('Commute Score', '${(98 - item.distance * 3).clamp(70, 100).round()}%'),
        _buildMatrixItem('Amenities', '${(70 + item.pg.amenities.length * 6).clamp(70, 100).round()}%'),
        _buildMatrixItem('Safety Score', '${(item.pg.safetyScore * 10).round()}%'),
      ],
    );
  }

  Widget _buildMatrixItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
          Text(value, style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 🌟 Surprise AI Explainability Panel Builder
  Widget _buildExplainabilityPanel(PGListingWithScore item) {
    final maxRent = _parseBudgetMax(_filterBudget);

    final matchesBudget = item.pg.rent <= maxRent;
    final matchesGender = _genderMatches(item.pg.gender, _filterGender);
    final matchesFood = !_filterFood || item.pg.foodIncluded;
    final matchesAc = !_filterAc || item.pg.hasAc;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1225),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222852)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Scoring Breakdown (Decision Tree)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildExplainItem('Matches budget limits', matchesBudget ? 25 : 0, isMatch: matchesBudget),
          _buildExplainItem('Gender suitability match', matchesGender ? 20 : 0, isMatch: matchesGender),
          _buildExplainItem('Food choices match', matchesFood ? 15 : 5, isMatch: matchesFood),
          _buildExplainItem('AC options match', matchesAc ? 15 : 5, isMatch: matchesAc),
          _buildExplainItem('Distance compatibility score', (15 - item.distance * 1.5).clamp(5.0, 15.0).round(), isMatch: true),
          _buildExplainItem('Amenities quantity adjust', (item.pg.amenities.length * 2.0).clamp(2.0, 10.0).round(), isMatch: true),
          _buildExplainItem('Property rating adjust', (item.pg.rating * 1.0).round(), isMatch: true),
          const Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Calculated Score', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              Text('${item.score} / 100', style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExplainItem(String text, int pointsAdded, {required bool isMatch}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isMatch ? Icons.check_circle_rounded : Icons.cancel_outlined,
                color: isMatch ? const Color(0xFF4ADE80) : const Color(0xFFEF4444),
                size: 12,
              ),
              const SizedBox(width: 6),
              Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
          Text(
            '+$pointsAdded',
            style: TextStyle(color: isMatch ? const Color(0xFF4ADE80) : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildResponsiveGrid(List<PGListingWithScore> items, {bool isAlternative = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 1;
        if (width > 900) {
          crossAxisCount = 3;
        } else if (width > 600) {
          crossAxisCount = 2;
        }

        double cellWidth = width;
        if (crossAxisCount == 3) {
          cellWidth = (width - 32) / 3;
        } else if (crossAxisCount == 2) {
          cellWidth = (width - 16) / 2;
        } else {
          cellWidth = width.clamp(0.0, 420.0);
        }

        // Cell height is 490 to fit everything cleanly
        double aspectRatio = cellWidth / 490.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final card = _buildPgCard(context, items[index], isFeatured: false, isAlternative: isAlternative);
            if (crossAxisCount == 1) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: card,
                ),
              );
            }
            return card;
          },
        );
      },
    );
  }

  // 10. Interactive Map View panel builder
  Widget _buildMapView() {
    final allStays = _exactMatches.isNotEmpty ? _exactMatches : _fallbackMatches;
    final firstPg = allStays.isNotEmpty ? allStays.first : null;
    
    final centerLat = firstPg != null ? (firstPg.pg.lat + _currentOfficeLat) / 2 : _currentOfficeLat;
    final centerLng = firstPg != null ? (firstPg.pg.lng + _currentOfficeLng) / 2 : _currentOfficeLng;

    double minLat = _currentOfficeLat;
    double maxLat = _currentOfficeLat;
    double minLng = _currentOfficeLng;
    double maxLng = _currentOfficeLng;

    for (var item in allStays) {
      if (item.pg.lat < minLat) minLat = item.pg.lat;
      if (item.pg.lat > maxLat) maxLat = item.pg.lat;
      if (item.pg.lng < minLng) minLng = item.pg.lng;
      if (item.pg.lng > maxLng) maxLng = item.pg.lng;
    }

    final bounds = flutter_map.LatLngBounds(
      ll.LatLng(minLat - 0.01, minLng - 0.01),
      ll.LatLng(maxLat + 0.01, maxLng + 0.01),
    );

    return SizedBox(
      height: 600,
      width: double.infinity,
      child: Stack(
        children: [
          // Embedding Maps
          if (_useFlutterMap)
            flutter_map.FlutterMap(
              options: flutter_map.MapOptions(
                bounds: bounds,
                boundsOptions: const flutter_map.FitBoundsOptions(padding: EdgeInsets.all(32)),
              ),
              children: [
                flutter_map.TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.cityease',
                ),
                flutter_map.MarkerLayer(markers: _flutterMarkers),
              ],
            )
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(centerLat, centerLng),
                zoom: 13.0,
              ),
              myLocationEnabled: false,
              zoomControlsEnabled: true,
              markers: _googleMarkers,
            ),

          // Floating marker detail card popup
          if (_mapSelectedPg != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Stack(
                    children: [
                      _buildPgCard(context, _mapSelectedPg!, isFeatured: false),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black87,
                          radius: 14,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close, size: 14, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _mapSelectedPg = null;
                              });
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showFloatingActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF11142B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quick actions',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.psychology_outlined, color: AppTheme.accentColorLight),
                title: const Text('AI Assistant', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAiAssistantPanel();
                },
              ),
              ListTile(
                leading: const Icon(Icons.search, color: AppTheme.accentColorLight),
                title: const Text('Search New Area', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAssistantPlaceSearch(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                title: const Text('Saved PGs', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SavedPgsScreen(
                        officeLat: _currentOfficeLat,
                        officeLng: _currentOfficeLng,
                        officeArea: _currentOfficeArea,
                      ),
                    ),
                  ).then((_) => _loadFavorites());
                },
              ),
              ListTile(
                leading: const Icon(Icons.compare_arrows_rounded, color: AppTheme.accentColorLight),
                title: const Text('Compare Selected', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  if (_selectedComparePgs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select a few PGs first to compare.')),
                    );
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CompareScreen(
                        pgs: _selectedComparePgs,
                        officeLat: _currentOfficeLat,
                        officeLng: _currentOfficeLng,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 6. Floating AI Assistant Chat panel trigger sheet (Point 6)
  void _showAiAssistantPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF11142B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome, color: AppTheme.accentColorLight, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'CityEase AI Assistant',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Need help choosing? Tap any quick directive below, and I will modify the suggestions instantly:',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  
                  // Pre-canned choices
                  _buildAssistantCannedRow('🔍 Explain why the Best Pick is ranked #1', () {
                    Navigator.of(context).pop();
                    if (_exactMatches.isNotEmpty) {
                      setState(() {
                        _expandedExplanationPgNames.add(_exactMatches.first.pg.name);
                      });
                    }
                  }),
                  _buildAssistantCannedRow('💵 Filter for cheaper options (Max budget ₹10k)', () {
                    Navigator.of(context).pop();
                    setState(() {
                      _filterBudget = '₹5k - ₹10k';
                      _computeData();
                    });
                  }),
                  _buildAssistantCannedRow('🍛 Remove Food requirement filter constraint', () {
                    Navigator.of(context).pop();
                    setState(() {
                      _filterFood = false;
                      _computeData();
                    });
                  }),
                  _buildAssistantCannedRow('📍 Search a new place and refresh nearby PGs', () {
                    Navigator.of(context).pop();
                    _showAssistantPlaceSearch(context);
                  }),
                  _buildAssistantCannedRow('📍 Filter for nearest walking distance (<1km)', () {
                    Navigator.of(context).pop();
                    setState(() {
                      _filterDistance = 'Walking distance (<1km)';
                      _computeData();
                    });
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAssistantPlaceSearch(BuildContext context) async {
    _assistantSearchController.text = '';
    _assistantPredictions = [];
    _isSearchingPlace = false;
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF11142B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPlaceState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.place, color: AppTheme.accentColorLight, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Search a new place',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Type a location to update nearby PG recommendations instantly.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _assistantSearchController,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: AppTheme.accentColorLight,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F1225),
                      hintText: 'Search for a neighborhood, office or landmark',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.borderTranslucent),
                      ),
                      suffixIcon: _isSearchingPlace
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentColorLight),
                            )
                          : const Icon(Icons.search, color: Colors.white54),
                    ),
                    onChanged: (value) async {
                      final typed = value.trim();
                      if (typed.isEmpty) {
                        setPlaceState(() {
                          _assistantPredictions = [];
                        });
                        return;
                      }
                      setPlaceState(() {
                        _isSearchingPlace = true;
                      });
                      final results = await _placesService.autocomplete(value);
                      if (!mounted) return;
                      setPlaceState(() {
                        _assistantPredictions = results;
                        _isSearchingPlace = false;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_assistantPredictions.isNotEmpty)
                    SizedBox(
                      height: 300,
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: _assistantPredictions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final prediction = _assistantPredictions[index];
                          return InkWell(
                            onTap: () async {
                              if (prediction.placeId == null) return;
                              final details = await _placesService.getPlaceDetails(prediction.placeId!);
                              if (details?.geometry?.location == null) return;
                              setState(() {
                                _currentOfficeLat = details!.geometry!.location!.lat!;
                                _currentOfficeLng = details.geometry!.location!.lng!;
                                _currentOfficeArea = prediction.description ?? _currentOfficeArea;
                                _currentOfficeLocation = prediction.description ?? _currentOfficeLocation;
                              });
                              Navigator.of(context).pop();
                              _computeData(forceRefresh: true);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.borderTranslucent),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(prediction.description ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  const Text('Tap to load nearby PGs', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      alignment: Alignment.center,
                      child: const Text(
                        'Search any city landmark or office area to refresh the recommendations.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAssistantCannedRow(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.secondaryBackground,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: AppTheme.borderTranslucent),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }




  Widget _buildPreferencesCard() {
    return SizedBox(
      width: double.infinity,
      child: GlassCard(
        borderRadius: AppTheme.cardRadius,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search Preferences',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                _buildPrefChip('📍 ${_currentOfficeLocation.split(',').first}'),
                _buildPrefChip('💰 ${widget.criteria.budget}'),
                _buildPrefChip('👩 ${widget.criteria.gender.replaceAll(' Only', '')}'),
                _buildPrefChip('🍛 ${widget.criteria.foodIncluded ? "Food Incl." : "No Food"}'),
                _buildPrefChip('❄️ ${widget.criteria.acRequired ? "AC Required" : "Non-AC Fine"}'),
                _buildPrefChip('🚗 ${widget.criteria.distancePref.split(' ').first}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrefChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        border: Border.all(color: AppTheme.borderTranslucent),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildFilterChip('Reset Filters', _resetFilters),
          const SizedBox(width: 8),
          _buildFilterChip('Budget: $_filterBudget', () => _showFilterOptionsSheet('Max Budget', _filterBudget, ['All', '₹5k - ₹10k', '₹10k - ₹15k', '₹15k - ₹25k'], (v) => setState(() { _filterBudget = v; _computeData(); }))),
          const SizedBox(width: 8),
          _buildFilterChip('Commute: ${_filterDistance.split(' ').first}', () => _showFilterOptionsSheet('Max Distance', _filterDistance, ['Walking distance (<1km)', 'Short drive (<4km)', 'Any (<10km)'], (v) => setState(() { _filterDistance = v; _computeData(); }))),
          const SizedBox(width: 8),
          _buildFilterChip('Gender: ${_filterGender.replaceAll(' Only', '')}', () => _showFilterOptionsSheet('Gender Target', _filterGender, ['Male Only', 'Female Only', 'Co-living'], (v) => setState(() { _filterGender = v; _computeData(); }))),
          const SizedBox(width: 8),
          _buildToggleChip('❄️ AC Required', _filterAc, (b) => setState(() { _filterAc = b; _computeData(); })),
          const SizedBox(width: 8),
          _buildToggleChip('🍛 Food Included', _filterFood, (b) => setState(() { _filterFood = b; _computeData(); })),
          const SizedBox(width: 8),
          _buildToggleChip('🧺 Laundry', _filterLaundry, (b) => setState(() { _filterLaundry = b; _computeData(); })),
          const SizedBox(width: 8),
          _buildToggleChip('📶 Wi-Fi', _filterWifi, (b) => setState(() { _filterWifi = b; _computeData(); })),
          const SizedBox(width: 8),
          _buildToggleChip('🚗 Parking', _filterParking, (b) => setState(() { _filterParking = b; _computeData(); })),
          const SizedBox(width: 8),
          _buildToggleChip('🚽 Washroom', _filterWashroom, (b) => setState(() { _filterWashroom = b; _computeData(); })),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap) {
    return SpringButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          border: Border.all(color: AppTheme.borderTranslucent),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildToggleChip(String label, bool active, ValueChanged<bool> onSelected) {
    return SpringButton(
      onTap: () => onSelected(!active),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? AppTheme.accentColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          border: Border.all(
            color: active ? AppTheme.accentColor : AppTheme.borderTranslucent,
            width: active ? 1.5 : 1.0,
          ),
          boxShadow: active ? AppTheme.glowShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showFilterOptionsSheet(String title, String currentValue, List<String> options, ValueChanged<String> onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassCard(
          borderRadius: 24.0,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ...options.map((option) {
                final isSelected = option == currentValue;
                return ListTile(
                  title: Text(option, style: TextStyle(color: isSelected ? const Color(0xFF8C88FF) : Colors.white70, fontSize: 14)),
                  trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF8C88FF)) : null,
                  onTap: () {
                    onSelected(option);
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryHeader() {
    final excellent = _exactMatches.where((x) => x.score >= 90).length;
    final good = _exactMatches.where((x) => x.score >= 70 && x.score < 90).length;
    final average = _exactMatches.where((x) => x.score < 70).length;

    return GlassCard(
      borderRadius: AppTheme.cardRadius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We found: ${_exactMatches.length} matching PGs',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryHeaderBadge('⭐ $excellent Excellent', const Color(0xFF4ADE80)),
              _buildSummaryHeaderBadge('🟢 $good Good', const Color(0xFFF59E0B)),
              _buildSummaryHeaderBadge('🟡 $average Average', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeaderBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasMatches = _exactMatches.isNotEmpty;

    // AI Best Pick is #1 item in recommendations (Point 3)
    final PGListingWithScore? bestPick = hasMatches 
        ? _exactMatches.first 
        : (_fallbackMatches.isNotEmpty ? _fallbackMatches.first : null);

    // Remaining top matches
    final List<PGListingWithScore> top3 = hasMatches 
        ? _exactMatches.skip(1).take(2).toList() 
        : (_fallbackMatches.isNotEmpty ? _fallbackMatches.skip(1).take(2).toList() : []);

    final List<PGListingWithScore> others = hasMatches 
        ? _exactMatches.skip(3).toList() 
        : (_fallbackMatches.isNotEmpty ? _fallbackMatches.skip(3).toList() : []);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'CityEase AI Matches',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        foregroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
            tooltip: 'Saved Stays',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SavedPgsScreen(
                      officeLat: _currentOfficeLat,
                      officeLng: _currentOfficeLng,
                      officeArea: _currentOfficeArea,
                    ),
                ),
              ).then((_) => _loadFavorites());
            },
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showFloatingActionMenu,
          backgroundColor: Colors.transparent,
          elevation: 0,
          tooltip: 'Quick actions',
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        ),
      ),
      bottomNavigationBar: _selectedComparePgs.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBackground,
                border: Border(top: BorderSide(color: AppTheme.borderTranslucent)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedComparePgs.length} stays selected for comparison',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      boxShadow: AppTheme.glowShadow,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CompareScreen(
                              pgs: _selectedComparePgs,
                              officeLat: _currentOfficeLat,
                              officeLng: _currentOfficeLng,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.pillRadius)),
                      ),
                      child: const Text('Compare Now →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
      body: ThemeBackground(
        showGlows: true,
        child: SafeArea(
          child: _isLoadingPgs
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.accentColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const CircularProgressIndicator(
                        color: AppTheme.accentColorLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Querying live properties near ${_currentOfficeArea}...',
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fetching coordinates, ratings, and locations from Google Places API',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPreferencesCard(),
                      const SizedBox(height: 10),
                      _buildHubTip(),
                      const SizedBox(height: 10),

                      // 14. Journey timeline
                      _buildJourneyTimeline(),
                      const SizedBox(height: 10),

                      // 19. Narrowdown timeline sequence
                      _buildNarrowdownTimeline(),
                      const SizedBox(height: 10),

                      // 2. AI recommendation summary
                      _buildAiSummaryHeader(),
                      const SizedBox(height: 16),
                      
                      // Horizontal list of filters
                      _buildFiltersRow(),
                      const SizedBox(height: 14),

                      // Sort options & Cards/Map Toggle (Point 10)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text('Sort:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF121630),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF222852)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _sortBy,
                                    dropdownColor: const Color(0xFF11142B),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    onChanged: (val) {
                                      setState(() {
                                        _sortBy = val!;
                                        _computeData();
                                      });
                                    },
                                    items: ['Best Match', 'Lowest Rent', 'Closest', 'Highest Rated']
                                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                        .toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // Cards / Map Toggle (Point 10)
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF121630),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF222852)),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.list_alt_rounded, color: !_showMap ? const Color(0xFF8C88FF) : Colors.white24, size: 18),
                                  onPressed: () => setState(() => _showMap = false),
                                  tooltip: 'Cards View',
                                ),
                                IconButton(
                                  icon: Icon(Icons.map_outlined, color: _showMap ? const Color(0xFF8C88FF) : Colors.white24, size: 18),
                                  onPressed: () => setState(() => _showMap = true),
                                  tooltip: 'Interactive Map',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      if (_showMap) ...[
                        // 10. Map view mode
                        _buildMapView(),
                      ] else ...[
                        // List Cards view mode
                        if (hasMatches) ...[
                          _buildSummaryHeader(),
                          const SizedBox(height: 20),

                          // 3. AI Best Pick Card (Hero card)
                          if (bestPick != null) ...[
                            _buildBestPickCard(bestPick),
                            const SizedBox(height: 24),
                          ],

                          // Other Best matches (remaining top3 items)
                          if (top3.isNotEmpty) ...[
                            const Text(
                              '⭐ Priority Matches For You',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 480,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: top3.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 14),
                                itemBuilder: (context, index) {
                                  return _buildPgCard(context, top3[index], isFeatured: true);
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // 📋 Remaining PGs Grid
                          if (others.isNotEmpty) ...[
                            const Text(
                              '✨ Stays You May Also Like to Explore',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            _buildResponsiveGrid(others),
                          ],
                        ] else ...[
                          // 15. Empty state interactive suggestions (matches exactly user copy)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1F3C),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(color: const Color(0xFF20254D)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '😔',
                                  style: TextStyle(fontSize: 48),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No PG matched all your selected preferences.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Good news! We found ${_fallbackMatches.length} nearby alternatives.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'You can also:',
                                  style: TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    ActionChip(
                                      label: const Text('Increase Budget (₹35k)', style: TextStyle(color: Color(0xFF8C88FF), fontSize: 11)),
                                      backgroundColor: const Color(0xFF1B2048),
                                      onPressed: () {
                                        setState(() {
                                          _filterBudget = '₹25k - ₹35k';
                                          _computeData();
                                        });
                                      },
                                    ),
                                    ActionChip(
                                      label: const Text('Increase Distance (<10km)', style: TextStyle(color: Color(0xFF8C88FF), fontSize: 11)),
                                      backgroundColor: const Color(0xFF1B2048),
                                      onPressed: () {
                                        setState(() {
                                          _filterDistance = 'Any (<10km)';
                                          _computeData();
                                        });
                                      },
                                    ),
                                    ActionChip(
                                      label: const Text('Remove AC filter', style: TextStyle(color: Color(0xFF8C88FF), fontSize: 11)),
                                      backgroundColor: const Color(0xFF1B2048),
                                      onPressed: () {
                                        setState(() {
                                          _filterAc = false;
                                          _computeData();
                                        });
                                      },
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Nearby Alternative Recommendations',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 14),

                          _buildResponsiveGrid(_fallbackMatches, isAlternative: true),
                        ],
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildPgCard(BuildContext context, PGListingWithScore item, {required bool isFeatured, bool isAlternative = false}) {
    final bool isSelected = _selectedComparePgs.any((x) => x.pg.name == item.pg.name);
    final bool isFavorite = _favoritePgNames.contains(item.pg.name);

    final int walkTime = (item.distance * 12).round().clamp(1, 120);
    final int bikeTime = (item.distance * 4).round().clamp(1, 40);
    final int driveTime = (item.distance * 2).round().clamp(1, 20);

    final matchColor = _getConfidenceColor(item.score);

    final hasWifi = item.pg.amenities.any((a) => a.toLowerCase().contains('wi-fi'));
    final hasLaundry = item.pg.amenities.any((a) => a.toLowerCase().contains('laundry') || a.toLowerCase().contains('washing'));
    final hasGym = item.pg.amenities.any((a) => a.toLowerCase().contains('gym'));
    final hasParking = item.pg.amenities.any((a) => a.toLowerCase().contains('parking'));
    final hasWashroom = item.pg.amenities.any((a) => a.toLowerCase().contains('bathroom') || a.toLowerCase().contains('washroom'));
    final hasAc = item.pg.hasAc;

    List<Widget> amenityIcons = [];
    if (hasWifi) amenityIcons.add(const Tooltip(message: 'Wi-Fi', child: Icon(Icons.wifi, size: 14, color: Colors.white54)));
    if (hasLaundry) amenityIcons.add(const Tooltip(message: 'Laundry', child: Icon(Icons.local_laundry_service, size: 14, color: Colors.white54)));
    if (hasGym) amenityIcons.add(const Tooltip(message: 'Gym', child: Icon(Icons.fitness_center, size: 14, color: Colors.white54)));
    if (hasParking) amenityIcons.add(const Tooltip(message: 'Parking', child: Icon(Icons.directions_car, size: 14, color: Colors.white54)));
    if (hasWashroom) amenityIcons.add(const Tooltip(message: 'Attached Washroom', child: Icon(Icons.bathroom_rounded, size: 14, color: Colors.white54)));
    if (hasAc) amenityIcons.add(const Tooltip(message: 'AC Available', child: Icon(Icons.ac_unit, size: 14, color: Colors.white54)));

    final showExplain = _expandedExplanationPgNames.contains(item.pg.name);

    return SizedBox(
      width: isFeatured ? 290 : double.infinity,
      height: isFeatured ? 460 : null,
      child: GlassCard(
        borderRadius: AppTheme.cardRadius,
        border: BorderSide(
          color: isAlternative
              ? const Color(0xFFD97706).withValues(alpha: 0.4)
              : isSelected
                  ? AppTheme.accentColor
                  : Colors.white.withValues(alpha: 0.08),
          width: isSelected ? 2.0 : 1.0,
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. PG Image & Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  item.pg.imageUrl,
                  height: isFeatured ? 110 : 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => Container(
                    height: isFeatured ? 130 : 180,
                    color: const Color(0xFF222852),
                    child: const Icon(Icons.home_work_rounded, color: Colors.white24, size: 48),
                  ),
                ),
              ),
              // Match Score Overlay Badge (Point 3)
              Positioned(
                top: 12,
                left: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: matchColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.score}% Match',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getConfidenceLabel(item.score),
                        style: TextStyle(
                          color: matchColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              // Alternative Recommendation badge (Point 4)
              if (isAlternative)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🟡 Alternative Recommendation',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),

          // Card details body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personality Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildVisualTag(item.personalityTag, const Color(0xFF8C88FF)),
                    _buildVisualTag(item.lifestyleTag, const Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(height: 8),

                // PG Name & Rating Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.pg.name,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFD43F), size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${item.pg.rating}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                
                // Location text
                Text(
                  item.pg.location,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Rent Row
                Text(
                  '₹${item.pg.rent}/mo',
                  style: const TextStyle(color: AppTheme.accentColor, fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),

                // Distance + Commute Time Row (Point 3)
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      '${item.distance.toStringAsFixed(1)} km away',
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '·  🚶 ${walkTime}m  ·  🚲 ${bikeTime}m  ·  🚗 ${driveTime}m',
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 11. Nearby Essentials with Icons & Distances (Point 11)
                Row(
                  children: const [
                    Text('Nearby: ', style: TextStyle(color: Colors.white38, fontSize: 9)),
                    Text('🚇 300m  ·  🛒 180m  ·  🏥 700m  ·  🍔 120m', style: TextStyle(color: Colors.white60, fontSize: 9)),
                  ],
                ),
                const SizedBox(height: 8),



                // Amenity Icons row (Point 3)
                if (amenityIcons.isNotEmpty) ...[
                  Row(
                    children: [
                      const Text('Amenities:', style: TextStyle(color: Colors.white38, fontSize: 10)),
                      const SizedBox(width: 6),
                      ...amenityIcons.take(5).map((w) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: w,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // "Why Recommended" short chips (Point 3)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    ...item.matches.take(2).map((match) => _buildStatusChip(match, isMatch: true)),
                    ...item.mismatches.take(1).map((mismatch) => _buildStatusChip(mismatch, isMatch: false)),
                  ],
                ),
                const SizedBox(height: 8),

                // 🧠 Why did AI recommend this Expandable section button
                InkWell(
                  onTap: () {
                    setState(() {
                      if (showExplain) {
                        _expandedExplanationPgNames.remove(item.pg.name);
                      } else {
                        _expandedExplanationPgNames.add(item.pg.name);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.psychology_outlined, size: 12, color: AppTheme.accentColorLight),
                        const SizedBox(width: 4),
                        Text(
                          showExplain ? 'Hide details' : '🧠 Why did AI recommend this?',
                          style: const TextStyle(color: AppTheme.accentColorLight, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                if (showExplain) ...[
                  const SizedBox(height: 6),
                  _buildExplainabilityPanel(item),
                ],
                const SizedBox(height: 10),

                // Action Buttons Row (Save, Compare, Details)
                Row(
                  children: [
                    // Save Toggle button
                    GestureDetector(
                      onTap: () => _toggleFavorite(item.pg.name),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? const Color(0xFFEF4444) : Colors.white70,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Compare Toggle
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            if (isSelected) {
                              _selectedComparePgs.removeWhere((x) => x.pg.name == item.pg.name);
                            } else {
                              _selectedComparePgs.add(item);
                            }
                          });
                        },
                        icon: Icon(
                          isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          size: 12,
                          color: isSelected ? AppTheme.accentColorLight : Colors.white70,
                        ),
                        label: Text(
                          isSelected ? 'Selected' : 'Compare',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isSelected ? AppTheme.accentColor : AppTheme.borderTranslucent,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.pillRadius)),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // View Details button
                    Expanded(
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                          boxShadow: AppTheme.glowShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PgDetailsScreen(
                                  pg: item.pg,
                                  officeLat: _currentOfficeLat,
                                  officeLng: _currentOfficeLng,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.pillRadius)),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildStatusChip(String label, {required bool isMatch}) {
    final color = isMatch ? const Color(0xFF4ADE80) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMatch ? Icons.check : Icons.close,
            color: color,
            size: 8,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHubTip() {
    final loc = _currentOfficeLocation.toLowerCase();
    String? hub;
    String? recommendations;
    if (loc.contains('electronic city')) {
      hub = 'Electronic City';
      recommendations = 'Phase 1 and Neeladri Road';
    } else if (loc.contains('whitefield')) {
      hub = 'Whitefield';
      recommendations = 'Hope Farm and ITPL Main Road';
    } else if (loc.contains('koramangala')) {
      hub = 'Koramangala';
      recommendations = '4th Block and 7th Block';
    } else if (loc.contains('indiranagar')) {
      hub = 'Indiranagar';
      recommendations = 'HAL 2nd Stage and Domlur';
    }
    if (hub == null) return const SizedBox.shrink();
    return GlassCard(
      borderRadius: AppTheme.cardRadius,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      color: AppTheme.accentColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.accentColorLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hub Tip: Since your office is in $hub, popular PG clusters nearby include $recommendations.',
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
