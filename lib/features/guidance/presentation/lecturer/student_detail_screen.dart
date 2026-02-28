import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/shared_widgets.dart';

/// Per-student detail screen for lecturers
class StudentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final milestoneRaw =
        student['milestoneProgress'] ?? student['milestone'] ?? 0;
    final double milestone = milestoneRaw is int
        ? milestoneRaw / 100
        : (milestoneRaw is double ? milestoneRaw : 0.0);
    final int guidance =
        (student['completedGuidanceCount'] ?? student['guidance'] ?? 0) is int
        ? (student['completedGuidanceCount'] ?? student['guidance'] ?? 0) as int
        : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SummaryCard(
                  student: student,
                  milestone: milestone,
                  guidance: guidance,
                ),
                const SizedBox(height: AppSpacing.base),
                _SeminarReadinessCard(milestone: milestone, guidance: guidance),
                const SizedBox(height: AppSpacing.base),
                _MilestoneSection(milestone: milestone),
                const SizedBox(height: AppSpacing.base),
                _GuidanceHistorySection(),
                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Detail Mahasiswa', style: AppTextStyles.h4),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final double milestone;
  final int guidance;

  const _SummaryCard({
    required this.student,
    required this.milestone,
    required this.guidance,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  ((student['fullName'] ?? student['name'] ?? '?') as String)
                      .substring(0, 1),
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (student['fullName'] ?? student['name'] ?? '-')
                          .toString(),
                      style: AppTextStyles.h4,
                    ),
                    Text(
                      (student['identityNumber'] ?? student['nim'] ?? '-')
                          .toString(),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              AppBadge(label: 'Aktif', variant: BadgeVariant.success),
            ],
          ),
          const AppDivider(),
          Text(
            (student['thesisTitle'] ?? student['thesis'] ?? '-').toString(),
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progress Milestone', style: AppTextStyles.caption),
                    const SizedBox(height: 4),
                    AppProgressBar(value: milestone, height: 8),
                    const SizedBox(height: 4),
                    Text(
                      '${(milestone * 100).round()}%',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Bimbingan', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Text(
                    '$guidance / 8',
                    style: AppTextStyles.h3.copyWith(
                      color: guidance >= 8
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                  Text('sesi selesai', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Seminar Readiness Card ───────────────────────────────────
class _SeminarReadinessCard extends StatelessWidget {
  final double milestone;
  final int guidance;

  const _SeminarReadinessCard({
    required this.milestone,
    required this.guidance,
  });

  @override
  Widget build(BuildContext context) {
    final isReady = milestone >= 1.0 && guidance >= 8;
    final isMilestoneOnly = milestone >= 1.0 && guidance < 8;

    final Color backColor = isReady
        ? AppColors.successLight
        : (isMilestoneOnly
              ? AppColors.warningLight
              : AppColors.surfaceSecondary);
    final Color iconColor = isReady
        ? AppColors.success
        : (isMilestoneOnly ? AppColors.warning : AppColors.textSecondary);
    final String statusText = isReady
        ? 'Semua syarat terpenuhi – dapat approval seminar'
        : isMilestoneOnly
        ? 'Milestone selesai, namun bimbingan belum cukup ($guidance/8)'
        : 'Belum memenuhi syarat kesiapan seminar';

    return AppCard(
      backgroundColor: backColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Text('Kesiapan Seminar', style: AppTextStyles.label),
              const Spacer(),
              if (isReady)
                AppButton(
                  label: 'Setujui',
                  icon: Icons.check,
                  width: 110,
                  color: AppColors.success,
                  onPressed: () => _showApproveDialog(context),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            statusText,
            style: AppTextStyles.bodySmall.copyWith(color: iconColor),
          ),
          const SizedBox(height: AppSpacing.md),
          _ReadinessCheckRow(
            icon: Icons.task_alt,
            label: 'Milestone 100%',
            isDone: milestone >= 1.0,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ReadinessCheckRow(
            icon: Icons.chat,
            label: 'Bimbingan ≥ 8 sesi ($guidance/8)',
            isDone: guidance >= 8,
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Setujui Kesiapan Seminar'),
        content: const Text(
          'Anda akan menyetujui kesiapan seminar mahasiswa ini. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kesiapan seminar berhasil disetujui!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
  }
}

class _ReadinessCheckRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDone;

  const _ReadinessCheckRow({
    required this.icon,
    required this.label,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.cancel_outlined,
          size: 16,
          color: isDone ? AppColors.success : AppColors.destructive,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: isDone ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Milestone Section ────────────────────────────────────────
class _MilestoneSection extends StatelessWidget {
  final double milestone;
  const _MilestoneSection({required this.milestone});

  final List<Map<String, dynamic>> _milestones = const [
    {'title': 'BAB 1 – Pendahuluan', 'status': 'completed'},
    {'title': 'BAB 2 – Tinjauan Pustaka', 'status': 'completed'},
    {'title': 'BAB 3 – Metodologi', 'status': 'in_progress'},
    {'title': 'BAB 4 – Implementasi', 'status': 'not_started'},
    {'title': 'BAB 5 – Penutup', 'status': 'not_started'},
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Milestone'),
          const SizedBox(height: AppSpacing.sm),
          ..._milestones.map(
            (m) => _MilestoneTile(title: m['title'], status: m['status']),
          ),
        ],
      ),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  final String title;
  final String status;
  const _MilestoneTile({required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDone = status == 'completed';
    final isCurrent = status == 'in_progress';
    final BadgeVariant variant = isDone
        ? BadgeVariant.success
        : (isCurrent ? BadgeVariant.primary : BadgeVariant.outline);
    final String label = isDone
        ? 'Selesai'
        : (isCurrent ? 'Progress' : 'Belum');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isDone
                ? Icons.check_circle
                : (isCurrent ? Icons.radio_button_on : Icons.circle_outlined),
            size: 18,
            color: isDone
                ? AppColors.success
                : (isCurrent ? AppColors.primary : AppColors.textTertiary),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: AppTextStyles.body)),
          AppBadge(label: label, variant: variant),
          const SizedBox(width: 8),
          if (isCurrent)
            InkWell(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Validasi',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.successDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Guidance History ─────────────────────────────────────────
class _GuidanceHistorySection extends StatelessWidget {
  const _GuidanceHistorySection();

  @override
  Widget build(BuildContext context) {
    final sessions = [
      {'date': '20 Feb 2025', 'topic': 'Review BAB 3', 'status': 'completed'},
      {
        'date': '12 Feb 2025',
        'topic': 'Diskusi Kerangka BAB 2',
        'status': 'summary_pending',
      },
      {
        'date': '05 Feb 2025',
        'topic': 'Perbaikan BAB 1',
        'status': 'completed',
      },
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Riwayat Bimbingan',
            actionLabel: 'Lihat Semua',
            onAction: () {},
          ),
          const SizedBox(height: AppSpacing.sm),
          ...sessions.map((s) {
            final isPending = s['status'] == 'summary_pending';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isPending ? AppColors.warning : AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['topic']!, style: AppTextStyles.label),
                        Text(s['date']!, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  if (isPending)
                    AppBadge(
                      label: 'Approve Catatan',
                      variant: BadgeVariant.warning,
                    ),
                  if (!isPending)
                    AppBadge(label: 'Selesai', variant: BadgeVariant.success),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
