import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/services.dart';
import '../../domain/models/models.dart';
import '../../data/database/database_helper.dart';

// ─── Service Providers ───────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final aiServiceProvider = Provider<AIService>((ref) => AIService());
final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());
final historyServiceProvider = Provider<HistoryService>((ref) => HistoryService());
final databaseHelperProvider =
    Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

// ─── Auth State ──────────────────────────────────────────────────────────────

/// Emits the current [AppUser?] from Firebase Auth changes.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// ─── Firestore History ───────────────────────────────────────────────────────

/// Loads the current user's analysis history from Firestore.
/// Re-fetches automatically whenever the auth state changes (login / logout).
final userHistoryProvider =
    FutureProvider.autoDispose<List<ResumeAnalysis>>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) return [];

  final history = ref.read(historyServiceProvider);
  return history.loadAll(authState.uid);
});

// ─── Resume Analysis In-Session State ────────────────────────────────────────

/// Holds the list of completed resume analyses for the current session.
/// On first build it initialises itself from Firestore.
final resumeAnalysesProvider =
    StateNotifierProvider<ResumeAnalysesNotifier, List<ResumeAnalysis>>((ref) {
  return ResumeAnalysesNotifier(ref);
});

class ResumeAnalysesNotifier extends StateNotifier<List<ResumeAnalysis>> {
  final Ref _ref;
  bool _loaded = false;

  ResumeAnalysesNotifier(this._ref) : super([]) {
    _loadFromFirestore();
  }

  /// Load history from Firestore for the current user.
  Future<void> _loadFromFirestore() async {
    if (_loaded) return;
    try {
      final authState = await _ref.read(authStateProvider.future);
      if (authState == null) return;

      final history = _ref.read(historyServiceProvider);
      final analyses = await history.loadAll(authState.uid);
      state = analyses;
      _loaded = true;
    } catch (e) {
      // If Firestore load fails, start with empty list — don't crash.
    }
  }

  /// Reload from Firestore (call after sign-in).
  Future<void> reload() async {
    _loaded = false;
    state = [];
    await _loadFromFirestore();
  }

  /// Add a new analysis and persist it to Firestore.
  Future<void> add(ResumeAnalysis analysis) async {
    state = [analysis, ...state];
    try {
      final authState = await _ref.read(authStateProvider.future);
      if (authState != null) {
        await _ref.read(historyServiceProvider).save(authState.uid, analysis);
      }
    } catch (_) {
      // Persist failure is non-fatal; the analysis is still shown in session.
    }
  }

  /// Remove an analysis from memory and Firestore.
  Future<void> remove(String id) async {
    state = state.where((a) => a.id != id).toList();
    try {
      final authState = await _ref.read(authStateProvider.future);
      if (authState != null) {
        await _ref.read(historyServiceProvider).delete(authState.uid, id);
      }
    } catch (_) {}
  }

  /// Clear all analyses from memory and Firestore.
  Future<void> clear() async {
    state = [];
    try {
      final authState = await _ref.read(authStateProvider.future);
      if (authState != null) {
        await _ref.read(historyServiceProvider).deleteAll(authState.uid);
      }
    } catch (_) {}
  }
}

// ─── Analysis Pipeline State ─────────────────────────────────────────────────

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

// ─── Selected Analysis (for detail screen) ───────────────────────────────────

final selectedAnalysisProvider = StateProvider<ResumeAnalysis?>((ref) => null);

// ─── AI Provider Selection ────────────────────────────────────────────────────

enum AIProvider { gemini, openai }

final aiProviderSelectionProvider =
    StateProvider<AIProvider>((ref) => AIProvider.gemini);
