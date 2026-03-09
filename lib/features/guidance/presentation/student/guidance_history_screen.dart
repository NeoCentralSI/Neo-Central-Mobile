import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/student_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import 'guidance_schedule_screen.dart';
import 'session_summary_screen.dart';

/// Student guidance history screen – fetches sessions from backend
class GuidanceHistoryScreen extends StatefulWidget {
  final bool isTab;
  const GuidanceHistoryScreen({super.key, this.isTab = false});

  @override
  State<GuidanceHistoryScreen> createState() => _GuidanceHistoryScreenState();
}

class _GuidanceHistoryScreenState extends State<GuidanceHistoryScreen> {
  final _api = StudentApiService();

  bool _isLoading = true;
  String? _error;
  List<dynamic> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _sessions = await _api.getGuidanceHistory();
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  int _countByStatus(String status) =>
      _sessions.where((s) => s['status'] == status).length;

  @override
  Widget build(BuildContext context) {
    final completedCount = _countByStatus('completed');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSecondary,
        body: Column(
          children: [
            // ── Gradient Header ──────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryLight, AppColors.primary],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.sm,
                    AppSpacing.pagePadding,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.isTab)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Riwayat Bimbingan',
                                  style: AppTextStyles.h2.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total $completedCount Sesi Selesai',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.white.withValues(
                                      alpha: 0.85,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GuidanceScheduleScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Baru'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.white,
                              side: const BorderSide(color: AppColors.white),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.buttonRadius,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.pagePadding),
                        child: _error!.contains('Active thesis not found')
                            ? _buildRequirementsNotMet()
                            : _buildErrorState(),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: _sessions.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.4,
                                  child: Center(
                                    child: Text(
                                      'Belum ada riwayat bimbingan',
                                      style: AppTextStyles.body,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                // Session list with chips inside card
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.pagePadding,
                                      vertical: AppSpacing.md,
                                    ),
                                    child: AppCard(
                                      padding: EdgeInsets.zero,
                                      radius: 20,
                                      child: Column(
                                        children: [
                                          // Filter chips inside card
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              AppSpacing.cardPadding,
                                              AppSpacing.cardPadding,
                                              AppSpacing.cardPadding,
                                              AppSpacing.sm,
                                            ),
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                children: [
                                                  _StatChip(
                                                    label:
                                                        '${_countByStatus("completed")} Selesai',
                                                    icon: Icons.check_circle,
                                                    color: AppColors.success,
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpacing.sm,
                                                  ),
                                                  _StatChip(
                                                    label:
                                                        '${_countByStatus("accepted")} Dijadwalkan',
                                                    icon: Icons.event,
                                                    color: AppColors.info,
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpacing.sm,
                                                  ),
                                                  _StatChip(
                                                    label:
                                                        '${_countByStatus("requested")} Menunggu',
                                                    icon: Icons.hourglass_empty,
                                                    color: AppColors.warning,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const Divider(
                                            height: 1,
                                            color: AppColors.divider,
                                          ),
                                          // Session list
                                          Expanded(
                                            child: ListView.separated(
                                              padding: EdgeInsets.zero,
                                              itemCount: _sessions.length,
                                              separatorBuilder: (_, __) =>
                                                  const Divider(
                                                    height: 1,
                                                    color: AppColors.divider,
                                                  ),
                                              itemBuilder: (context, index) =>
                                                  _GuidanceSessionItem(
                                                    session: _sessions[index],
                                                    onRefresh: _loadData,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline,
          size: 48,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: 12),
        Text('Gagal memuat data', style: AppTextStyles.h4),
        const SizedBox(height: 8),
        AppButton(
          label: 'Coba Lagi',
          icon: Icons.refresh,
          onPressed: _loadData,
        ),
      ],
    );
  }

  Widget _buildRequirementsNotMet() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: Colors.amber,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Syarat Mata Kuliah Belum Terpenuhi',
          style: AppTextStyles.h3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Anda belum memenuhi persyaratan untuk mengambil mata kuliah Tugas Akhir. Anda harus tercatat mengambil mata kuliah Tugas Akhir (proposal disetujui).',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: const Text('Muat Ulang'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _StatChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceSessionItem extends StatefulWidget {
  final dynamic session;
  final VoidCallback onRefresh;
  const _GuidanceSessionItem({required this.session, required this.onRefresh});

  @override
  State<_GuidanceSessionItem> createState() => _GuidanceSessionItemState();
}

class _GuidanceSessionItemState extends State<_GuidanceSessionItem> {
  final _api = StudentApiService();
  bool _isCancelling = false;
  bool _isRescheduling = false;

  String get _guidanceId =>
      (widget.session['id'] ?? widget.session['guidanceId'] ?? '').toString();

  /// Whether the session is in a state that can be cancelled.
  bool get _canCancel {
    final status = (widget.session['status'] ?? '').toString();
    return status == 'requested' || status == 'accepted';
  }

  /// Whether the student can fill in session notes.
  /// Only for accepted (scheduled) sessions that have occurred.
  bool get _canFillNotes {
    final status = (widget.session['status'] ?? '').toString();
    if (status != 'accepted') return false;
    // Check if session summary already exists
    final summary = widget.session['sessionSummary'];
    if (summary != null && summary.toString().trim().isNotEmpty) return false;
    return true;
  }

  /// Reschedule is only allowed for 'requested' status.
  bool get _canReschedule {
    final status = (widget.session['status'] ?? '').toString();
    return status == 'requested';
  }

  Future<void> _showRescheduleDialog() async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Jadwal Ulang'),
            ],
          ),
          titleTextStyle: AppTextStyles.h4,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih tanggal dan waktu baru untuk sesi bimbingan.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              // Date picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.surfaceSecondary,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        selectedDate != null
                            ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                            : 'Pilih tanggal',
                        style: AppTextStyles.body.copyWith(
                          color: selectedDate != null
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Time picker
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedTime = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.surfaceSecondary,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        selectedTime != null
                            ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                            : 'Pilih waktu',
                        style: AppTextStyles.body.copyWith(
                          color: selectedTime != null
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Batal',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: selectedDate != null && selectedTime != null
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
              child: const Text('Jadwal Ulang'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true ||
        selectedDate == null ||
        selectedTime == null ||
        !mounted) {
      return;
    }

    final guidanceDate = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    setState(() => _isRescheduling = true);
    try {
      await _api.rescheduleGuidance(_guidanceId, guidanceDate: guidanceDate);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal bimbingan berhasil diubah'),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onRefresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isRescheduling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.destructive,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRescheduling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menjadwal ulang: $e'),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  Future<void> _showCancelDialog() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.destructiveLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.cancel_outlined,
                color: AppColors.destructive,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Batalkan Bimbingan?'),
          ],
        ),
        titleTextStyle: AppTextStyles.h4,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sesi bimbingan ini akan dibatalkan. Tindakan ini tidak bisa dikembalikan.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Alasan pembatalan (opsional)',
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.textTertiary,
                ),
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Kembali',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await _api.cancelGuidance(
        _guidanceId,
        reason: reasonController.text.trim().isNotEmpty
            ? reasonController.text.trim()
            : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bimbingan berhasil dibatalkan'),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onRefresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.destructive,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membatalkan: $e'),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
    reasonController.dispose();
  }

  Future<void> _navigateToSessionSummary() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SessionSummaryScreen(session: widget.session),
      ),
    );
    if (result == true) {
      widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.session['status'] ?? '').toString();
    final BadgeVariant variant;
    final String badgeLabel;

    switch (status) {
      case 'completed':
        variant = BadgeVariant.success;
        badgeLabel = 'Selesai';
        break;
      case 'accepted':
        variant = BadgeVariant.primary;
        badgeLabel = 'Dijadwalkan';
        break;
      case 'requested':
        variant = BadgeVariant.warning;
        badgeLabel = 'Menunggu';
        break;
      case 'rejected':
        variant = BadgeVariant.destructive;
        badgeLabel = 'Ditolak';
        break;
      case 'cancelled':
        variant = BadgeVariant.outline;
        badgeLabel = 'Dibatalkan';
        break;
      case 'summary_submitted':
        variant = BadgeVariant.warning;
        badgeLabel = 'Catatan Dikirim';
        break;
      default:
        variant = BadgeVariant.outline;
        badgeLabel = status;
    }

    // Use formatted date from backend, or raw requestedDate
    final dateStr =
        widget.session['requestedDateFormatted'] ??
        widget.session['approvedDateFormatted'] ??
        _formatDate(widget.session['requestedDate']) ??
        '-';
    final supervisorName = (widget.session['supervisorName'] ?? '-').toString();
    // Use studentNotes as topic if available
    final topic =
        (widget.session['studentNotes'] ??
                widget.session['topic'] ??
                'Bimbingan')
            .toString();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPadding,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            topic,
                            style: AppTextStyles.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppBadge(label: badgeLabel, variant: variant),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      supervisorName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 13,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(dateStr.toString(), style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Action Buttons ─────────────────────────────────
          if (_canFillNotes || _canCancel || _canReschedule) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (_canFillNotes)
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: _navigateToSessionSummary,
                        icon: const Icon(Icons.edit_note_rounded, size: 16),
                        label: const Text(
                          'Isi Catatan',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.buttonRadius,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ),
                // Spacer before icon buttons
                if (_canFillNotes && (_canReschedule || _canCancel))
                  const SizedBox(width: AppSpacing.sm),
                // Reschedule icon button
                if (_canReschedule)
                  _isRescheduling
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : Tooltip(
                          message: 'Jadwal Ulang',
                          child: Material(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: _showRescheduleDialog,
                              customBorder: const CircleBorder(),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.schedule,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                if (_canReschedule && _canCancel)
                  const SizedBox(width: AppSpacing.xs),
                // Cancel icon button
                if (_canCancel)
                  _isCancelling
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.destructive,
                            ),
                          ),
                        )
                      : Tooltip(
                          message: 'Batalkan',
                          child: Material(
                            color: AppColors.destructiveLight,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: _showCancelDialog,
                              customBorder: const CircleBorder(),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.destructive,
                                ),
                              ),
                            ),
                          ),
                        ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String? _formatDate(dynamic raw) {
    if (raw == null) return null;
    try {
      final dt = DateTime.parse(raw.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }
}
