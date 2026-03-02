import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/student_api_service.dart';
import '../../../../core/utils/formatters.dart' as fmt;
import '../../../../shared/widgets/shared_widgets.dart';

/// Student screen to request a new guidance session (bimbingan).
///
/// Loads real supervisors + milestones from API and submits via
/// POST /thesisGuidance/student/guidance/request (multipart/form-data).
class GuidanceScheduleScreen extends StatefulWidget {
  final bool isTab;
  const GuidanceScheduleScreen({super.key, this.isTab = false});

  @override
  State<GuidanceScheduleScreen> createState() => _GuidanceScheduleScreenState();
}

class _GuidanceScheduleScreenState extends State<GuidanceScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _docUrlController = TextEditingController();
  final StudentApiService _api = StudentApiService();

  // ── Data from API ──────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  // ignore: unused_field — kept for potential future use (e.g. file upload)
  String _thesisId = '';
  List<Map<String, dynamic>> _supervisors = [];
  List<Map<String, dynamic>> _milestones = [];

  // ── Form state ─────────────────────────────────────────────
  String? _selectedSupervisorId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _duration = 60;
  final Set<String> _selectedMilestoneIds = {};
  bool _showAdvanced = false;
  bool _isSubmitting = false;
  String? _selectedFilePath;
  String? _selectedFileName;

  // ── Availability ───────────────────────────────────────────
  List<Map<String, dynamic>> _busySlots = [];
  bool _hasConflict = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _docUrlController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // DATA LOADING
  // ─────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supervisorsRes = await _api.getSupervisorsWithThesisId();

      final supervisors =
          (supervisorsRes['supervisors'] as List<dynamic>?) ?? [];
      final thesisId = (supervisorsRes['thesisId'] as String?) ?? '';

      List<dynamic> milestones = [];
      if (thesisId.isNotEmpty) {
        milestones = await _api.getMilestones(thesisId);
      }

      if (!mounted) return;
      setState(() {
        _thesisId = thesisId;
        _supervisors = supervisors
            .map((s) => Map<String, dynamic>.from(s as Map))
            .toList();
        _milestones = milestones
            .where((m) {
              final status = (m['status'] as String?) ?? '';
              // Only show non-completed milestones
              return status != 'completed';
            })
            .map((m) => Map<String, dynamic>.from(m as Map))
            .toList();

        // Default to Pembimbing 1 (first supervisor)
        if (_supervisors.isNotEmpty && _selectedSupervisorId == null) {
          // Sort: pembimbing1 first
          _supervisors.sort((a, b) {
            final roleA = ((a['role'] ?? '') as String).toLowerCase();
            final roleB = ((b['role'] ?? '') as String).toLowerCase();
            if (roleA.contains('pembimbing1') ||
                roleA.contains('pembimbing 1')) {
              return -1;
            }
            if (roleB.contains('pembimbing1') ||
                roleB.contains('pembimbing 1')) {
              return 1;
            }
            return roleA.compareTo(roleB);
          });
          _selectedSupervisorId = _supervisors.first['id'] as String?;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e is ApiException ? e.message : e.toString();
      });
    }
  }

  // ─────────────────────────────────────────────────────────
  // AVAILABILITY CHECK
  // ─────────────────────────────────────────────────────────

  Future<void> _checkAvailability() async {
    if (_selectedSupervisorId == null || _selectedDate == null) return;

    try {
      final dayStart = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      ).toUtc().toIso8601String();
      final dayEnd = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        23,
        59,
        59,
      ).toUtc().toIso8601String();

      final slots = await _api.getSupervisorAvailability(
        _selectedSupervisorId!,
        start: dayStart,
        end: dayEnd,
      );

      if (!mounted) return;
      setState(() {
        _busySlots = slots
            .map((s) => Map<String, dynamic>.from(s as Map))
            .toList();
        _hasConflict = _checkTimeConflict();
      });
    } catch (_) {
      // Silently ignore availability check errors
    }
  }

  bool _checkTimeConflict() {
    if (_selectedDate == null || _selectedTime == null) return false;

    final requestStart = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final requestEnd = requestStart.add(Duration(minutes: _duration));

    for (final slot in _busySlots) {
      final slotStart = DateTime.tryParse(slot['start'] ?? '');
      final slotEnd = DateTime.tryParse(slot['end'] ?? '');
      if (slotStart == null || slotEnd == null) continue;

      final localStart = slotStart.toLocal();
      final localEnd = slotEnd.toLocal();

      // Overlap check
      if (requestStart.isBefore(localEnd) && requestEnd.isAfter(localStart)) {
        return true;
      }
    }
    return false;
  }

  // ─────────────────────────────────────────────────────────
  // DATE & TIME PICKERS
  // ─────────────────────────────────────────────────────────

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _checkAvailability();
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _hasConflict = _checkTimeConflict();
      });
    }
  }

  // ─────────────────────────────────────────────────────────
  // SUBMIT
  // ─────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedTime == null) {
      _showSnackBar(
        'Pilih tanggal dan waktu bimbingan terlebih dahulu.',
        false,
      );
      return;
    }

    if (_selectedMilestoneIds.isEmpty) {
      _showSnackBar('Pilih minimal 1 milestone yang ingin dibahas.', false);
      return;
    }

    if (_hasConflict) {
      _showSnackBar(
        'Waktu yang dipilih bentrok dengan jadwal dosen. Pilih waktu lain.',
        false,
      );
      return;
    }

    // Build ISO datetime
    final dateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    setState(() => _isSubmitting = true);

    try {
      await _api.requestGuidance(
        guidanceDate: dateTime.toUtc().toIso8601String(),
        milestoneIds: _selectedMilestoneIds.toList(),
        studentNotes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        supervisorId: _selectedSupervisorId,
        documentUrl: _docUrlController.text.trim().isNotEmpty
            ? _docUrlController.text.trim()
            : null,
        duration: _duration,
        filePath: _selectedFilePath,
        fileName: _selectedFileName,
      );

      if (!mounted) return;
      _showSnackBar('Permintaan bimbingan berhasil dikirim!', true);

      if (widget.isTab) {
        // Reset form when used as a tab
        _resetForm();
      } else {
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message, false);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal mengirim permintaan: $e', false);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
      _duration = 60;
      _selectedMilestoneIds.clear();
      _showAdvanced = false;
      _busySlots = [];
      _hasConflict = false;
      _selectedFilePath = null;
      _selectedFileName = null;
    });
    _notesController.clear();
    _docUrlController.clear();
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.success : AppColors.destructive,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.base),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────

  String _formatRoleName(String role) => fmt.formatRoleName(role);

  String _toTitleCase(String name) => fmt.toTitleCase(name);

  String _formatDate(DateTime date) => fmt.formatDateIndonesian(date);

  String _formatTime(TimeOfDay t) => fmt.formatTime(t);

  bool get _canSubmit =>
      _selectedDate != null &&
      _selectedTime != null &&
      _selectedMilestoneIds.isNotEmpty &&
      !_hasConflict &&
      !_isSubmitting;

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
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
          child: Row(
            children: [
              if (!widget.isTab)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: AppColors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              Text(
                'Ajukan Bimbingan',
                style: AppTextStyles.h2.copyWith(color: AppColors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
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
              const SizedBox(height: AppSpacing.base),
              Text(
                'Gagal memuat data',
                style: AppTextStyles.h4.copyWith(color: AppColors.destructive),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.base),
              AppButton(label: 'Coba Lagi', onPressed: _loadData),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main form card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bimbingan Baru', style: AppTextStyles.h4),
                            const SizedBox(height: 2),
                            Text(
                              'Atur jadwal pertemuan dengan dosen',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const AppDivider(),

                    // ── Supervisor selection ──
                    _buildSupervisorSection(),

                    const SizedBox(height: AppSpacing.base),

                    // ── Date picker ──
                    _buildDateSection(),

                    const SizedBox(height: AppSpacing.base),

                    // ── Time picker ──
                    _buildTimeSection(),

                    const SizedBox(height: AppSpacing.base),

                    // ── Duration selector ──
                    _buildDurationSection(),

                    const SizedBox(height: AppSpacing.base),

                    // ── Milestone selection ──
                    _buildMilestoneSection(),

                    const SizedBox(height: AppSpacing.base),

                    // ── Notes ──
                    _buildNotesSection(),

                    const SizedBox(height: AppSpacing.base),

                    // ── File attachment ──
                    _buildFileSection(),

                    // ── Advanced options (document URL) ──
                    _buildAdvancedSection(),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.base),

              // ── Conflict warning ──
              if (_hasConflict) _buildConflictWarning(),

              // ── Busy slots info ──
              if (_busySlots.isNotEmpty && !_hasConflict) _buildBusySlotsInfo(),

              const SizedBox(height: AppSpacing.base),

              // Info note
              AppCard(
                backgroundColor: AppColors.infoLight,
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Permintaan akan dikirim ke dosen pembimbing. Anda akan mendapat notifikasi setelah disetujui.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.infoDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Submit button
              AppButton(
                label: 'Kirim Permintaan',
                icon: Icons.send_outlined,
                onPressed: _canSubmit ? _submit : null,
                isLoading: _isSubmitting,
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SECTION BUILDERS
  // ─────────────────────────────────────────────────────────

  Widget _buildSupervisorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PILIH PEMBIMBING', style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        if (_supervisors.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Belum ada pembimbing yang ditugaskan.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warningDark,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Row(
            children: _supervisors.asMap().entries.map((entry) {
              final idx = entry.key;
              final sup = entry.value;
              final id = sup['id'] as String? ?? '';
              final name = (sup['name'] as String?) ?? '';
              final role = (sup['role'] as String?) ?? '';
              final isSelected = _selectedSupervisorId == id;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedSupervisorId = id);
                    _checkAvailability();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                      right: idx < _supervisors.length - 1 ? 4 : 0,
                      left: idx > 0 ? 4 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.smallRadius,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _formatRoleName(role),
                          style: AppTextStyles.label.copyWith(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _toTitleCase(name),
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected
                                ? AppColors.white.withValues(alpha: 0.8)
                                : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TANGGAL BIMBINGAN *', style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: _selectedDate == null
                      ? AppColors.textTertiary
                      : AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  _selectedDate == null
                      ? 'Pilih tanggal...'
                      : _formatDate(_selectedDate!),
                  style: AppTextStyles.body.copyWith(
                    color: _selectedDate == null
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WAKTU BIMBINGAN *', style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: _selectTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: _selectedTime == null
                      ? AppColors.textTertiary
                      : AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  _selectedTime == null
                      ? 'Pilih waktu...'
                      : _formatTime(_selectedTime!),
                  style: AppTextStyles.body.copyWith(
                    color: _selectedTime == null
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DURASI', style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [30, 60, 90, 120].map((mins) {
            final isSelected = _duration == mins;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _duration = mins;
                    _hasConflict = _checkTimeConflict();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    '$mins mnt',
                    style: AppTextStyles.label.copyWith(
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMilestoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('MILESTONE YANG DIBAHAS *', style: AppTextStyles.labelSmall),
            const Spacer(),
            if (_selectedMilestoneIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                ),
                child: Text(
                  '${_selectedMilestoneIds.length} dipilih',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_milestones.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Semua milestone telah selesai atau belum ada milestone.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: _milestones.asMap().entries.map((entry) {
                final index = entry.key;
                final milestone = entry.value;
                final id = milestone['id'] as String? ?? '';
                final title = milestone['title'] as String? ?? 'Untitled';
                final status = milestone['status'] as String? ?? '';
                final isChecked = _selectedMilestoneIds.contains(id);
                final isLast = index == _milestones.length - 1;

                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isChecked) {
                            _selectedMilestoneIds.remove(id);
                          } else {
                            _selectedMilestoneIds.add(id);
                          }
                        });
                      },
                      borderRadius: BorderRadius.vertical(
                        top: index == 0
                            ? const Radius.circular(AppSpacing.smallRadius)
                            : Radius.zero,
                        bottom: isLast
                            ? const Radius.circular(AppSpacing.smallRadius)
                            : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? AppColors.primary
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isChecked
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: isChecked
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: AppColors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: AppTextStyles.label.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  _buildStatusChip(status),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      const Divider(
                        height: 1,
                        indent: 44,
                        color: AppColors.borderLight,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'in_progress':
        bgColor = AppColors.primary.withValues(alpha: 0.1);
        textColor = AppColors.primaryDark;
        label = 'Sedang Dikerjakan';
        break;
      case 'pending_review':
        bgColor = AppColors.warningLight;
        textColor = AppColors.warningDark;
        label = 'Menunggu Review';
        break;
      case 'revision_needed':
        bgColor = AppColors.destructiveLight;
        textColor = AppColors.destructiveDark;
        label = 'Revisi';
        break;
      case 'not_started':
        bgColor = AppColors.borderLight;
        textColor = AppColors.textSecondary;
        label = 'Belum Dimulai';
        break;
      default:
        bgColor = AppColors.borderLight;
        textColor = AppColors.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: textColor, fontSize: 10),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CATATAN / TOPIK PEMBAHASAN', style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Apa yang ingin dibahas? (opsional)',
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.textTertiary,
            ),
            filled: true,
            fillColor: AppColors.surfaceSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
          style: AppTextStyles.body,
        ),
      ],
    );
  }

  // ── File picker ──
  Future<void> _pickFile() async {
    try {
      PlatformFile? picked;
      try {
        // Try with custom filter first
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        picked = result?.files.firstOrNull;
      } catch (_) {
        // Fallback: allow any file type if custom fails
        final result = await FilePicker.platform.pickFiles(type: FileType.any);
        picked = result?.files.firstOrNull;
      }

      if (picked != null && picked.path != null) {
        setState(() {
          _selectedFilePath = picked!.path;
          _selectedFileName = picked.name;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal memilih file: $e', false);
      }
    }
  }

  Widget _buildFileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LAMPIRAN DOKUMEN', style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
              border: Border.all(
                color: _selectedFileName != null
                    ? AppColors.primary
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedFileName != null
                      ? Icons.description
                      : Icons.attach_file,
                  color: _selectedFileName != null
                      ? AppColors.primary
                      : AppColors.textTertiary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedFileName ?? 'Pilih file (PDF)...',
                    style: AppTextStyles.body.copyWith(
                      color: _selectedFileName != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_selectedFileName != null)
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedFilePath = null;
                      _selectedFileName = null;
                    }),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.textTertiary,
                      size: 18,
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          child: Row(
            children: [
              Icon(
                _showAdvanced
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                'Opsi Lanjutan',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (_showAdvanced) ...[
          const SizedBox(height: AppSpacing.md),
          Text('LINK DOKUMEN', style: AppTextStyles.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _docUrlController,
            decoration: InputDecoration(
              hintText: 'Google Docs, Overleaf, Notion... (opsional)',
              hintStyle: AppTextStyles.body.copyWith(
                color: AppColors.textTertiary,
              ),
              prefixIcon: const Icon(Icons.link, color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.surfaceSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            style: AppTextStyles.body,
            keyboardType: TextInputType.url,
          ),
        ],
      ],
    );
  }

  Widget _buildConflictWarning() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: AppCard(
        backgroundColor: AppColors.destructiveLight,
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.destructive,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Waktu yang dipilih bentrok dengan jadwal dosen lainnya. Silakan pilih waktu yang berbeda.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.destructiveDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusySlotsInfo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: AppCard(
        backgroundColor: AppColors.warningLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: AppColors.warning, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Jadwal dosen hari ini:',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.warningDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ..._busySlots.map((slot) {
              final start = DateTime.tryParse(slot['start'] ?? '');
              final end = DateTime.tryParse(slot['end'] ?? '');
              if (start == null || end == null) {
                return const SizedBox.shrink();
              }
              final localStart = start.toLocal();
              final localEnd = end.toLocal();
              return Padding(
                padding: const EdgeInsets.only(left: 24, top: 2),
                child: Text(
                  '${_formatTime(TimeOfDay.fromDateTime(localStart))} – ${_formatTime(TimeOfDay.fromDateTime(localEnd))}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warningDark,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
