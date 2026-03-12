import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/student_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';

/// Screen for student to view and update milestone progress.
class MilestoneProgressScreen extends StatefulWidget {
  final String thesisId;
  const MilestoneProgressScreen({super.key, required this.thesisId});

  @override
  State<MilestoneProgressScreen> createState() =>
      _MilestoneProgressScreenState();
}

class _MilestoneProgressScreenState extends State<MilestoneProgressScreen> {
  final _api = StudentApiService();

  bool _isLoading = true;
  String? _error;
  List<dynamic> _milestones = [];

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
      _milestones = await _api.getMilestones(widget.thesisId);
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

  int get _overallProgress {
    if (_milestones.isEmpty) return 0;
    final total = _milestones.fold<int>(
      0,
      (sum, m) => sum + ((m['progressPercentage'] as num?)?.toInt() ?? 0),
    );
    return (total / _milestones.length).round();
  }

  int get _completedCount =>
      _milestones.where((m) => m['status'] == 'completed').length;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSecondary,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: _milestones.isEmpty
                              ? ListView(
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.4,
                                      child: Center(
                                        child: Text(
                                          'Belum ada milestone',
                                          style: AppTextStyles.body,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.pagePadding,
                                    AppSpacing.md,
                                    AppSpacing.pagePadding,
                                    100,
                                  ),
                                  children: [
                                    AppCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          for (int i = 0;
                                              i < _milestones.length;
                                              i++)
                                            _MilestoneTimelineItem(
                                              milestone: _milestones[i],
                                              index: i + 1,
                                              isLast:
                                                  i == _milestones.length - 1,
                                              onUpdate: _loadData,
                                            ),
                                        ],
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

  Widget _buildHeader() {
    return Container(
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
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Milestone',
                          style:
                              AppTextStyles.h2.copyWith(color: AppColors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_completedCount/${_milestones.length} milestone selesai',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Overall progress ring
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white.withValues(alpha: 0.15),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            value: _overallProgress / 100,
                            strokeWidth: 4,
                            strokeCap: StrokeCap.round,
                            backgroundColor:
                                AppColors.white.withValues(alpha: 0.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.white),
                          ),
                        ),
                        Text(
                          '$_overallProgress%',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text('Gagal memuat data', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          AppButton(
            label: 'Coba Lagi',
            icon: Icons.refresh,
            onPressed: _loadData,
            width: 160,
          ),
        ],
      ),
    );
  }
}

// ─── Milestone Timeline Item ─────────────────────────────────
class _MilestoneTimelineItem extends StatefulWidget {
  final dynamic milestone;
  final int index;
  final bool isLast;
  final VoidCallback onUpdate;

  const _MilestoneTimelineItem({
    required this.milestone,
    required this.index,
    required this.isLast,
    required this.onUpdate,
  });

  @override
  State<_MilestoneTimelineItem> createState() => _MilestoneTimelineItemState();
}

class _MilestoneTimelineItemState extends State<_MilestoneTimelineItem> {
  final _api = StudentApiService();
  bool _isUpdating = false;
  double _sliderValue = 0;
  bool _showSlider = false;

  String get _milestoneId =>
      (widget.milestone['id'] ?? widget.milestone['milestoneId'] ?? '')
          .toString();

  String get _name =>
      (widget.milestone['name'] ?? widget.milestone['title'] ?? 'Milestone')
          .toString();

  String get _status =>
      (widget.milestone['status'] ?? 'not_started').toString();

  int get _progress =>
      (widget.milestone['progressPercentage'] as num?)?.toInt() ?? 0;

  bool get _canUpdate =>
      _status != 'completed';

  String get _deadline {
    final raw = widget.milestone['deadline'] ?? widget.milestone['dueDate'];
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString());
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    _sliderValue = _progress.toDouble();
  }

  @override
  void didUpdateWidget(covariant _MilestoneTimelineItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_showSlider) {
      _sliderValue = _progress.toDouble();
    }
  }

  Color get _dotColor {
    switch (_status) {
      case 'completed':
        return AppColors.success;
      case 'in_progress':
        return AppColors.primary;
      case 'pending_review':
        return AppColors.warning;
      case 'revision_needed':
        return AppColors.destructive;
      default:
        return AppColors.border;
    }
  }

  BadgeVariant get _statusBadgeVariant {
    switch (_status) {
      case 'completed':
        return BadgeVariant.success;
      case 'in_progress':
        return BadgeVariant.primary;
      case 'pending_review':
        return BadgeVariant.warning;
      case 'revision_needed':
        return BadgeVariant.destructive;
      default:
        return BadgeVariant.secondary;
    }
  }

  String get _statusLabel {
    switch (_status) {
      case 'completed':
        return 'Selesai';
      case 'in_progress':
        return 'Dikerjakan';
      case 'pending_review':
        return 'Menunggu Review';
      case 'revision_needed':
        return 'Perlu Revisi';
      case 'not_started':
        return 'Belum Dimulai';
      default:
        return _status;
    }
  }

  Future<void> _updateProgress() async {
    final newProgress = _sliderValue.round();
    if (newProgress == _progress) {
      setState(() => _showSlider = false);
      return;
    }

    setState(() => _isUpdating = true);
    try {
      await _api.updateMilestoneProgress(
        _milestoneId,
        progressPercentage: newProgress,
      );

      // If status is not_started and progress > 0, also update status
      if (_status == 'not_started' && newProgress > 0) {
        await _api.updateMilestoneStatus(
          _milestoneId,
          status: 'in_progress',
        );
      }

      if (!mounted) return;
      setState(() {
        _isUpdating = false;
        _showSlider = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Progress diperbarui ke $newProgress%'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      widget.onUpdate();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.destructive,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui progress: $e'),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline rail (dot + vertical line) ──
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Dot
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                    border: _status == 'not_started'
                        ? Border.all(color: AppColors.border, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: _status == 'completed'
                        ? const Icon(Icons.check, size: 14, color: AppColors.white)
                        : Text(
                            '${widget.index}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: _status == 'not_started'
                                  ? AppColors.textTertiary
                                  : AppColors.white,
                              fontSize: 11,
                            ),
                          ),
                  ),
                ),
                // Vertical connector line
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: _status == 'completed'
                          ? AppColors.success.withValues(alpha: 0.4)
                          : AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // ── Content ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: widget.isLast ? 0 : AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Badge row
                  Row(
                    children: [
                      Expanded(
                        child: Text(_name, style: AppTextStyles.label),
                      ),
                      const SizedBox(width: 8),
                      AppBadge(label: _statusLabel, variant: _statusBadgeVariant),
                    ],
                  ),
                  if (_deadline.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(_deadline, style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  // Progress bar
                  Row(
                    children: [
                      Expanded(child: AppProgressBar(value: _progress / 100)),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '$_progress%',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 11,
                          color: _progress >= 100
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Update progress section (expandable)
                  if (_canUpdate) ...[
                    const SizedBox(height: AppSpacing.sm),
                    if (_showSlider) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Text(
                            '${_sliderValue.round()}%',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primary,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor:
                                    AppColors.primary.withValues(alpha: 0.15),
                                thumbColor: AppColors.primary,
                                overlayColor:
                                    AppColors.primary.withValues(alpha: 0.12),
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                ),
                              ),
                              child: Slider(
                                value: _sliderValue,
                                min: 0,
                                max: 100,
                                divisions: 20,
                                onChanged: (v) =>
                                    setState(() => _sliderValue = v),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: OutlinedButton(
                                onPressed: () => setState(() {
                                  _showSlider = false;
                                  _sliderValue = _progress.toDouble();
                                }),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: const BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text('Batal', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: ElevatedButton.icon(
                                onPressed: _isUpdating ? null : _updateProgress,
                                icon: _isUpdating
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save_rounded, size: 14),
                                label: const Text('Simpan', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      SizedBox(
                        height: 30,
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _showSlider = true),
                          icon: const Icon(Icons.edit_outlined, size: 13),
                          label: const Text('Update', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.buttonRadius),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      ),
                  ],

                  // Revision notes
                  if (_status == 'revision_needed' &&
                      widget.milestone['revisionNotes'] != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.destructiveLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              size: 14, color: AppColors.destructiveDark),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Catatan Revisi',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.destructiveDark,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.milestone['revisionNotes'].toString(),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.destructiveDark,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
