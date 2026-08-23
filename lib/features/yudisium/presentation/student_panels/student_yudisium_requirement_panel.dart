import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/binary_download.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../thesis_shared/data/models/academic_requirement.dart';
import '../../data/models/yudisium_models.dart';
import '../controllers/student_yudisium_controller.dart';

class StudentYudisiumRequirementPanel extends StatefulWidget {
  final StudentYudisiumController controller;
  final StudentYudisiumOverview overview;
  final StudentYudisiumRequirements? requirements;
  final VoidCallback onOpenExitSurvey;

  const StudentYudisiumRequirementPanel({
    super.key,
    required this.controller,
    required this.overview,
    required this.requirements,
    required this.onOpenExitSurvey,
  });

  @override
  State<StudentYudisiumRequirementPanel> createState() =>
      _StudentYudisiumRequirementPanelState();
}

class _StudentYudisiumRequirementPanelState
    extends State<StudentYudisiumRequirementPanel> {
  String? _downloadingItemId;

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.destructive : AppColors.successDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickAndUpload(
    YudisiumRequirementUploadStatus requirement,
  ) async {
    PlatformFile? file;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (result != null && result.files.isNotEmpty) file = result.files.first;
    } catch (exception) {
      _message('Gagal memilih file: $exception', error: true);
      return;
    }
    if (file == null || file.path == null) return;
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      _message('Format dokumen harus PDF.', error: true);
      return;
    }
    if (file.size > 10 * 1024 * 1024) {
      _message('Ukuran file maksimal 10 MB.', error: true);
      return;
    }
    try {
      await widget.controller.upload(
        filePath: file.path!,
        fileName: file.name,
        requirementId: requirement.id,
      );
      _message('Dokumen berhasil diunggah.');
    } catch (exception) {
      _message('Gagal mengunggah dokumen: $exception', error: true);
    }
  }

  Future<void> _download(YudisiumRequirementUploadStatus requirement) async {
    final contextData = widget.requirements;
    final document = requirement.document;
    if (contextData?.yudisiumId == null ||
        contextData?.participantId == null ||
        document == null) {
      _message('Identitas dokumen belum lengkap.', error: true);
      return;
    }
    setState(() => _downloadingItemId = document.itemId);
    try {
      final response = await widget.controller.downloadRequirement(
        yudisiumId: contextData!.yudisiumId!,
        participantId: contextData.participantId!,
        itemId: document.itemId,
      );
      final saved = await saveBinaryResponse(
        response,
        fallbackFileName: document.fileName ?? '${requirement.name}.pdf',
      );
      if (saved) _message('Dokumen berhasil disimpan.');
    } catch (exception) {
      _message('Gagal mengunduh dokumen: $exception', error: true);
    } finally {
      if (mounted) setState(() => _downloadingItemId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = widget.overview;
    final eventOpen = overview.yudisium?.status == YudisiumDisplayStatus.open;
    final activeStatus =
        widget.requirements?.participantStatus ?? overview.participantStatus;
    final documentLocked =
        !overview.allChecklistMet ||
        !eventOpen ||
        (activeStatus?.locksDocuments ?? false);

    return Column(
      children: [
        _ChecklistCard(
          checklist: overview.checklist,
          eventOpen: eventOpen,
          onOpenExitSurvey: widget.onOpenExitSurvey,
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          radius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Upload Dokumen Yudisium',
                      style: AppTextStyles.label,
                    ),
                  ),
                  Text(
                    'PDF, maks. 10 MB',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              if (documentLocked && activeStatus?.locksDocuments != true) ...[
                const SizedBox(height: 10),
                _RequirementNotice(
                  text: !eventOpen
                      ? 'Upload hanya tersedia saat pendaftaran yudisium dibuka.'
                      : 'Selesaikan persyaratan akademik dan exit survey terlebih dahulu.',
                ),
              ],
              const SizedBox(height: 10),
              if (widget.requirements?.requirements.isNotEmpty == true)
                for (final requirement
                    in widget.requirements!.requirements) ...[
                  _DocumentRow(
                    requirement: requirement,
                    locked: documentLocked,
                    uploading:
                        widget.controller.uploadingRequirementId ==
                        requirement.id,
                    downloading:
                        _downloadingItemId == requirement.document?.itemId,
                    onUpload: () => _pickAndUpload(requirement),
                    onDownload: () => _download(requirement),
                  ),
                  const SizedBox(height: 8),
                ]
              else if (overview.requirements.isNotEmpty)
                for (final requirement in overview.requirements) ...[
                  _PreviewDocumentRow(requirement: requirement),
                  const SizedBox(height: 8),
                ]
              else
                Text(
                  'Belum ada dokumen persyaratan untuk periode ini.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final YudisiumChecklist checklist;
  final bool eventOpen;
  final VoidCallback onOpenExitSurvey;

  const _ChecklistCard({
    required this.checklist,
    required this.eventOpen,
    required this.onOpenExitSurvey,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Checklist Persyaratan', style: AppTextStyles.label),
          const SizedBox(height: 12),
          for (final entry in checklist.orderedItems) ...[
            _ChecklistRow(
              item: entry.item,
              isExitSurvey: entry.key == 'exitSurvey',
              eventOpen: eventOpen,
              onOpenExitSurvey: onOpenExitSurvey,
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final YudisiumChecklistItem item;
  final bool isExitSurvey;
  final bool eventOpen;
  final VoidCallback onOpenExitSurvey;

  const _ChecklistRow({
    required this.item,
    required this.isExitSurvey,
    required this.eventOpen,
    required this.onOpenExitSurvey,
  });

  @override
  Widget build(BuildContext context) {
    final hasProgress = item.current != null && item.required != null;
    final status = item.met
        ? 'Terpenuhi'
        : hasProgress && item.current! > 0
        ? '${item.current}/${item.required}'
        : 'Menunggu';
    final canOpenSurvey = item.met || item.isAvailable;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: item.met
            ? AppColors.successLight.withValues(alpha: 0.5)
            : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.met
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: item.met
                ? AppColors.successDark
                : AppColors.surface,
            child: Icon(
              item.met ? Icons.check : Icons.schedule,
              size: 12,
              color: item.met ? Colors.white : AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  status,
                  style: AppTextStyles.caption.copyWith(
                    color: item.met
                        ? AppColors.successDark
                        : AppColors.textSecondary,
                  ),
                ),
                if (isExitSurvey && !canOpenSurvey)
                  Text(
                    eventOpen
                        ? 'Lengkapi seluruh persyaratan akademik terlebih dahulu.'
                        : 'Exit survey aktif saat pendaftaran dibuka.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          if (isExitSurvey)
            OutlinedButton(
              onPressed: canOpenSurvey ? onOpenExitSurvey : null,
              child: Text(item.met ? 'Lihat' : 'Isi Survey'),
            ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final YudisiumRequirementUploadStatus requirement;
  final bool locked;
  final bool uploading;
  final bool downloading;
  final VoidCallback onUpload;
  final VoidCallback onDownload;

  const _DocumentRow({
    required this.requirement,
    required this.locked,
    required this.uploading,
    required this.downloading,
    required this.onUpload,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final approved = requirement.status == DocumentStatus.approved;
    final declined = requirement.status == DocumentStatus.declined;
    final uploaded = requirement.document != null;
    final canUpload = !locked && !approved && !uploading;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: approved
                    ? AppColors.successDark
                    : declined
                    ? AppColors.destructive
                    : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requirement.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _documentStatus(requirement),
                      style: AppTextStyles.caption.copyWith(
                        color: approved
                            ? AppColors.successDark
                            : declined
                            ? AppColors.destructive
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (requirement.description?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              requirement.description!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (declined && requirement.validationNotes?.isNotEmpty == true) ...[
            const SizedBox(height: 5),
            Text(
              'Catatan: ${requirement.validationNotes}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.destructive,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              if (uploaded)
                OutlinedButton.icon(
                  onPressed: downloading ? null : onDownload,
                  icon: downloading
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  label: const Text('Unduh'),
                ),
              OutlinedButton.icon(
                onPressed: canUpload ? onUpload : null,
                icon: uploading
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_outlined),
                label: Text(uploaded ? 'Ganti File' : 'Upload'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _documentStatus(YudisiumRequirementUploadStatus value) =>
      switch (value.status) {
        DocumentStatus.approved => 'Terverifikasi',
        DocumentStatus.declined => 'Ditolak',
        DocumentStatus.submitted => 'Menunggu verifikasi',
        null => 'Belum diunggah',
      };
}

class _PreviewDocumentRow extends StatelessWidget {
  final YudisiumOverviewRequirement requirement;

  const _PreviewDocumentRow({required this.requirement});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.65,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                requirement.name,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const OutlinedButton(onPressed: null, child: Text('Upload')),
          ],
        ),
      ),
    );
  }
}

class _RequirementNotice extends StatelessWidget {
  final String text;

  const _RequirementNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline,
            size: 16,
            color: AppColors.warningDark,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.warningDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
