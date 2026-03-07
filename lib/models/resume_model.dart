import 'package:cloud_firestore/cloud_firestore.dart';

class ResumeModel {
  final String id;
  final String userId;
  final String fileUrl;
  final Timestamp uploadDate;

  ResumeModel({
    required this.id,
    required this.userId,
    required this.fileUrl,
    required this.uploadDate,
  });

  factory ResumeModel.fromJson(Map<String, dynamic> json) {
    Timestamp parseTimestamp(dynamic ts) {
      if (ts is Timestamp) return ts;
      if (ts is String) return Timestamp.fromDate(DateTime.parse(ts));
      return Timestamp.now();
    }

    return ResumeModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      uploadDate: parseTimestamp(json['uploadDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fileUrl': fileUrl,
      'uploadDate': uploadDate,
    };
  }
}
