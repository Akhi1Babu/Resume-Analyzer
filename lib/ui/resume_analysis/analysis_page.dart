import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../models/analysis_model.dart';
import '../../services/resume_service.dart';
import '../widgets/kinetic_background.dart';
part 'chat_sheet.dart';
part 'voice_interview_sheet.dart';

class AnalysisPage extends StatefulWidget {
  final AnalysisModel? analysis;

  const AnalysisPage({super.key, this.analysis});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  bool _isTailoring = false;
  bool _isLoadingInterviewQ = false;
  bool _isLoadingSkillPlan = false;
  final ResumeService _resumeService = ResumeService();

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;
    if (analysis == null) {
      return Scaffold(
        body: KineticBackground(
          child: Center(
            child: Text(
              'No analysis data found.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
      );
    }

    final score = analysis.score;
    final detectedSections = analysis.detectedSections;
    final suggestions = analysis.suggestions;

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'voiceInterview',
            onPressed: () => _openVoiceInterviewSheet(
              context,
              widget.analysis?.rewrittenResumeText ?? '',
            ),
            backgroundColor: const Color(0xFF7B2FFF),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.record_voice_over),
            label: const Text(
              'Voice Interview',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 12,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'chatResume',
            onPressed: () => _openChatSheet(
              context,
              widget.analysis?.rewrittenResumeText ?? '',
            ),
            backgroundColor: const Color(0xFF00FFC2),
            foregroundColor: const Color(0xFF0F0F1E),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text(
              'Chat with Resume',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 12,
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text(
          'Analysis Result',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: KineticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildScoreCircle(context, score),
                if (analysis.jobMatchPercentage != null) ...[
                  const SizedBox(height: 48),
                  _buildSectionTitle('Job Match Analysis'),
                  const SizedBox(height: 16),
                  _buildJobMatchCard(analysis),
                ],
                const SizedBox(height: 48),
                _buildSectionTitle('Performance Radar'),
                const SizedBox(height: 16),
                _buildRadarChartCard(analysis.categoryScores),
                const SizedBox(height: 48),
                _buildSectionTitle('Detected Sections'),
                const SizedBox(height: 16),
                _buildDetectedSections(detectedSections),
                const SizedBox(height: 48),
                _buildSectionTitle('Improvement Suggestions'),
                const SizedBox(height: 16),
                _buildSuggestions(suggestions),
                if (analysis.rewrittenBullets.isNotEmpty) ...[
                  const SizedBox(height: 48),
                  _buildSectionTitle('Magic Rewrite Bullets'),
                  const SizedBox(height: 16),
                  _buildRewrittenBullets(analysis.rewrittenBullets),
                ],
                if (analysis.rewrittenResumeText != null &&
                    analysis.rewrittenResumeText!.isNotEmpty) ...[
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Fully Rewritten Resume'),
                      if (analysis.rewrittenResumeLatex != null)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF00FFC2),
                            side: const BorderSide(color: Color(0xFF00FFC2)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () => _downloadLatex(
                            context,
                            analysis.rewrittenResumeLatex!,
                          ),
                          icon: const Icon(Icons.code, size: 18),
                          label: const Text(
                            'Get LaTeX Code',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRewrittenResumeText(analysis.rewrittenResumeText!),
                ],
                const SizedBox(height: 64),
                // --- Tailor for Job Button ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7B2FFF).withOpacity(0.25),
                        const Color(0xFF00FFC2).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF7B2FFF).withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.work_outline,
                            color: Color(0xFF7B2FFF),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tailor Resume for a Job',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Paste a job description to get a perfectly tailored resume that includes all the required keywords.',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 32,
                          ),
                          backgroundColor: const Color(0xFF7B2FFF),
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: const Color(0xFF7B2FFF).withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isTailoring
                            ? null
                            : () => _showTailorDialog(
                                context,
                                analysis.rewrittenResumeText ?? '',
                              ),
                        icon: _isTailoring
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_fix_high),
                        label: Text(
                          _isTailoring
                              ? 'Generating Tailored Resume…'
                              : 'Tailor Resume for Job Description',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- Interview Questions Card ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF8A00).withOpacity(0.22),
                        const Color(0xFFFFB800).withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFFF8A00).withOpacity(0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8A00).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.record_voice_over,
                              color: Color(0xFFFF8A00),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Interview Questions',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Get 18-22 AI-curated questions tailored to your resume, grouped by category with answer tips.',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 32,
                          ),
                          backgroundColor: const Color(0xFFFF8A00),
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: const Color(
                            0xFFFF8A00,
                          ).withOpacity(0.45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoadingInterviewQ
                            ? null
                            : () => _showInterviewQuestionsDialog(
                                context,
                                analysis.rewrittenResumeText ?? '',
                              ),
                        icon: _isLoadingInterviewQ
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.quiz_outlined),
                        label: Text(
                          _isLoadingInterviewQ
                              ? 'Generating Questions…'
                              : 'Generate Interview Questions',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // --- Skill Learning Plan Card ---
                if (analysis.missingKeywords.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00B4FF).withOpacity(0.18),
                          const Color(0xFF7B2FFF).withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF00B4FF).withOpacity(0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF00B4FF,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.school_outlined,
                                color: Color(0xFF00B4FF),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '📚 Skill Learning Plan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tap any missing skill to get a personalized 30-day learning roadmap.',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: analysis.missingKeywords.map((skill) {
                            return ActionChip(
                              onPressed: _isLoadingSkillPlan
                                  ? null
                                  : () => _showSkillPlanDialog(
                                      context,
                                      skill,
                                      analysis.suggestions.isNotEmpty
                                          ? analysis.suggestions.first
                                          : 'Software Developer',
                                    ),
                              avatar: const Icon(
                                Icons.add_circle_outline,
                                size: 16,
                                color: Color(0xFF00B4FF),
                              ),
                              label: Text(
                                skill,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: const Color(
                                0xFF00B4FF,
                              ).withOpacity(0.12),
                              side: BorderSide(
                                color: const Color(0xFF00B4FF).withOpacity(0.4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            );
                          }).toList(),
                        ),
                        if (_isLoadingSkillPlan) ...[
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF00B4FF),
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Generating learning plan…',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: 32),
                // --- Bottom Action Buttons ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 32,
                        ),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      onPressed: () => context.go('/dashboard'),
                      icon: const Icon(Icons.dashboard),
                      label: const Text(
                        'Dashboard',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 32,
                        ),
                        backgroundColor: const Color(0xFF00FFC2),
                        foregroundColor: const Color(0xFF0F0F1E),
                        elevation: 10,
                        shadowColor: const Color(0xFF00FFC2).withOpacity(0.5),
                      ),
                      onPressed: () => _exportToPdf(context, analysis),
                      icon: const Icon(Icons.download),
                      label: const Text(
                        'Download ATS Resume',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the Tailor for Job bottom sheet dialog
  void _showTailorDialog(BuildContext context, String resumeText) {
    final jdController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '🎯 Tailor Resume to Job Description',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Paste the job description below. Our AI will rewrite your resume to include all the important keywords and generate a perfectly tailored LaTeX file.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: jdController,
                    maxLines: 10,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Paste job description here...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF7B2FFF),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: const Color(0xFF7B2FFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      final jd = jdController.text.trim();
                      if (jd.isEmpty) return;
                      Navigator.of(ctx).pop();
                      setState(() => _isTailoring = true);
                      try {
                        final latex = await _resumeService.tailorResumeToJob(
                          resumeText: resumeText,
                          jobDescription: jd,
                        );
                        _downloadLatex(context, latex);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: const Color(0xFFFF4949),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isTailoring = false);
                      }
                    },
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text(
                      'Generate Tailored Resume',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Shows a full-screen bottom sheet with AI-generated interview questions
  void _showInterviewQuestionsDialog(
    BuildContext context,
    String resumeText,
  ) async {
    if (resumeText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resume text is not available. Please re-analyze.'),
          backgroundColor: Color(0xFFFF4949),
        ),
      );
      return;
    }

    setState(() => _isLoadingInterviewQ = true);

    Map<String, dynamic>? data;
    String? error;

    try {
      data = await _resumeService.generateInterviewQuestions(
        resumeText: resumeText,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoadingInterviewQ = false);
    }

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: const Color(0xFFFF4949),
        ),
      );
      return;
    }

    final categories = (data?['categories'] as List<dynamic>?) ?? [];

    // Map icon string → IconData
    IconData _iconFor(String name) {
      switch (name) {
        case 'psychology':
          return Icons.psychology;
        case 'code':
          return Icons.code;
        case 'work':
          return Icons.work_outline;
        case 'lightbulb':
          return Icons.lightbulb_outline;
        default:
          return Icons.help_outline;
      }
    }

    Color _colorFrom(String hex) {
      try {
        return Color(int.parse(hex.replaceFirst('#', '0xFF')));
      } catch (_) {
        return const Color(0xFF00FFC2);
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.98,
          builder: (ctx, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF12121F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Drag handle + header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFF8A00,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.record_voice_over,
                                color: Color(0xFFFF8A00),
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🎤 Interview Questions',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Tailored to your resume by Our AI',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.white.withOpacity(0.08)),
                      ],
                    ),
                  ),

                  // Questions list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      itemCount: categories.length,
                      itemBuilder: (ctx, catIdx) {
                        final cat = categories[catIdx] as Map<String, dynamic>;
                        final catName = cat['name'] as String? ?? 'Questions';
                        final catIcon = _iconFor(cat['icon'] as String? ?? '');
                        final catColor = _colorFrom(
                          cat['color'] as String? ?? '#00FFC2',
                        );
                        final questions =
                            (cat['questions'] as List<dynamic>?) ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            // Category header
                            Row(
                              children: [
                                Icon(catIcon, color: catColor, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  catName,
                                  style: TextStyle(
                                    color: catColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: catColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${questions.length}',
                                    style: TextStyle(
                                      color: catColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Question tiles
                            ...questions.asMap().entries.map((entry) {
                              final qIdx = entry.key;
                              final q = entry.value as Map<String, dynamic>;
                              final question = q['q'] as String? ?? '';
                              final tip = q['tip'] as String? ?? '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E35),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: catColor.withOpacity(0.18),
                                  ),
                                ),
                                child: Theme(
                                  data: Theme.of(
                                    ctx,
                                  ).copyWith(dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    leading: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: catColor.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${qIdx + 1}',
                                          style: TextStyle(
                                            color: catColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      question,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    iconColor: catColor,
                                    collapsedIconColor: Colors.white38,
                                    children: [
                                      if (tip.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            0,
                                            16,
                                            16,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: catColor.withOpacity(0.08),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: catColor.withOpacity(
                                                  0.2,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.tips_and_updates,
                                                  color: catColor,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    tip,
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.75),
                                                      fontSize: 13,
                                                      height: 1.5,
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
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Skill Learning Plan Dialog ─────────────────────────────────────────────
  Future<void> _showSkillPlanDialog(
    BuildContext context,
    String skill,
    String jobTitle,
  ) async {
    setState(() => _isLoadingSkillPlan = true);
    Map<String, dynamic>? plan;
    String? error;
    try {
      plan = await _resumeService.generateSkillLearningPlan(
        skill: skill,
        targetJobTitle: jobTitle,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoadingSkillPlan = false);
    }
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: const Color(0xFFFF4949),
        ),
      );
      return;
    }

    final weeks = (plan?['weeks'] as List<dynamic>?) ?? [];
    final resources = (plan?['resources'] as List<dynamic>?) ?? [];
    final summary = plan?['summary'] as String? ?? '';
    final project = plan?['projectIdea'] as String? ?? '';

    final weekColors = [
      const Color(0xFF00FFC2),
      const Color(0xFF00B4FF),
      const Color(0xFF7B2FFF),
      const Color(0xFFFFB800),
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        builder: (ctx, scroll) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF12121F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B4FF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: Color(0xFF00B4FF),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '30-Day Plan: $skill',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'For: $jobTitle',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (summary.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B4FF).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00B4FF).withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    summary,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              // Weekly breakdown
              ...weeks.asMap().entries.map((e) {
                final w = e.value as Map<String, dynamic>;
                final color = weekColors[e.key % weekColors.length];
                final tasks = (w['tasks'] as List<dynamic>?) ?? [];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Theme(
                    data: Theme.of(
                      ctx,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: e.key == 0,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'W${w['week']}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        w['theme'] as String? ?? '',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        '${w['days']}  •  ${w['goal']}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      iconColor: color,
                      collapsedIconColor: Colors.white38,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...tasks.map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: color,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          t.toString(),
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if ((w['milestone'] as String?)?.isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.flag_outlined,
                                        color: color,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Milestone: ${w['milestone']}',
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              // Resources
              if (resources.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  '📖 Resources',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...resources.map((r) {
                  final res = r as Map<String, dynamic>;
                  final isFree = res['free'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          res['type'] == 'Course'
                              ? Icons.play_circle_outline
                              : res['type'] == 'Book'
                              ? Icons.book_outlined
                              : Icons.computer,
                          color: const Color(0xFF00B4FF),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                res['name'] as String? ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if ((res['url'] as String?)?.isNotEmpty == true)
                                Text(
                                  res['url'] as String,
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isFree
                                ? const Color(0xFF00FFC2).withOpacity(0.15)
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isFree ? 'Free' : 'Paid',
                            style: TextStyle(
                              color: isFree
                                  ? const Color(0xFF00FFC2)
                                  : Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              // Project idea
              if (project.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFB800).withOpacity(0.15),
                        const Color(0xFFFF8A00).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFB800).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFFFFB800),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🚀 Resume Project Idea',
                              style: TextStyle(
                                color: Color(0xFFFFB800),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              project,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.82),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Live Chat with Resume ─────────────────────────────────────────────────
  void _openChatSheet(BuildContext context, String resumeText) {
    if (resumeText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resume text unavailable. Please re-analyze first.'),
          backgroundColor: Color(0xFFFF4949),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ChatSheet(resumeText: resumeText, resumeService: _resumeService),
    );
  }

  // ── Voice Interview With Resume ───────────────────────────────────────────
  void _openVoiceInterviewSheet(BuildContext context, String resumeText) {
    if (resumeText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resume text unavailable. Please re-analyze first.'),
          backgroundColor: Color(0xFFFF4949),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoiceInterviewSheet(
        resumeText: resumeText,
        resumeService: _resumeService,
      ),
    );
  }

  Widget _buildScoreCircle(BuildContext context, int score) {
    final color = score >= 80
        ? const Color(0xFF00FFC2)
        : (score >= 50 ? const Color(0xFFFFB800) : const Color(0xFFFF4949));
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 4),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              score.toString(),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: color,
                fontSize: 80,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '/ 100',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildJobMatchCard(AnalysisModel analysis) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Match Score',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              Text(
                '${analysis.jobMatchPercentage}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00FFC2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: analysis.jobMatchPercentage! / 100,
            backgroundColor: Colors.white.withOpacity(0.1),
            color: const Color(0xFF00FFC2),
            minHeight: 12,
            borderRadius: BorderRadius.circular(10),
          ),
          if (analysis.missingKeywords.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Missing Keywords from Job Description:',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.missingKeywords
                  .map(
                    (k) => Chip(
                      label: Text(k),
                      backgroundColor: const Color(0xFFFF4949).withOpacity(0.2),
                      labelStyle: const TextStyle(color: Color(0xFFFF4949)),
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRadarChartCard(Map<String, int> scores) {
    if (scores.isEmpty) {
      scores = {
        'Impact': 0,
        'Brevity': 0,
        'Action Verbs': 0,
        'Formatting': 0,
        'Skills': 0,
      };
    }
    return _buildGlassCard(
      child: SizedBox(
        height: 300,
        child: RadarChart(
          RadarChartData(
            tickCount: 5,
            radarShape: RadarShape.polygon,
            tickBorderData: BorderSide(color: Colors.white.withOpacity(0.2)),
            gridBorderData: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            getTitle: (index, angle) {
              final keys = scores.keys.toList();
              return RadarChartTitle(
                text: keys[index],
                angle: angle,
                positionPercentageOffset: 0.1,
              );
            },
            titleTextStyle: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            dataSets: [
              RadarDataSet(
                fillColor: const Color(0xFF00FFC2).withOpacity(0.3),
                borderColor: const Color(0xFF00FFC2),
                entryRadius: 4,
                dataEntries: scores.values
                    .map((v) => RadarEntry(value: v.toDouble()))
                    .toList(),
                borderWidth: 2,
              ),
            ],
          ),
          swapAnimationDuration: const Duration(milliseconds: 800),
          swapAnimationCurve: Curves.easeOutExpo,
        ),
      ),
    );
  }

  Widget _buildDetectedSections(Map<String, bool> sections) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: sections.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Icon(
                  entry.value ? Icons.check_circle : Icons.cancel,
                  color: entry.value
                      ? const Color(0xFF00FFC2)
                      : const Color(0xFFFF4949),
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  entry.value ? 'Found' : 'Missing',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSuggestions(List<String> suggestions) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: suggestions.map((sug) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFFFB800),
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    sug,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRewrittenBullets(List<RewrittenBullet> bullets) {
    return _buildGlassCard(
      child: Column(
        children: bullets.map((b) {
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.close, color: Color(0xFFFF4949), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        b.before,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          decoration: TextDecoration.lineThrough,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Icon(
                      Icons.arrow_downward,
                      color: Colors.white24,
                      size: 20,
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check, color: Color(0xFF00FFC2), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        b.after,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRewrittenResumeText(String text) {
    return _buildGlassCard(
      child: SelectableText(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
      ),
    );
  }

  void _downloadLatex(BuildContext context, String latexCode) {
    final base64Data = base64Encode(utf8.encode(latexCode));
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = 'data:text/plain;charset=utf-8;base64,$base64Data'
      ..style.display = 'none'
      ..download = 'ATS_Optimized_Resume.tex';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'LaTeX source downloaded! Open in Overleaf to generate PDF.',
          ),
          backgroundColor: Color(0xFF00FFC2),
        ),
      );
    }
  }

  Future<void> _exportToPdf(
    BuildContext context,
    AnalysisModel analysis,
  ) async {
    final PdfDocument document = PdfDocument();

    // Set page margins for a more professional LaTeX look
    document.pageSettings.margins.all = 40;

    final PdfPage page = document.pages.add();

    // LaTeX-style fonts
    final PdfFont nameFont = PdfStandardFont(
      PdfFontFamily.timesRoman,
      24,
      style: PdfFontStyle.bold,
    );
    final PdfFont contactFont = PdfStandardFont(PdfFontFamily.timesRoman, 10);
    final PdfFont sectionHeaderFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      12,
      style: PdfFontStyle.bold,
    );
    final PdfFont jobTitleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      11,
      style: PdfFontStyle.bold,
    );
    final PdfFont bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 10);

    // If we have a fully rewritten text, print it semantically imitating LaTeX ATS layouts
    if (analysis.rewrittenResumeText != null &&
        analysis.rewrittenResumeText!.isNotEmpty) {
      double yPos = 0;
      PdfPage currentPage = page;
      bool inHeaderPhase = true;

      final lines = analysis.rewrittenResumeText!.split('\n');
      for (var rawLine in lines) {
        String line = rawLine.trim();
        if (line.isEmpty) {
          yPos += 4;
          continue;
        }

        PdfFont currentFont = bodyFont;
        double xOffset = 0;
        PdfTextAlignment alignment = PdfTextAlignment.left;

        // Semantic Detection
        bool isSectionHeader =
            line == line.toUpperCase() &&
            line.length < 50 &&
            !line.startsWith('-') &&
            !line.startsWith('•') &&
            !line.contains('@');

        if (isSectionHeader) {
          inHeaderPhase = false; // We have left the name/contact block
          currentFont = sectionHeaderFont;
          yPos += 16; // Top padding for sections
        } else if (inHeaderPhase) {
          // Centered Header Phase (Name & Contact)
          alignment = PdfTextAlignment.center;
          if (!line.contains('@') &&
              !line.contains('1') &&
              !line.contains('link') &&
              line.length < 35 &&
              yPos == 0) {
            currentFont = nameFont; // First short string is likely the name
            yPos += 8;
          } else {
            currentFont = contactFont;
          }
        } else if (line.startsWith('-') ||
            line.startsWith('•') ||
            line.startsWith('*')) {
          // Bullet point formatting
          xOffset = 18; // Indent bullet points precisely
          currentFont = bodyFont;
          line = line.replaceFirst(
            RegExp(r'^[-•*]\s*'),
            '${String.fromCharCode(149)}  ',
          );
        } else if (line.contains('|')) {
          // A subheading formatted as: Title | Company | Location | Dates
          // We will draw it directly here to allow right alignment
          final parts = line.split('|').map((e) => e.trim()).toList();

          if (parts.length >= 2) {
            String leftText1 = parts[0];
            String rightText1 = parts.length > 3
                ? parts[3]
                : (parts.length > 2 ? parts[2] : parts[1]);

            // Draw Left
            currentPage.graphics.drawString(
              leftText1,
              jobTitleFont,
              bounds: Rect.fromLTWH(
                0,
                yPos + 6,
                currentPage.getClientSize().width,
                20,
              ),
            );
            // Draw Right
            final Size rightSize = bodyFont.measureString(rightText1);
            currentPage.graphics.drawString(
              rightText1,
              bodyFont,
              bounds: Rect.fromLTWH(
                currentPage.getClientSize().width - rightSize.width,
                yPos + 6,
                rightSize.width,
                20,
              ),
            );
            yPos += 18;

            if (parts.length >= 3) {
              String leftText2 = parts[1];
              String rightText2 = parts.length > 3 ? parts[2] : '';

              if (leftText2.isNotEmpty || rightText2.isNotEmpty) {
                currentPage.graphics.drawString(
                  leftText2,
                  bodyFont,
                  bounds: Rect.fromLTWH(
                    0,
                    yPos,
                    currentPage.getClientSize().width,
                    20,
                  ),
                );

                if (rightText2.isNotEmpty) {
                  final Size rightSize2 = bodyFont.measureString(rightText2);
                  currentPage.graphics.drawString(
                    rightText2,
                    bodyFont,
                    bounds: Rect.fromLTWH(
                      currentPage.getClientSize().width - rightSize2.width,
                      yPos,
                      rightSize2.width,
                      20,
                    ),
                  );
                }
                yPos += 14;
              }
            }
            continue; // Skip the default drawing below
          }
        } else {
          currentFont = bodyFont;
        }

        final element = PdfTextElement(
          text: line,
          font: currentFont,
          format: PdfStringFormat(
            lineSpacing: 1.5,
            alignment: alignment,
            wordWrap: PdfWordWrapType.word,
          ),
        );

        // Page break calculation
        if (yPos > currentPage.getClientSize().height - 40) {
          currentPage = document.pages.add();
          yPos = 0;
        }

        final PdfLayoutResult? result = element.draw(
          page: currentPage,
          bounds: Rect.fromLTWH(
            xOffset,
            yPos,
            currentPage.getClientSize().width - xOffset,
            currentPage.getClientSize().height - yPos,
          ),
        );

        if (result != null) {
          yPos = result.bounds.bottom + 2;

          // Draw standard LaTeX horizontal rule under section headers
          if (isSectionHeader) {
            yPos += 4;
            currentPage.graphics.drawLine(
              PdfPen(PdfColor(0, 0, 0), width: 1.2),
              Offset(0, yPos),
              Offset(
                currentPage.getClientSize().width,
                yPos,
              ), // Draw full width like standard template
            );
            yPos += 6;
          }
        }
      }
    } else {
      // Fallback for older resumes without rewrite metadata
      final PdfFont boldFont = PdfStandardFont(
        PdfFontFamily.helvetica,
        14,
        style: PdfFontStyle.bold,
      );
      final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);
      double currentY = 40;

      if (analysis.rewrittenBullets.isNotEmpty) {
        page.graphics.drawString(
          'Optimized Bullet Points to Copy/Paste:',
          boldFont,
          bounds: Rect.fromLTWH(0, currentY, 500, 20),
        );
        currentY += 30;
        for (var bullet in analysis.rewrittenBullets) {
          page.graphics.drawString(
            '• ${bullet.after}',
            font,
            bounds: Rect.fromLTWH(20, currentY, 480, 50),
          );
          currentY += 50;
        }
      }

      currentY += 20;
      page.graphics.drawString(
        'Missing Keywords from Job Description:',
        boldFont,
        bounds: Rect.fromLTWH(0, currentY, 500, 20),
      );
      currentY += 30;
      for (var word in analysis.missingKeywords) {
        page.graphics.drawString(
          '• $word',
          font,
          bounds: Rect.fromLTWH(20, currentY, 480, 20),
        );
        currentY += 20;
      }
    }

    List<int> bytes = await document.save();
    document.dispose();

    // Download in browser using base64 bypassing corrupted Blobs
    final String base64Data = base64Encode(bytes);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = 'data:application/pdf;base64,$base64Data'
      ..style.display = 'none'
      ..download = 'ATS_Optimized_Resume.pdf';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF downloaded successfully!'),
          backgroundColor: Color(0xFF00FFC2),
        ),
      );
    }
  }
}

// --- Chat Sheet Widget ---
class _ChatSheet extends StatefulWidget {
  final String resumeText;
  final ResumeService resumeService;
  const _ChatSheet({required this.resumeText, required this.resumeService});
  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}
