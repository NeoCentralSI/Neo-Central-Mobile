import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/shared_widgets.dart';

/// Guidance session detail screen for lecturer to approve or reject a request
class GuidanceSessionDetailScreen extends StatefulWidget {
  final Map<String, String> session;
  const GuidanceSessionDetailScreen({super.key, required this.session});

  @override
  State<GuidanceSessionDetailScreen> createState() =>
      _GuidanceSessionDetailScreenState();
}

class _GuidanceSessionDetailScreenState
    extends State<GuidanceSessionDetailScreen> {
  bool _isApproving = false;
  bool _isRejecting = false;

  void _approve() async {
    setState(() => _isApproving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isApproving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permintaan bimbingan disetujui!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _reject() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Permintaan'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Alasan penolakan (opsional)',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _isRejecting = true);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() => _isRejecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan ditolak'),
            backgroundColor: AppColors.destructive,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Detail Permintaan', style: AppTextStyles.h4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          (s['name'] ?? 'M').substring(0, 1),
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['name'] ?? '', style: AppTextStyles.h4),
                            Text(
                              s['nim'] ?? '',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const AppBadge(
                        label: 'Menunggu',
                        variant: BadgeVariant.warning,
                      ),
                    ],
                  ),
                  const AppDivider(),
                  InfoRow(
                    icon: Icons.topic_outlined,
                    label: 'Topik',
                    value: s['topic'] ?? '',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Tanggal Diminta',
                    value: s['date'] ?? '',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InfoRow(
                    icon: Icons.person_outlined,
                    label: 'Role Pembimbing',
                    value: s['supervisor'] ?? '',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            AppCard(
              backgroundColor: AppColors.infoLight,
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pastikan jadwal Anda tersedia pada tanggal tersebut sebelum menyetujui.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.infoDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Tolak',
                    isOutline: true,
                    color: AppColors.destructive,
                    icon: Icons.close,
                    isLoading: _isRejecting,
                    onPressed: _reject,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Setujui',
                    icon: Icons.check,
                    color: AppColors.success,
                    isLoading: _isApproving,
                    onPressed: _approve,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
