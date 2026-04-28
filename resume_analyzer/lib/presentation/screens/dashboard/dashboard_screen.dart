import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:resume_analyzer/core/theme/app_colors.dart';
import 'package:resume_analyzer/core/theme/app_shadows.dart';
import 'package:resume_analyzer/data/services/services.dart';
import 'package:resume_analyzer/domain/models/models.dart';
import 'package:resume_analyzer/presentation/providers/providers.dart';
import 'package:resume_analyzer/presentation/widgets/shared_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyses = ref.watch(resumeAnalysesProvider);
    final analysisState = ref.watch(analysisStateProvider);
    final authState = ref.watch(authStateProvider);

    final user = authState.value;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    // Greeting
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.displayName ?? 'Analyzer',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms),
                    ),
                    // Logout Button
                    GestureDetector(
                      onTap: () => _showLogoutConfirmation(context, ref),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.15),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Iconsax.logout,
                            color: AppColors.error,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats Cards ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Row(
                  children: [
                    _StatCard(
                      icon: Iconsax.document_text,
                      label: 'Analyzed',
                      value: '${analyses.length}',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 14),
                    _StatCard(
                      icon: Iconsax.chart_2,
                      label: 'Avg Score',
                      value: analyses.isEmpty
                          ? '—'
                          : '${(analyses.map((a) => a.atsScore).reduce((a, b) => a + b) / analyses.length).round()}',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 14),
                    _StatCard(
                      icon: Iconsax.star_1,
                      label: 'Best',
                      value: analyses.isEmpty
                          ? '—'
                          : '${analyses.map((a) => a.atsScore).reduce((a, b) => a > b ? a : b)}',
                      color: AppColors.warning,
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.1),
              ),
            ),

            // ── Section Title ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Row(
                  children: [
                    Text(
                      'Recent Analyses',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    if (analyses.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          ref.read(resumeAnalysesProvider.notifier).clear();
                        },
                        icon: const Icon(Iconsax.trash, size: 16),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Analysis Status ──
            if (analysisState.isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: StatusCard(message: analysisState.statusMessage),
                ),
              ),
            if (analysisState.status == AnalysisStatus.error)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: StatusCard(
                    message: analysisState.errorMessage ?? 'Analysis failed',
                    isError: true,
                  ),
                ),
              ),

            // ── Resume List or Empty State ──
            if (analyses.isEmpty && !analysisState.isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Iconsax.document_upload,
                  title: 'No resumes analyzed yet',
                  subtitle: 'Tap the + button to upload a PDF resume\nand get AI-powered insights',
                  action: PremiumButton(
                    label: 'Upload Resume',
                    icon: Iconsax.add,
                    onPressed: () => _handleUpload(context, ref),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final analysis = analyses[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 400),
                        child: SlideAnimation(
                          verticalOffset: 30,
                          child: FadeInAnimation(
                            child: _ResumeCard(
                              analysis: analysis,
                              onTap: () {
                                ref.read(selectedAnalysisProvider.notifier).state = analysis;
                                Navigator.pushNamed(context, '/detail');
                              },
                              onDelete: () {
                                ref.read(resumeAnalysesProvider.notifier).remove(analysis.id);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: analyses.length,
                  ),
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      // ── FAB ──
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.fab,
        ),
        child: FloatingActionButton.extended(
          onPressed: analysisState.isLoading
              ? null
              : () => _handleUpload(context, ref),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Iconsax.add),
          label: const Text('Analyze'),
        ),
      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Show logout confirmation dialog.
  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.logout, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 14),
            const Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authServiceProvider).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  /// Upload flow: pick file → enter job description → analyze.
  Future<void> _handleUpload(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(analysisStateProvider.notifier);

    try {
      notifier.setPickingFile();

      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        notifier.reset();
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        notifier.setError('Could not read the selected file.');
        return;
      }

      // Reset state before showing dialog
      notifier.reset();

      // Show Job Description input dialog
      if (!context.mounted) return;
      final jobDescription = await _showJobDescriptionDialog(context);

      // User cancelled the dialog
      if (jobDescription == null) {
        notifier.reset();
        return;
      }

      // Extract text
      notifier.setExtracting();
      final pdfService = ref.read(pdfServiceProvider);
      final text = await pdfService.extractText(Uint8List.fromList(bytes));

      // Analyze
      notifier.setAnalyzing();
      final aiService = ref.read(aiServiceProvider);
      final id = const Uuid().v4();

      final analysis = await aiService.analyzeResume(
        resumeText: text,
        fileName: file.name,
        analysisId: id,
        jobDescription: jobDescription.isEmpty ? null : jobDescription,
      );

      ref.read(resumeAnalysesProvider.notifier).add(analysis);
      notifier.setDone(analysis);

      // Navigate to detail
      ref.read(selectedAnalysisProvider.notifier).state = analysis;
      if (context.mounted) {
        Navigator.pushNamed(context, '/detail');
      }
    } on PdfServiceException catch (e) {
      notifier.setError(e.message);
    } on AIServiceException catch (e) {
      notifier.setError(e.message);
    } catch (e) {
      notifier.setError('Something went wrong: $e');
    }
  }

  /// Shows a dialog to input the Job Description before analysis.
  /// Returns the JD text, empty string for no JD, or null if cancelled.
  Future<String?> _showJobDescriptionDialog(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.briefcase, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Job Description',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste the job description to get a targeted analysis. '
                'Leave empty for a general resume review.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 8,
                  minLines: 5,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'e.g. We are looking for a Senior Flutter Developer with 3+ years of experience in mobile development...',
                    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null), // Cancel
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''), // Skip JD
            child: Text(
              'Skip',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            icon: const Icon(Iconsax.scan, size: 18),
            label: const Text('Analyze'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Private Widgets ──────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  final ResumeAnalysis analysis;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ResumeCard({
    required this.analysis,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = AppColors.scoreColor(analysis.atsScore);
    final scoreBg = AppColors.scoreLightColor(analysis.atsScore);
    final scoreLabel = AppColors.scoreLabel(analysis.atsScore);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.sm,
            ),
            child: Row(
              children: [
                // Score badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: scoreBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scoreColor.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Text(
                      '${analysis.atsScore}',
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analysis.fileName,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: scoreBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              scoreLabel,
                              style: TextStyle(
                                color: scoreColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (analysis.hasJobDescription) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Iconsax.briefcase, size: 10, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'JD Match',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('MMM d, h:mm a').format(analysis.analyzedAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Iconsax.arrow_right_3,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
