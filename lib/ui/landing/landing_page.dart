import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/kinetic_background.dart';

// ─── Dramatic scroll-reveal widget ───────────────────────────────────────────
class _RevealSection extends StatefulWidget {
  final Widget child;
  final ScrollController scrollController;
  final Duration delay;
  final Offset slideFrom;

  const _RevealSection({
    required this.child,
    required this.scrollController,
    this.delay = Duration.zero,
    this.slideFrom = const Offset(0, 0.25),
  });

  @override
  State<_RevealSection> createState() => _RevealSectionState();
}

class _RevealSectionState extends State<_RevealSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _scale;

  // Key placed on the OUTER container (visible regardless of opacity)
  final GlobalKey _anchorKey = GlobalKey();
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slide = Tween<Offset>(
      begin: widget.slideFrom,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _scale = Tween<double>(
      begin: 0.93,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    widget.scrollController.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_triggered || !mounted) return;
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;
    if (offset.dy < screenH * 0.90) {
      _triggered = true;
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_check);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Outer SizedBox holds the anchor key so layout is always measurable
    return SizedBox(
      key: _anchorKey,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(_slide.value.dx * 100, _slide.value.dy * 100),
            child: Transform.scale(scale: _scale.value, child: child),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

// ─── Landing Page ─────────────────────────────────────────────────────────────
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();

  // Section anchors
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _ctaKey = GlobalKey();

  // Hero animation
  late AnimationController _heroCtrl;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _scroll.dispose();
    _heroCtrl.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: KineticBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // ── SCROLLABLE CONTENT ───────────────────────────────────
              SingleChildScrollView(
                controller: _scroll,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 72),

                        // ── HERO (slides down from top) ──────────────
                        FadeTransition(
                          opacity: _heroFade,
                          child: SlideTransition(
                            position: _heroSlide,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                40,
                                48,
                                40,
                                56,
                              ),
                              child: Column(
                                children: [
                                  // Glowing icon
                                  Container(
                                    padding: const EdgeInsets.all(28),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF00FFC2,
                                      ).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF00FFC2,
                                          ).withOpacity(0.4),
                                          blurRadius: 80,
                                          spreadRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.hub,
                                      size: 80,
                                      color: Color(0xFF00FFC2),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF00FFC2,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(40),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF00FFC2,
                                        ).withOpacity(0.3),
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
                                  Text(
                                    'AI Resume Analyzer',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                  ),
                                  const SizedBox(height: 20),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 640,
                                    ),
                                    child: Text(
                                      'Stop wondering why you didn\'t get the interview. Upload your resume and let our AI engine brutally critique, score, and rewrite it — then download as a professional LaTeX PDF.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white.withOpacity(0.72),
                                        height: 1.65,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 48),
                                  ElevatedButton.icon(
                                    onPressed: () => context.go('/login'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 52,
                                        vertical: 22,
                                      ),
                                      backgroundColor: const Color(0xFF00FFC2),
                                      foregroundColor: const Color(0xFF0F0F1E),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      elevation: 16,
                                      shadowColor: const Color(
                                        0xFF00FFC2,
                                      ).withOpacity(0.55),
                                    ),
                                    icon: const Icon(
                                      Icons.rocket_launch,
                                      size: 22,
                                    ),
                                    label: const Text(
                                      'Get Started — It\'s Free',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── STATS BAR ────────────────────────────────
                        _RevealSection(
                          scrollController: _scroll,
                          delay: const Duration(milliseconds: 100),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 32,
                                horizontal: 40,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF00FFC2).withOpacity(0.07),
                                    const Color(0xFF7B2FFF).withOpacity(0.07),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.spaceAround,
                                spacing: 48,
                                runSpacing: 24,
                                children: [
                                  _stat('Gemini 2.5', 'Flash AI Model'),
                                  _stat('ATS Score', 'Real-time'),
                                  _stat('LaTeX PDF', 'One-click Export'),
                                  _stat('100%', 'Secure & Private'),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 88),

                        // ── SERVICES HEADING ──────────────────────────
                        _RevealSection(
                          scrollController: _scroll,
                          slideFrom: const Offset(0, 0.20),
                          child: Padding(
                            key: _servicesKey,
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              children: [
                                _sectionLabel('SERVICES'),
                                const SizedBox(height: 14),
                                Text(
                                  'Everything You Need to Land That Job',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
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
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // ── SERVICE CARDS (staggered, alternating slide direction) ─
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            alignment: WrapAlignment.center,
                            children: [
                              _RevealSection(
                                scrollController: _scroll,
                                delay: const Duration(milliseconds: 0),
                                slideFrom: const Offset(-0.15, 0.1),
                                child: _serviceCard(
                                  icon: Icons.psychology_alt,
                                  title: 'Brutal AI Feedback',
                                  description:
                                      'Our AI doesn\'t sugarcoat. It critiques your resume with humorous, pointed feedback so you know exactly what\'s holding you back.',
                                  color: const Color(0xFFFFB800),
                                  tag: 'Core',
                                ),
                              ),
                              _RevealSection(
                                scrollController: _scroll,
                                delay: const Duration(milliseconds: 100),
                                slideFrom: const Offset(0, 0.2),
                                child: _serviceCard(
                                  icon: Icons.radar,
                                  title: 'ATS Score & Radar',
                                  description:
                                      'Get an overall ATS score + a 5-axis radar rating your resume on Impact, Brevity, Action Verbs, Formatting, and Skills.',
                                  color: const Color(0xFF00FFC2),
                                  tag: 'Analytics',
                                ),
                              ),
                              _RevealSection(
                                scrollController: _scroll,
                                delay: const Duration(milliseconds: 200),
                                slideFrom: const Offset(0.15, 0.1),
                                child: _serviceCard(
                                  icon: Icons.work_outline,
                                  title: 'Job Description Match',
                                  description:
                                      'Paste a job description to see your match % and the exact keywords missing from your resume.',
                                  color: const Color(0xFF7B2FFF),
                                  tag: 'ATS',
                                ),
                              ),
                              _RevealSection(
                                scrollController: _scroll,
                                delay: const Duration(milliseconds: 100),
                                slideFrom: const Offset(-0.15, 0.1),
                                child: _serviceCard(
                                  icon: Icons.auto_fix_high,
                                  title: 'Magic Bullet Rewriter',
                                  description:
                                      'AI rewrites your weakest bullets into metric-driven, action-packed statements that get past ATS filters.',
                                  color: const Color(0xFFFF4949),
                                  tag: 'AI Rewrite',
                                ),
                              ),
                              _RevealSection(
                                scrollController: _scroll,
                                delay: const Duration(milliseconds: 200),
                                slideFrom: const Offset(0, 0.2),
                                child: _serviceCard(
                                  icon: Icons.description_outlined,
                                  title: 'Full Resume Rewrite',
                                  description:
                                      'Get a completely polished, ATS-optimized version of your entire resume — rewritten section by section.',
                                  color: const Color(0xFF00B4FF),
                                  tag: 'AI Rewrite',
                                ),
                              ),
                              _RevealSection(
                                scrollController: _scroll,
                                delay: const Duration(milliseconds: 300),
                                slideFrom: const Offset(0.15, 0.1),
                                child: _serviceCard(
                                  icon: Icons.picture_as_pdf,
                                  title: 'LaTeX PDF Download',
                                  description:
                                      'Download your resume as a professional LaTeX source in the Harshibar ATS template — Overleaf-ready.',
                                  color: const Color(0xFFFF8A00),
                                  tag: 'Export',
                                ),
                              ),
                              _RevealSection(
                                scrollController: _scroll,
                                delay: const Duration(milliseconds: 200),
                                slideFrom: const Offset(-0.15, 0.1),
                                child: _serviceCard(
                                  icon: Icons.tune,
                                  title: 'Tailor for Any Job',
                                  description:
                                      'Paste a specific job description and get a tailored LaTeX resume that naturally weaves in every required keyword.',
                                  color: const Color(0xFF00FFC2),
                                  tag: 'Pro Feature',
                                ),
                              ),
                              _RevealSection(
                                scrollController: _scroll,
                                delay: const Duration(milliseconds: 300),
                                slideFrom: const Offset(0, 0.2),
                                child: _serviceCard(
                                  icon: Icons.history,
                                  title: 'Analysis History',
                                  description:
                                      'All analyses saved securely to Firebase. Track improvement and revisit any previous result anytime.',
                                  color: const Color(0xFF7B2FFF),
                                  tag: 'Cloud',
                                ),
                              ),
                              _RevealSection(
                                scrollController: _scroll,
                                delay: const Duration(milliseconds: 400),
                                slideFrom: const Offset(0.15, 0.1),
                                child: _serviceCard(
                                  icon: Icons.lock_outline,
                                  title: '100% Private & Secure',
                                  description:
                                      'Your resume is parsed entirely in-browser. No file is ever uploaded — only the analysis result is saved.',
                                  color: const Color(0xFFFFB800),
                                  tag: 'Privacy',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 96),

                        // ── HOW IT WORKS ──────────────────────────────
                        _RevealSection(
                          scrollController: _scroll,
                          slideFrom: const Offset(0, 0.20),
                          child: Padding(
                            key: _howItWorksKey,
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              children: [
                                _sectionLabel('HOW IT WORKS'),
                                const SizedBox(height: 14),
                                Text(
                                  'From Upload to Job-Ready in 4 Steps',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 32,
                            runSpacing: 32,
                            children: [
                              _RevealSection(
                                scrollController: _scroll,
                                delay: const Duration(milliseconds: 0),
                                slideFrom: const Offset(-0.2, 0.15),
                                child: _stepCard(
                                  '01',
                                  'Upload PDF',
                                  'Drop your resume PDF. Parsed securely in your browser — files never leave your device.',
                                  const Color(0xFF00FFC2),
                                  Icons.upload_file,
                                ),
                              ),
                              _RevealSection(
                                scrollController: _scroll,
                                delay: const Duration(milliseconds: 120),
                                slideFrom: const Offset(0, 0.25),
                                child: _stepCard(
                                  '02',
                                  'AI Analysis',
                                  'Gemini AI scores, critiques, and rewrites every section with brutal honesty.',
                                  const Color(0xFF7B2FFF),
                                  Icons.psychology,
                                ),
                              ),
                              _RevealSection(
                                scrollController: _scroll,
                                delay: const Duration(milliseconds: 240),
                                slideFrom: const Offset(0, 0.25),
                                child: _stepCard(
                                  '03',
                                  'Review Results',
                                  'See your ATS score, radar chart, missing keywords, and full AI rewrite.',
                                  const Color(0xFFFFB800),
                                  Icons.analytics,
                                ),
                              ),
                              _RevealSection(
                                scrollController: _scroll,
                                delay: const Duration(milliseconds: 360),
                                slideFrom: const Offset(0.2, 0.15),
                                child: _stepCard(
                                  '04',
                                  'Download & Apply',
                                  'Download the polished LaTeX PDF and apply with a resume that gets noticed.',
                                  const Color(0xFFFF4949),
                                  Icons.download_done,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 96),

                        // ── FINAL CTA ─────────────────────────────────
                        _RevealSection(
                          scrollController: _scroll,
                          slideFrom: const Offset(0, 0.20),
                          delay: const Duration(milliseconds: 50),
                          child: Container(
                            key: _ctaKey,
                            margin: const EdgeInsets.fromLTRB(32, 0, 32, 80),
                            padding: const EdgeInsets.symmetric(
                              vertical: 56,
                              horizontal: 40,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF7B2FFF).withOpacity(0.2),
                                  const Color(0xFF00FFC2).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: const Color(0xFF7B2FFF).withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '🚀',
                                  style: TextStyle(fontSize: 56),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Ready to Fix Your Resume?',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Join candidates who upgraded their resumes with AI.',
                                  textAlign: TextAlign.center,
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
                                    shadowColor: const Color(
                                      0xFF00FFC2,
                                    ).withOpacity(0.5),
                                  ),
                                  icon: const Icon(
                                    Icons.auto_fix_high,
                                    size: 22,
                                  ),
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── FLOATING NAVBAR ──────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildNavbar(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Navbar ────────────────────────────────────────────────────────────────

  Widget _buildNavbar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1E).withOpacity(0.78),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.hub, color: Color(0xFF00FFC2), size: 26),
          const SizedBox(width: 10),
          const Text(
            'ResumeAI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          _navButton('Services', () => _scrollTo(_servicesKey)),
          const SizedBox(width: 4),
          _navButton('How It Works', () => _scrollTo(_howItWorksKey)),
          const SizedBox(width: 4),
          _navButton('Contact', () => _scrollTo(_ctaKey)),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: const Color(0xFF00FFC2),
              foregroundColor: const Color(0xFF0F0F1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF7B2FFF).withOpacity(0.15),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFF7B2FFF).withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF7B2FFF),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF00FFC2),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        ),
      ],
    );
  }

  Widget _serviceCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required String tag,
  }) {
    return Container(
      width: 295,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.75),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 28,
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
                child: Icon(icon, size: 26, color: color),
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
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCard(
    String number,
    String title,
    String description,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.4), width: 2),
                ),
              ),
              Icon(icon, color: color, size: 26),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Color(0xFF0F0F1E),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
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
