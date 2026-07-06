import 'dart:async';
import 'package:flutter/material.dart';
import '../models/survey_criteria.dart';
import '../utils/app_theme.dart';
import 'results_screen.dart';

class AiLoadingScreen extends StatefulWidget {
  final SurveyCriteria criteria;

  const AiLoadingScreen({super.key, required this.criteria});

  @override
  State<AiLoadingScreen> createState() => _AiLoadingScreenState();
}

class _AiLoadingScreenState extends State<AiLoadingScreen> {
  int _currentStepIndex = 0;
  double _progress = 0.0;
  bool _cursorVisible = true;
  Timer? _cursorTimer;
  Timer? _progressTimer;

  final List<String> _steps = [
    'Understanding your preferences',
    'Searching 5,000+ PGs in India',
    'Calculating compatibility scores',
    'Ranking recommendations',
    'Finalizing perfect matches',
  ];

  @override
  void initState() {
    super.initState();
    _startCursorBlink();
    _startAnimation();
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startCursorBlink() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _cursorVisible = !_cursorVisible;
      });
    });
  }

  Future<void> _startAnimation() async {
    const stepDuration = Duration(milliseconds: 600);
    
    // Progress bar animation
    _progressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        if (_progress < 1.0) {
          _progress += 0.01;
        }
      });
    });

    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(stepDuration);
      if (!mounted) return;
      setState(() {
        _currentStepIndex = i + 1;
      });
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ResultsScreen(criteria: widget.criteria),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemeBackground(
      showGlows: true,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Glowing Chatbot bubble
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accentColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentColor.withValues(alpha: 0.15),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.accentColorLight,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                
                // ChatGPT style thinking header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'CityEase AI is thinking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Opacity(
                      opacity: _cursorVisible ? 1.0 : 0.0,
                      child: Container(
                        margin: const EdgeInsets.only(left: 4, top: 4),
                        width: 8,
                        height: 18,
                        color: AppTheme.accentColorLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Narrowing down 5,000+ stays across India...',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 36),

                // Premium Progress Indicator Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    color: AppTheme.accentColor,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 32),

                // ChatGPT thinking list container
                GlassCard(
                  borderRadius: AppTheme.cardRadius,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(_steps.length, (index) {
                      final isCompleted = _currentStepIndex > index;
                      final isCurrent = _currentStepIndex == index;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? const Color(0xFF4ADE80).withValues(alpha: 0.15)
                                    : isCurrent
                                        ? AppTheme.accentColor.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                border: Border.all(
                                  color: isCompleted
                                      ? const Color(0xFF4ADE80)
                                      : isCurrent
                                          ? AppTheme.accentColor
                                          : Colors.white24,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        size: 10,
                                        color: Color(0xFF4ADE80),
                                      )
                                    : isCurrent
                                        ? const SizedBox(
                                            width: 6,
                                            height: 6,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: AppTheme.accentColor,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _steps[index],
                              style: TextStyle(
                                color: isCompleted
                                    ? Colors.white
                                    : isCurrent
                                        ? AppTheme.accentColorLight
                                        : Colors.white38,
                                fontSize: 13,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
