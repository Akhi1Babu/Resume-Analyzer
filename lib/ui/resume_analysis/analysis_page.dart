import 'dart:ui';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:universal_html/html.dart' as html;
import '../../models/analysis_model.dart';
import '../widgets/kinetic_background.dart';

class AnalysisPage extends StatelessWidget {
  final AnalysisModel? analysis;

  const AnalysisPage({super.key, this.analysis});

  @override
  Widget build(BuildContext context) {
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

    final score = analysis!.score;
    final detectedSections = analysis!.detectedSections;
    final suggestions = analysis!.suggestions;

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
                if (analysis!.jobMatchPercentage != null) ...[
                  const SizedBox(height: 48),
                  _buildSectionTitle('Job Match Analysis'),
                  const SizedBox(height: 16),
                  _buildJobMatchCard(analysis!),
                ],
                const SizedBox(height: 48),
                _buildSectionTitle('Performance Radar'),
                const SizedBox(height: 16),
                _buildRadarChartCard(analysis!.categoryScores),
                const SizedBox(height: 48),
                _buildSectionTitle('Detected Sections'),
                const SizedBox(height: 16),
                _buildDetectedSections(detectedSections),
                const SizedBox(height: 48),
                _buildSectionTitle('Improvement Suggestions'),
                const SizedBox(height: 16),
                _buildSuggestions(suggestions),
                if (analysis!.rewrittenBullets.isNotEmpty) ...[
                  const SizedBox(height: 48),
                  _buildSectionTitle('Magic Rewrite Bullets'),
                  const SizedBox(height: 16),
                  _buildRewrittenBullets(analysis!.rewrittenBullets),
                ],
                const SizedBox(height: 64),
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
                      onPressed: () => _exportToPdf(context, analysis!),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text(
                        'Download Suggestions as pdf',
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

  Future<void> _exportToPdf(
    BuildContext context,
    AnalysisModel analysis,
  ) async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final PdfFont boldFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      14,
      style: PdfFontStyle.bold,
    );

    // Title
    page.graphics.drawString(
      'ATS-Friendly AI Rewritten Resume Data',
      boldFont,
      bounds: const Rect.fromLTWH(0, 0, 500, 30),
    );

    // Draw content
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
