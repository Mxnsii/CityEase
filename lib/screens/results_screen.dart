import 'package:flutter/material.dart';

import '../data/mock_pg_listings.dart';
import '../models/pg_listing.dart';
import '../models/survey_criteria.dart';
import '../utils/geo_utils.dart';
import 'compare_screen.dart';
import 'pg_details_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _computeData();
  }

  @override
  void didUpdateWidget(ResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.criteria != widget.criteria) {
      _computeData();
    }
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
    final maxRent = _parseBudgetMax(widget.criteria.budget);
    final distanceLimit = _parseDistanceLimit(widget.criteria.distancePref);

    // 1. Fetch relevant stays (fallback dynamically if no local stays exist)
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

    // 2. Score and categorize each stay
    for (var pg in sourceListings) {
      final distance = GeoUtils.calculateDistanceKm(
          widget.criteria.officeLat, widget.criteria.officeLng, pg.lat, pg.lng);
      final commuteTime = GeoUtils.calculateCommuteMinutes(distance);

      // Verify strict match parameters
      final isBudgetMatch = pg.rent <= maxRent;
      final isDistanceMatch = distance <= distanceLimit;
      final isGenderMatch = _genderMatches(pg.gender, widget.criteria.gender);
      final isFoodMatch = !widget.criteria.foodIncluded || pg.foodIncluded;
      final isAcMatch = !widget.criteria.acRequired || pg.hasAc;

      final isStrictMatch = isBudgetMatch && isDistanceMatch && isGenderMatch && isFoodMatch && isAcMatch;

      // 3. Compute dynamic checklist (matches / mismatches)
      List<String> matches = [];
      List<String> mismatches = [];

      if (isBudgetMatch) {
        matches.add('Within budget (₹${pg.rent})');
      } else {
        mismatches.add('₹${pg.rent}/mo exceeds budget');
      }

      if (isDistanceMatch) {
        matches.add('Close to office (${distance.toStringAsFixed(1)} km)');
      } else {
        mismatches.add('${distance.toStringAsFixed(1)} km exceeds preferred range');
      }

      if (isGenderMatch) {
        matches.add('${pg.gender} accommodation');
      } else {
        mismatches.add('Is ${pg.gender} instead of ${widget.criteria.gender.replaceAll(' Only', '')}');
      }

      if (pg.foodIncluded) {
        matches.add('Food Included');
      } else if (widget.criteria.foodIncluded) {
        mismatches.add('Food not included');
      }

      if (pg.hasAc) {
        matches.add('AC Room');
      } else if (widget.criteria.acRequired) {
        mismatches.add('Non-AC room');
      }

      // Add general matched amenities
      for (var amenity in pg.amenities.take(2)) {
        matches.add('Has $amenity');
      }

      // 4. Calculate Match Score (0 - 100)
      double distScore = (1.0 - (distance / 12.0).clamp(0.0, 1.0)) * 20;
      double budgetScore = maxRent == 999999 ? 20.0 : (1.0 - (pg.rent / maxRent).clamp(0.0, 1.0)) * 20;
      double genderScore = isGenderMatch ? 20.0 : 0.0;
      double foodScore = (pg.foodIncluded || !widget.criteria.foodIncluded) ? 15.0 : 5.0;
      double acScore = (pg.hasAc || !widget.criteria.acRequired) ? 15.0 : 5.0;
      double ratingScore = (pg.rating / 5.0) * 10.0;

      int totalScore = (distScore + budgetScore + genderScore + foodScore + acScore + ratingScore).clamp(0, 100).round();

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

    // Sort exact matches by score descending
    exactMatches.sort((a, b) => b.score.compareTo(a.score));

    // Sort fallbacks by distance (since proximity is key for fallback suggestions)
    fallbacks.sort((a, b) => a.distance.compareTo(b.distance));

    setState(() {
      _exactMatches = exactMatches;
      _fallbackMatches = fallbacks;
      _selectedComparePgs.clear(); // Clear selections on compute
    });
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
      ),
      // Floating Compare Selected Button
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

                // Recommendation Summary Card
                Container(
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
                        children: const [
                          Icon(Icons.tune_rounded, color: Color(0xFF8C88FF), size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Your Search Preferences',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow('Office Location', widget.criteria.officeLocation),
                      _buildSummaryRow('Rent Budget', widget.criteria.budget),
                      _buildSummaryRow('Gender target', widget.criteria.gender),
                      _buildSummaryRow('Food Preference', widget.criteria.foodIncluded ? 'Food Included' : 'No Food Preference'),
                      _buildSummaryRow('AC requirement', widget.criteria.acRequired ? 'AC Room Required' : 'Non-AC is Fine'),
                      _buildSummaryRow('Commute range', widget.criteria.distancePref),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Matches Count Banner
                if (hasMatches) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ADE80).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF4ADE80), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Found ${_exactMatches.length} Matching PGs',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Perfectly matching all your onboarding filters.',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Best Matches For You Section
                  const Text(
                    'Best Matches for You',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 28),

                  // Other Matching PGs Section
                  if (others.isNotEmpty) ...[
                    const Text(
                      'Other Matching PGs',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: others.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _buildPgCard(context, others[index], isFeatured: false);
                      },
                    ),
                  ],
                ] else ...[
                  // Fallback state empty banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF30151C),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFF55222E)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFF77171), size: 24),
                            SizedBox(width: 10),
                            Text(
                              'No PGs match all of your preferences.',
                              style: TextStyle(color: Color(0xFFF77171), fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'We relaxed some matching parameters to show you nearby alternatives centered around your office location.',
                          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Alternative Stays Header
                  const Text(
                    'Available PGs Near Your Office',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Alternative suggestions ordered by proximity.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _fallbackMatches.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      return _buildPgCard(context, _fallbackMatches[index], isFeatured: false, isAlternative: true);
                    },
                  ),
                ],
                const SizedBox(height: 80), // extra padding for floating button
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.split(',').first.trim(),
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPgCard(BuildContext context, PGListingWithScore item, {required bool isFeatured, bool isAlternative = false}) {
    final bool isSelected = _selectedComparePgs.any((x) => x.pg.name == item.pg.name);

    return Container(
      width: isFeatured ? 300 : double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF121632),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isAlternative
              ? const Color(0xFF55222E).withValues(alpha: 0.5)
              : isSelected
                  ? const Color(0xFF6F5CFF)
                  : const Color(0xFF222852),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Badge Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                child: Image.network(
                  item.pg.imageUrl,
                  height: isFeatured ? 150 : 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => Container(
                    height: isFeatured ? 150 : 130,
                    color: const Color(0xFF222852),
                    child: const Icon(Icons.home_work_rounded, color: Colors.white24, size: 48),
                  ),
                ),
              ),
              // Match Score Overlay Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isAlternative
                          ? [const Color(0xFFEC4899), const Color(0xFFD946EF)]
                          : [const Color(0xFF6F5CFF), const Color(0xFF5038FF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (isAlternative ? const Color(0xFFEC4899) : const Color(0xFF6F5CFF)).withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    isAlternative ? 'Alternative Stay' : '${item.score}% Match',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // Select for Comparison Checkbox Overlay
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedComparePgs.removeWhere((x) => x.pg.name == item.pg.name);
                      } else {
                        _selectedComparePgs.add(item);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1225).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6F5CFF) : Colors.white24,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          color: isSelected ? const Color(0xFF8C88FF) : Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSelected ? 'Selected' : 'Compare',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Main details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.pg.name,
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFD43F), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${item.pg.rating}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.pg.location,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Pricing, Commute and Proximity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${item.pg.rent}/mo',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.distance.toStringAsFixed(1)} km away',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '~${item.commuteMinutes} min commute',
                          style: const TextStyle(color: Color(0xFF8C88FF), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // WHY THIS PG / EXPLAINABILITY LIST
                const Text(
                  'Why this PG?',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...item.matches.take(3).map((match) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF4ADE80), size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              match,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                // Show mismatch criteria clearly
                if (item.mismatches.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...item.mismatches.take(2).map((mismatch) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.cancel_outlined, color: Color(0xFFF87171), size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                mismatch,
                                style: const TextStyle(color: Color(0xFFFFA1A1), fontSize: 11, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 16),

                // Amenities
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.pg.amenities.take(3).map((amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2048),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        amenity,
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Primary Details trigger
                ElevatedButton(
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
                    minimumSize: const Size.fromHeight(42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
