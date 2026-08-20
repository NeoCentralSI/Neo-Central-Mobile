import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/defence_api_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../thesis_shared/data/models/academic_requirement.dart';
import '../../../thesis_shared/presentation/widgets/authenticated_binary_download_button.dart';
import '../../data/models/defence_models.dart';

class DefenceIdentityPanel extends StatelessWidget {
  final DefenceDetail detail;

  const DefenceIdentityPanel({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final supervisors = [...detail.supervisors]
      ..sort((a, b) => a.role.compareTo(b.role));
    final examiners = [...detail.examiners]
      ..sort((a, b) => a.order.compareTo(b.order));
    final documents = _documentEntries();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Section(
            icon: Icons.calendar_today_outlined,
            title: 'Informasi Sidang TA',
            children: [
              _InfoRow(label: 'Nama Mahasiswa', value: detail.student.name),
              _InfoRow(label: 'NIM', value: detail.student.nim),
              for (final examiner in examiners)
                _InfoRow(
                  label: 'Penguji ${examiner.order}',
                  value: examiner.lecturerName,
                ),
              _InfoRow(
                label: 'Tanggal',
                value: _dateLabel(detail.date) ?? 'Belum dijadwalkan',
              ),
              _InfoRow(
                label: 'Waktu',
                value: _timeRange(detail.startTime, detail.endTime),
              ),
              _InfoRow(label: 'Ruangan', value: detail.room?.name ?? '-'),
              if (detail.room?.location != null)
                _InfoRow(label: 'Lokasi', value: detail.room!.location!),
              if (detail.meetingLink != null)
                _InfoRow(label: 'Link Daring', value: detail.meetingLink!),
              if (detail.scheduledAt != null)
                _InfoRow(
                  label: 'Jadwal Ditetapkan',
                  value: formatDateIndonesian(detail.scheduledAt!.toLocal()),
                ),
              if (detail.cancelledReason != null)
                _InfoRow(
                  label: 'Alasan Pembatalan',
                  value: detail.cancelledReason!,
                ),
              if (detail.status.canDownloadInvitation)
                AuthenticatedBinaryDownloadButton(
                  download: () =>
                      DefenceApiService().downloadInvitationLetter(detail.id),
                  fallbackFileName: 'Undangan-Sidang-TA.pdf',
                  successMessage: 'Surat undangan berhasil disimpan.',
                  errorPrefix: 'Gagal mengunduh surat undangan',
                  label: 'Unduh Surat Undangan',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          _Section(
            icon: Icons.menu_book_outlined,
            title: 'Informasi Tugas Akhir',
            children: [
              _InfoRow(label: 'Judul', value: detail.thesis.title),
              for (final supervisor in supervisors)
                _InfoRow(
                  label: formatRoleName(supervisor.role),
                  value: supervisor.name,
                ),
            ],
          ),
          if (documents.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.base),
            _Section(
              icon: Icons.description_outlined,
              title: 'Dokumen Sidang',
              children: documents,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  List<Widget> _documentEntries() {
    if (detail.documentTypes.isNotEmpty) {
      return detail.documentTypes
          .map((requirement) {
            DefenceDocument? document;
            for (final candidate in detail.documents) {
              if (candidate.requirementId == requirement.id) {
                document = candidate;
                break;
              }
            }
            return _DocumentRow(
              defenceId: detail.id,
              name: requirement.name,
              document: document,
            );
          })
          .toList(growable: false);
    }
    return detail.documents
        .map(
          (document) => _DocumentRow(
            defenceId: detail.id,
            name: document.requirementName ?? 'Dokumen Sidang',
            document: document,
          ),
        )
        .toList(growable: false);
  }

  String? _dateLabel(String? value) {
    final date = value == null ? null : DateTime.tryParse(value);
    return date == null ? null : formatDateIndonesian(date.toLocal());
  }

  String _timeRange(String? start, String? end) {
    final startLabel = _timeLabel(start);
    final endLabel = _timeLabel(end);
    if (startLabel == null && endLabel == null) return 'Belum dijadwalkan';
    if (endLabel == null) return '$startLabel WIB';
    return '$startLabel–$endLabel WIB';
  }

  String? _timeLabel(String? value) {
    if (value == null || value.isEmpty) return null;
    final plain = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
    if (plain != null) {
      return '${plain.group(1)!.padLeft(2, '0')}.${plain.group(2)}';
    }
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.hour.toString().padLeft(2, '0')}.${date.minute.toString().padLeft(2, '0')}';
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.label),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final String defenceId;
  final String name;
  final DefenceDocument? document;

  const _DocumentRow({
    required this.defenceId,
    required this.name,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    final current = document;
    final (statusLabel, variant) = _documentStatus(current?.status);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 20,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.label),
                    Text(
                      current?.fileName ?? 'Belum diunggah',
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (current != null)
                AppBadge(label: statusLabel, variant: variant),
            ],
          ),
          if (current?.submittedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Diunggah ${formatDateIndonesian(current!.submittedAt!.toLocal())}',
              style: AppTextStyles.caption,
            ),
          ],
          if (current?.notes != null) ...[
            const SizedBox(height: 6),
            Text(
              'Catatan: ${current!.notes}',
              style: AppTextStyles.caption.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (current != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: AuthenticatedBinaryDownloadButton(
                download: () => DefenceApiService().downloadDocument(
                  defenceId,
                  current.requirementId,
                ),
                fallbackFileName: current.fileName ?? 'Dokumen-Sidang-TA.pdf',
                successMessage: 'Dokumen berhasil disimpan.',
                errorPrefix: 'Gagal mengunduh dokumen',
                label: 'Unduh',
                style: BinaryDownloadButtonStyle.text,
              ),
            ),
          ],
        ],
      ),
    );
  }

  (String, BadgeVariant) _documentStatus(DocumentStatus? status) {
    return switch (status) {
      DocumentStatus.approved => ('Disetujui', BadgeVariant.success),
      DocumentStatus.declined => ('Ditolak', BadgeVariant.destructive),
      _ => ('Menunggu', BadgeVariant.warning),
    };
  }
}
