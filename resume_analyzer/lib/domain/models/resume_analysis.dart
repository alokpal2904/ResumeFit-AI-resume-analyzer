/// Domain entity representing a parsed resume analysis result.
class ResumeAnalysis {
  final String id;
  final String fileName;
  final DateTime analyzedAt;
  final int atsScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> suggestions;
  final List<KeywordMatch> keywordMatches;
  final String? summary;
  final String? jobDescription;

  const ResumeAnalysis({
    required this.id,
    required this.fileName,
    required this.analyzedAt,
    required this.atsScore,
    required this.strengths,
    required this.weaknesses,
    required this.suggestions,
    required this.keywordMatches,
    this.summary,
    this.jobDescription,
  });

  /// Whether this analysis was done against a specific job description.
  bool get hasJobDescription =>
      jobDescription != null && jobDescription!.trim().isNotEmpty;

  /// Create from the structured JSON returned by the AI,
  /// or from a Firestore document (which includes analyzed_at).
  factory ResumeAnalysis.fromJson(Map<String, dynamic> json, {
    required String id,
    required String fileName,
    String? jobDescription,
  }) {
    // Parse analyzed_at: present in Firestore docs, absent in fresh AI responses.
    DateTime analyzedAt = DateTime.now();
    final rawDate = json['analyzed_at'];
    if (rawDate != null) {
      try {
        analyzedAt = DateTime.parse(rawDate as String);
      } catch (_) {}
    }

    return ResumeAnalysis(
      id: id,
      fileName: fileName,
      analyzedAt: analyzedAt,
      atsScore: (json['ats_score'] as num?)?.toInt() ?? 0,
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      suggestions: List<String>.from(json['suggestions'] ?? []),
      keywordMatches: (json['keyword_matches'] as List<dynamic>?)
              ?.map((e) => KeywordMatch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      summary: json['summary'] as String?,
      jobDescription: jobDescription,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'file_name': fileName,
        'analyzed_at': analyzedAt.toIso8601String(),
        'ats_score': atsScore,
        'strengths': strengths,
        'weaknesses': weaknesses,
        'suggestions': suggestions,
        'keyword_matches': keywordMatches.map((e) => e.toJson()).toList(),
        'summary': summary,
        'job_description': jobDescription,
      };
}

/// A single keyword match insight.
class KeywordMatch {
  final String keyword;
  final bool found;
  final String? context;

  const KeywordMatch({
    required this.keyword,
    required this.found,
    this.context,
  });

  factory KeywordMatch.fromJson(Map<String, dynamic> json) {
    return KeywordMatch(
      keyword: json['keyword'] as String? ?? '',
      found: json['found'] as bool? ?? false,
      context: json['context'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'keyword': keyword,
        'found': found,
        'context': context,
      };
}
