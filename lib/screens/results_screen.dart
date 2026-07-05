import 'package:flutter/material.dart';

import '../data/mock_pg_listings.dart';
import '../models/neighborhood.dart';
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

  PGListingWithScore({
    required this.pg,
    required this.score,
    required this.distance,
    required this.commuteMinutes,
  });
}

class _ResultsScreenState extends State<ResultsScreen> {
  String? _selectedNeighborhood;
  List<Neighborhood> _derivedNeighborhoods = [];
  List<PGListingWithScore> _allRankedPgs = [];
  List<PGListingWithScore> _topRecommendations = [];

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

  int _parseCommuteMax(String commuteStr) {
    if (commuteStr.contains('15')) return 15;
    if (commuteStr.contains('30')) return 30;
    if (commuteStr.contains('45')) return 45;
    return 120;
  }

  void _computeData() {
    final maxRent = _parseBudgetMax(widget.criteria.budget);
    final maxCommute = _parseCommuteMax(widget.criteria.commute);

    // 1. Gather all potential listings (including dynamic fallback generation if none exist locally)
    List<PGListing> sourceListings = [];
    
    // Check if we have hardcoded listings within 25km of coordinates
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
      // Dynamic generation fallback for India-wide locations (e.g. Jaipur, Jammu, Jamshedpur)
      sourceListings = generateDynamicMockPgs(
        widget.criteria.officeArea,
        widget.criteria.officeLat,
        widget.criteria.officeLng,
      );
    }

    // 2. Filter & score listings
    List<PGListingWithScore> rankedPgs = [];
    Map<String, List<PGListingWithScore>> groupedPgs = {};

    for (var pg in sourceListings) {
      final distance = GeoUtils.calculateDistanceKm(
          widget.criteria.officeLat, widget.criteria.officeLng, pg.lat, pg.lng);

      // Radius filter: Keep inside 15 km to give more options across custom cities
      if (distance > 15.0) continue;

      final commuteTime = GeoUtils.calculateCommuteMinutes(distance);
      // Commute filter
      if (commuteTime > maxCommute) continue;

      // Budget filter
      if (pg.rent > maxRent) continue;

      // Calculate matching score out of 100
      // A. Distance score (max 35 pts): Closer is better
      double distanceScore = (1.0 - (distance / 15.0).clamp(0.0, 1.0)) * 35;

      // B. Budget score (max 30 pts): Lower rent is better relative to budget
      double budgetScore = 30.0;
      if (maxRent != 999999) {
        budgetScore = (1.0 - (pg.rent / maxRent).clamp(0.0, 1.0)) * 30;
      }

      // C. Quality score (max 20 pts): Rating based
      double qualityScore = (pg.rating / 5.0) * 20;

      // D. Safety score (max 15 pts): Safety rating based
      double safetyScoreVal = (pg.safetyScore / 10.0) * 15;

      // E. Vibe Match bonus: Add +5 if lifestyle matches vibe keyword
      double vibeBonus = 0;
      if (pg.vibe.toLowerCase().contains(widget.criteria.lifestyle.toLowerCase().split(' ').first)) {
        vibeBonus = 5;
      }

      int finalScore = (distanceScore + budgetScore + qualityScore + safetyScoreVal + vibeBonus).clamp(0, 100).round();

      final pgWithScore = PGListingWithScore(
        pg: pg,
        score: finalScore,
        distance: distance,
        commuteMinutes: commuteTime,
      );

      rankedPgs.add(pgWithScore);

      if (!groupedPgs.containsKey(pg.neighborhood)) {
        groupedPgs[pg.neighborhood] = [];
      }
      groupedPgs[pg.neighborhood]!.add(pgWithScore);
    }

    // 3. Sort PGs by score descending
    rankedPgs.sort((a, b) => b.score.compareTo(a.score));

    // Get Top 3 PG recommendations overall
    List<PGListingWithScore> top3 = rankedPgs.take(3).toList();

    // 4. Group remaining or derived neighborhoods
    List<Neighborhood> neighborhoods = [];
    for (var entry in groupedPgs.entries) {
      final neighborhoodName = entry.key;
      final pgs = entry.value;

      double totalRent = 0;
      double totalSafety = 0;
      double totalRating = 0;
      double totalCommute = 0;
      int totalScore = 0;

      for (var pgScore in pgs) {
        totalRent += pgScore.pg.rent;
        totalSafety += pgScore.pg.safetyScore;
        totalRating += pgScore.pg.rating;
        totalCommute += pgScore.commuteMinutes;
        totalScore += pgScore.score;
      }

      final avgRent = (totalRent / pgs.length).round();
      final avgSafety = totalSafety / pgs.length;
      final avgRating = totalRating / pgs.length;
      final avgCommute = (totalCommute / pgs.length).round();
      final avgScore = (totalScore / pgs.length).round();

      neighborhoods.add(Neighborhood(
        name: neighborhoodName,
        region: 'Local Area',
        tagline: 'Stays near your office',
        averageRent: avgRent,
        commuteMinutes: avgCommute,
        safetyScore: double.parse(avgSafety.toStringAsFixed(1)),
        vibe: pgs.first.pg.vibe,
        matchScore: avgScore,
        brief: '$neighborhoodName offers stays within your commute, averaging about $avgCommute min with balanced rents.',
        reasons: [
          'Average safety score of ${avgSafety.toStringAsFixed(1)}/10',
          'Average rating of ${avgRating.toStringAsFixed(1)}/5',
          '${pgs.length} verified listings available',
        ],
      ));
    }

    neighborhoods.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    setState(() {
      _allRankedPgs = rankedPgs;
      _topRecommendations = top3;
      _derivedNeighborhoods = neighborhoods;
      if (neighborhoods.isNotEmpty && _selectedNeighborhood == null) {
        _selectedNeighborhood = neighborhoods.first.name;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_allRankedPgs.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF090B19),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: const Text('Top Neighborhoods'),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 72, color: Color(0xFF3B4078)),
              const SizedBox(height: 18),
              const Text(
                'No stays found matching your criteria.',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try expanding your budget or commute settings.',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refine Search'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF5E54FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Neighborhood primary = _derivedNeighborhoods.firstWhere(
        (n) => n.name == _selectedNeighborhood,
        orElse: () => _derivedNeighborhoods.first);

    final Neighborhood? secondary = _derivedNeighborhoods.length > 1
        ? _derivedNeighborhoods.firstWhere((n) => n.name != primary.name,
            orElse: () => _derivedNeighborhoods[1])
        : null;

    final List<PGListingWithScore> filteredPgs =
        _allRankedPgs.where((pg) => pg.pg.neighborhood == primary.name).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF090B19),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Your Stay Matches'),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(true),
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
                // Header Criteria Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131732),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF222855)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.work_outline_rounded, color: Color(0xFF8C88FF), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${widget.criteria.officeLocation.split(',').first} · ${widget.criteria.budget} · ${widget.criteria.commute}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Top 3 Recommendations Section
                const Row(
                  children: [
                    Icon(Icons.stars_rounded, color: Color(0xFFFFD43F), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Top 3 Recommendations',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 380,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _topRecommendations.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      return _buildFeaturedCard(context, _topRecommendations[index]);
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // Neighborhoods section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Explore Areas',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (secondary != null)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CompareScreen(left: primary, right: secondary),
                            ),
                          );
                        },
                        icon: const Icon(Icons.compare_arrows_rounded, size: 18, color: Color(0xFF8C88FF)),
                        label: const Text('Compare Areas', style: TextStyle(color: Color(0xFF8C88FF), fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Neighborhood Selectors
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _derivedNeighborhoods.length > 4 ? 4 : _derivedNeighborhoods.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final n = _derivedNeighborhoods[index];
                      final isSelected = n.name == _selectedNeighborhood;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedNeighborhood = n.name;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF5E54FF) : const Color(0xFF121630),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF8C88FF) : const Color(0xFF222852),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              n.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white60,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // Selected Neighborhood AI Brief Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111530),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF222855)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: Color(0xFF8C88FF), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${primary.name} Summary',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5E54FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF8C88FF).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '${primary.matchScore}% Match',
                              style: const TextStyle(color: Color(0xFF8C88FF), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        primary.brief,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildMiniMetric('Rent', '₹${primary.averageRent ~/ 1000}k/mo'),
                          const SizedBox(width: 8),
                          _buildMiniMetric('Commute', '${primary.commuteMinutes} min'),
                          const SizedBox(width: 8),
                          _buildMiniMetric('Safety', '${primary.safetyScore}/10'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _showReasonsBottomSheet(context, primary),
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(42),
                          backgroundColor: const Color(0xFF1C224B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Why choose this area?',
                          style: TextStyle(color: Color(0xFF9A91FF), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Other stays list
                Text(
                  'Other Stays in ${primary.name}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 250,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredPgs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _buildStandardCard(context, filteredPgs[index]);
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0C0F22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1C224B)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, PGListingWithScore item) {
    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: const Color(0xFF121632),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF222852)),
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
          // Image + floating badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                child: Image.network(
                  item.pg.imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => Container(
                    height: 140,
                    color: const Color(0xFF222852),
                    child: const Icon(Icons.home_work_rounded, color: Colors.white24, size: 48),
                  ),
                ),
              ),
              // Match Score badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6F5CFF), Color(0xFF5038FF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6F5CFF).withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    '${item.score}% Match',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // Verified badge
              if (item.pg.verified)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1225).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified_user_rounded, color: Color(0xFF8C88FF), size: 12),
                        SizedBox(width: 4),
                        Text('Verified', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Content
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
                const SizedBox(height: 6),
                Text(
                  item.pg.location,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Price and Commute
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${item.pg.rent}/mo',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${item.commuteMinutes} min commute',
                      style: const TextStyle(color: Color(0xFF8C88FF), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Key Amenities
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
                const SizedBox(height: 16),

                // View Details Button
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
                  child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardCard(BuildContext context, PGListingWithScore item) {
    return GestureDetector(
      onTap: () {
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
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF12152D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF222852)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                item.pg.imageUrl,
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(
                  height: 90,
                  color: const Color(0xFF222852),
                  child: const Icon(Icons.home_work_rounded, color: Colors.white24, size: 36),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.pg.name,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFD43F), size: 14),
                const SizedBox(width: 4),
                Text('${item.pg.rating}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                const Spacer(),
                Text('₹${item.pg.rent}/mo', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${item.commuteMinutes} min commute (${item.distance.toStringAsFixed(1)} km)',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2048),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('View Stay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReasonsBottomSheet(BuildContext context, Neighborhood neighborhood) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111530),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Why choose ${neighborhood.name}?',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...neighborhood.reasons.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF8C88FF), size: 18),
                      const SizedBox(width: 12),
                      Expanded(child: Text(reason, style: const TextStyle(color: Colors.white70, fontSize: 14))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF6F5CFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
