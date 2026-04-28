import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:resume_analyzer/core/theme/app_colors.dart';
import 'package:resume_analyzer/core/theme/app_shadows.dart';
import 'package:resume_analyzer/presentation/providers/providers.dart';

class ResumeDetailScreen extends ConsumerWidget {
  const ResumeDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(selectedAnalysisProvider);

    if (analysis == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analysis')),
        body: const Center(child: Text('No analysis selected')),
      );
    }

    final scoreColor = AppColors.scoreColor(analysis.atsScore);
    final scoreLabel = AppColors.scoreLabel(analysis.atsScore);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Custom App Bar ──
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Iconsax.arrow_left_2, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis.fileName,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMMM d, yyyy · h:mm a').format(analysis.analyzedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Iconsax.share, size: 18),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share feature coming soon!')),
                  );
                },
              ),
              const SizedBox(width: 12),
            ],
          ),

          // ── Score Gauge Card ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.md,
                ),
                child: Column(
                  children: [
                    Text(
                      'ATS Compatibility Score',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    // ── Syncfusion Radial Gauge ──
                    SizedBox(
                      height: 220,
                      child: SfRadialGauge(
                        enableLoadingAnimation: true,
                        animationDuration: 1500,
                        axes: <RadialAxis>[
                          RadialAxis(
                            minimum: 0,
                            maximum: 100,
                            startAngle: 150,
                            endAngle: 30,
                            showLabels: false,
                            showTicks: false,
                            radiusFactor: 0.85,
                            axisLineStyle: AxisLineStyle(
                              thickness: 0.15,
                              thicknessUnit: GaugeSizeUnit.factor,
                              color: AppColors.surface,
                              cornerStyle: CornerStyle.bothCurve,
                            ),
                            pointers: <GaugePointer>[
                              RangePointer(
                                value: analysis.atsScore.toDouble(),
                                width: 0.15,
                                sizeUnit: GaugeSizeUnit.factor,
                                color: scoreColor,
                                cornerStyle: CornerStyle.bothCurve,
                                enableAnimation: true,
                                animationDuration: 1500,
                                animationType: AnimationType.easeOutBack,
                                gradient: SweepGradient(
                                  colors: [
                                    scoreColor.withValues(alpha: 0.6),
                                    scoreColor,
                                  ],
                                ),
                              ),
                            ],
                            annotations: <GaugeAnnotation>[
                              GaugeAnnotation(
                                angle: 90,
                                positionFactor: 0.05,
                                widget: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${analysis.atsScore}',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w800,
                                        color: scoreColor,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.scoreLightColor(analysis.atsScore),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        scoreLabel,
                                        style: TextStyle(
                                          color: scoreColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Score bar breakdown
                    _ScoreBar(label: 'Formatting', value: _calcSubScore(analysis.atsScore, 0.9)),
                    const SizedBox(height: 10),
                    _ScoreBar(label: 'Keywords', value: _calcSubScore(analysis.atsScore, 1.05)),
                    const SizedBox(height: 10),
                    _ScoreBar(label: 'Impact', value: _calcSubScore(analysis.atsScore, 0.85)),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
            ),
          ),

          // ── Summary ──
          if (analysis.summary != null && analysis.summary!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryLight,
                        AppColors.primaryLight.withValues(alpha: 0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Iconsax.info_circle5,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          analysis.summary!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.6,
                              ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
              ),
            ),

          // ── Accordion Sections ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                children: [
                  _FeedbackSection(
                    icon: Iconsax.tick_circle5,
                    title: 'Strengths',
                    items: analysis.strengths,
                    color: AppColors.success,
                    bgColor: AppColors.successLight,
                    delay: 300,
                  ),
                  const SizedBox(height: 12),
                  _FeedbackSection(
                    icon: Iconsax.warning_25,
                    title: 'Weaknesses',
                    items: analysis.weaknesses,
                    color: AppColors.warning,
                    bgColor: AppColors.warningLight,
                    delay: 400,
                  ),
                  const SizedBox(height: 12),
                  _FeedbackSection(
                    icon: Iconsax.lamp_charge5,
                    title: 'Suggestions',
                    items: analysis.suggestions,
                    color: AppColors.primary,
                    bgColor: AppColors.primaryLight,
                    delay: 500,
                  ),
                  const SizedBox(height: 12),
                  _KeywordSection(
                    keywords: analysis.keywordMatches,
                    delay: 600,
                  ),
                ],
              ),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  double _calcSubScore(int mainScore, double factor) {
    return (mainScore * factor).clamp(0, 100).toDouble();
  }
}

// ── Score Bar ──────────────────────────────────────────

class _ScoreBar extends StatelessWidget {
  final String label;
  final double value;

  const _ScoreBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.scoreColor(value.round());

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 6,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 32,
          child: Text(
            '${value.round()}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// ── Feedback Accordion Section ──────────────────────────

class _FeedbackSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final Color color;
  final Color bgColor;
  final int delay;

  const _FeedbackSection({
    required this.icon,
    required this.title,
    required this.items,
    required this.color,
    required this.bgColor,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: title == 'Strengths',
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          children: items.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(top: entry.key == 0 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: Duration(milliseconds: delay)).slideX(begin: 0.05);
  }
}

// ── Keywords Section ──────────────────────────────────────

class _KeywordSection extends StatelessWidget {
  final List keywords;
  final int delay;

  const _KeywordSection({required this.keywords, required this.delay});

  @override
  Widget build(BuildContext context) {
    if (keywords.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Iconsax.search_normal_15,
                color: AppColors.primary, size: 20),
          ),
          title: Row(
            children: [
              Text(
                'Keyword Matches',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${keywords.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: keywords.map((kw) {
                final found = kw.found;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: found ? AppColors.successLight : AppColors.errorLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: found
                          ? AppColors.success.withValues(alpha: 0.2)
                          : AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        found ? Iconsax.tick_circle5 : Iconsax.close_circle5,
                        color: found ? AppColors.success : AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        kw.keyword,
                        style: TextStyle(
                          color: found ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (keywords.any((kw) => kw.context != null)) ...[
              const SizedBox(height: 16),
              ...keywords.where((kw) => kw.context != null).map((kw) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        kw.found ? Iconsax.tick_circle : Iconsax.info_circle,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodySmall,
                            children: [
                              TextSpan(
                                text: '${kw.keyword}: ',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(text: kw.context),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: Duration(milliseconds: delay)).slideX(begin: 0.05);
  }
}
