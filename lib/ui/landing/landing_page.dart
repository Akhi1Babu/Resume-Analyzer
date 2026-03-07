import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/kinetic_background.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: KineticBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 40.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFC2).withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FFC2).withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.hub,
                      size: 80,
                      color: Color(0xFF00FFC2),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'AI Resume Analyzer',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Text(
                      'Stop wondering why you didn\'t get the interview. Upload your resume and let our advanced AI engine tear it apart and give you brutally honest feedback, all parsed instantly and securely.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Features Row
                  Wrap(
                    spacing: 30,
                    runSpacing: 30,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildFeatureCard(
                        icon: Icons.psychology,
                        title: 'Brutally Honest AI',
                        description:
                            'We won\'t sugarcoat it. If your resume lacks impact, our custom AI will tell you exactly what you are missing with no filter.',
                        color: const Color(0xFFFFB800),
                      ),
                      _buildFeatureCard(
                        icon: Icons.speed,
                        title: 'Instant Parsing',
                        description:
                            'No more waiting. Your PDF is digested instantly in the browser and fired directly to the analysis engine.',
                        color: const Color(0xFF00FFC2),
                      ),
                      _buildFeatureCard(
                        icon: Icons.history,
                        title: 'Immutable History',
                        description:
                            'View your past roastings and track your progress securely with full native Firebase Cloud integration.',
                        color: const Color(0xFF7000FF),
                      ),
                    ],
                  ),

                  const SizedBox(height: 80),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 56,
                        vertical: 24,
                      ),
                      backgroundColor: const Color(0xFF00FFC2),
                      foregroundColor: const Color(0xFF0F0F1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      elevation: 10,
                      shadowColor: const Color(0xFF00FFC2).withOpacity(0.5),
                    ),
                    child: const Text(
                      'Get Started Now',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2F).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
