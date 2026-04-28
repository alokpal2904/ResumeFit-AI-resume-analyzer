import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/services.dart';
import '../../domain/models/models.dart';
import '../../data/database/database_helper.dart';

// ─── Service Providers ───

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final aiServiceProvider = Provider<AIService>((ref) => AIService());
final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());
final databaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

// ─── Auth State ───

final authStateProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// ─── Resume Analysis State ───

/// Holds the list of completed resume analyses for the current session.
final resumeAnalysesProvider =
    StateNotifierProvider<ResumeAnalysesNotifier, List<ResumeAnalysis>>((ref) {
  return ResumeAnalysesNotifier();
});

class ResumeAnalysesNotifier extends StateNotifier<List<ResumeAnalysis>> {
  ResumeAnalysesNotifier() : super([]);

  void add(ResumeAnalysis analysis) {
    state = [analysis, ...state];
  }

  void remove(String id) {
    state = state.where((a) => a.id != id).toList();
  }

  void clear() {
    state = [];
  }
}

// ─── Analysis Loading State ───

enum AnalysisStatus { idle, pickingFile, extractingText, analyzing, done, error }

class AnalysisState {
  final AnalysisStatus status;
  final String? errorMessage;
  final ResumeAnalysis? result;
  final String statusMessage;

  const AnalysisState({
    this.status = AnalysisStatus.idle,
    this.errorMessage,
    this.result,
    this.statusMessage = '',
  });

  AnalysisState copyWith({
    AnalysisStatus? status,
    String? errorMessage,
    ResumeAnalysis? result,
    String? statusMessage,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      result: result ?? this.result,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  bool get isLoading =>
      status == AnalysisStatus.pickingFile ||
      status == AnalysisStatus.extractingText ||
      status == AnalysisStatus.analyzing;
}

final analysisStateProvider =
    StateNotifierProvider<AnalysisStateNotifier, AnalysisState>((ref) {
  return AnalysisStateNotifier();
});

class AnalysisStateNotifier extends StateNotifier<AnalysisState> {
  AnalysisStateNotifier() : super(const AnalysisState());

  void setPickingFile() {
    state = state.copyWith(
      status: AnalysisStatus.pickingFile,
      statusMessage: 'Selecting resume...',
      errorMessage: null,
    );
  }

  void setExtracting() {
    state = state.copyWith(
      status: AnalysisStatus.extractingText,
      statusMessage: 'Extracting text from PDF...',
    );
  }

  void setAnalyzing() {
    state = state.copyWith(
      status: AnalysisStatus.analyzing,
      statusMessage: 'AI is analyzing your resume...',
    );
  }

  void setDone(ResumeAnalysis result) {
    state = AnalysisState(
      status: AnalysisStatus.done,
      result: result,
      statusMessage: 'Analysis complete!',
    );
  }

  void setError(String message) {
    state = AnalysisState(
      status: AnalysisStatus.error,
      errorMessage: message,
      statusMessage: 'Analysis failed',
    );
  }

  void reset() {
    state = const AnalysisState();
  }
}

// ─── Selected Analysis (for detail screen) ───

final selectedAnalysisProvider = StateProvider<ResumeAnalysis?>((ref) => null);

// ─── AI Provider Selection ───

enum AIProvider { gemini, openai }

final aiProviderSelectionProvider = StateProvider<AIProvider>((ref) => AIProvider.gemini);
