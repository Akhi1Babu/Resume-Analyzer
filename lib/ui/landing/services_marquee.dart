part of 'landing_page.dart';

// ─── Data record for one service card ─────────────────────────────────────────
class _SC {
  final IconData icon;
  final String title;
  final String description;
  final int colorValue;
  final String tag;

  const _SC(this.icon, this.title, this.description, this.colorValue, this.tag);

  Color get color => Color(colorValue);
}

// ─── The full marquee widget (2 rows) ─────────────────────────────────────────
class _ServicesMarquee extends StatefulWidget {
  const _ServicesMarquee({super.key});

  @override
  State<_ServicesMarquee> createState() => _ServicesMarqueeState();
}

class _ServicesMarqueeState extends State<_ServicesMarquee>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl1;
  late final AnimationController _ctrl2;

  static const _row1 = [
    _SC(
      Icons.psychology_alt,
      'Brutal AI Feedback',
      'Honest, humorous critique of every section so you know exactly what is holding you back.',
      0xFFFFB800,
      'Core',
    ),
    _SC(
      Icons.radar,
      'ATS Score & Radar',
      '5-axis radar chart scoring Impact, Brevity, Action Verbs, Formatting and Skills in real time.',
      0xFF00FFC2,
      'Analytics',
    ),
    _SC(
      Icons.work_outline,
      'Job-Match %',
      'Paste a job description and see your keyword match score plus every missing skill highlighted.',
      0xFF7B2FFF,
      'ATS',
    ),
    _SC(
      Icons.auto_fix_high,
      'Magic Bullet Rewriter',
      'Transforms weak bullets into metric-driven, action-packed statements that sail past ATS filters.',
      0xFFFF4949,
      'AI Rewrite',
    ),
    _SC(
      Icons.description_outlined,
      'Full Resume Rewrite',
      'A completely polished, ATS-optimised version of your entire resume, rewritten section by section.',
      0xFF00B4FF,
      'AI Rewrite',
    ),
    _SC(
      Icons.picture_as_pdf,
      'LaTeX PDF Export',
      'Download professional LaTeX source in the Harshibar ATS template. Overleaf-ready in one click.',
      0xFFFF8A00,
      'Export',
    ),
  ];

  static const _row2 = [
    _SC(
      Icons.tune,
      'Tailor for Any Job',
      'Paste a job description and get a new LaTeX resume that naturally weaves in every required keyword.',
      0xFF00FFC2,
      'Pro',
    ),
    _SC(
      Icons.history,
      'Analysis History',
      'All analyses saved securely to Firebase. Track your progress and revisit any past result.',
      0xFF7B2FFF,
      'Cloud',
    ),
    _SC(
      Icons.lock_outline,
      '100% Private & Secure',
      'Resume parsed entirely in-browser. No file is ever uploaded — only the analysis result is stored.',
      0xFFFFB800,
      'Privacy',
    ),
    _SC(
      Icons.record_voice_over,
      'Interview Questions',
      '18-22 AI-curated questions grouped by Behavioural, Technical, Situational and Role-Specific.',
      0xFF00B4FF,
      'Interview',
    ),
    _SC(
      Icons.school_outlined,
      'Skill Learning Plan',
      'Tap any missing skill for a personalised 30-day roadmap with weekly tasks, resources and a project idea.',
      0xFF7B2FFF,
      'Upskill',
    ),
    _SC(
      Icons.smart_toy_outlined,
      'Live Chat with Resume',
      'Ask our AI career coach anything — your strengths, gaps, salary insight, or role-readiness check.',
      0xFF00FFC2,
      'AI Chat',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat();
    _ctrl2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 32),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl1.dispose();
    _ctrl2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MarqueeRow(controller: _ctrl1, items: _row1, reverse: false),
        const SizedBox(height: 20),
        _MarqueeRow(controller: _ctrl2, items: _row2, reverse: true),
      ],
    );
  }
}

// ─── One continuously scrolling row ──────────────────────────────────────────
class _MarqueeRow extends StatelessWidget {
  final AnimationController controller;
  final List<_SC> items;
  final bool reverse;

  const _MarqueeRow({
    required this.controller,
    required this.items,
    required this.reverse,
  });

  @override
  Widget build(BuildContext context) {
    const cardW = 300.0;
    const gap = 20.0;
    const stride = cardW + gap;
    final total = items.length * stride;

    return SizedBox(
      height: 200,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            final rawOffset = controller.value * total;
            final offset = reverse ? -rawOffset : rawOffset;
            return Stack(
              children: List.generate(items.length * 3, (i) {
                final sc = items[i % items.length];
                final basePos = i * stride - offset;
                // Loop: keep cards in a visible window of 3*total
                final looped = ((basePos % total) + total) % total - stride;
                return Positioned(
                  left: looped,
                  top: 0,
                  child: _HoverCard(sc: sc),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

// ─── Hover-glow service card ──────────────────────────────────────────────────
class _HoverCard extends StatefulWidget {
  final _SC sc;

  const _HoverCard({required this.sc});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.sc.color;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 300,
        height: 200,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _hovered
              ? c.withOpacity(0.14)
              : const Color(0xFF1A1A2E).withOpacity(0.85),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _hovered ? c.withOpacity(0.75) : c.withOpacity(0.22),
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: c.withOpacity(0.40),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
                ]
              : [BoxShadow(color: c.withOpacity(0.07), blurRadius: 18)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: c.withOpacity(_hovered ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.sc.icon, size: 24, color: c),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.sc.tag,
                    style: TextStyle(
                      color: c,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              widget.sc.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                widget.sc.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
