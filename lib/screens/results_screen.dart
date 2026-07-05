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

class _ResultsScreenState extends State<ResultsScreen> {
  String? _selectedNeighborhood;
  List<Neighborhood> _derivedNeighborhoods = [];
  List<PGListing> _allValidPgs = [];

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
    // e.g. "< 15 mins", "< 30 mins", "Any"
    if (commuteStr.contains('15')) return 15;
    if (commuteStr.contains('30')) return 30;
    if (commuteStr.contains('45')) return 45;
    return 120; // fallback if "Any" or unparseable
  }

  void _computeData() {
    List<PGListing> validPgs = [];
    final maxRent = _parseBudgetMax(widget.criteria.budget);
    final maxCommute = _parseCommuteMax(widget.criteria.commute);
    
    Map<String, List<PGListing>> groupedPgs = {};
    
    // 3. Correct Filtering Pipeline
    for (var pg in allPgListings) {
      final distance = GeoUtils.calculateDistanceKm(
          widget.criteria.officeLat, widget.criteria.officeLng, pg.lat, pg.lng);
      
      // Step A: filter within radius (10 km)
      if (distance > 10.0) continue;
      
      final commuteTime = GeoUtils.calculateCommuteMinutes(distance);
      // Step B: filter by max commute
      if (commuteTime > maxCommute) continue;
      
      // Step C: filter by budget
      if (pg.rent > maxRent) continue;
      
      validPgs.add(pg);
      
      if (!groupedPgs.containsKey(pg.neighborhood)) {
        groupedPgs[pg.neighborhood] = [];
      }
      groupedPgs[pg.neighborhood]!.add(pg);
    }
    
    // 4 & 5. Neighborhoods Based on FILTERED PGs ONLY
    List<Neighborhood> neighborhoods = [];
    for (var entry in groupedPgs.entries) {
      final neighborhoodName = entry.key;
      final pgs = entry.value;
      
      double totalRent = 0;
      double totalSafety = 0;
      double totalRating = 0;
      double totalCommute = 0;
      
      for (var pg in pgs) {
        totalRent += pg.rent;
        totalSafety += pg.safetyScore;
        totalRating += pg.rating;
        final dist = GeoUtils.calculateDistanceKm(
          widget.criteria.officeLat, widget.criteria.officeLng, pg.lat, pg.lng);
        totalCommute += GeoUtils.calculateCommuteMinutes(dist);
      }
      
      final avgRent = (totalRent / pgs.length).round();
      final avgSafety = totalSafety / pgs.length;
      final avgRating = totalRating / pgs.length;
      final avgCommute = (totalCommute / pgs.length).round();
      
      double score = (0.3 * ((40000 - avgRent) / 40000 * 100)) + 
                     (0.3 * ((60 - avgCommute.clamp(0, 60)) / 60 * 100)) + 
                     (0.2 * avgSafety * 10) + 
                     (0.2 * avgRating * 20);
                     
      neighborhoods.add(Neighborhood(
        name: neighborhoodName,
        region: 'Local',
        tagline: 'Derived from real PG data',
        averageRent: avgRent,
        commuteMinutes: avgCommute,
        safetyScore: double.parse(avgSafety.toStringAsFixed(1)),
        vibe: pgs.first.vibe,
        matchScore: score.clamp(0, 100).round(),
        // 6. AI Match Brief (Now Context-Aware)
        brief: '$neighborhoodName offers stays within your $maxCommute min commute, with an average commute of $avgCommute min and balanced rent options.',
        reasons: [
          'Average safety score of ${avgSafety.toStringAsFixed(1)}',
          'Average rating of ${avgRating.toStringAsFixed(1)}',
          '${pgs.length} verified stays available',
        ],
      ));
    }
    
    // Sort by matchScore descending
    neighborhoods.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    
    setState(() {
      _allValidPgs = validPgs;
      _derivedNeighborhoods = neighborhoods;
      if (neighborhoods.isNotEmpty && _selectedNeighborhood == null) {
        _selectedNeighborhood = neighborhoods.first.name;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_derivedNeighborhoods.isEmpty) {
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
              const Icon(Icons.search_off, size: 64, color: Color(0xFF2D3161)),
              const SizedBox(height: 16),
              const Text('No stays found matching your strict criteria.', 
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Try expanding your commute time or budget.', 
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.refresh),
                label: const Text('Refine Search'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF5E54FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Neighborhood primary = _derivedNeighborhoods.firstWhere(
      (n) => n.name == _selectedNeighborhood, 
      orElse: () => _derivedNeighborhoods.first
    );
    
    final Neighborhood? secondary = _derivedNeighborhoods.length > 1 ? 
      _derivedNeighborhoods.firstWhere((n) => n.name != primary.name, orElse: () => _derivedNeighborhoods[1]) : null;

    final List<PGListing> filteredPgs = _allValidPgs.where((pg) => pg.neighborhood == primary.name).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF090B19),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Top Neighborhoods'),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text('Based on ${widget.criteria.officeLocation} · ${widget.criteria.budget}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 20),
                
                // Neighborhood Selector
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _derivedNeighborhoods.length > 3 ? 3 : _derivedNeighborhoods.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final n = _derivedNeighborhoods[index];
                      final isSelected = n.name == _selectedNeighborhood;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedNeighborhood = n.name;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF5E54FF) : const Color(0xFF11162D),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? const Color(0xFF8C88FF) : const Color(0xFF2D3161)),
                          ),
                          child: Center(
                            child: Text(n.name, style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            )),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // AI Match Brief
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11162D),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF2D3161)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_graph, color: Color(0xFF8C88FF)),
                          const SizedBox(width: 10),
                          const Text('AI Match Brief',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF322DE8),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text('${primary.matchScore}% match', style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(primary.brief,
                          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _buildMetric('Rent', '₹${primary.averageRent ~/ 1000}k avg'),
                          const SizedBox(width: 10),
                          _buildMetric('Commute', '${primary.commuteMinutes} min avg'),
                          const SizedBox(width: 10),
                          _buildMetric('Vibe', primary.vibe),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          _showReasonsBottomSheet(context, primary);
                        },
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: const Color(0xFF171B3B),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Why this?', style: TextStyle(color: Color(0xFF9A91FF))),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PGs in ${primary.name}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    if (secondary != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CompareScreen(left: primary, right: secondary),
                            ),
                          );
                        },
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Comparison'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF5E54FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Showing highly rated stays based on your filters.',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 280,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredPgs.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      return _buildPgCard(context, filteredPgs[index]);
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

  Widget _buildMetric(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF10142A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showReasonsBottomSheet(BuildContext context, Neighborhood neighborhood) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF11162D),
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
              Text('Why choose ${neighborhood.name}?', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...neighborhood.reasons.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF8C88FF), size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(reason, style: const TextStyle(color: Colors.white70, fontSize: 15))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF6F5CFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Got it', style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildPgCard(BuildContext context, PGListing listing) {
    final distance = GeoUtils.calculateDistanceKm(
        widget.criteria.officeLat, widget.criteria.officeLng, listing.lat, listing.lng);
    final commuteMinutes = GeoUtils.calculateCommuteMinutes(distance);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PgDetailsScreen(
              pg: listing,
              officeLat: widget.criteria.officeLat,
              officeLng: widget.criteria.officeLng,
            ),
          ),
        );
      },
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF11162D),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF2D3161)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(listing.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                if (listing.verified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A3159),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('Verified', style: TextStyle(color: Color(0xFF8C88FF), fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(listing.location, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.star, size: 14, color: const Color(0xFFFFC857)),
                const SizedBox(width: 4),
                Text('${listing.rating}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(width: 10),
                Text(listing.source, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text('₹${listing.rent}/mo', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F244C),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('${listing.safetyScore}/10', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('$commuteMinutes min commute', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            Text(listing.vibe, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF21274D),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('View Stay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
