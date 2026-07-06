import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class AppTheme {
  // 1. Apple-Inspired Dark Color Palette
  static const Color primaryBackground = Color(0xFF070913); // Midnight Navy/Black
  static const Color secondaryBackground = Color(0xFF0E1327); // Dark Indigo Surface
  static const Color cardBackground = Color(0xFF141933); // Glass panel backing
  static const Color elevatedCardBackground = Color(0xFF1B2245);

  static Color borderTranslucent = Colors.white.withValues(alpha: 0.08);
  static const Color borderFocused = Color(0xFF6366F1);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  // Accent Colors
  static const Color accentColor = Color(0xFF6366F1); // Apple Indigo
  static const Color accentColorLight = Color(0xFF0EA5E9); // Apple Soft Cyan

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentColor, Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1AFFFFFF), // white 10%
      Color(0x05FFFFFF), // white 2%
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.15),
          blurRadius: 24,
          spreadRadius: 1,
        ),
      ];

  // Softer Corner Radii (Apple standards)
  static double get cardRadius => 24.0;
  static double get buttonRadius => 20.0;
  static double get searchRadius => 28.0;
  static double get imageRadius => 20.0;
  static double get pillRadius => 30.0;
}

// 2. ThemeBackground: Renders layered radial gradients and slow ambient glow blobs
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
        // Background Gradient (Gently Shifting Radial Center)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double value = _controller.value;
              final double dx = 0.15 * math.sin(value * 2 * math.pi);
              final double dy = 0.15 * math.cos(value * 2 * math.pi);
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.2 + dx, -0.3 + dy),
                    radius: 1.6,
                    colors: const [
                      Color(0xFF0E132B), // Dark Indigo depth
                      AppTheme.primaryBackground,
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Floating Glow Blobs (Radial color layers)
        if (widget.showGlows)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double value = _controller.value;
                final double dx1 = 100 * math.sin(value * 2 * math.pi);
                final double dy1 = 80 * math.cos(value * 2 * math.pi);
                final double dx2 = 80 * math.sin((value + 0.5) * 2 * math.pi);
                final double dy2 = 100 * math.cos((value + 0.5) * 2 * math.pi);

                return Stack(
                  children: [
                    // Blob 1: Purple Ambient Glow
                    Positioned(
                      top: 80 + dy1,
                      left: -60 + dx1,
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Blob 2: Cyan Ambient Glow
                    Positioned(
                      bottom: 120 + dy2,
                      right: -60 + dx2,
                      child: Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.accentColorLight.withValues(alpha: 0.12),
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

        // Content Layer
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

// 3. GlassCard: Premium Apple Frosted Glass effect
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
    this.blur = 20.0,
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
              color: color ?? Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(radius),
              border: Border.fromBorderSide(
                border ?? BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
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

// 4. SpringButton: Custom Apple Spring Physics button interaction
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
