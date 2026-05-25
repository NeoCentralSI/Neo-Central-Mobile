import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../notifications/presentation/notification_screen.dart';

import '../../../../core/services/internship_api_service.dart';

class InternshipDashboardScreen extends StatefulWidget {
  final UserModel? user;
  final Function(int)? onSwitchTab;
  const InternshipDashboardScreen({super.key, this.user, this.onSwitchTab});

  @override
  State<InternshipDashboardScreen> createState() =>
      _InternshipDashboardScreenState();
}

class _InternshipDashboardScreenState extends State<InternshipDashboardScreen> {
  final _api = InternshipApiService();
  bool _isLoading = true;
  bool _isSavingDetails = false;
  String? _error;

  Map<String, dynamic>? _internship;
  Map<String, dynamic>? _failedInternship;
  List<dynamic> _logbooks = [];

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
      final res = await _api.getLogbookOverview();
      if (res['success'] == true) {
        final data = res['data'];
        final internship = data['internship'];
        Map<String, dynamic>? failedInternship;

        if (internship == null) {
          try {
            final history = await _api.getInternshipHistory();
            for (final item in history) {
              if (item is Map && item['status'] == 'FAILED') {
                failedInternship = Map<String, dynamic>.from(item);
                break;
              }
            }
          } catch (_) {
            failedInternship = null;
          }
        }

        setState(() {
          _internship = internship;
          _failedInternship = failedInternship;
          _logbooks = internship == null ? [] : data['logbooks'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception(res['message'] ?? 'Gagal memuat data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.user?.fullName ?? 'Mahasiswa';
    final firstName = userName.split(' ').first;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kerja Praktik')),
        body: _buildRefreshableState(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_internship == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kerja Praktik')),
        drawer: AppDrawer(user: widget.user, activeRoute: 'internship'),
        body: _buildRefreshableState(
          child: _failedInternship != null
              ? _buildFailedInternshipState(_failedInternship!)
              : _buildNoActiveInternshipState(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      drawer: AppDrawer(user: widget.user, activeRoute: 'internship'),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildHeader(context, firstName),
              Padding(
                padding: const EdgeInsets.only(
                  top: 280,
                  left: AppSpacing.pagePadding,
                  right: AppSpacing.pagePadding,
                  bottom: 32,
                ),
                child: Column(
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 24),
                    _buildProgressSection(),
                    const SizedBox(height: 24),
                    _buildFinalScoreSection(),
                    const SizedBox(height: 24),
                    _buildSupervisorSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationScreen()),
        ),
        backgroundColor: Colors.amber,
        child: const Icon(
          Icons.notifications_active_outlined,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRefreshableState({required Widget child}) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(child: child),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoActiveInternshipState() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.amber),
          SizedBox(height: 16),
          Text(
            'Anda belum memiliki Kerja Praktik yang aktif.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Silakan lakukan pendaftaran melalui web portal.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFailedInternshipState(Map<String, dynamic> internship) {
    final proposal = internship['proposal'] as Map<String, dynamic>?;
    final companyName =
        proposal?['targetCompany']?['companyName'] ??
        proposal?['companyName'] ??
        internship['companyName'] ??
        'perusahaan sebelumnya';
    final grade = (internship['finalGrade'] ?? '-').toString();
    final score = _parseScore(internship['finalNumericScore']);
    final startDate = _formatShortDate(
      internship['actualStartDate'] ?? proposal?['startDate'],
    );
    final endDate = _formatShortDate(
      internship['actualEndDate'] ?? proposal?['endDate'],
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.destructive.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.destructive.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel_outlined,
                size: 36,
                color: AppColors.destructive,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'KP Sebelumnya Gagal',
              style: AppTextStyles.h3.copyWith(color: AppColors.destructive),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Kerja Praktik di $companyName sudah dinyatakan gagal. Silakan daftar ulang melalui web portal.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _buildFailedInfoRow('Periode', '$startDate - $endDate'),
                  const Divider(height: 20),
                  _buildFailedInfoRow(
                    'Nilai Akhir',
                    score == null
                        ? grade
                        : '$grade (${score.toStringAsFixed(2)})',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Logbook, bimbingan, dan seminar akan tampil lagi setelah ada KP baru yang berstatus berjalan.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatShortDate(dynamic value) {
    if (value == null) return '-';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return '-';
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool _hasText(dynamic value) {
    return value != null && value.toString().trim().isNotEmpty;
  }

  bool get _hasInternshipDetails {
    final internship = _internship;
    if (internship == null) return false;
    return _hasText(internship['fieldSupervisorName']) &&
        _hasText(internship['fieldSupervisorEmail']) &&
        _hasText(internship['unitSection']);
  }

  bool get _canEditInternshipDetails {
    final internship = _internship;
    if (internship == null) return false;
    return !_hasInternshipDetails &&
        internship['isLogbookLocked'] != true &&
        internship['fieldAssessmentStatus'] != 'COMPLETED';
  }

  void _showInternshipDetailsDialog() {
    final fieldSupervisorNameController = TextEditingController(
      text: _internship?['fieldSupervisorName']?.toString() ?? '',
    );
    final fieldSupervisorEmailController = TextEditingController(
      text: _internship?['fieldSupervisorEmail']?.toString() ?? '',
    );
    final fieldSupervisorPhoneController = TextEditingController(
      text: _internship?['fieldSupervisorPhone']?.toString() ?? '',
    );
    final fieldSupervisorNipController = TextEditingController(
      text: _internship?['fieldSupervisorNip']?.toString() ?? '',
    );
    final unitSectionController = TextEditingController(
      text: _internship?['unitSection']?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Informasi Kerja Praktik', style: AppTextStyles.h4),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Isi data pembimbing lapangan dan divisi kerja. Nama, email, dan unit wajib diisi.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailsField(
                    controller: fieldSupervisorNameController,
                    label: 'Nama Pembimbing Lapangan',
                    hint: 'Nama lengkap pembimbing',
                  ),
                  const SizedBox(height: 14),
                  _buildDetailsField(
                    controller: fieldSupervisorEmailController,
                    label: 'Email Pembimbing Lapangan',
                    hint: 'email@perusahaan.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _buildDetailsField(
                    controller: fieldSupervisorPhoneController,
                    label: 'Nomor HP Pembimbing',
                    hint: 'Contoh: 081234567890',
                    keyboardType: TextInputType.phone,
                    optional: true,
                  ),
                  const SizedBox(height: 14),
                  _buildDetailsField(
                    controller: fieldSupervisorNipController,
                    label: 'NIP Pembimbing',
                    hint: 'NIP pembimbing',
                    optional: true,
                  ),
                  const SizedBox(height: 14),
                  _buildDetailsField(
                    controller: unitSectionController,
                    label: 'Unit / Bagian Kerja',
                    hint: 'Contoh: Divisi IT',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSavingDetails
                          ? null
                          : () {
                              final fieldSupervisorName =
                                  fieldSupervisorNameController.text.trim();
                              final fieldSupervisorEmail =
                                  fieldSupervisorEmailController.text.trim();
                              final unitSection = unitSectionController.text
                                  .trim();

                              if (fieldSupervisorName.isEmpty ||
                                  fieldSupervisorEmail.isEmpty ||
                                  unitSection.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Nama pembimbing, email, dan unit kerja wajib diisi.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              Navigator.pop(context);
                              _submitInternshipDetails(
                                fieldSupervisorName: fieldSupervisorName,
                                fieldSupervisorEmail: fieldSupervisorEmail,
                                fieldSupervisorPhone:
                                    fieldSupervisorPhoneController.text.trim(),
                                fieldSupervisorNip: fieldSupervisorNipController
                                    .text
                                    .trim(),
                                unitSection: unitSection,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Simpan Informasi'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      fieldSupervisorNameController.dispose();
      fieldSupervisorEmailController.dispose();
      fieldSupervisorPhoneController.dispose();
      fieldSupervisorNipController.dispose();
      unitSectionController.dispose();
    });
  }

  Widget _buildDetailsField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          optional ? '$label (Opsional)' : label,
          style: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitInternshipDetails({
    required String fieldSupervisorName,
    required String fieldSupervisorEmail,
    required String fieldSupervisorPhone,
    required String fieldSupervisorNip,
    required String unitSection,
  }) async {
    setState(() => _isSavingDetails = true);
    try {
      await _api.updateInternshipDetails(
        fieldSupervisorName: fieldSupervisorName,
        fieldSupervisorEmail: fieldSupervisorEmail,
        fieldSupervisorPhone: fieldSupervisorPhone.isEmpty
            ? null
            : fieldSupervisorPhone,
        fieldSupervisorNip: fieldSupervisorNip.isEmpty
            ? null
            : fieldSupervisorNip,
        unitSection: unitSection,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informasi Kerja Praktik berhasil disimpan.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan informasi KP: $e'),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingDetails = false);
      }
    }
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Container(
      width: double.infinity,
      height: 320,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        60,
        AppSpacing.pagePadding,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Builder(
                builder: (BuildContext innerContext) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(innerContext).openDrawer(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Kerja Praktik',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hi, $name',
                      style: AppTextStyles.h1.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Add a summary card like in TA dashboard if needed, or just keep it simple
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROGRES LOGBOOK',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${((_logbooks.isNotEmpty ? _logbooks.where((l) => l['activityDescription'] != null && l['activityDescription'].toString().isNotEmpty).length / _logbooks.length : 0.0) * 100).toInt()}%',
                          style: AppTextStyles.h1.copyWith(
                            color: Colors.white,
                            fontSize: 36,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'terisi',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.assignment_turned_in,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final proposal = _internship!['proposal'] as Map<String, dynamic>?;
    final companyName =
        proposal?['targetCompany']?['companyName'] ??
        proposal?['companyName'] ??
        _internship!['companyName'] ??
        'Perusahaan';

    // Format dates
    String dateRange = '-';
    final startDateStr =
        _internship!['actualStartDate'] ?? proposal?['startDate'];
    final endDateStr = _internship!['actualEndDate'] ?? proposal?['endDate'];

    if (startDateStr != null && endDateStr != null) {
      try {
        final start = DateTime.parse(startDateStr.toString());
        final end = DateTime.parse(endDateStr.toString());
        final months = [
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
        dateRange =
            'Periode: ${months[start.month - 1]} ${start.year} - ${months[end.month - 1]} ${end.year}';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: AppTextStyles.h3.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(dateRange, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Text(
                  _internship!['status'].toString().toUpperCase(),
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final totalLogbooks = _logbooks.length;
    final filledLogbooks = _logbooks
        .where(
          (l) =>
              l['activityDescription'] != null &&
              l['activityDescription'].toString().isNotEmpty,
        )
        .length;
    final progress = totalLogbooks > 0 ? filledLogbooks / totalLogbooks : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progres Logbook',
                style: AppTextStyles.h4.copyWith(fontSize: 14),
              ),
              Text(
                '$filledLogbooks/$totalLogbooks Hari',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Lengkapi logbook harian Anda untuk memenuhi persyaratan penilaian.',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildFinalScoreSection() {
    final score = _parseScore(_internship!['finalNumericScore']);
    final grade = (_internship!['finalGrade'] ?? '-').toString();
    final lecturerStatus = (_internship!['lecturerAssessmentStatus'] ?? '')
        .toString();
    final fieldStatus = (_internship!['fieldAssessmentStatus'] ?? '')
        .toString();
    final hasFinalScore = score != null && grade != '-' && grade.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nilai Akhir',
                style: AppTextStyles.h4.copyWith(fontSize: 14),
              ),
              Icon(
                hasFinalScore
                    ? Icons.verified_rounded
                    : Icons.hourglass_bottom_rounded,
                color: hasFinalScore ? AppColors.success : AppColors.warning,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasFinalScore)
            Row(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      grade,
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.primary,
                        fontSize: 30,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skor Numerik',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        score.toStringAsFixed(2),
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gabungan penilaian dosen pembimbing dan pembimbing lapangan.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nilai akhir belum tersedia. Nilai akan muncul setelah seluruh penilaian selesai diproses.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          _buildAssessmentStatusRow(
            label: 'Dosen Pembimbing',
            status: lecturerStatus,
            icon: Icons.school_rounded,
          ),
          const SizedBox(height: 10),
          _buildAssessmentStatusRow(
            label: 'Pembimbing Lapangan',
            status: fieldStatus,
            icon: Icons.business_center_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentStatusRow({
    required String label,
    required String status,
    required IconData icon,
  }) {
    final completed = status == 'COMPLETED';
    final color = completed ? AppColors.success : AppColors.warning;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            completed ? 'Selesai' : 'Belum Selesai',
            style: AppTextStyles.label.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  double? _parseScore(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Widget _buildSupervisorSection() {
    final supervisor = _internship!['supervisor'] as Map<String, dynamic>?;
    final lecturerName = supervisor != null && supervisor['user'] != null
        ? supervisor['user']['fullName'] ?? '-'
        : '-';
    final fieldName = _hasText(_internship!['fieldSupervisorName'])
        ? _internship!['fieldSupervisorName'].toString()
        : '-';
    final unitSection = _hasText(_internship!['unitSection'])
        ? _internship!['unitSection'].toString()
        : '-';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pembimbing',
                style: AppTextStyles.h4.copyWith(fontSize: 14),
              ),
              if (_canEditInternshipDetails)
                TextButton.icon(
                  onPressed: _isSavingDetails
                      ? null
                      : _showInternshipDetailsDialog,
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Isi Info'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          if (!_hasInternshipDetails) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                'Lengkapi pembimbing lapangan dan unit kerja agar data KP siap digunakan untuk logbook dan penilaian.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.warningDark,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildSupervisorItem(
            role: 'Dosen Pembimbing',
            name: lecturerName,
            icon: Icons.school_rounded,
          ),
          const Divider(height: 24),
          _buildSupervisorItem(
            role: 'Pembimbing Lapangan',
            name: fieldName,
            icon: Icons.business_center_rounded,
            details: [
              _buildSupervisorDetail(
                'Email',
                _internship!['fieldSupervisorEmail'],
              ),
              _buildSupervisorDetail(
                'No. HP',
                _internship!['fieldSupervisorPhone'],
              ),
              _buildSupervisorDetail('NIP', _internship!['fieldSupervisorNip']),
            ],
          ),
          const Divider(height: 24),
          _buildSupervisorItem(
            role: 'Unit / Bagian',
            name: unitSection,
            icon: Icons.apartment_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorItem({
    required String role,
    required String name,
    required IconData icon,
    List<Widget> details = const [],
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role.toUpperCase(),
                style: AppTextStyles.label.copyWith(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                name,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 4),
                ...details,
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupervisorDetail(String label, dynamic value) {
    final display = _hasText(value) ? value.toString() : '-';
    return Text(
      '$label: $display',
      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
    );
  }
}
