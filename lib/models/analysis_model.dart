import 'package:cloud_firestore/cloud_firestore.dart';

class RewrittenBullet {
  final String before;
  final String after;

  RewrittenBullet({required this.before, required this.after});

  factory RewrittenBullet.fromJson(Map<String, dynamic> json) {
    return RewrittenBullet(
      before: json['before'] ?? '',
      after: json['after'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'before': before, 'after': after};
}

class AnalysisModel {
  final String id;
  final String userId;
  final String resumeUrl;
  final int score;
  final List<String> suggestions;
  final Timestamp timestamp;
  final Map<String, bool> detectedSections;

  // New Fields
  final int? jobMatchPercentage; // Made optional for backwards compatibility
  final List<String> missingKeywords;
  final List<RewrittenBullet> rewrittenBullets;
  final Map<String, int> categoryScores;

  AnalysisModel({
    required this.id,
    required this.userId,
    required this.resumeUrl,
    required this.score,
    required this.suggestions,
    required this.timestamp,
    required this.detectedSections,
    this.jobMatchPercentage,
    this.missingKeywords = const [],
    this.rewrittenBullets = const [],
    this.categoryScores = const {},
  });

  factory AnalysisModel.fromJson(Map<String, dynamic> json) {
    Timestamp parseTimestamp(dynamic ts) {
      if (ts is Timestamp) return ts;
      if (ts is String) return Timestamp.fromDate(DateTime.parse(ts));
      return Timestamp.now();
    }

    return AnalysisModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      resumeUrl: json['resumeUrl'] ?? '',
      score: json['score'] ?? 0,
      suggestions: List<String>.from(json['suggestions'] ?? []),
      timestamp: parseTimestamp(json['timestamp']),
      detectedSections: Map<String, bool>.from(json['detectedSections'] ?? {}),
      jobMatchPercentage: json['jobMatchPercentage'],
      missingKeywords: List<String>.from(json['missingKeywords'] ?? []),
      rewrittenBullets:
          (json['rewrittenBullets'] as List<dynamic>?)
              ?.map((e) => RewrittenBullet.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      categoryScores: Map<String, int>.from(json['categoryScores'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'resumeUrl': resumeUrl,
      'score': score,
      'suggestions': suggestions,
      'timestamp': timestamp,
      'detectedSections': detectedSections,
      if (jobMatchPercentage != null) 'jobMatchPercentage': jobMatchPercentage,
      'missingKeywords': missingKeywords,
      'rewrittenBullets': rewrittenBullets.map((e) => e.toJson()).toList(),
      'categoryScores': categoryScores,
    };
  }
}
