import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_pg_listings.dart';
import '../models/pg_listing.dart';
import '../models/survey_criteria.dart';
import '../utils/geo_utils.dart';
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

  PGListingWithScore({
    required this.pg,
    required this.score,
    required this.distance,
    required this.commuteMinutes,
    required this.matches,
    required this.mismatches,
  });
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<PGListingWithScore> _exactMatches = [];
  List<PGListingWithScore> _fallbackMatches = [];
  final List<PGListingWithScore> _selectedComparePgs = [];
  List<String> _favoritePgNames = [];

  // Refined Interactive Filters State (Point 8)
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

  @override
  void initState() {
    super.initState();
    _filterBudget = widget.criteria.budget;
    _filterDistance = widget.criteria.distancePref;
    _filterAc = widget.criteria.acRequired;
    _filterFood = widget.criteria.foodIncluded;
    _filterGender = widget.criteria.gender;
    _computeData();
    _loadFavorites();
  }

  @override
  void didUpdateWidget(ResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.criteria != widget.criteria) {
      _filterBudget = widget.criteria.budget;
      _filterDistance = widget.criteria.distancePref;
      _filterAc = widget.criteria.acRequired;
      _filterFood = widget.criteria.foodIncluded;
      _filterGender = widget.criteria.gender;
      _computeData();
    }
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

  void _computeData() {
    final maxRent = _parseBudgetMax(_filterBudget);
    final distanceLimit = _parseDistanceLimit(_filterDistance);

    List<PGListing> sourceListings = [];
    bool hasLocalHardcoded = false;
    for (var pg in allPgListings) {
      final distance = GeoUtils.calculateDistanceKm(
          widget.criteria.officeLat, widget.criteria.officeLng, pg.lat, pg.lng);
      if (distance < 25.0) {
        hasLocalHardcoded = true;
        break;
      }
    }

    if (hasLocalHardcoded) {
      sourceListings = allPgListings;
    } else {
      sourceListings = generateDynamicMockPgs(
        widget.criteria.officeArea,
        widget.criteria.officeLat,
        widget.criteria.officeLng,
      );
    }

    List<PGListingWithScore> exactMatches = [];
    List<PGListingWithScore> fallbacks = [];

    for (var pg in sourceListings) {
      if (_showFavoritesOnly && !_favoritePgNames.contains(pg.name)) {
        continue;
      }

      final distance = GeoUtils.calculateDistanceKm(
          widget.criteria.officeLat, widget.criteria.officeLng, pg.lat, pg.lng);
      final commuteTime = GeoUtils.calculateCommuteMinutes(distance);

      // Amenities filter checks
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
        mismatches.add('₹${pg.rent}/mo exceeds budget');
      }

      if (isDistanceMatch) {
        matches.add('Walking Distance');
      } else {
        mismatches.add('${distance.toStringAsFixed(1)} km exceeds preferred range');
      }

      if (isGenderMatch) {
        matches.add('${pg.gender} PG');
      } else {
        mismatches.add('Is ${pg.gender} instead of ${_filterGender.replaceAll(' Only', '')}');
      }

      if (pg.foodIncluded) {
        matches.add('Food Included');
      } else if (_filterFood) {
        mismatches.add('Food not included');
      }

      if (pg.hasAc) {
        matches.add('AC Room');
      } else if (_filterAc) {
        mismatches.add('Non-AC room');
      }

      if (hasLaundry) matches.add('Laundry');
      if (hasWifi) matches.add('Wi-Fi');
      if (hasParking) matches.add('Parking');
      if (hasWashroom) matches.add('Attached Washroom');

      // 20. End-to-end scoring model weights:
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

      final rankedItem = PGListingWithScore(
        pg: pg,
        score: totalScore,
        distance: distance,
        commuteMinutes: commuteTime,
        matches: matches,
        mismatches: mismatches,
      );

      if (isStrictMatch) {
        exactMatches.add(rankedItem);
      } else {
        fallbacks.add(rankedItem);
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

    setState(() {
      _exactMatches = exactMatches;
      _fallbackMatches = fallbacks;
    });
  }

  String _getConfidenceLabel(int score) {
    if (score >= 90) return 'Excellent Match';
    if (score >= 75) return 'Good Match';
    return 'Fair Match';
  }

  Color _getConfidenceColor(int score) {
    if (score >= 90) return const Color(0xFF4ADE80);
    if (score >= 75) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _buildHubTip() {
    final loc = widget.criteria.officeLocation.toLowerCase();
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
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF6F5CFF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6F5CFF).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF8C88FF), size: 20),
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

  // 7. Search Preferences Card using horizontal visual chips
  Widget _buildPreferencesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131732),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF222855)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Search Preferences',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(true), // triggers onboarding reset
                icon: const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF8C88FF)),
                label: const Text('Edit Preferences', style: TextStyle(color: Color(0xFF8C88FF), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPrefChip('📍 ${widget.criteria.officeLocation.split(',').first}'),
              _buildPrefChip('💰 ${widget.criteria.budget}'),
              _buildPrefChip('👩 ${widget.criteria.gender.replaceAll(' Only', '')}'),
              _buildPrefChip('🍛 ${widget.criteria.foodIncluded ? "Food Incl." : "No Food"}'),
              _buildPrefChip('❄️ ${widget.criteria.acRequired ? "AC Required" : "Non-AC Fine"}'),
              _buildPrefChip('🚗 ${widget.criteria.distancePref.split(' ').first}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrefChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2048),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  // 8. Filters: horizontal list of modern filter chips
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
    return ActionChip(
      label: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      backgroundColor: const Color(0xFF121630),
      side: const BorderSide(color: Color(0xFF222852)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onPressed: onTap,
    );
  }

  Widget _buildToggleChip(String label, bool active, ValueChanged<bool> onSelected) {
    return FilterChip(
      label: Text(label, style: TextStyle(color: active ? Colors.white : Colors.white60, fontSize: 12)),
      selected: active,
      selectedColor: const Color(0xFF6F5CFF),
      checkmarkColor: Colors.white,
      backgroundColor: const Color(0xFF121630),
      side: BorderSide(color: active ? const Color(0xFF8C88FF) : const Color(0xFF222852)),
      onSelected: onSelected,
    );
  }

  void _showFilterOptionsSheet(String title, String currentValue, List<String> options, ValueChanged<String> onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF11142B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
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

  // 6. Recommendation Summary header
  Widget _buildSummaryHeader() {
    final excellent = _exactMatches.where((x) => x.score >= 90).length;
    final good = _exactMatches.where((x) => x.score >= 70 && x.score < 90).length;
    final average = _exactMatches.where((x) => x.score < 70).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11142B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF20254D)),
      ),
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

    // Split exact matches list: Top 3 vs remaining
    final List<PGListingWithScore> top3 = hasMatches ? _exactMatches.take(3).toList() : [];
    final List<PGListingWithScore> others = hasMatches ? _exactMatches.skip(3).toList() : [];

    return Scaffold(
      backgroundColor: const Color(0xFF090B19),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('AI Stay Recommendations'),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(true),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
            tooltip: 'Saved Stays',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SavedPgsScreen(
                    officeLat: widget.criteria.officeLat,
                    officeLng: widget.criteria.officeLng,
                    officeArea: widget.criteria.officeArea,
                  ),
                ),
              ).then((_) => _loadFavorites());
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedComparePgs.isEmpty
          ? null
          : Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton.extended(
                backgroundColor: const Color(0xFF6F5CFF),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CompareScreen(
                        pgs: _selectedComparePgs,
                        officeLat: widget.criteria.officeLat,
                        officeLng: widget.criteria.officeLng,
                      ),
                    ),
                  );
                },
                label: Text(
                  'Compare Selected (${_selectedComparePgs.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                icon: const Icon(Icons.compare_arrows_rounded, color: Colors.white),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildPreferencesCard(),
                _buildHubTip(),
                const SizedBox(height: 18),
                
                // Horizontal list of filters
                _buildFiltersRow(),
                const SizedBox(height: 18),

                // Sort by selection dropdown
                Row(
                  children: [
                    const Text('Sort by:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121630),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF222852)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          dropdownColor: const Color(0xFF11142B),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
                    const Spacer(),
                    FilterChip(
                      label: Text(
                        '❤️ Favs (${_favoritePgNames.length})',
                        style: TextStyle(
                          color: _showFavoritesOnly ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selected: _showFavoritesOnly,
                      checkmarkColor: Colors.white,
                      selectedColor: const Color(0xFFEF4444),
                      backgroundColor: const Color(0xFF121630),
                      side: BorderSide(color: _showFavoritesOnly ? const Color(0xFFEF4444) : const Color(0xFF222852)),
                      onSelected: (selected) {
                        setState(() {
                          _showFavoritesOnly = selected;
                          _computeData();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                if (hasMatches) ...[
                  _buildSummaryHeader(),
                  const SizedBox(height: 24),

                  // Best Matches For You Section
                  const Text(
                    '⭐ Best Matches for You',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 550,
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
                  const SizedBox(height: 28),

                  // Other Matching PGs Section
                  if (others.isNotEmpty) ...[
                    const Text(
                      '📋 Other Matching PGs',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildResponsiveGrid(others),
                  ],
                ] else ...[
                  // 17. Empty state improvement (matches exactly user copy)
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
                        const Text(
                          'Don\'t worry!\nWe found some nearby alternatives you might like.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                        ),
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
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
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

        // Set fixed height to fit all card elements cleanly
        double aspectRatio = cellWidth / 680.0;

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

  Widget _buildPgCard(BuildContext context, PGListingWithScore item, {required bool isFeatured, bool isAlternative = false}) {
    final bool isSelected = _selectedComparePgs.any((x) => x.pg.name == item.pg.name);
    final bool isFavorite = _favoritePgNames.contains(item.pg.name);

    final int walkTime = (item.distance * 12).round().clamp(1, 120);
    final int bikeTime = (item.distance * 4).round().clamp(1, 40);
    final int driveTime = (item.distance * 2).round().clamp(1, 20);

    final matchColor = _getConfidenceColor(item.score);

    // Build amenity icons (Point 2)
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

    return Container(
      width: isFeatured ? 290 : double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF121632),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAlternative
              ? const Color(0xFFD97706).withValues(alpha: 0.4)
              : isSelected
                  ? const Color(0xFF6F5CFF)
                  : const Color(0xFF222852),
          width: isSelected ? 2 : 1,
        ),
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
                  height: isFeatured ? 140 : 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => Container(
                    height: isFeatured ? 140 : 180,
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
                // 3. PG Name & Rating Row
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
                  style: const TextStyle(color: Color(0xFF8C88FF), fontSize: 15, fontWeight: FontWeight.w800),
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
                const Text(
                  'Why Recommended?',
                  style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    ...item.matches.take(2).map((match) => _buildStatusChip(match, isMatch: true)),
                    ...item.mismatches.take(1).map((mismatch) => _buildStatusChip(mismatch, isMatch: false)),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Buttons Row (Save, Compare, Details)
                Row(
                  children: [
                    // Save Toggle button
                    GestureDetector(
                      onTap: () => _toggleFavorite(item.pg.name),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B2048),
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
                          color: isSelected ? const Color(0xFF8C88FF) : Colors.white70,
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
                            color: isSelected ? const Color(0xFF6F5CFF) : Colors.white30,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // View Details button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PgDetailsScreen(
                                pg: item.pg,
                                officeLat: widget.criteria.officeLat,
                                officeLng: widget.criteria.officeLng,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF6F5CFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
}
