import 'package:flutter/material.dart';

import '../models/neighborhood.dart';

class CompareScreen extends StatelessWidget {
  final Neighborhood left;
  final Neighborhood right;

  const CompareScreen({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090B19),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Compare Neighborhoods', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const Text('Side-by-side comparison', style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildCandidateHeader('Candidate 1', left)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildCandidateHeader('Candidate 2', right)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildComparisonRow(
                title: 'Commute Time',
                icon: Icons.schedule,
                val1: '${left.commuteMinutes} min',
                val2: '${right.commuteMinutes} min',
                isLeftBetter: left.commuteMinutes < right.commuteMinutes,
              ),
              const SizedBox(height: 24),
              _buildComparisonRow(
                title: 'Safety Score',
                icon: Icons.shield_outlined,
                val1: '${left.safetyScore}/10',
                val2: '${right.safetyScore}/10',
                isLeftBetter: left.safetyScore > right.safetyScore,
              ),
              const SizedBox(height: 24),
              _buildComparisonRow(
                title: 'Avg Rent',
                icon: Icons.currency_rupee,
                val1: '₹${left.averageRent ~/ 1000}k',
                val2: '₹${right.averageRent ~/ 1000}k',
                isLeftBetter: left.averageRent < right.averageRent,
              ),
              const SizedBox(height: 24),
              _buildComparisonRow(
                title: 'AI Match Score',
                icon: Icons.auto_graph,
                val1: '${left.matchScore}%',
                val2: '${right.matchScore}%',
                isLeftBetter: left.matchScore > right.matchScore,
              ),
              const SizedBox(height: 24),
              _buildComparisonRow(
                title: 'Vibe',
                icon: Icons.local_cafe_outlined,
                val1: left.vibe,
                val2: right.vibe,
                isLeftBetter: null, // neutral comparison
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCandidateHeader(String badge, Neighborhood item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10142A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2D3161)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF202652),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(badge, style: const TextStyle(color: Color(0xFF8C88FF), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          Text(item.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(item.tagline, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildComparisonRow({
    required String title,
    required IconData icon,
    required String val1,
    required String val2,
    required bool? isLeftBetter,
  }) {
    final leftColor = isLeftBetter == true ? const Color(0xFF143026) : const Color(0xFF10142A);
    final leftBorder = isLeftBetter == true ? const Color(0xFF1D5A3C) : const Color(0xFF2D3161);
    final leftTextColor = isLeftBetter == true ? const Color(0xFF4ADE80) : Colors.white;

    final rightColor = isLeftBetter == false ? const Color(0xFF143026) : const Color(0xFF10142A);
    final rightBorder = isLeftBetter == false ? const Color(0xFF1D5A3C) : const Color(0xFF2D3161);
    final rightTextColor = isLeftBetter == false ? const Color(0xFF4ADE80) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.white54),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: leftColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: leftBorder),
                ),
                child: Text(val1, style: TextStyle(color: leftTextColor, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: rightColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: rightBorder),
                ),
                child: Text(val2, style: TextStyle(color: rightTextColor, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
