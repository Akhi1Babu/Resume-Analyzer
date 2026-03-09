import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:universal_html/html.dart' as html;
import '../../models/analysis_model.dart';
import '../../services/resume_service.dart';
import '../widgets/kinetic_background.dart';

class AnalysisPage extends StatefulWidget {
  final AnalysisModel? analysis;

  const AnalysisPage({super.key, this.analysis});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  bool _isTailoring = false;
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
