import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'results_screen.dart';

class CompareScreen extends StatelessWidget {
  final List<PGListingWithScore> pgs;
  final double officeLat;
  final double officeLng;

  const CompareScreen({
    super.key,
    required this.pgs,
    required this.officeLat,
    required this.officeLng,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Identify best values for highlighting
    int bestRentIndex = -1;
    int bestDistanceIndex = -1;
    int bestScoreIndex = -1;
    int bestRatingIndex = -1;

    if (pgs.isNotEmpty) {
      int minRent = pgs.first.pg.rent;
      double minDistance = pgs.first.distance;
      int maxScore = pgs.first.score;
      double maxRating = pgs.first.pg.rating;

      bestRentIndex = 0;
      bestDistanceIndex = 0;
      bestScoreIndex = 0;
      bestRatingIndex = 0;

      for (int i = 1; i < pgs.length; i++) {
        if (pgs[i].pg.rent < minRent) {
          minRent = pgs[i].pg.rent;
          bestRentIndex = i;
        }
        if (pgs[i].distance < minDistance) {
          minDistance = pgs[i].distance;
          bestDistanceIndex = i;
        }
        if (pgs[i].score > maxScore) {
          maxScore = pgs[i].score;
          bestScoreIndex = i;
        }
        if (pgs[i].pg.rating > maxRating) {
          maxRating = pgs[i].pg.rating;
          bestRatingIndex = i;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Compare Stays', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text('Comparing ${pgs.length} selected PGs', style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fixed Labels Column (Left)
                      _buildLabelsColumn(),

                      // Scrollable Stays Columns (Right)
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(pgs.length, (index) {
                              final item = pgs[index];
                              return _buildStayValueColumn(
                                item,
                                index,
                                isBestRent: index == bestRentIndex,
                                isBestDistance: index == bestDistanceIndex,
                                isBestScore: index == bestScoreIndex,
                                isBestRating: index == bestRatingIndex,
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelsColumn() {
    return Container(
      width: 130,
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCellLabel('Stay Details', height: 90),
          _buildCellLabel('Room Preview', height: 100),
          _buildCellLabel('Match Rate', height: 60),
          _buildCellLabel('Monthly Rent', height: 60),
          _buildCellLabel('Distance', height: 60),
          _buildCellLabel('Commute Time', height: 60),
          _buildCellLabel('Rating', height: 60),
          _buildCellLabel('Gender Target', height: 60),
          _buildCellLabel('Food Included', height: 60),
          _buildCellLabel('AC / Non-AC', height: 60),
          _buildCellLabel('🚽 Attached Washroom', height: 50),
          _buildCellLabel('📶 Wi-Fi', height: 50),
          _buildCellLabel('🧺 Laundry', height: 50),
          _buildCellLabel('🏋️ Gym', height: 50),
          _buildCellLabel('🚗 Parking', height: 50),
          _buildCellLabel('🔒 Security', height: 50),
          _buildCellLabel('Other Features', height: 80),
        ],
      ),
    );
  }

  Widget _buildCellLabel(String label, {required double height}) {
    return Container(
      height: height,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderTranslucent, width: 1)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStayValueColumn(
    PGListingWithScore item,
    int index, {
    required bool isBestRent,
    required bool isBestDistance,
    required bool isBestScore,
    required bool isBestRating,
  }) {
    final hasWifi = item.pg.amenities.any((a) => a.toLowerCase().contains('wi-fi'));
    final hasLaundry = item.pg.amenities.any((a) => a.toLowerCase().contains('laundry') || a.toLowerCase().contains('washing'));
    final hasGym = item.pg.amenities.any((a) => a.toLowerCase().contains('gym'));
    final hasParking = item.pg.amenities.any((a) => a.toLowerCase().contains('parking'));
    final hasSecurity = item.pg.amenities.any((a) => a.toLowerCase().contains('security'));
    final hasWashroom = item.pg.amenities.any((a) => a.toLowerCase().contains('bathroom') || a.toLowerCase().contains('washroom'));

    final otherAmenities = item.pg.amenities
        .where((a) =>
            !a.toLowerCase().contains('wi-fi') &&
            !a.toLowerCase().contains('laundry') &&
            !a.toLowerCase().contains('washing') &&
            !a.toLowerCase().contains('gym') &&
            !a.toLowerCase().contains('parking') &&
            !a.toLowerCase().contains('security') &&
            !a.toLowerCase().contains('bathroom') &&
            !a.toLowerCase().contains('washroom'))
        .join(', ');

    return Container(
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: index == 0
            ? const BorderRadius.horizontal(left: Radius.circular(16))
            : index == pgs.length - 1
                ? const BorderRadius.horizontal(right: Radius.circular(16))
                : BorderRadius.zero,
      ),
      child: Column(
        children: [
          // Stay Details Header
          Container(
            height: 90,
            padding: const EdgeInsets.all(10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderTranslucent)),
            ),
            child: Text(
              item.pg.name,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Preview Photo
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderTranslucent)),
            ),
            child: Image.network(
              item.pg.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (c, o, s) => const Icon(Icons.home_work_rounded, color: Colors.white24),
            ),
          ),

          // Match Rate (Highlight if Best)
          _buildComparisonCell(
            '${item.score}% Match',
            height: 60,
            isBest: isBestScore,
          ),

          // Rent (Highlight if Best)
          _buildComparisonCell(
            '₹${item.pg.rent}/mo',
            height: 60,
            isBest: isBestRent,
          ),

          // Distance (Highlight if Best)
          _buildComparisonCell(
            '${item.distance.toStringAsFixed(1)} km',
            height: 60,
            isBest: isBestDistance,
          ),

          // Commute Time
          _buildComparisonCell(
            '${item.commuteMinutes} min',
            height: 60,
          ),

          // Rating (Highlight if Best)
          _buildComparisonCell(
            '${item.pg.rating} ⭐',
            height: 60,
            isBest: isBestRating,
          ),

          // Gender Target
          _buildComparisonCell(
            item.pg.gender,
            height: 60,
          ),

          // Food Option
          _buildComparisonCell(
            item.pg.foodIncluded ? 'Included' : 'Not Included',
            height: 60,
          ),

          // AC Option
          _buildComparisonCell(
            item.pg.hasAc ? 'AC Room' : 'Non-AC',
            height: 60,
          ),

          // Attached Washroom Check
          _buildIconCell(hasWashroom, height: 50),

          // Wi-Fi Check
          _buildIconCell(hasWifi, height: 50),

          // Laundry Check
          _buildIconCell(hasLaundry, height: 50),

          // Gym Check
          _buildIconCell(hasGym, height: 50),

          // Parking Check
          _buildIconCell(hasParking, height: 50),

          // Security Check
          _buildIconCell(hasSecurity, height: 50),

          // Other amenities list
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderTranslucent)),
            ),
            child: Text(
              otherAmenities.isEmpty ? 'None' : otherAmenities,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCell(
    String value, {
    required double height,
    bool isBest = false,
  }) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isBest ? AppTheme.accentColor.withValues(alpha: 0.12) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderTranslucent),
          left: isBest ? BorderSide(color: AppTheme.accentColorLight, width: 1.5) : BorderSide.none,
          right: isBest ? BorderSide(color: AppTheme.accentColorLight, width: 1.5) : BorderSide.none,
        ),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isBest ? AppTheme.accentColorLight : Colors.white,
          fontWeight: isBest ? FontWeight.w900 : FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildIconCell(bool active, {required double height}) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderTranslucent)),
      ),
      child: Icon(
        active ? Icons.check_circle_rounded : Icons.cancel_outlined,
        color: active ? const Color(0xFF4ADE80) : Colors.white24,
        size: 18,
      ),
    );
  }
}
