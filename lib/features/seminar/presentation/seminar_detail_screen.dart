import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/services/seminar_api_service.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../thesis_shared/domain/thesis_access_policy.dart';
import '../data/models/seminar_models.dart';
import 'panels/seminar_assessment_panel.dart';
import 'panels/seminar_audience_panel.dart';
import 'panels/seminar_identity_panel.dart';
import 'panels/seminar_revision_panel.dart';

class SeminarDetailScreen extends StatefulWidget {
  final String seminarId;
  final UserModel? user;

  const SeminarDetailScreen({super.key, required this.seminarId, this.user});

  @override
  State<SeminarDetailScreen> createState() => _SeminarDetailScreenState();
}

class _SeminarDetailScreenState extends State<SeminarDetailScreen>
    with TickerProviderStateMixin {
  final _api = SeminarApiService();
  late TabController _tabController;
  SeminarDetail? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final detail = await _api.getSeminarDetail(widget.seminarId);
      if (!mounted) return;
      final tabCount = _buildTabSpecs(detail).length;
      if (_tabController.length != tabCount) {
        final previousIndex = _tabController.index;
        _tabController.dispose();
        _tabController = TabController(
          length: tabCount,
          vsync: this,
          initialIndex: previousIndex < tabCount ? previousIndex : 0,
        );
      }
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        _error = exception.toString();
        _isLoading = false;
      });
    }
  }

  bool _isSupervisor(SeminarDetail detail) {
    final lecturerId = widget.user?.lecturer?.id;
    return lecturerId != null &&
        detail.supervisors.any((person) => person.lecturerId == lecturerId);
  }

  bool _isExaminer(SeminarDetail detail) {
    final lecturerId = widget.user?.lecturer?.id;
    return lecturerId != null &&
        detail.examiners.any((person) => person.lecturerId == lecturerId);
  }

  bool _isPresenter(SeminarDetail detail) {
    final studentId = widget.user?.student?.id;
    if (studentId != null && detail.student.id == studentId) return true;
    return widget.user?.identityNumber == detail.student.nim;
  }

  List<_TabSpec> _buildTabSpecs(SeminarDetail detail) {
    final supervisor = _isSupervisor(detail);
    final examiner = _isExaminer(detail);
    final presenter = _isPresenter(detail);
    final appRole = widget.user?.appRole;
    final leadership =
        appRole == UserRole.headOfDepartment || appRole == UserRole.admin;
    final showInteractiveData = detail.status.canShowAssessment;
    final finalized = detail.resultFinalizedAt != null || detail.status.isFinal;
    final showAssessment = canViewThesisAssessment(
      workflowAllowsAssessment: showInteractiveData,
      finalized: finalized,
      isPresenter: presenter,
      isSupervisor: supervisor,
      isExaminer: examiner,
      isLeadership: leadership,
    );
    final showRevision = canViewThesisRevision(
      passedWithRevision: detail.status == SeminarStatus.passedWithRevision,
      isArchive: false,
      isPresenter: presenter,
      isSupervisor: supervisor,
    );

    return [
      _TabSpec(
        label: 'Identitas',
        builder: () => SeminarIdentityPanel(detail: detail),
      ),
      if (showAssessment)
        _TabSpec(
          label: 'Penilaian',
          builder: () => SeminarAssessmentPanel(
            seminarId: detail.id,
            detail: detail,
            user: widget.user,
            onRefresh: _load,
          ),
        ),
      if (showInteractiveData)
        _TabSpec(
          label: 'Peserta',
          builder: () => SeminarAudiencePanel(
            seminarId: detail.id,
            detail: detail,
            user: widget.user,
          ),
        ),
      if (showRevision)
        _TabSpec(
          label: 'Revisi',
          builder: () => SeminarRevisionPanel(
            seminarId: detail.id,
            detail: detail,
            user: widget.user,
            onRefresh: _load,
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      body: SafeArea(
        child: switch ((_isLoading, _error, _detail)) {
          (true, _, null) => _loadingView(),
          (_, String error, null) => _errorView(error),
          (_, _, SeminarDetail detail) => _content(detail),
          _ => _errorView('Detail seminar tidak tersedia.'),
        },
      ),
    );
  }

  Widget _loadingView() {
    return Column(
      children: [
        _header(title: 'Detail Seminar', tabs: const []),
        const Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _errorView(String message) {
    return Column(
      children: [
        _header(title: 'Detail Seminar', tabs: const []),
        Expanded(
          child: Center(
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
                  const SizedBox(height: 12),
                  Text('Gagal memuat detail seminar', style: AppTextStyles.h4),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _load,
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

  Widget _content(SeminarDetail detail) {
    final tabs = _buildTabSpecs(detail);
    return Column(
      children: [
        _header(
          title: 'Detail Seminar Hasil',
          subtitle: '${detail.student.name} • ${detail.student.nim}',
          status: detail.status,
          tabs: tabs,
        ),
        Expanded(
          child: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: tabs.map((tab) => tab.builder()).toList(),
              ),
              if (_isLoading)
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header({
    required String title,
    String? subtitle,
    SeminarStatus? status,
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
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h1.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
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
              if (status != null) _HeaderStatusBadge(status: status),
            ],
          ),
          if (tabs.length > 1) ...[
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: tabs.map((tab) => Tab(text: tab.label)).toList(),
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
  final Widget Function() builder;

  const _TabSpec({required this.label, required this.builder});
}

class _HeaderStatusBadge extends StatelessWidget {
  final SeminarStatus status;

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
        seminarStatusLabel(status.value),
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String seminarStatusLabel(String status) {
  return switch (status) {
    'registered' => 'Terdaftar',
    'verified' => 'Terverifikasi',
    'examiner_assigned' => 'Penguji Ditetapkan',
    'scheduled' => 'Dijadwalkan',
    'ongoing' => 'Berlangsung',
    'passed' => 'Lulus',
    'passed_with_revision' => 'Lulus + Revisi',
    'failed' => 'Gagal',
    'cancelled' => 'Dibatalkan',
    _ => status,
  };
}

BadgeVariant seminarStatusVariant(String status) {
  return switch (status) {
    'ongoing' => BadgeVariant.primary,
    'scheduled' || 'examiner_assigned' => BadgeVariant.warning,
    'passed' || 'passed_with_revision' => BadgeVariant.success,
    'failed' || 'cancelled' => BadgeVariant.destructive,
    'verified' => BadgeVariant.outline,
    'registered' => BadgeVariant.secondary,
    _ => BadgeVariant.secondary,
  };
}
