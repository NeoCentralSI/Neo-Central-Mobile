import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/examiner_assignment_api_service.dart';
import '../../thesis_shared/data/models/examiner_assignment_models.dart';
import '../../thesis_shared/data/models/thesis_people_models.dart';
import '../../../shared/widgets/shared_widgets.dart';

/// Full-screen form to assign examiners to a seminar / defence.
///
/// Mobile counterpart to the web `LecturerThesisSeminarAssignExaminerDialog`
/// / `LecturerThesisDefenceAssignExaminerDialog`. We use an entire screen
/// rather than a modal because the picker list is dense and the schedule
/// dashboard needs vertical room.
class AssignExaminerFormScreen extends StatefulWidget {
  /// 'seminar' or 'defence'. Picks which API endpoint set to call.
  final String kind;

  /// Seminar or defence id.
  final String parentId;

  final String studentName;
  final String studentNim;
  final String thesisTitle;

  /// Existing examiners on this seminar/defence. Each item:
  /// `{ lecturerId, lecturerName, availabilityStatus, order }`.
  /// Examiners with `availabilityStatus == 'available'` are locked (cannot
  /// be changed). Other statuses are pre-selected but editable.
  final List<ExaminerAssignment> existingExaminers;

  /// Lecturers who previously rejected this assignment (shown as a hint).
  final List<ExaminerAssignment> rejectedExaminers;

  const AssignExaminerFormScreen({
    super.key,
    required this.kind,
    required this.parentId,
    required this.studentName,
    required this.studentNim,
    required this.thesisTitle,
    this.existingExaminers = const [],
    this.rejectedExaminers = const [],
  });

  @override
  State<AssignExaminerFormScreen> createState() =>
      _AssignExaminerFormScreenState();
}

class _AssignExaminerFormScreenState extends State<AssignExaminerFormScreen> {
  final _api = ExaminerAssignmentApiService();
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  List<EligibleExaminer> _lecturers = const [];
  final Set<String> _selectedIds = {};

  late final Set<String> _lockedIds = widget.existingExaminers
      .where(
        (examiner) =>
            examiner.availabilityStatus == ExaminerAvailabilityStatus.available,
      )
      .map((examiner) => examiner.lecturerId)
      .toSet();

  late final Set<String> _rejectedIds = widget.rejectedExaminers
      .map((examiner) => examiner.lecturerId)
      .toSet();

  bool get _isEdit => widget.existingExaminers.isNotEmpty;
  bool get _isPartialReplace => _lockedIds.isNotEmpty;
  bool get _requiresTwoExaminers => widget.kind == 'defence';
  bool get _selectionIsValid => _requiresTwoExaminers
      ? _selectedIds.length == 2
      : _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Pre-select active (non-unavailable) examiners.
    for (final examiner in widget.existingExaminers) {
      if (examiner.availabilityStatus !=
          ExaminerAvailabilityStatus.unavailable) {
        _selectedIds.add(examiner.lecturerId);
      }
    }
    _fetchEligible();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchEligible() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = widget.kind == 'seminar'
          ? await _api.getEligibleSeminarExaminers(widget.parentId)
          : await _api.getEligibleDefenceExaminers(widget.parentId);
      if (!mounted) return;
      setState(() {
        _lecturers = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<EligibleExaminer> get _filteredLecturers {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _lecturers;
    return _lecturers.where((l) {
      return l.fullName.toLowerCase().contains(q) ||
          l.identityNumber.toLowerCase().contains(q) ||
          l.scienceGroup.toLowerCase().contains(q);
    }).toList();
  }

  void _toggle(String id) {
    if (_lockedIds.contains(id)) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_requiresTwoExaminers && _selectedIds.length >= 2) {
          _toast(
            'Sidang Tugas Akhir menggunakan tepat 2 penguji',
            AppColors.warning,
          );
          return;
        }
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _submit() async {
    if (!_selectionIsValid) {
      _toast(
        _requiresTwoExaminers
            ? 'Harus memilih tepat 2 penguji'
            : 'Harus memilih minimal 1 penguji',
        AppColors.destructive,
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final ids = _selectedIds.toList();
      if (widget.kind == 'seminar') {
        await _api.assignSeminarExaminers(widget.parentId, ids);
      } else {
        await _api.assignDefenceExaminers(widget.parentId, ids);
      }
      if (!mounted) return;
      _toast('Penguji berhasil ditetapkan', AppColors.success);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _toast('Gagal menetapkan penguji: $e', AppColors.destructive);
    }
  }

  void _toast(String msg, Color bg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  String get _title {
    if (_isPartialReplace) return 'Ganti Penguji';
    if (_isEdit) return 'Ubah Penguji';
    return 'Tetapkan Penguji';
  }

  String get _submitLabel {
    if (_isPartialReplace) return 'Simpan Pengganti';
    if (_isEdit) return 'Simpan Perubahan';
    return 'Tetapkan Penguji';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStudentCard(),
            _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Header ──────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        12,
        AppSpacing.pagePadding,
        20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.kind == 'seminar' ? 'Seminar Hasil' : 'Sidang TA',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _title,
                  style: AppTextStyles.h1.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.base,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        radius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(widget.studentName, style: AppTextStyles.label),
                ),
                Text(
                  widget.studentNim,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.thesisTitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Cari dosen (nama / NIP / KBK)…',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  // ── Body states ─────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorBlock(message: _error!, onRetry: _fetchEligible);
    }
    final filtered = _filteredLecturers;
    if (filtered.isEmpty) {
      return _EmptyBlock(
        title: _searchCtrl.text.trim().isEmpty
            ? 'Tidak ada dosen tersedia'
            : 'Tidak ditemukan',
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        4,
        AppSpacing.pagePadding,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isPartialReplace
                    ? 'Pilih Dosen Pengganti'
                    : 'Pilih Dosen Penguji',
                style: AppTextStyles.label,
              ),
              AppBadge(
                label: _requiresTwoExaminers
                    ? '${_selectedIds.length}/2 dipilih'
                    : '${_selectedIds.length} dipilih',
                variant: !_selectionIsValid
                    ? BadgeVariant.secondary
                    : BadgeVariant.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _buildLecturerTile(filtered[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLecturerTile(EligibleExaminer lecturer) {
    final id = lecturer.id;
    final isSelected = _selectedIds.contains(id);
    final isLocked = _lockedIds.contains(id);
    final isRejected = _rejectedIds.contains(id);
    final isPrevious = lecturer.isPreviousExaminer;
    final ranges = lecturer.availabilityRanges;

    final order = isLocked
        ? widget.existingExaminers
              .firstWhere((examiner) => examiner.lecturerId == id)
              .order
        : (isSelected ? _selectedIds.toList().indexOf(id) + 1 : null);

    Color bg;
    if (isLocked) {
      bg = AppColors.surfaceSecondary;
    } else if (isSelected) {
      bg = AppColors.primary.withValues(alpha: 0.08);
    } else {
      bg = AppColors.surface;
    }

    return InkWell(
      onTap: isLocked ? null : () => _toggle(id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected && !isLocked
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: isLocked ? null : (_) => _toggle(id),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lecturer.fullName,
                        style: AppTextStyles.label.copyWith(
                          color: isLocked
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${lecturer.identityNumber} · ${lecturer.scienceGroup}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (order != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: AppBadge(
                      label: 'Penguji $order',
                      variant: isLocked
                          ? BadgeVariant.success
                          : BadgeVariant.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _ChipText(
                  icon: Icons.event_busy_outlined,
                  label: 'Acara Mendatang: ${lecturer.upcomingCount}',
                ),
                if (isLocked)
                  const _ChipText(
                    icon: Icons.lock_outline,
                    label: 'Sudah Bersedia',
                    color: AppColors.success,
                  ),
                if (isPrevious && !isLocked)
                  const _ChipText(
                    icon: Icons.history,
                    label: 'Penguji Sebelumnya',
                    color: AppColors.warning,
                  ),
                if (isRejected)
                  const _ChipText(
                    icon: Icons.cancel_outlined,
                    label: 'Pernah Menolak',
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
            if (ranges.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ketersediaan',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...ranges.take(3).map((range) {
                      return Text(
                        range.label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      );
                    }),
                    if (ranges.length > 3)
                      Text(
                        '+${ranges.length - 3} lainnya',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        12,
        AppSpacing.pagePadding,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
      ),
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: _isSubmitting || !_selectionIsValid ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  _submitLabel,
                  style: AppTextStyles.label.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── helpers ────────────────────────────────────────────────────

class _ChipText extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _ChipText({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBlock({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.destructive,
            ),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat dosen',
              style: AppTextStyles.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
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

class _EmptyBlock extends StatelessWidget {
  final String title;
  const _EmptyBlock({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 56,
            color: AppColors.textTertiary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
