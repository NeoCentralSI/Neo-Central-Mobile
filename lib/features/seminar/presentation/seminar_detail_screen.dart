import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/services/seminar_api_service.dart';
import '../../../shared/widgets/shared_widgets.dart';
import 'panels/seminar_assessment_panel.dart';
import 'panels/seminar_audience_panel.dart';
import 'panels/seminar_identity_panel.dart';
import 'panels/seminar_revision_panel.dart';

/// Seminar Hasil — shared detail screen.
///
/// Tabs: Identitas, Penilaian, Peserta, Revisi.
/// Scheduling tab is intentionally omitted on mobile (admin-only on web).
///
/// Accessed via card tap from:
///   • Seminar Hasil ▸ Mahasiswa Bimbingan  (Supervisor)
///   • Seminar Hasil ▸ Menguji Mahasiswa    (Examiner)
///   • Tetapkan Penguji ▸ Seminar Hasil     (HoD — read-only view)
class SeminarDetailScreen extends StatefulWidget {
  final String seminarId;
  final UserModel? user;

  const SeminarDetailScreen({
    super.key,
    required this.seminarId,
    this.user,
  });

  @override
  State<SeminarDetailScreen> createState() => _SeminarDetailScreenState();
}

class _SeminarDetailScreenState extends State<SeminarDetailScreen>
    with TickerProviderStateMixin {
  final _api = SeminarApiService();
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _detail = const {};

  @override
  void initState() {
    super.initState();
    // Initial controller; rebuilt once we know which tabs are visible.
    _tabController = TabController(length: 1, vsync: this);
    _fetch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final detail = await _api.getSeminarDetail(widget.seminarId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
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

  bool _isOngoing(Map<String, dynamic> d) {
    final status = (d['status'] ?? '').toString();
    if (status == 'ongoing') return true;
    if (status != 'scheduled') return false;
    final dateStr = d['date']?.toString();
    final startStr = d['startTime']?.toString();
    if (dateStr == null || startStr == null) return false;
    try {
      final dateObj = DateTime.parse(dateStr);
      final timeObj = DateTime.parse(startStr);
      final start = DateTime(
        dateObj.toUtc().year,
        dateObj.toUtc().month,
        dateObj.toUtc().day,
        timeObj.toUtc().hour,
        timeObj.toUtc().minute,
      );
      return DateTime.now().isAfter(start) ||
          DateTime.now().isAtSameMomentAs(start);
    } catch (_) {
      return false;
    }
  }

  bool _isFinalized(Map<String, dynamic> d) {
    const finalStatuses = ['passed', 'passed_with_revision', 'failed'];
    return finalStatuses.contains((d['status'] ?? '').toString());
  }

  bool _isUserSupervisor(Map<String, dynamic> d) {
    final lecturerId = widget.user?.lecturer?.id;
    if (lecturerId == null) return false;
    final supervisors = (d['supervisors'] as List?) ?? const [];
    return supervisors.whereType<Map>().any((s) => s['lecturerId'] == lecturerId);
  }

  bool _isUserExaminer(Map<String, dynamic> d) {
    final lecturerId = widget.user?.lecturer?.id;
    if (lecturerId == null) return false;
    final examiners = (d['examiners'] as List?) ?? const [];
    return examiners.whereType<Map>().any((e) => e['lecturerId'] == lecturerId);
  }

  bool _isUserPresenter(Map<String, dynamic> d) {
    final studentId = widget.user?.student?.id;
    if (studentId == null) return false;
    final detailStudent = d['student'];
    if (detailStudent is Map && detailStudent['id'] == studentId) return true;
    // Fallback by NIM match
    final myNim = widget.user?.identityNumber;
    if (myNim != null && detailStudent is Map && detailStudent['nim'] == myNim) {
      return true;
    }
    return false;
  }

  bool get _isUserHod =>
      widget.user?.appRole == UserRole.headOfDepartment;

  List<_TabSpec> _computeTabs(Map<String, dynamic> d) {
    final ongoing = _isOngoing(d);
    final finalized = _isFinalized(d);
    final isSupervisor = _isUserSupervisor(d);
    final isExaminer = _isUserExaminer(d);
    final isPresenter = _isUserPresenter(d);
    final isHod = _isUserHod;
    final status = (d['status'] ?? '').toString();

    final tabs = <_TabSpec>[
      _TabSpec(
        label: 'Identitas',
        builder: (refresh) => SeminarIdentityPanel(detail: d),
      ),
    ];

    // Penilaian visible to: presenter, supervisor, examiner, and HoD.
    final showAssessment = (ongoing || finalized) &&
        (isPresenter || isSupervisor || isExaminer || isHod);
    if (showAssessment) {
      tabs.add(_TabSpec(
        label: 'Penilaian',
        builder: (refresh) => SeminarAssessmentPanel(
          seminarId: widget.seminarId,
          detail: d,
          user: widget.user,
          onRefresh: refresh,
        ),
      ));
    }

    // Peserta visible to anyone when ongoing/finalized (audience list is public).
    final showAudience = ongoing || finalized;
    if (showAudience) {
      tabs.add(_TabSpec(
        label: 'Peserta',
        builder: (refresh) => SeminarAudiencePanel(
          seminarId: widget.seminarId,
          detail: d,
          user: widget.user,
        ),
      ));
    }

    // Revisi: supervisor approves; presenter creates/edits/submits.
    final showRevisions =
        (isSupervisor || isPresenter) && status == 'passed_with_revision';
    if (showRevisions) {
      tabs.add(_TabSpec(
        label: 'Revisi',
        builder: (refresh) => SeminarRevisionPanel(
          seminarId: widget.seminarId,
          detail: d,
          user: widget.user,
          onRefresh: refresh,
        ),
      ));
    }

    return tabs;
  }

  void _ensureTabController(int length) {
    if (_tabController.length != length) {
      final oldIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(
        length: length,
        vsync: this,
        initialIndex: oldIndex < length ? oldIndex : 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        _buildHeader(title: 'Detail Seminar', tabs: const []),
        const Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        _buildHeader(title: 'Detail Seminar', tabs: const []),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.destructive),
                  const SizedBox(height: 12),
                  Text('Gagal memuat detail seminar',
                      style: AppTextStyles.h4, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    _error ?? '',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _fetch,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final tabs = _computeTabs(_detail);
    _ensureTabController(tabs.length);

    final studentName = (_detail['student']?['name'] ?? '-').toString();
    final studentNim = (_detail['student']?['nim'] ?? '-').toString();
    final status = (_detail['status'] ?? '-').toString();

    return Column(
      children: [
        _buildHeader(
          title: 'Detail Seminar Hasil',
          subtitle: '$studentName • $studentNim',
          status: status,
          tabs: tabs,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: tabs.map((t) => t.builder(_fetch)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader({
    required String title,
    String? subtitle,
    String? status,
    required List<_TabSpec> tabs,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        12,
        AppSpacing.pagePadding,
        4,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 22),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h1
                          .copyWith(color: Colors.white, fontSize: 20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (status != null && status != '-')
                _HeaderStatusBadge(status: status),
            ],
          ),
          if (tabs.length > 1) ...[
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: [for (final t in tabs) Tab(text: t.label)],
            ),
          ] else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TabSpec {
  final String label;
  final Widget Function(Future<void> Function() refresh) builder;
  _TabSpec({required this.label, required this.builder});
}

class _HeaderStatusBadge extends StatelessWidget {
  final String status;
  const _HeaderStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(
        seminarStatusLabel(status),
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Shared seminar status label translator (used by detail screen + panels).
String seminarStatusLabel(String s) {
  switch (s) {
    case 'registered':
      return 'Terdaftar';
    case 'verified':
      return 'Terverifikasi';
    case 'examiner_assigned':
      return 'Penguji Ditetapkan';
    case 'scheduled':
      return 'Dijadwalkan';
    case 'ongoing':
      return 'Berlangsung';
    case 'passed':
      return 'Lulus';
    case 'passed_with_revision':
      return 'Lulus + Revisi';
    case 'failed':
      return 'Gagal';
    case 'cancelled':
      return 'Dibatalkan';
    default:
      return s;
  }
}

/// Status → badge variant mapping used by panels.
BadgeVariant seminarStatusVariant(String s) {
  switch (s) {
    case 'ongoing':
      return BadgeVariant.primary;
    case 'scheduled':
    case 'examiner_assigned':
      return BadgeVariant.warning;
    case 'passed':
    case 'passed_with_revision':
      return BadgeVariant.success;
    case 'failed':
    case 'cancelled':
      return BadgeVariant.destructive;
    case 'verified':
      return BadgeVariant.outline;
    case 'registered':
    default:
      return BadgeVariant.secondary;
  }
}
