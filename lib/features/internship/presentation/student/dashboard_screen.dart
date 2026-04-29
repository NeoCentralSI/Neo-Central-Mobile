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
  State<InternshipDashboardScreen> createState() => _InternshipDashboardScreenState();
}

class _InternshipDashboardScreenState extends State<InternshipDashboardScreen> {
  final _api = InternshipApiService();
  bool _isLoading = true;
  String? _error;
  
  Map<String, dynamic>? _internship;
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
        setState(() {
          _internship = data['internship'];
          _logbooks = data['logbooks'] ?? [];
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kerja Praktik')),
        body: Center(
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 48, color: Colors.amber),
                const SizedBox(height: 16),
                const Text(
                  'Anda belum memiliki Kerja Praktik yang aktif.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Silakan lakukan pendaftaran melalui web portal.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
        child: const Icon(Icons.notifications_active_outlined, color: Colors.white),
      ),
    );
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
          colors: [
            AppColors.primaryLight,
            AppColors.primary,
          ],
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
    final companyName = proposal?['targetCompany']?['companyName'] ?? 
                        proposal?['companyName'] ?? 
                        _internship!['companyName'] ?? 
                        'Perusahaan';
    
    // Format dates
    String dateRange = '-';
    final startDateStr = _internship!['actualStartDate'] ?? proposal?['startDate'];
    final endDateStr = _internship!['actualEndDate'] ?? proposal?['endDate'];

    if (startDateStr != null && endDateStr != null) {
      try {
        final start = DateTime.parse(startDateStr.toString());
        final end = DateTime.parse(endDateStr.toString());
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        dateRange = 'Periode: ${months[start.month-1]} ${start.year} - ${months[end.month-1]} ${end.year}';
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
                    Text(
                      dateRange,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    final filledLogbooks = _logbooks.where((l) => l['activityDescription'] != null && l['activityDescription'].toString().isNotEmpty).length;
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
              Text('Progres Logbook', style: AppTextStyles.h4.copyWith(fontSize: 14)),
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
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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

  Widget _buildSupervisorSection() {
    final supervisor = _internship!['supervisor'] as Map<String, dynamic>?;
    final lecturerName = supervisor != null && supervisor['user'] != null 
        ? supervisor['user']['fullName'] ?? '-' 
        : '-';
    final fieldName = _internship!['fieldSupervisorName'] ?? '-';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pembimbing', style: AppTextStyles.h4.copyWith(fontSize: 14)),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorItem({
    required String role,
    required String name,
    required IconData icon,
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
            ],
          ),
        ),
      ],
    );
  }
}
