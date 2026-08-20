import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/seminar_api_service.dart';
import '../../../core/utils/formatters.dart';
import '../data/models/seminar_models.dart';

Future<bool?> showExaminerResponseDialog(
  BuildContext context, {
  required LecturerSeminarListItem seminar,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ExaminerResponseDialog(seminar: seminar),
  );
}

class _ExaminerResponseDialog extends StatefulWidget {
  final LecturerSeminarListItem seminar;

  const _ExaminerResponseDialog({required this.seminar});

  @override
  State<_ExaminerResponseDialog> createState() =>
      _ExaminerResponseDialogState();
}

class _ExaminerResponseDialogState extends State<_ExaminerResponseDialog> {
  final _api = SeminarApiService();
  final _reasonController = TextEditingController();
  ExaminerResponse? _submitting;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _respond(ExaminerResponse response) async {
    final examinerId = widget.seminar.myExaminerId;
    if (examinerId == null) return;

    setState(() => _submitting = response);
    try {
      final result = await _api.respondToExaminerAssignment(
        widget.seminar.id,
        examinerId,
        response: response,
        unavailableReasons: response == ExaminerResponse.unavailable
            ? _reasonController.text
            : null,
      );
      if (!mounted) return;

      Navigator.of(context).pop(true);
      final accepted = response == ExaminerResponse.available;
      final message = accepted
          ? result.seminarTransitioned
                ? 'Penugasan disetujui. Semua penguji telah bersedia dan seminar siap dijadwalkan.'
                : 'Penugasan sebagai penguji telah disetujui.'
          : 'Penugasan sebagai penguji telah ditolak.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: accepted
              ? AppColors.successDark
              : AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (exception) {
      if (!mounted) return;
      setState(() => _submitting = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim respons: $exception'),
          backgroundColor: AppColors.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final seminar = widget.seminar;
    final supervisors = [...seminar.supervisors]
      ..sort((a, b) => a.role.compareTo(b.role));
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konfirmasi Penugasan Penguji',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Anda ditugaskan sebagai penguji seminar hasil.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _submitting == null
                        ? () => Navigator.of(context).pop()
                        : null,
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoLine(
                      icon: Icons.school_outlined,
                      title: seminar.studentName,
                      subtitle: seminar.studentNim,
                    ),
                    const SizedBox(height: 10),
                    _InfoLine(
                      icon: Icons.menu_book_outlined,
                      title: seminar.thesisTitle,
                    ),
                    if (supervisors.isNotEmpty) ...[
                      const Divider(height: 24),
                      for (final supervisor in supervisors)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${formatRoleName(supervisor.role)}: ${supervisor.name}',
                            style: AppTextStyles.caption,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('Peran Anda', style: AppTextStyles.bodySmall),
                  const Spacer(),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('Penguji ${seminar.myExaminerOrder ?? '-'}'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Apakah Anda bersedia menjadi penguji untuk seminar hasil mahasiswa ini?',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 14),
              Text(
                'Alasan Tidak Bersedia (Opsional)',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                enabled: _submitting == null,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Masukkan alasan jika tidak bersedia…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _submitting == null
                          ? () => _respond(ExaminerResponse.unavailable)
                          : null,
                      icon: _ActionIcon(
                        active: _submitting == ExaminerResponse.unavailable,
                        icon: Icons.close_rounded,
                        color: AppColors.destructive,
                      ),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.destructive,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _submitting == null
                          ? () => _respond(ExaminerResponse.available)
                          : null,
                      icon: _ActionIcon(
                        active: _submitting == ExaminerResponse.available,
                        icon: Icons.check_rounded,
                        color: Colors.white,
                      ),
                      label: const Text('Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _InfoLine({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.label),
              if (subtitle != null)
                Text(subtitle!, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final bool active;
  final IconData icon;
  final Color color;

  const _ActionIcon({
    required this.active,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (!active) return Icon(icon, size: 18);
    return SizedBox(
      width: 14,
      height: 14,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
}
