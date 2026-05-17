import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/shared_widgets.dart';

/// Identitas panel — read-only summary of the defence identity.
///
/// Mirrors SeminarIdentityPanel but adds grade and final-score display
/// when the defence result is finalised.
class DefenceIdentityPanel extends StatelessWidget {
  final Map<String, dynamic> detail;
  const DefenceIdentityPanel({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final student = (detail['student'] as Map?) ?? const {};
    final thesis = (detail['thesis'] as Map?) ?? const {};
    final supervisors = ((detail['supervisors'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList()
      ..sort((a, b) =>
          (a['role'] ?? '').toString().compareTo((b['role'] ?? '').toString()));
    final examiners = ((detail['examiners'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final docTypes = ((detail['documentTypes'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final documents = ((detail['documents'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();

    final finalScore = detail['finalScore'];
    final grade = (detail['grade'] ?? '').toString();
    final resultFinalizedAt = (detail['resultFinalizedAt'] ?? '').toString();
    final isFinalized = resultFinalizedAt.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isFinalized) ...[
            _buildResultCard(finalScore, grade),
            const SizedBox(height: AppSpacing.base),
          ],
          _Section(
            icon: Icons.calendar_today_outlined,
            title: 'Informasi Sidang',
            children: [
              _InfoRow(label: 'Nama Mahasiswa', value: (student['name'] ?? '-').toString()),
              _InfoRow(label: 'NIM', value: (student['nim'] ?? '-').toString()),
              for (var i = 0; i < examiners.length; i++)
                _InfoRow(
                  label: 'Penguji ${examiners[i]['order'] ?? i + 1}',
                  value: (examiners[i]['lecturerName'] ?? '-').toString(),
                ),
              _InfoRow(
                label: 'Tanggal',
                value: _formatDate(detail['date']?.toString()) ??
                    'Belum dijadwalkan',
              ),
              _InfoRow(
                label: 'Waktu',
                value: _formatTimeRange(
                  detail['startTime']?.toString(),
                  detail['endTime']?.toString(),
                ),
              ),
              _InfoRow(
                label: 'Ruangan',
                value: ((detail['room'] as Map?)?['name'] ?? '-').toString(),
              ),
              if ((detail['meetingLink'] ?? '').toString().isNotEmpty)
                _InfoRow(
                  label: 'Link Daring',
                  value: detail['meetingLink'].toString(),
                ),
              if ((detail['invitationLetterNo'] ?? '').toString().isNotEmpty)
                _InfoRow(
                  label: 'No. Undangan',
                  value: detail['invitationLetterNo'].toString(),
                ),
              if ((detail['scheduledAt'] ?? '').toString().isNotEmpty)
                _InfoRow(
                  label: 'Jadwal Ditetapkan',
                  value: _formatDate(detail['scheduledAt']?.toString()) ?? '-',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          _Section(
            icon: Icons.menu_book_outlined,
            title: 'Informasi Tugas Akhir',
            children: [
              _InfoRow(
                label: 'Judul',
                value: (thesis['title'] ?? '-').toString(),
              ),
              for (var i = 0; i < supervisors.length; i++)
                _InfoRow(
                  label: (supervisors[i]['role'] ?? 'Pembimbing ${i + 1}')
                      .toString(),
                  value: (supervisors[i]['name'] ?? '-').toString(),
                ),
            ],
          ),
          if (docTypes.isNotEmpty || documents.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.base),
            _Section(
              icon: Icons.description_outlined,
              title: 'Dokumen Sidang',
              children: _buildDocuments(docTypes, documents),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildResultCard(dynamic finalScore, String grade) {
    final score = (finalScore as num?)?.toDouble();
    final isPass = score != null && score >= 55;
    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isPass
                  ? AppColors.successLight
                  : AppColors.destructive.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              grade.isNotEmpty ? grade : '-',
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.w900,
                color:
                    isPass ? AppColors.successDark : AppColors.destructiveDark,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nilai Akhir Sidang', style: AppTextStyles.label),
                const SizedBox(height: 4),
                if (score != null)
                  Text(
                    score.toStringAsFixed(2),
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isPass
                          ? AppColors.successDark
                          : AppColors.destructiveDark,
                    ),
                  ),
                const SizedBox(height: 4),
                AppBadge(
                  label: isPass ? 'LULUS' : 'TIDAK LULUS',
                  variant:
                      isPass ? BadgeVariant.success : BadgeVariant.destructive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDocuments(
    List<Map<String, dynamic>> docTypes,
    List<Map<String, dynamic>> documents,
  ) {
    final list = docTypes.isNotEmpty
        ? docTypes.map((dt) {
            final doc = documents.firstWhere(
              (d) => d['documentTypeId'] == dt['id'],
              orElse: () => const {},
            );
            return _DocumentRow(
              name: (dt['name'] ?? 'Dokumen').toString(),
              document: doc.isEmpty ? null : doc,
            );
          }).toList()
        : documents
            .map((doc) => _DocumentRow(
                  name: (doc['documentTypeName'] ?? 'Dokumen').toString(),
                  document: doc,
                ))
            .toList();
    return list;
  }

  static String? _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return null;
    }
  }

  static String _formatTimeRange(String? startIso, String? endIso) {
    final start = _extractTime(startIso);
    final end = _extractTime(endIso);
    if (start == null && end == null) return '--:--';
    if (end == null) return '$start WIB';
    return '$start – $end WIB';
  }

  static String? _extractTime(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final d = DateTime.parse(iso);
      return '${d.toUtc().hour.toString().padLeft(2, '0')}.${d.toUtc().minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return null;
    }
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
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
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
  final String name;
  final Map<String, dynamic>? document;

  const _DocumentRow({required this.name, this.document});

  @override
  Widget build(BuildContext context) {
    final doc = document;
    final status = (doc?['status'] ?? '').toString();
    final fileName = (doc?['fileName'] ?? 'Belum diunggah').toString();
    final submittedAt = doc?['submittedAt']?.toString();

    final hasDoc = doc != null;
    final (label, variant) = _statusDisplay(status);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: hasDoc ? AppColors.successLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description,
                  size: 16,
                  color: hasDoc
                      ? AppColors.successDark
                      : AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      submittedAt != null
                          ? '$fileName • ${_formatShort(submittedAt)}'
                          : fileName,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasDoc) AppBadge(label: label, variant: variant),
            ],
          ),
          if ((doc?['notes'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Catatan: ${doc!['notes']}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static (String, BadgeVariant) _statusDisplay(String s) {
    switch (s) {
      case 'approved':
        return ('Disetujui', BadgeVariant.success);
      case 'declined':
        return ('Ditolak', BadgeVariant.destructive);
      default:
        return ('Menunggu', BadgeVariant.warning);
    }
  }

  static String _formatShort(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
