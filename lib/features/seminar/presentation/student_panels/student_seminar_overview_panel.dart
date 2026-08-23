import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../thesis_shared/data/models/academic_requirement.dart';
import '../../data/models/seminar_models.dart';
import '../controllers/student_seminar_controller.dart';
import '../seminar_detail_screen.dart';

class StudentSeminarOverviewPanel extends StatefulWidget {
  final UserModel? user;
  final ValueChanged<String> onSeminarTap;
  final int refreshSignal;

  const StudentSeminarOverviewPanel({
    super.key,
    required this.user,
    required this.onSeminarTap,
    this.refreshSignal = 0,
  });

  @override
  State<StudentSeminarOverviewPanel> createState() =>
      _StudentSeminarOverviewPanelState();
}

class _StudentSeminarOverviewPanelState
    extends State<StudentSeminarOverviewPanel> {
  late final StudentSeminarController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StudentSeminarController()..load();
  }

  @override
  void didUpdateWidget(covariant StudentSeminarOverviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(AcademicRequirement requirement) async {
    final overview = _controller.overview;
    if (overview == null) return;
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: false,
    );
    if (!mounted || selection == null || selection.files.isEmpty) return;
    final file = selection.files.single;
    if (file.path == null) {
      _message('File tidak dapat diakses dari perangkat ini.', error: true);
      return;
    }
    if (file.size > overview.uploadConfig.maxFileSizeBytes) {
      _message(
        'Ukuran file maksimal ${overview.uploadConfig.maxFileSizeMb} MB.',
        error: true,
      );
      return;
    }

    try {
      await _controller.uploadRequirement(
        requirementId: requirement.id,
        filePath: file.path!,
        fileName: file.name,
      );
      _message('Dokumen berhasil diunggah dan menunggu verifikasi.');
    } catch (error) {
      _message('Gagal mengunggah dokumen: $error', error: true);
    }
  }

  void _message(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.destructive : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoading && _controller.overview == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_controller.error != null && _controller.overview == null) {
          return _ErrorView(
            error: _controller.error!,
            onRetry: _controller.load,
          );
        }
        final overview = _controller.overview;
        if (overview == null) return const SizedBox.shrink();

        return RefreshIndicator(
          onRefresh: _controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              _IdentityCard(user: widget.user, overview: overview),
              const SizedBox(height: AppSpacing.base),
              if (overview.seminar != null) ...[
                _CurrentSeminarCard(
                  seminar: overview.seminar!,
                  thesisTitle: overview.thesisTitle,
                  onTap: () => widget.onSeminarTap(overview.seminar!.id),
                ),
                const SizedBox(height: AppSpacing.base),
              ],
              _MilestoneCard(milestones: overview.milestones),
              const SizedBox(height: AppSpacing.base),
              _ChecklistCard(checklist: overview.checklist),
              const SizedBox(height: AppSpacing.base),
              _RequirementsCard(
                overview: overview,
                uploadingRequirementId: _controller.uploadingRequirementId,
                onUpload: _pickAndUpload,
              ),
              if (_controller.history.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.base),
                _HistoryCard(
                  history: _controller.history,
                  onOpen: widget.onSeminarTap,
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final UserModel? user;
  final StudentSeminarOverview overview;

  const _IdentityCard({required this.user, required this.overview});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Identitas Mahasiswa'),
          const SizedBox(height: 14),
          InfoRow(
            icon: Icons.person_outline,
            label: 'Nama',
            value: user?.fullName ?? '-',
          ),
          const SizedBox(height: 10),
          InfoRow(
            icon: Icons.badge_outlined,
            label: 'NIM',
            value: user?.identityNumber ?? '-',
          ),
          const SizedBox(height: 10),
          InfoRow(
            icon: Icons.menu_book_outlined,
            label: 'Judul Tugas Akhir',
            value: overview.thesisTitle ?? 'Tugas akhir belum tersedia',
          ),
        ],
      ),
    );
  }
}

class _CurrentSeminarCard extends StatelessWidget {
  final SeminarInfo seminar;
  final String? thesisTitle;
  final VoidCallback onTap;

  const _CurrentSeminarCard({
    required this.seminar,
    required this.thesisTitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Seminar Aktif', style: AppTextStyles.h4)),
              AppBadge(
                label: seminarStatusLabel(seminar.status.value),
                variant: seminarStatusVariant(seminar.status.value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            thesisTitle ?? '-',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          if (seminar.date != null) ...[
            const SizedBox(height: 10),
            Text(
              _formatDate(seminar.date),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (seminar.room != null || seminar.meetingLink != null) ...[
            const SizedBox(height: 6),
            Text(
              seminar.room?.name ?? 'Online • ${seminar.meetingLink}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Lihat detail', style: AppTextStyles.primaryLabel),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final List<SeminarMilestone> milestones;

  const _MilestoneCard({required this.milestones});

  @override
  Widget build(BuildContext context) {
    final completed = milestones.where((item) => item.checked).length;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionHeader(title: 'Progres Seminar')),
              Text(
                '$completed/${milestones.length}',
                style: AppTextStyles.label,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppProgressBar(
            value: milestones.isEmpty ? 0 : completed / milestones.length,
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < milestones.length; index++) ...[
            _StatusRow(
              label: milestones[index].label,
              complete: milestones[index].checked,
            ),
            if (index != milestones.length - 1) const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final SeminarChecklist checklist;

  const _ChecklistCard({required this.checklist});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Checklist Pendaftaran'),
          const SizedBox(height: 14),
          for (var index = 0; index < checklist.items.length; index++) ...[
            _ChecklistRow(item: checklist.items[index]),
            if (index != checklist.items.length - 1) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final SeminarChecklistItem item;

  const _ChecklistRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          item.met ? Icons.check_circle : Icons.radio_button_unchecked,
          color: item.met ? AppColors.success : AppColors.textTertiary,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label, style: AppTextStyles.label),
              if (item.current != null && item.required != null)
                Text(
                  '${item.current}/${item.required}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              for (final supervisor in item.supervisors)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '${supervisor.role}: ${supervisor.name} • ${supervisor.ready ? 'Siap' : 'Belum siap'}',
                    style: AppTextStyles.caption.copyWith(
                      color: supervisor.ready
                          ? AppColors.successDark
                          : AppColors.warningDark,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RequirementsCard extends StatelessWidget {
  final StudentSeminarOverview overview;
  final String? uploadingRequirementId;
  final ValueChanged<AcademicRequirement> onUpload;

  const _RequirementsCard({
    required this.overview,
    required this.uploadingRequirementId,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Dokumen Persyaratan'),
          const SizedBox(height: 6),
          Text(
            'Format PDF, maksimal ${overview.uploadConfig.maxFileSizeMb} MB.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (!overview.requirementConfiguration.isConfigured) ...[
            const SizedBox(height: 12),
            _Notice(
              message:
                  overview.requirementConfiguration.message ??
                  'Persyaratan belum dikonfigurasi.',
            ),
          ] else if (overview.requirements.isEmpty) ...[
            const SizedBox(height: 12),
            const _Notice(message: 'Belum ada persyaratan dokumen.'),
          ] else ...[
            const SizedBox(height: 12),
            for (
              var index = 0;
              index < overview.requirements.length;
              index++
            ) ...[
              _RequirementRow(
                requirement: overview.requirements[index],
                canUpload: overview.canUpload,
                isUploading:
                    uploadingRequirementId == overview.requirements[index].id,
                onUpload: () => onUpload(overview.requirements[index]),
              ),
              if (index != overview.requirements.length - 1)
                const Divider(height: 24),
            ],
          ],
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final AcademicRequirement requirement;
  final bool canUpload;
  final bool isUploading;
  final VoidCallback onUpload;

  const _RequirementRow({
    required this.requirement,
    required this.canUpload,
    required this.isUploading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final document = requirement.document;
    final approved = document?.status == DocumentStatus.approved;
    final uploadAllowed = canUpload && !approved && !isUploading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(requirement.name, style: AppTextStyles.label),
                  if (requirement.description != null)
                    Text(
                      requirement.description!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (document?.fileName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        document!.fileName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppBadge(
              label: _documentLabel(document?.status),
              variant: _documentVariant(document?.status),
            ),
          ],
        ),
        if (document?.notes != null && document!.notes!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          _Notice(message: 'Catatan verifikator: ${document.notes}'),
        ],
        if (canUpload && !approved) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: uploadAllowed ? onUpload : null,
              icon: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: Text(document == null ? 'Unggah' : 'Unggah Ulang'),
            ),
          ),
        ],
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final List<SeminarHistoryItem> history;
  final ValueChanged<String> onOpen;

  const _HistoryCard({required this.history, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Riwayat Percobaan'),
          const SizedBox(height: 12),
          for (var index = 0; index < history.length; index++) ...[
            InkWell(
              onTap: () => onOpen(history[index].id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(history[index].date),
                            style: AppTextStyles.label,
                          ),
                          if (history[index].cancelledReason != null)
                            Text(
                              history[index].cancelledReason!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    AppBadge(
                      label: seminarStatusLabel(history[index].status.value),
                      variant: seminarStatusVariant(
                        history[index].status.value,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            if (index != history.length - 1) const Divider(),
          ],
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool complete;

  const _StatusRow({required this.label, required this.complete});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          complete ? Icons.check_circle : Icons.radio_button_unchecked,
          color: complete ? AppColors.success : AppColors.textTertiary,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  final String message;

  const _Notice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: AppTextStyles.caption.copyWith(color: AppColors.warningDark),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.destructive,
            ),
            const SizedBox(height: 10),
            Text('Gagal memuat seminar', style: AppTextStyles.h4),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(String? raw) {
  if (raw == null || raw.isEmpty) return 'Jadwal belum ditetapkan';
  final date = DateTime.tryParse(raw);
  return date == null ? raw : formatDateIndonesian(date.toLocal());
}

String _documentLabel(DocumentStatus? status) {
  return switch (status) {
    DocumentStatus.submitted => 'Menunggu',
    DocumentStatus.approved => 'Disetujui',
    DocumentStatus.declined => 'Ditolak',
    null => 'Belum diunggah',
  };
}

BadgeVariant _documentVariant(DocumentStatus? status) {
  return switch (status) {
    DocumentStatus.submitted => BadgeVariant.warning,
    DocumentStatus.approved => BadgeVariant.success,
    DocumentStatus.declined => BadgeVariant.destructive,
    null => BadgeVariant.secondary,
  };
}
