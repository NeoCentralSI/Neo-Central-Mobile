import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/binary_download.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../data/models/yudisium_models.dart';
import '../controllers/student_yudisium_controller.dart';
import 'student_yudisium_cpl_history_panel.dart';
import 'student_yudisium_requirement_panel.dart';

class StudentYudisiumOverviewPanel extends StatefulWidget {
  final StudentYudisiumController controller;
  final StudentYudisiumOverview overview;
  final StudentYudisiumRequirements? requirements;
  final VoidCallback onOpenExitSurvey;

  const StudentYudisiumOverviewPanel({
    super.key,
    required this.controller,
    required this.overview,
    required this.requirements,
    required this.onOpenExitSurvey,
  });

  @override
  State<StudentYudisiumOverviewPanel> createState() =>
      _StudentYudisiumOverviewPanelState();
}

class _StudentYudisiumOverviewPanelState
    extends State<StudentYudisiumOverviewPanel> {
  String? _downloading;

  Future<void> _download({required bool certificate}) async {
    if (_downloading != null) return;
    final key = certificate ? 'certificate' : 'cpl';
    setState(() => _downloading = key);
    try {
      final response = certificate
          ? await widget.controller.downloadCertificate()
          : await widget.controller.downloadCplReport();
      final saved = await saveBinaryResponse(
        response,
        fallbackFileName: certificate
            ? 'Sertifikat-Yudisium-${widget.overview.studentNim}.pdf'
            : 'Laporan-CPL-${widget.overview.studentNim}.pdf',
      );
      if (saved) _message('Dokumen berhasil disimpan.');
    } catch (exception) {
      _message('Gagal mengunduh dokumen: $exception', error: true);
    } finally {
      if (mounted) setState(() => _downloading = null);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final overview = widget.overview;
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: widget.controller.load,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              if (widget.controller.error != null)
                _InlineNotice(
                  text: widget.controller.error!,
                  color: AppColors.destructive,
                ),
              if (overview.yudisium == null)
                _EmptyPeriodBanner(onReload: widget.controller.load)
              else
                _IdentityCard(
                  overview: overview,
                  downloading: _downloading,
                  onDownloadCpl: () => _download(certificate: false),
                  onDownloadCertificate: () => _download(certificate: true),
                ),
              const SizedBox(height: AppSpacing.base),
              _StatusCard(overview: overview),
              const SizedBox(height: AppSpacing.base),
              StudentYudisiumRequirementPanel(
                controller: widget.controller,
                overview: overview,
                requirements: widget.requirements,
                onOpenExitSurvey: widget.onOpenExitSurvey,
              ),
              if (overview.cplScores.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.base),
                StudentYudisiumCplPanel(scores: overview.cplScores),
              ],
              if (overview.history.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.base),
                StudentYudisiumHistoryPanel(items: overview.history),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
        if (widget.controller.isLoading)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

class _EmptyPeriodBanner extends StatelessWidget {
  final VoidCallback onReload;

  const _EmptyPeriodBanner({required this.onReload});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_busy_outlined, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Periode Yudisium Belum Tersedia',
                  style: AppTextStyles.h4,
                ),
                const SizedBox(height: 4),
                Text(
                  'Belum ada periode yudisium yang dibuka. Exit survey dan upload dokumen akan aktif pada periode pendaftaran.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: onReload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final StudentYudisiumOverview overview;
  final String? downloading;
  final VoidCallback onDownloadCpl;
  final VoidCallback onDownloadCertificate;

  const _IdentityCard({
    required this.overview,
    required this.downloading,
    required this.onDownloadCpl,
    required this.onDownloadCertificate,
  });

  @override
  Widget build(BuildContext context) {
    final event = overview.yudisium!;
    final participant = overview.participantStatus;
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Informasi Yudisium', style: AppTextStyles.label),
              AppBadge(
                label: _eventStatusLabel(event.status),
                variant: _eventStatusVariant(event.status),
              ),
              if (participant != null)
                AppBadge(
                  label: _participantStatusLabel(participant),
                  variant: _participantStatusVariant(participant),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.emoji_events_outlined,
            label: 'Periode',
            value: event.name,
          ),
          _InfoRow(
            icon: Icons.date_range_outlined,
            label: 'Pendaftaran',
            value:
                '${_formatDate(event.registrationOpenDate)} – ${_formatDate(event.registrationCloseDate)}',
          ),
          _InfoRow(
            icon: Icons.event_available_outlined,
            label: 'Pelaksanaan',
            value: _formatDate(event.eventDate),
          ),
          _InfoRow(
            icon: Icons.place_outlined,
            label: 'Ruangan',
            value: event.room?.name ?? '-',
          ),
          if (participant?.canDownloadCplReport == true ||
              participant?.canDownloadCertificate == true) ...[
            const SizedBox(height: 10),
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (participant?.canDownloadCplReport == true)
                  OutlinedButton.icon(
                    onPressed: downloading == null ? onDownloadCpl : null,
                    icon: downloading == 'cpl'
                        ? const _SmallLoader()
                        : const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Laporan CPL'),
                  ),
                if (participant?.canDownloadCertificate == true)
                  OutlinedButton.icon(
                    onPressed: downloading == null
                        ? onDownloadCertificate
                        : null,
                    icon: downloading == 'certificate'
                        ? const _SmallLoader()
                        : const Icon(Icons.workspace_premium_outlined),
                    label: const Text('Sertifikat'),
                  ),
              ],
            ),
          ],
          if (event.status == YudisiumDisplayStatus.draft ||
              event.status == YudisiumDisplayStatus.closed) ...[
            const SizedBox(height: 10),
            _InlineNotice(
              text: event.status == YudisiumDisplayStatus.draft
                  ? 'Pendaftaran belum dibuka. Exit survey dan upload dokumen masih terkunci.'
                  : 'Pendaftaran sudah ditutup. Hubungi Koordinator Yudisium jika Anda belum terdaftar.',
              color: AppColors.warningDark,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final StudentYudisiumOverview overview;

  const _StatusCard({required this.overview});

  static const _steps = [
    'Checklist Persyaratan & Survey',
    'Verifikasi Dokumen & Validasi CPL',
    'Eligibel',
    'Ditetapkan sebagai Peserta',
    'Lulus Yudisium',
  ];

  @override
  Widget build(BuildContext context) {
    final active = overview.activeStepIndex;
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Status Yudisium', style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(
            'Progres pengajuan yudisium Anda',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < _steps.length; index++)
            _StatusStep(
              label: _steps[index],
              met: index <= active,
              showLine: index < _steps.length - 1,
              lineMet: index < active,
            ),
          const SizedBox(height: 8),
          AppProgressBar(value: active < 0 ? 0 : (active + 1) / _steps.length),
          const SizedBox(height: 6),
          Text(
            active < 0
                ? 'Checklist persyaratan belum terpenuhi'
                : '${active + 1} dari ${_steps.length} tahap selesai',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final String label;
  final bool met;
  final bool showLine;
  final bool lineMet;

  const _StatusStep({
    required this.label,
    required this.met,
    required this.showLine,
    required this.lineMet,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: met ? AppColors.successDark : AppColors.surface,
                    border: Border.all(
                      color: met ? AppColors.successDark : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    met ? Icons.check : Icons.schedule,
                    size: 12,
                    color: met ? Colors.white : AppColors.textTertiary,
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineMet ? AppColors.successDark : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    met ? 'Terpenuhi' : 'Menunggu',
                    style: AppTextStyles.caption.copyWith(
                      color: met
                          ? AppColors.successDark
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final String text;
  final Color color;

  const _InlineNotice({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallLoader extends StatelessWidget {
  const _SmallLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  const months = [
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
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

String _eventStatusLabel(YudisiumDisplayStatus status) => switch (status) {
  YudisiumDisplayStatus.draft => 'Draft',
  YudisiumDisplayStatus.open => 'Pendaftaran Dibuka',
  YudisiumDisplayStatus.closed => 'Pendaftaran Ditutup',
  YudisiumDisplayStatus.ongoing => 'Berlangsung',
  YudisiumDisplayStatus.completed => 'Selesai',
};

BadgeVariant _eventStatusVariant(YudisiumDisplayStatus status) =>
    switch (status) {
      YudisiumDisplayStatus.open ||
      YudisiumDisplayStatus.ongoing => BadgeVariant.primary,
      YudisiumDisplayStatus.completed => BadgeVariant.success,
      YudisiumDisplayStatus.closed => BadgeVariant.warning,
      YudisiumDisplayStatus.draft => BadgeVariant.secondary,
    };

String _participantStatusLabel(YudisiumParticipantStatus status) =>
    switch (status) {
      YudisiumParticipantStatus.registered => 'Proses Verifikasi',
      YudisiumParticipantStatus.eligible => 'Eligibel',
      YudisiumParticipantStatus.appointed => 'Peserta Yudisium',
      YudisiumParticipantStatus.rejected => 'Tidak Memenuhi',
      YudisiumParticipantStatus.finalized => 'Lulus Yudisium',
    };

BadgeVariant _participantStatusVariant(YudisiumParticipantStatus status) =>
    switch (status) {
      YudisiumParticipantStatus.registered => BadgeVariant.warning,
      YudisiumParticipantStatus.eligible ||
      YudisiumParticipantStatus.appointed ||
      YudisiumParticipantStatus.finalized => BadgeVariant.success,
      YudisiumParticipantStatus.rejected => BadgeVariant.destructive,
    };
