import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class AppTheme {
  static const Color pageBackground = Color(0xFF080B14);
  static const Color deepNavy = Color(0xFF111827);
  static const Color indigoGlow = Color(0xFF1E1B4B);
  static const Color darkPurple = Color(0xFF2A1E5C);

  static const Color primaryBackground = pageBackground;
  static const Color secondaryBackground = deepNavy;
  static const Color cardBackground = Color(0xFF171C2D);
  static const Color elevatedCardBackground = Color(0xFF202746);

  static const Color surfaceLevel1 = pageBackground;
  static const Color surfaceLevel2 = Color(0xFF171C2D);
  static const Color surfaceLevel3 = Color(0xFF202746);

  static Color borderTranslucent = Colors.white.withValues(alpha: 0.08);
  static const Color borderFocused = Color(0xFF7C5CFF);

  static const Color textPrimary = Color(0xFFF7F8FF);
  static const Color textSecondary = Color(0xFFD8E0F3);
  static const Color textMuted = Color(0xFF8A93A8);

  static const Color accentColor = Color(0xFF7C5CFF);
  static const Color accentColorLight = Color(0xFF38BDF8);
  static const Color successColor = Color(0xFF34D399);
  static const Color warningColor = Color(0xFFFBBF24);
  static const Color errorColor = Color(0xFFFB7185);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentColor, Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [accentColorLight, Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1AFFFFFF),
      Color(0x0DFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ambientGlowGradient = LinearGradient(
    colors: [Color(0x4D7C5CFF), Color(0x4D38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.34),
          blurRadius: 26,
          spreadRadius: -3,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: accentColor.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.2),
          blurRadius: 28,
          spreadRadius: 1,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get hoverShadow => [
        BoxShadow(
          color: accentColorLight.withValues(alpha: 0.16),
          blurRadius: 30,
          spreadRadius: 1,
          offset: const Offset(0, 18),
        ),
      ];

  static double get cardRadius => 24.0;
  static double get buttonRadius => 999.0;
  static double get searchRadius => 28.0;
  static double get imageRadius => 20.0;
  static double get pillRadius => 999.0;
}

class ThemeBackground extends StatefulWidget {
  final Widget child;
  final bool showGlows;

  const ThemeBackground({
    super.key,
    required this.child,
    this.showGlows = true,
  });

  @override
  State<ThemeBackground> createState() => _ThemeBackgroundState();
}

class _ThemeBackgroundState extends State<ThemeBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: const [
                      Color(0xFF0C1222),
                      AppTheme.primaryBackground,
                      AppTheme.deepNavy,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              );
            },
          ),
        ),

        if (widget.showGlows)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double value = _controller.value;
                final double dx1 = 90 * math.sin(value * 2 * math.pi);
                final double dy1 = 70 * math.cos(value * 2 * math.pi);
                final double dx2 = 80 * math.sin((value + 0.35) * 2 * math.pi);
                final double dy2 = 100 * math.cos((value + 0.35) * 2 * math.pi);
                final double dx3 = 70 * math.sin((value + 0.7) * 2 * math.pi);
                final double dy3 = 90 * math.cos((value + 0.7) * 2 * math.pi);

                return Stack(
                  children: [
                    Positioned(
                      top: 80 + dy1,
                      left: -70 + dx1,
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.accentColor.withValues(alpha: 0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 110 + dy2,
                      right: -60 + dx2,
                      child: Container(
                        width: 360,
                        height: 360,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.accentColorLight.withValues(alpha: 0.14),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 150 + dy3,
                      right: 40 + dx3,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.indigoGlow.withValues(alpha: 0.12),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final double blur;
  final Color? color;
  final BorderSide? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 22.0,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = borderRadius ?? AppTheme.cardRadius;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: AppTheme.glassGradient,
              color: color ?? AppTheme.cardBackground.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(radius),
              border: Border.fromBorderSide(
                border ?? BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.0,
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const SpringButton({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<SpringButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}
