import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../data/models/yudisium_models.dart';

class StudentYudisiumCplPanel extends StatelessWidget {
  final List<YudisiumCplScore> scores;

  const StudentYudisiumCplPanel({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    final passed = scores.where((score) => score.passed).length;
    final validated = scores.where((score) => score.status.isValidated).length;
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(title: 'Capaian Pembelajaran'),
              ),
              AppBadge(
                label: '$passed/${scores.length} tercapai',
                variant: passed == scores.length
                    ? BadgeVariant.success
                    : BadgeVariant.warning,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '$validated dari ${scores.length} nilai telah divalidasi.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 13),
          for (var index = 0; index < scores.length; index++) ...[
            _CplScoreCard(score: scores[index]),
            if (index != scores.length - 1) const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

class _CplScoreCard extends StatelessWidget {
  final YudisiumCplScore score;

  const _CplScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final isValidated = score.status.isValidated;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  score.code,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.infoDark,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(score.description, style: AppTextStyles.bodySmall),
              ),
              const SizedBox(width: 6),
              AppBadge(
                label: score.passed ? 'Lulus' : 'Belum tercapai',
                variant: score.passed
                    ? BadgeVariant.success
                    : BadgeVariant.destructive,
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              _ScoreMetric(
                label: 'Nilai',
                value: score.score == null ? '-' : _formatNumber(score.score!),
              ),
              const SizedBox(width: 10),
              _ScoreMetric(
                label: 'Minimal',
                value: _formatNumber(score.minimalScore),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isValidated
                  ? AppColors.successLight
                  : AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isValidated ? Icons.verified_outlined : Icons.schedule,
                  size: 17,
                  color: isValidated
                      ? AppColors.successDark
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isValidated
                            ? score.validatedBy ?? 'Terverifikasi'
                            : 'Belum diverifikasi',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isValidated
                              ? AppColors.successDark
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (isValidated &&
                          (score.validatedAt != null ||
                              score.validatedByNip != null)) ...[
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (score.validatedAt != null)
                              _formatDateTime(score.validatedAt!),
                            if (score.validatedByNip != null)
                              'NIP ${score.validatedByNip}',
                          ].join(' • '),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ScoreMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.label),
          ],
        ),
      ),
    );
  }
}

class StudentYudisiumHistoryPanel extends StatelessWidget {
  final List<YudisiumHistoryItem> items;

  const StudentYudisiumHistoryPanel({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(title: 'Riwayat Pendaftaran Yudisium'),
              ),
              AppBadge(
                label: '${items.length} pendaftaran',
                variant: BadgeVariant.secondary,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Pendaftaran yang ditolak pada periode sebelumnya.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 13),
          for (var index = 0; index < items.length; index++) ...[
            _HistoryCard(item: items[index]),
            if (index != items.length - 1) const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final YudisiumHistoryItem item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(item.yudisiumName, style: AppTextStyles.label),
              ),
              const SizedBox(width: 8),
              const AppBadge(
                label: 'Tidak memenuhi',
                variant: BadgeVariant.destructive,
              ),
            ],
          ),
          const SizedBox(height: 9),
          _HistoryLine(
            icon: Icons.date_range_outlined,
            label: 'Pendaftaran',
            value:
                '${_formatDate(item.registrationOpenDate)} – ${_formatDate(item.registrationCloseDate)}',
          ),
          const SizedBox(height: 5),
          _HistoryLine(
            icon: Icons.event_outlined,
            label: 'Pelaksanaan',
            value: _formatDate(item.eventDate),
          ),
        ],
      ),
    );
  }
}

class _HistoryLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HistoryLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Text('$label: ', style: AppTextStyles.caption),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatNumber(num value) {
  final decimal = value.toDouble();
  return decimal == decimal.roundToDouble()
      ? decimal.toInt().toString()
      : decimal
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_formatDate(local)} $hour:$minute';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];
