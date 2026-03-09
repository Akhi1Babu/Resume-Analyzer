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
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ── HERO ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 60.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Glowing icon
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FFC2).withOpacity(0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FFC2).withOpacity(0.35),
                              blurRadius: 60,
                              spreadRadius: 8,
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
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FFC2).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: const Color(0xFF00FFC2).withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          '✦  Powered by Gemini AI',
                          style: TextStyle(
                            color: Color(0xFF00FFC2),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Headline
                      Text(
                        'AI Resume Analyzer',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                      ),
                      const SizedBox(height: 20),
                      // Subheadline
                      Container(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Text(
                          'Stop wondering why you didn\'t get the interview. Upload your resume and let our advanced AI engine tear it apart — with brutally honest feedback, ATS scoring, keyword gap analysis, and a fully rewritten version ready to download.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.75),
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      // CTA Buttons
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => context.go('/login'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                                vertical: 22,
                              ),
                              backgroundColor: const Color(0xFF00FFC2),
                              foregroundColor: const Color(0xFF0F0F1E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                              elevation: 12,
                              shadowColor: const Color(
                                0xFF00FFC2,
                              ).withOpacity(0.5),
                            ),
                            icon: const Icon(Icons.rocket_launch, size: 20),
                            label: const Text(
                              'Get Started — It\'s Free',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── STATS BAR ─────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 40,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00FFC2).withOpacity(0.08),
                        const Color(0xFF7B2FFF).withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceAround,
                    spacing: 40,
                    runSpacing: 20,
                    children: [
                      _buildStat('Gemini AI', 'Powered'),
                      _buildStat('ATS Score', 'Real-time'),
                      _buildStat('LaTeX PDF', 'Download'),
                      _buildStat('100%', 'Secure & Private'),
                    ],
                  ),
                ),

                const SizedBox(height: 80),

                // ── SECTION TITLE ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    children: [
                      Text(
                        'Everything You Need to Land That Job',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'All features included. No subscriptions. No paywalls.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // ── SERVICES GRID ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildServiceCard(
                        icon: Icons.psychology_alt,
                        title: 'Brutal AI Feedback',
                        description:
                            'Our AI doesn\'t sugarcoat. It tears into your resume with humorous, pointed critique so you know exactly what\'s holding you back.',
                        color: const Color(0xFFFFB800),
                        tag: 'Core',
                      ),
                      _buildServiceCard(
                        icon: Icons.score,
                        title: 'ATS Score & Radar',
                        description:
                            'Get an overall ATS score plus a 5-axis radar chart rating your resume on Impact, Brevity, Action Verbs, Formatting, and Skills.',
                        color: const Color(0xFF00FFC2),
                        tag: 'Analytics',
                      ),
                      _buildServiceCard(
                        icon: Icons.work_outline,
                        title: 'Job Description Match',
                        description:
                            'Paste a job description to see your match percentage and the exact keywords that are missing from your resume.',
                        color: const Color(0xFF7B2FFF),
                        tag: 'ATS',
                      ),
                      _buildServiceCard(
                        icon: Icons.auto_fix_high,
                        title: 'Magic Bullet Rewriter',
                        description:
                            'AI rewrites your weakest resume bullets into metric-driven, action-packed statements that get past ATS filters.',
                        color: const Color(0xFFFF4949),
                        tag: 'AI Rewrite',
                      ),
                      _buildServiceCard(
                        icon: Icons.description_outlined,
                        title: 'Full Resume Rewrite',
                        description:
                            'Get a completely polished, ATS-optimized version of your entire resume — rewritten section by section from scratch.',
                        color: const Color(0xFF00B4FF),
                        tag: 'AI Rewrite',
                      ),
                      _buildServiceCard(
                        icon: Icons.picture_as_pdf,
                        title: 'LaTeX PDF Download',
                        description:
                            'Download your rewritten resume as a professional LaTeX source file in the popular Harshibar / Jake\'s template — Overleaf-ready.',
                        color: const Color(0xFFFF8A00),
                        tag: 'Export',
                      ),
                      _buildServiceCard(
                        icon: Icons.tune,
                        title: 'Tailor for Any Job',
                        description:
                            'Paste a specific job description and get a fully tailored LaTeX resume that naturally weaves in every required keyword.',
                        color: const Color(0xFF00FFC2),
                        tag: 'Pro Feature',
                      ),
                      _buildServiceCard(
                        icon: Icons.history,
                        title: 'Analysis History',
                        description:
                            'All your past analyses are saved securely to Firebase. Track your improvement and revisit any previous result anytime.',
                        color: const Color(0xFF7B2FFF),
                        tag: 'Cloud',
                      ),
                      _buildServiceCard(
                        icon: Icons.lock_outline,
                        title: '100% Private & Secure',
                        description:
                            'Your resume is parsed entirely in-browser. No file is ever stored on our servers — only the analysis result is saved.',
                        color: const Color(0xFFFFB800),
                        tag: 'Privacy',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),

                // ── HOW IT WORKS ─────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.07)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'How It Works',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 40),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 32,
                        runSpacing: 32,
                        children: [
                          _buildStep(
                            number: '01',
                            title: 'Upload PDF',
                            description:
                                'Drop your resume PDF. It\'s parsed securely in your browser.',
                            color: const Color(0xFF00FFC2),
                          ),
                          _buildStep(
                            number: '02',
                            title: 'AI Analysis',
                            description:
                                'Gemini AI scores, critiques, and rewrites every section of your resume.',
                            color: const Color(0xFF7B2FFF),
                          ),
                          _buildStep(
                            number: '03',
                            title: 'Review Results',
                            description:
                                'See your ATS score, radar chart, section feedback, and full rewrite.',
                            color: const Color(0xFFFFB800),
                          ),
                          _buildStep(
                            number: '04',
                            title: 'Download & Apply',
                            description:
                                'Download the polished LaTeX PDF and start applying with confidence.',
                            color: const Color(0xFFFF4949),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),

                // ── FINAL CTA ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 80.0),
                  child: Column(
                    children: [
                      Text(
                        'Ready to Fix Your Resume?',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Join thousands of candidates who upgraded their resumes with AI.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 36),
                      ElevatedButton.icon(
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
                          elevation: 12,
                          shadowColor: const Color(0xFF00FFC2).withOpacity(0.5),
                        ),
                        icon: const Icon(Icons.rocket_launch, size: 22),
                        label: const Text(
                          'Analyze My Resume Now',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: Color(0xFF00FFC2),
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required String tag,
  }) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.58),
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
    required Color color,
  }) {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4), width: 2),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
