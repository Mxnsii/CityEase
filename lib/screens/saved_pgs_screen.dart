import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_pg_listings.dart';
import '../models/pg_listing.dart';
import '../utils/geo_utils.dart';
import '../utils/app_theme.dart';
import 'pg_details_screen.dart';
import 'results_screen.dart';

class SavedPgsScreen extends StatefulWidget {
  final double officeLat;
  final double officeLng;
  final String officeArea;

  const SavedPgsScreen({
    super.key,
    required this.officeLat,
    required this.officeLng,
    required this.officeArea,
  });

  @override
  State<SavedPgsScreen> createState() => _SavedPgsScreenState();
}

class _SavedPgsScreenState extends State<SavedPgsScreen> {
  List<PGListingWithScore> _savedStays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedStays();
  }

  Future<void> _loadSavedStays() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteNames = prefs.getStringList('favorite_pg_names') ?? [];

    // Gather all potential sources
    List<PGListing> allPossibleListings = [];
    allPossibleListings.addAll(allPgListings);
    
    // Add dynamic ones near current office area
    allPossibleListings.addAll(generateDynamicMockPgs(
      widget.officeArea,
      widget.officeLat,
      widget.officeLng,
    ));

    // Filter unique matches
    final Map<String, PGListing> uniqueStays = {};
    for (var pg in allPossibleListings) {
      if (favoriteNames.contains(pg.name)) {
        uniqueStays[pg.name] = pg;
      }
    }

    final List<PGListingWithScore> savedStays = [];
    for (var pg in uniqueStays.values) {
      final distance = GeoUtils.calculateDistanceKm(widget.officeLat, widget.officeLng, pg.lat, pg.lng);
      final commuteTime = GeoUtils.calculateCommuteMinutes(distance);

      // Matches list
      List<String> matches = ['Saved stay'];
      if (pg.foodIncluded) matches.add('Food Included');
      if (pg.hasAc) matches.add('AC Room');

      savedStays.add(PGListingWithScore(
        pg: pg,
        score: 90, // Static high match score reference
        distance: distance,
        commuteMinutes: commuteTime,
        matches: matches,
        mismatches: [],
        personalityTag: 'Saved Stay',
        lifestyleTag: 'Verified Room',
      ));
    }

    setState(() {
      _savedStays = savedStays;
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteNames = prefs.getStringList('favorite_pg_names') ?? [];
    favoriteNames.remove(name);
    await prefs.setStringList('favorite_pg_names', favoriteNames);
    
    setState(() {
      _savedStays.removeWhere((x) => x.pg.name == name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Saved Stays'),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
            : _savedStays.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite_border_rounded, size: 72, color: AppTheme.textMuted),
                          const SizedBox(height: 18),
                          const Text(
                            'No Saved Stays Yet',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap the heart icon on any PG card to save it here for quick access later.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _savedStays.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = _savedStays[index];
                      final walkTime = (item.distance * 12).round().clamp(1, 120);
                      final bikeTime = (item.distance * 4).round().clamp(1, 40);
                      final driveTime = (item.distance * 2).round().clamp(1, 20);

                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          border: Border.all(color: AppTheme.borderTranslucent),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
                                  child: Image.network(
                                    item.pg.imageUrl,
                                    height: 130,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, o, s) => Container(
                                      height: 130,
                                      color: AppTheme.secondaryBackground,
                                      child: const Icon(Icons.home_work_rounded, color: Colors.white24, size: 48),
                                    ),
                                  ),
                                ),
                                // Remove favorite button
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => _removeFavorite(item.pg.name),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.favorite_rounded, color: Colors.red, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '₹${item.pg.rent}/mo',
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                      ),
                                      Text(
                                        '${item.distance.toStringAsFixed(1)} km away',
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Commute rows
                                  Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Row(children: [
                                         const Icon(Icons.directions_walk_rounded, color: AppTheme.accentColorLight, size: 14),
                                         const SizedBox(width: 4),
                                         Text('${walkTime}m walk', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                       ]),
                                       Row(children: [
                                         const Icon(Icons.directions_bike_rounded, color: AppTheme.accentColorLight, size: 14),
                                         const SizedBox(width: 4),
                                         Text('${bikeTime}m bike', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                       ]),
                                       Row(children: [
                                         const Icon(Icons.directions_car_rounded, color: AppTheme.accentColorLight, size: 14),
                                         const SizedBox(width: 4),
                                         Text('${driveTime}m drive', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                       ]),
                                     ],
                                   ),
                                   const SizedBox(height: 16),
                                   Container(
                                     height: 40,
                                     width: double.infinity,
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
                                               officeLat: widget.officeLat,
                                               officeLng: widget.officeLng,
                                             ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.pillRadius)),
                                        ),
                                        child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    )
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
