import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/survey_criteria.dart';
import '../utils/app_theme.dart';
import 'chat_onboarding_screen.dart';
import 'results_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final List<_Star> _stars = [];
  final double _parallaxWidth = 800.0; // The virtual width where the parallax pattern repeats

  bool _hasSavedPreferences = false;
  String _savedOfficeName = '';
  String? _savedBudget;
  String? _savedOfficeArea;
  String? _savedOfficeLocation;
  double? _savedOfficeLat;
  double? _savedOfficeLng;
  String? _savedGender;
  bool? _savedFoodIncluded;
  String? _savedDistancePref;
  bool? _savedAcRequired;

  Future<void> _checkSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final officeName = prefs.getString('saved_office_location');
    if (officeName != null && officeName.isNotEmpty) {
      setState(() {
        _hasSavedPreferences = true;
        _savedOfficeName = officeName.split(',').first.trim();
        _savedBudget = prefs.getString('saved_budget');
        _savedOfficeArea = prefs.getString('saved_office_area');
        _savedOfficeLocation = prefs.getString('saved_office_location');
        _savedOfficeLat = prefs.getDouble('saved_office_lat');
        _savedOfficeLng = prefs.getDouble('saved_office_lng');
        _savedGender = prefs.getString('saved_gender');
        _savedFoodIncluded = prefs.getBool('saved_food_included');
        _savedDistancePref = prefs.getString('saved_distance_pref');
        _savedAcRequired = prefs.getBool('saved_ac_required');
      });
    }
  }

  void _resumeSavedSearch() {
    final criteria = SurveyCriteria(
      budget: _savedBudget ?? 'All',
      officeArea: _savedOfficeArea ?? '',
      officeLocation: _savedOfficeLocation ?? '',
      officeLat: _savedOfficeLat ?? 12.9352,
      officeLng: _savedOfficeLng ?? 77.6245,
      lifestyle: 'Quiet Comfort',
      commute: 'Any',
      gender: _savedGender ?? 'Co-living',
      foodIncluded: _savedFoodIncluded ?? true,
      distancePref: _savedDistancePref ?? 'Any (<10km)',
      acRequired: _savedAcRequired ?? true,
    );

    final navigator = Navigator.of(context);
    navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(criteria: criteria),
      ),
    ).then((shouldReset) {
      if (shouldReset == true) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => const ChatOnboardingScreen(),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _checkSavedPreferences();
    // 12-second infinite loop for smooth continuous parallax scrolling
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Generate static stars with random positions, sizes, and twinkle speeds
    final random = math.Random();
    for (int i = 0; i < 40; i++) {
      _stars.add(_Star(
        xRatio: random.nextDouble(),
        yRatio: random.nextDouble() * 0.45, // Keep stars in the upper half of the screen
        size: random.nextDouble() * 2.5 + 1.0,
        twinkleSpeed: random.nextDouble() * 3.0 + 1.0,
        twinklePhase: random.nextDouble() * math.pi,
      ));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ThemeBackground(
        showGlows: true,
        child: Stack(
          children: [

          // 2. Twinkling Stars Background Layer
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                painter: _StarPainter(stars: _stars, animationValue: _animationController.value),
                size: Size.infinite,
              );
            },
          ),

          // 3. Stationary Glowing Crescent Moon
          Positioned(
            top: 70,
            right: 50,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 2),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: (value * 0.85).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.9 + (value * 0.1),
                    child: child,
                  ),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Soft outer glow of the moon
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFEFA7).withValues(alpha: 0.12),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  // Moon body
                  CustomPaint(
                    size: const Size(50, 50),
                    painter: _CrescentMoonPainter(),
                  ),
                ],
              ),
            ),
          ),

          // 4. Parallax City Skylines
          // Background Layer: Distant Skyscrapers (Slowest speed: multiplier 0.25)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SkylinePainter(
                    scrollOffset: _animationController.value * _parallaxWidth,
                    repeatWidth: _parallaxWidth,
                    layerType: _SkylineLayer.background,
                    color: AppTheme.cardBackground.withValues(alpha: 0.35),
                  ),
                );
              },
            ),
          ),

          // Midground Layer: Apartments & Mid-sized Blocks (Medium speed: multiplier 0.55)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SkylinePainter(
                    scrollOffset: _animationController.value * _parallaxWidth * 2.2,
                    repeatWidth: _parallaxWidth,
                    layerType: _SkylineLayer.midground,
                    color: AppTheme.cardBackground.withValues(alpha: 0.65),
                  ),
                );
              },
            ),
          ),

          // Foreground Layer: Cozy Houses, Streetlamps, & Trees (Fastest speed: multiplier 1.0)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SkylinePainter(
                    scrollOffset: _animationController.value * _parallaxWidth * 4.0,
                    repeatWidth: _parallaxWidth,
                    layerType: _SkylineLayer.foreground,
                    color: AppTheme.primaryBackground,
                  ),
                );
              },
            ),
          ),

          // 5. Hero UI Layout
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Upper Brand / Header Section
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, -30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6F5CFF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF6F5CFF).withValues(alpha: 0.3)),
                            ),
                            child: const Icon(
                              Icons.location_city_rounded,
                              color: Color(0xFF8C88FF),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'CityEase',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center Glassmorphic Card
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeOutQuad,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.95 + (value * 0.05),
                          child: child,
                        ),
                      );
                    },
                    child: GlassCard(
                      borderRadius: AppTheme.cardRadius,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pulse-glowing location badge
                          _GlowingBadge(),
                          const SizedBox(height: 20),
                          const Text(
                            'Smart Match Your\nPerfect Stay',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              height: 1.25,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Skip the endless scrolling. Give your budget and commute constraints, and let our AI locate your ideal neighborhood and PG.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          if (_hasSavedPreferences) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                                border: Border.all(color: AppTheme.borderTranslucent),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.history_rounded, color: AppTheme.accentColorLight, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Welcome Back!',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Resume searching PGs near\n"$_savedOfficeName"?',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SpringButton(
                                        onTap: _resumeSavedSearch,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentColor,
                                            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                                            boxShadow: AppTheme.glowShadow,
                                          ),
                                          child: const Text('Resume Search', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SpringButton(
                                        onTap: () {
                                          setState(() {
                                            _hasSavedPreferences = false;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: AppTheme.borderTranslucent),
                                            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                                          ),
                                          child: const Text('New Search', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Button Section
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 1600),
                      curve: Curves.easeOutQuint,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AnimatedGetStartedButton(
                            onPressed: () {
                              // Beautiful scale transition into ChatOnboardingScreen
                              Navigator.of(context).pushReplacement(
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 700),
                                  reverseTransitionDuration: const Duration(milliseconds: 500),
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      const ChatOnboardingScreen(),
                                  transitionsBuilder:
                                      (context, animation, secondaryAnimation, child) {
                                    final scaleTween = Tween<double>(begin: 0.93, end: 1.0).animate(
                                      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                                    );
                                    final fadeTween = Tween<double>(begin: 0.0, end: 1.0).animate(
                                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                                    );
                                    return FadeTransition(
                                      opacity: fadeTween,
                                      child: ScaleTransition(
                                        scale: scaleTween,
                                        child: child,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.shield_outlined, color: Colors.white38, size: 14),
                              SizedBox(width: 6),
                              Text(
                                '100% Verified Accommodation Stays',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

// -----------------------------------------------------------------------------
// Stars data & painting
// -----------------------------------------------------------------------------
class _Star {
  final double xRatio;
  final double yRatio;
  final double size;
  final double twinkleSpeed;
  final double twinklePhase;

  _Star({
    required this.xRatio,
    required this.yRatio,
    required this.size,
    required this.twinkleSpeed,
    required this.twinklePhase,
  });
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double animationValue;

  _StarPainter({required this.stars, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (final star in stars) {
      // Calculate a dynamic twinkling opacity using a sine wave
      final time = animationValue * 2 * math.pi;
      final opacity = (math.sin(time * star.twinkleSpeed + star.twinklePhase) + 1.0) / 2.0;
      
      paint.color = Colors.white.withValues(alpha: 0.15 + (opacity * 0.75));

      final x = star.xRatio * size.width;
      final y = star.yRatio * size.height;

      // Draw a soft glowing dot
      canvas.drawCircle(Offset(x, y), star.size, paint);
      
      // For larger stars, add a subtle cross-glow halo
      if (star.size > 2.2 && opacity > 0.7) {
        final haloPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.25 * opacity)
          ..strokeWidth = 0.5;
        
        canvas.drawLine(Offset(x - 4, y), Offset(x + 4, y), haloPaint);
        canvas.drawLine(Offset(x, y - 4), Offset(x, y + 4), haloPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) => true;
}

// -----------------------------------------------------------------------------
// Crescent Moon Painting
// -----------------------------------------------------------------------------
class _CrescentMoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final moonPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFAD6), Color(0xFFFFDF7A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Create the outer moon circle path
    final moonPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    // Cut a circular bite out of it to make a gorgeous crescent
    final shadowPath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(center.dx - radius * 0.45, center.dy - radius * 0.15),
        radius: radius * 0.95,
      ));

    final crescentPath = Path.combine(
      PathOperation.difference,
      moonPath,
      shadowPath,
    );

    canvas.drawPath(crescentPath, moonPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// Parallax City Skyline Painter
// -----------------------------------------------------------------------------
enum _SkylineLayer { background, midground, foreground }

class _SkylinePainter extends CustomPainter {
  final double scrollOffset;
  final double repeatWidth;
  final _SkylineLayer layerType;
  final Color color;

  _SkylinePainter({
    required this.scrollOffset,
    required this.repeatWidth,
    required this.layerType,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw the scrolling city across the entire width.
    // We draw multiple tiles adjacent to each other to guarantee seamless infinite scrolling.
    double startX = -(scrollOffset % repeatWidth);
    
    while (startX < size.width) {
      _drawSingleTile(canvas, size, startX, paint);
      startX += repeatWidth;
    }
  }

  void _drawSingleTile(Canvas canvas, Size size, double startX, Paint mainPaint) {
    final path = Path();
    final double horizonY = size.height * 0.92; // Baseline height of the skyline in the canvas

    // Choose different skyline shapes based on depth layer
    switch (layerType) {
      case _SkylineLayer.background:
        // Distant Skyscrapers silhouette
        path.moveTo(startX, size.height);
        path.lineTo(startX, horizonY - 140);
        path.lineTo(startX + 60, horizonY - 140);
        path.lineTo(startX + 60, horizonY - 80);
        
        // Tall skyscraper spire
        path.lineTo(startX + 100, horizonY - 80);
        path.lineTo(startX + 100, horizonY - 210); // Spire peak
        path.lineTo(startX + 101, horizonY - 210);
        path.lineTo(startX + 101, horizonY - 170);
        path.lineTo(startX + 130, horizonY - 170);
        path.lineTo(startX + 130, horizonY - 100);

        // Medium block
        path.lineTo(startX + 180, horizonY - 100);
        path.lineTo(startX + 180, horizonY - 130);
        path.lineTo(startX + 240, horizonY - 130);
        path.lineTo(startX + 240, horizonY - 60);

        // Classic stepped skyscraper
        path.lineTo(startX + 300, horizonY - 60);
        path.lineTo(startX + 300, horizonY - 150);
        path.lineTo(startX + 315, horizonY - 150);
        path.lineTo(startX + 315, horizonY - 180);
        path.lineTo(startX + 345, horizonY - 180);
        path.lineTo(startX + 345, horizonY - 150);
        path.lineTo(startX + 360, horizonY - 150);
        path.lineTo(startX + 360, horizonY - 90);

        // Slanted-roof tower
        path.lineTo(startX + 420, horizonY - 90);
        path.lineTo(startX + 450, horizonY - 190); // Slant top
        path.lineTo(startX + 500, horizonY - 190);
        path.lineTo(startX + 500, horizonY - 100);

        // Blocky high-rise
        path.lineTo(startX + 560, horizonY - 100);
        path.lineTo(startX + 560, horizonY - 160);
        path.lineTo(startX + 620, horizonY - 160);
        path.lineTo(startX + 620, horizonY - 70);

        // Wide tower with antenna
        path.lineTo(startX + 670, horizonY - 70);
        path.lineTo(startX + 670, horizonY - 120);
        path.lineTo(startX + 710, horizonY - 120);
        path.lineTo(startX + 710, horizonY - 180); // Antenna base
        path.lineTo(startX + 711, horizonY - 220); // Antenna tip
        path.lineTo(startX + 712, horizonY - 180);
        path.lineTo(startX + 750, horizonY - 120);
        path.lineTo(startX + 800, horizonY - 120);
        
        path.lineTo(startX + repeatWidth, size.height);
        canvas.drawPath(path, mainPaint);
        
        // Draw very faint glowing windows on distant skyscrapers
        final windowPaint = Paint()..color = const Color(0xFFFFEA9F).withValues(alpha: 0.08);
        canvas.drawRect(Rect.fromLTWH(startX + 20, horizonY - 120, 8, 12), windowPaint);
        canvas.drawRect(Rect.fromLTWH(startX + 20, horizonY - 100, 8, 12), windowPaint);
        canvas.drawRect(Rect.fromLTWH(startX + 40, horizonY - 110, 8, 12), windowPaint);
        canvas.drawRect(Rect.fromLTWH(startX + 322, horizonY - 130, 16, 8), windowPaint);
        canvas.drawRect(Rect.fromLTWH(startX + 465, horizonY - 160, 10, 20), windowPaint);
        canvas.drawRect(Rect.fromLTWH(startX + 580, horizonY - 140, 8, 8), windowPaint);
        canvas.drawRect(Rect.fromLTWH(startX + 595, horizonY - 140, 8, 8), windowPaint);
        break;

      case _SkylineLayer.midground:
        // Medium apartments and factories/offices
        path.moveTo(startX, size.height);
        path.lineTo(startX, horizonY - 70);
        path.lineTo(startX + 50, horizonY - 70);
        
        // High-density housing structure
        path.lineTo(startX + 50, horizonY - 100);
        path.lineTo(startX + 120, horizonY - 100);
        path.lineTo(startX + 120, horizonY - 70);

        // Cozy pitched apartments
        path.lineTo(startX + 170, horizonY - 70);
        path.lineTo(startX + 195, horizonY - 95); // Peak
        path.lineTo(startX + 220, horizonY - 70);
        path.lineTo(startX + 250, horizonY - 70);
        path.lineTo(startX + 250, horizonY - 45);
        path.lineTo(startX + 310, horizonY - 45);
        path.lineTo(startX + 310, horizonY - 85);

        // Office block
        path.lineTo(startX + 360, horizonY - 85);
        path.lineTo(startX + 410, horizonY - 85);
        path.lineTo(startX + 410, horizonY - 55);

        // Tall condo structure
        path.lineTo(startX + 460, horizonY - 55);
        path.lineTo(startX + 460, horizonY - 115);
        path.lineTo(startX + 530, horizonY - 115);
        path.lineTo(startX + 530, horizonY - 80);

        // Tree/shrub transition
        path.lineTo(startX + 570, horizonY - 80);
        path.lineTo(startX + 570, horizonY - 50);
        
        // Flat apartments
        path.lineTo(startX + 650, horizonY - 50);
        path.lineTo(startX + 650, horizonY - 90);
        path.lineTo(startX + 710, horizonY - 90);
        path.lineTo(startX + 710, horizonY - 60);
        
        path.lineTo(startX + repeatWidth, size.height);
        canvas.drawPath(path, mainPaint);

        // Draw soft glowing yellow/orange windows for midground
        final midWindowPaint = Paint()..color = const Color(0xFFFFD483).withValues(alpha: 0.18);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(startX + 70, horizonY - 85, 10, 10), const Radius.circular(2)), midWindowPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(startX + 95, horizonY - 85, 10, 10), const Radius.circular(2)), midWindowPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(startX + 270, horizonY - 35, 8, 12), const Radius.circular(2)), midWindowPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(startX + 290, horizonY - 35, 8, 12), const Radius.circular(2)), midWindowPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(startX + 480, horizonY - 100, 12, 8), const Radius.circular(1)), midWindowPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(startX + 505, horizonY - 100, 12, 8), const Radius.circular(1)), midWindowPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(startX + 480, horizonY - 85, 12, 8), const Radius.circular(1)), midWindowPaint);
        break;

      case _SkylineLayer.foreground:
        // Highly-detailed cozy houses, pitched roofs, trees, streetlamps
        path.moveTo(startX, size.height);
        path.lineTo(startX, horizonY - 35);
        
        // Cozy House 1 with pitched roof & chimney
        path.lineTo(startX + 20, horizonY - 35);
        path.lineTo(startX + 20, horizonY - 45); // Chimney
        path.lineTo(startX + 28, horizonY - 45);
        path.lineTo(startX + 28, horizonY - 39);
        path.lineTo(startX + 45, horizonY - 55); // Left roof slant
        path.lineTo(startX + 70, horizonY - 30); // Right roof slant
        path.lineTo(startX + 90, horizonY - 30);
        path.lineTo(startX + 90, horizonY - 45); // Gable attachment
        path.lineTo(startX + 115, horizonY - 70); // Gable peak
        path.lineTo(startX + 140, horizonY - 45);
        path.lineTo(startX + 150, horizonY - 45);
        path.lineTo(startX + 150, horizonY - 20);

        // Circular Foreground Tree
        _drawTree(canvas, startX + 180, horizonY - 15, 25, mainPaint);
        
        path.lineTo(startX + 210, horizonY - 20);
        
        // House 2: Modern geometric cottage
        path.lineTo(startX + 220, horizonY - 20);
        path.lineTo(startX + 220, horizonY - 60);
        path.lineTo(startX + 270, horizonY - 75); // Slanted modern roof
        path.lineTo(startX + 285, horizonY - 75);
        path.lineTo(startX + 285, horizonY - 15);

        // Dense evergreen pine trees
        _drawPineTree(canvas, startX + 320, horizonY, 35, mainPaint);
        _drawPineTree(canvas, startX + 345, horizonY, 45, mainPaint);

        path.lineTo(startX + 370, horizonY - 15);
        
        // House 3: Duplex with double gable roofs
        path.lineTo(startX + 380, horizonY - 15);
        path.lineTo(startX + 380, horizonY - 45);
        path.lineTo(startX + 405, horizonY - 65); // Roof 1 peak
        path.lineTo(startX + 430, horizonY - 45);
        path.lineTo(startX + 455, horizonY - 65); // Roof 2 peak
        path.lineTo(startX + 480, horizonY - 45);
        path.lineTo(startX + 500, horizonY - 45);
        path.lineTo(startX + 500, horizonY - 10);

        // Cozy picket fence
        _drawPicketFence(canvas, startX + 510, horizonY, 6, 40, mainPaint);

        path.lineTo(startX + 560, horizonY - 10);

        // House 4: Tiny cottage & streetlamp
        path.lineTo(startX + 575, horizonY - 10);
        path.lineTo(startX + 575, horizonY - 35);
        path.lineTo(startX + 595, horizonY - 55); // Cottage peak
        path.lineTo(startX + 615, horizonY - 35);
        path.lineTo(startX + 630, horizonY - 35);
        path.lineTo(startX + 630, horizonY - 5);

        // Streetlamp & Tree
        _drawStreetLamp(canvas, startX + 660, horizonY, mainPaint);
        _drawTree(canvas, startX + 710, horizonY - 10, 28, mainPaint);

        path.lineTo(startX + 750, horizonY - 10);
        path.lineTo(startX + repeatWidth, horizonY - 35);
        path.lineTo(startX + repeatWidth, size.height);
        
        canvas.drawPath(path, mainPaint);

        // Warm, glowing windows in the foreground (looks extremely welcoming!)
        final glowWindowPaint = Paint()..color = const Color(0xFFFFDE82);
        final glowShaderPaint = Paint()
          ..color = const Color(0xFFFFDE82).withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

        // House 1 Window
        final rectW1 = Rect.fromLTWH(startX + 102, horizonY - 40, 12, 12);
        canvas.drawRect(rectW1, glowShaderPaint);
        canvas.drawRect(rectW1, glowWindowPaint);
        
        // House 2 Window (Large modern glowing glass panel)
        final rectW2 = Rect.fromLTWH(startX + 235, horizonY - 52, 22, 28);
        canvas.drawRect(rectW2, glowShaderPaint);
        canvas.drawRect(rectW2, glowWindowPaint);
        // Draw window panes details
        final panePaint = Paint()..color = color..strokeWidth = 2;
        canvas.drawLine(Offset(startX + 246, horizonY - 52), Offset(startX + 246, horizonY - 24), panePaint);
        canvas.drawLine(Offset(startX + 235, horizonY - 38), Offset(startX + 257, horizonY - 38), panePaint);

        // House 3 Windows (multiple)
        final rectW3a = Rect.fromLTWH(startX + 395, horizonY - 40, 10, 12);
        final rectW3b = Rect.fromLTWH(startX + 445, horizonY - 40, 10, 12);
        canvas.drawRect(rectW3a, glowShaderPaint);
        canvas.drawRect(rectW3a, glowWindowPaint);
        canvas.drawRect(rectW3b, glowShaderPaint);
        canvas.drawRect(rectW3b, glowWindowPaint);

        // House 4 Window (Circular window under attic peak)
        final circleCenter = Offset(startX + 595, horizonY - 30);
        canvas.drawCircle(circleCenter, 5, glowShaderPaint);
        canvas.drawCircle(circleCenter, 5, glowWindowPaint);

        // Draw streetlamp glow
        canvas.drawCircle(Offset(startX + 660, horizonY - 48), 6, Paint()..color = const Color(0xFFFFF2C2));
        canvas.drawCircle(Offset(startX + 660, horizonY - 48), 12, Paint()..color = const Color(0xFFFFEA8F).withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        break;
    }
  }

  void _drawTree(Canvas canvas, double cx, double cy, double radius, Paint paint) {
    canvas.drawCircle(Offset(cx, cy - radius * 0.4), radius, paint);
    canvas.drawCircle(Offset(cx - radius * 0.4, cy), radius * 0.8, paint);
    canvas.drawCircle(Offset(cx + radius * 0.4, cy), radius * 0.8, paint);
    // Trunk
    canvas.drawRect(Rect.fromLTWH(cx - 3, cy, 6, 40), paint);
  }

  void _drawPineTree(Canvas canvas, double bottomX, double bottomY, double height, Paint paint) {
    final pinePath = Path()
      ..moveTo(bottomX, bottomY - height)
      // Top segment
      ..lineTo(bottomX - 10, bottomY - height + 15)
      ..lineTo(bottomX - 5, bottomY - height + 15)
      // Mid segment
      ..lineTo(bottomX - 18, bottomY - height + 32)
      ..lineTo(bottomX - 8, bottomY - height + 32)
      // Bottom segment
      ..lineTo(bottomX - 25, bottomY)
      ..lineTo(bottomX + 25, bottomY)
      ..lineTo(bottomX + 8, bottomY - height + 32)
      ..lineTo(bottomX + 18, bottomY - height + 32)
      ..lineTo(bottomX + 5, bottomY - height + 15)
      ..lineTo(bottomX + 10, bottomY - height + 15)
      ..close();
    canvas.drawPath(pinePath, paint);
  }

  void _drawPicketFence(Canvas canvas, double startX, double horizonY, double height, double width, Paint paint) {
    final fenceY = horizonY - 14;
    // Draw two horizontal support bars
    canvas.drawRect(Rect.fromLTWH(startX, fenceY + 3, width, 2), paint);
    canvas.drawRect(Rect.fromLTWH(startX, fenceY + 9, width, 2), paint);
    // Draw vertical pickets
    double x = startX + 2;
    while (x < startX + width) {
      final picket = Path()
        ..moveTo(x, horizonY)
        ..lineTo(x, fenceY + 2)
        ..lineTo(x + 2, fenceY) // pointed top
        ..lineTo(x + 4, fenceY + 2)
        ..lineTo(x + 4, horizonY)
        ..close();
      canvas.drawPath(picket, paint);
      x += 8;
    }
  }

  void _drawStreetLamp(Canvas canvas, double cx, double horizonY, Paint paint) {
    // Post
    canvas.drawRect(Rect.fromLTWH(cx - 2, horizonY - 45, 4, 45), paint);
    // Arm
    final armPath = Path()
      ..moveTo(cx - 2, horizonY - 45)
      ..quadraticBezierTo(cx - 10, horizonY - 48, cx - 10, horizonY - 40)
      ..lineTo(cx - 8, horizonY - 40)
      ..quadraticBezierTo(cx - 8, horizonY - 45, cx + 2, horizonY - 43)
      ..close();
    canvas.drawPath(armPath, paint);
    // Cap
    canvas.drawRect(Rect.fromLTWH(cx - 12, horizonY - 48, 6, 2), paint);
  }

  @override
  bool shouldRepaint(covariant _SkylinePainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset ||
      oldDelegate.layerType != layerType ||
      oldDelegate.color != color;
}

// -----------------------------------------------------------------------------
// Glowing Pin Badge Widget
// -----------------------------------------------------------------------------
class _GlowingBadge extends StatefulWidget {
  @override
  State<_GlowingBadge> createState() => _GlowingBadgeState();
}

class _GlowingBadgeState extends State<_GlowingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scaleValue = 1.0 + (_pulseController.value * 0.08);
        final glowOpacity = 0.2 + (_pulseController.value * 0.4);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Pulsing Glow halo
            Transform.scale(
              scale: scaleValue * 1.35,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6F5CFF).withValues(alpha: 0.08 * glowOpacity),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6F5CFF).withValues(alpha: 0.25 * glowOpacity),
                      blurRadius: 18,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            // Middle translucent layer
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6F5CFF).withValues(alpha: 0.12),
                border: Border.all(
                  color: const Color(0xFF8C88FF).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
            ),
            // Center pin icon
            Transform.scale(
              scale: scaleValue,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Animated Get Started Button
// -----------------------------------------------------------------------------
class _AnimatedGetStartedButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedGetStartedButton({required this.onPressed});

  @override
  State<_AnimatedGetStartedButton> createState() => _AnimatedGetStartedButtonState();
}

class _AnimatedGetStartedButtonState extends State<_AnimatedGetStartedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final Animation<double> _scaleAnimation;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        final floatGlow = 0.35 + (_hoverController.value * 0.35);

        return GestureDetector(
          onTapDown: (_) => setState(() => _isTapped = true),
          onTapUp: (_) {
            setState(() => _isTapped = false);
            widget.onPressed();
          },
          onTapCancel: () => setState(() => _isTapped = false),
          child: Transform.scale(
            scale: _isTapped ? 0.95 : _scaleAnimation.value,
            child: Container(
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withValues(alpha: 0.3 * floatGlow),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Get Started',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
