import 'dart:convert';

class ResumeHistoryModel {
  final String? id;
  final String title;
  final String summary;
  final double score;
  final DateTime createdAt;

  ResumeHistoryModel({
    this.id,
    required this.title,
    required this.summary,
    required this.score,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'score': score,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ResumeHistoryModel.fromMap(Map<String, dynamic> map) {
    return ResumeHistoryModel(
      id: map['id'],
      title: map['title'],
      summary: map['summary'],
      score: map['score']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ResumeHistoryModel.fromJson(String source) => ResumeHistoryModel.fromMap(json.decode(source));
}
