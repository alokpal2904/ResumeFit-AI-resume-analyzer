import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:resume_analyzer/domain/models/models.dart';

/// AI service using OpenRouter API with GPT-4o-mini model.
/// Analyzes resume against a specific job description.
class AIService {
  static const String _openRouterBaseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'openai/gpt-4o-mini';

  /// Build the system prompt dynamically based on whether a JD is provided.
  static String _buildSystemPrompt({required bool hasJobDescription}) {
    final jdSection = hasJobDescription
        ? '''
You will be given TWO inputs:
1. A RESUME to analyze
2. A JOB DESCRIPTION that the candidate is applying for

Your analysis MUST be tailored to the specific job description. Compare the resume against the JD requirements and evaluate how well the candidate matches.
'''
        : '''
You will be given a RESUME to analyze. Evaluate it as a general-purpose resume.
''';

    return '''
You are an expert ATS (Applicant Tracking System) resume analyzer and career coach.

$jdSection

Return a JSON object with EXACTLY this structure:

{
  "ats_score": <integer 0-100>,
  "summary": "<2-3 sentence overview: how well does this resume match the ${hasJobDescription ? 'job description' : 'general job market'}? What is the overall impression?>",
  "strengths": ["<strength 1>", "<strength 2>", ...],
  "weaknesses": ["<weakness 1>", "<weakness 2>", ...],
  "suggestions": ["<actionable suggestion 1>", "<actionable suggestion 2>", ...],
  "keyword_matches": [
    {"keyword": "<important keyword from ${hasJobDescription ? 'the job description' : 'the industry'}>", "found": true/false, "context": "<where it appears in the resume or why it's missing>"},
    ...
  ]
}

Scoring Guidelines:
- ats_score: Rate 0-100 based on:
  ${hasJobDescription ? '• Relevance to the specific job description (40% weight)' : '• General industry relevance (40% weight)'}
  ${hasJobDescription ? '• Match with required skills, qualifications, and experience (25% weight)' : '• Skill presentation and clarity (25% weight)'}
  • Resume formatting, structure, and ATS-parsability (15% weight)
  • Use of action verbs and quantified achievements (10% weight)
  • Overall professionalism and clarity (10% weight)

Content Guidelines:
- strengths: List 3-6 specific things the resume does well${hasJobDescription ? ' relative to the JD' : ''}.
- weaknesses: List 3-6 specific areas that need improvement${hasJobDescription ? ' to better match the JD' : ''}.
- suggestions: Provide 4-8 actionable, specific improvements.${hasJobDescription ? ' Prioritize changes that would improve JD match.' : ''}
- keyword_matches: Check for 8-15 important keywords${hasJobDescription ? ' extracted from the job description' : ' common in the industry'}. For each, indicate if found in the resume and provide context.
- Be specific, constructive, and professional.
- Return ONLY valid JSON, no markdown formatting.
''';
  }

  /// Analyze resume text, optionally against a job description.
  Future<ResumeAnalysis> analyzeResume({
    required String resumeText,
    required String fileName,
    required String analysisId,
    String? jobDescription,
  }) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_openrouter_api_key_here') {
      throw AIServiceException(
        'OpenRouter API key not configured.\n'
        'Get your key at https://openrouter.ai/keys\n'
        'Then add it to the .env file.',
      );
    }

    final hasJD = jobDescription != null && jobDescription.trim().isNotEmpty;
    final systemPrompt = _buildSystemPrompt(hasJobDescription: hasJD);

    // Build the user message
    String userMessage;
    if (hasJD) {
      userMessage = '''
=== JOB DESCRIPTION ===
$jobDescription

=== RESUME ===
$resumeText

Analyze this resume against the job description above. Score it based on how well it matches the JD requirements.''';
    } else {
      userMessage = '''
=== RESUME ===
$resumeText

Analyze this resume for general ATS compatibility and quality.''';
    }

    try {
      final response = await http.post(
        Uri.parse(_openRouterBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://resume-analyzer.app',
          'X-Title': 'Resume Analyzer',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.3,
          'max_tokens': 4096,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = _tryParseError(response.body);
        throw AIServiceException(
          'OpenRouter API error (${response.statusCode}): $errorBody',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      // Handle OpenRouter error responses within 200 status
      if (body.containsKey('error')) {
        final error = body['error'];
        throw AIServiceException(
          'OpenRouter error: ${error['message'] ?? error}',
        );
      }

      final content = body['choices'][0]['message']['content'] as String;
      final json = jsonDecode(_cleanJsonResponse(content)) as Map<String, dynamic>;

      return ResumeAnalysis.fromJson(
        json,
        id: analysisId,
        fileName: fileName,
        jobDescription: jobDescription,
      );
    } catch (e) {
      if (e is AIServiceException) rethrow;
      throw AIServiceException('Failed to analyze resume: $e');
    }
  }

  /// Legacy aliases — both route to the same OpenRouter endpoint.
  Future<ResumeAnalysis> analyzeWithGemini({
    required String resumeText,
    required String fileName,
    required String analysisId,
    String? jobDescription,
  }) => analyzeResume(
    resumeText: resumeText,
    fileName: fileName,
    analysisId: analysisId,
    jobDescription: jobDescription,
  );

  Future<ResumeAnalysis> analyzeWithOpenAI({
    required String resumeText,
    required String fileName,
    required String analysisId,
    String? jobDescription,
  }) => analyzeResume(
    resumeText: resumeText,
    fileName: fileName,
    analysisId: analysisId,
    jobDescription: jobDescription,
  );

  /// Try to extract a human-readable error from the response body.
  String _tryParseError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json.containsKey('error')) {
        final error = json['error'];
        if (error is Map) return error['message'] ?? body;
        return error.toString();
      }
      return body;
    } catch (_) {
      return body;
    }
  }

  /// Strips markdown code fences if the AI wraps JSON in them.
  String _cleanJsonResponse(String response) {
    String cleaned = response.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }
}

/// Custom exception for AI service errors.
class AIServiceException implements Exception {
  final String message;
  const AIServiceException(this.message);

  @override
  String toString() => 'AIServiceException: $message';
}
