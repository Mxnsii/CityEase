import 'package:flutter/material.dart';
import '../models/survey_criteria.dart';
import 'results_screen.dart';

class AiLoadingScreen extends StatefulWidget {
  final SurveyCriteria criteria;

  const AiLoadingScreen({super.key, required this.criteria});

  @override
  State<AiLoadingScreen> createState() => _AiLoadingScreenState();
}

class _AiLoadingScreenState extends State<AiLoadingScreen> {
  int _currentStepIndex = 0;
  final List<String> _steps = [
    'Reading your preferences',
    'Finding nearby PGs',
    'Calculating match score',
    'Ranking recommendations',
  ];

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _currentStepIndex = i + 1;
      });
    }

    // Short delay before transitioning to ResultsScreen
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
    return Scaffold(
      backgroundColor: const Color(0xFF090B19),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing AI Brain Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F5CFF).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6F5CFF).withValues(alpha: 0.35),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6F5CFF).withValues(alpha: 0.15),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF8C88FF),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Finding your perfect PG...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'CityEase AI is searching matching stays',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
                const SizedBox(height: 48),

                // Checklist Steps
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11142B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF20254D)),
                  ),
                  child: Column(
                    children: List.generate(_steps.length, (index) {
                      final isCompleted = _currentStepIndex > index;
                      final isCurrent = _currentStepIndex == index;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? const Color(0xFF4ADE80).withValues(alpha: 0.2)
                                    : isCurrent
                                        ? const Color(0xFF6F5CFF).withValues(alpha: 0.2)
                                        : Colors.transparent,
                                border: Border.all(
                                  color: isCompleted
                                      ? const Color(0xFF4ADE80)
                                      : isCurrent
                                          ? const Color(0xFF6F5CFF)
                                          : Colors.white24,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        size: 12,
                                        color: Color(0xFF4ADE80),
                                      )
                                    : isCurrent
                                        ? const SizedBox(
                                            width: 8,
                                            height: 8,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: Color(0xFF6F5CFF),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              _steps[index],
                              style: TextStyle(
                                color: isCompleted
                                    ? Colors.white
                                    : isCurrent
                                        ? const Color(0xFF8C88FF)
                                        : Colors.white38,
                                fontSize: 14,
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
