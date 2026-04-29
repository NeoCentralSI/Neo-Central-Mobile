import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/services/internship_api_service.dart';
import 'student_detail_screen.dart';
import '../../../notifications/presentation/notification_screen.dart';

class InternshipLecturerDashboard extends StatefulWidget {
  final UserModel? user;
  const InternshipLecturerDashboard({super.key, this.user});

  @override
  State<InternshipLecturerDashboard> createState() => _InternshipLecturerDashboardState();
}

class _InternshipLecturerDashboardState extends State<InternshipLecturerDashboard> {
  final _api = InternshipApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _students = [];

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
      final res = await _api.getSupervisedStudents();
      setState(() {
        _students = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.user?.fullName ?? 'Dosen';
    final firstName = userName.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      drawer: AppDrawer(user: widget.user, activeRoute: 'internship'),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState()
                : SingleChildScrollView(
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
                              _buildSummaryCard(),
                              const SizedBox(height: 24),
                              _buildPendingApprovals(),
                              const SizedBox(height: 24),
                              _buildStudentSection(),
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
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.notifications_active_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(child: Text(_error ?? 'Terjadi kesalahan'));
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Container(
      width: double.infinity,
      height: 320,
      padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, 60, AppSpacing.pagePadding, 24),
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
                builder: (innerContext) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(innerContext).openDrawer(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DASHBOARD DOSEN',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Hi, $name',
                      style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 28),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Simple Stats in Header like student's progress card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS BIMBINGAN',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitoring Kerja Praktik',
                      style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalBimbingan = _students.length;
    final selesaiSeminar = _students.where((s) => s['status'] == 'COMPLETED' || s['status'] == 'FINISHED').length;
    // Assuming 'finalReport' or 'reportFile' indicates final fix report upload
    final laporanFinal = _students.where((s) => s['finalReport'] != null || s['status'] == 'COMPLETED').length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSummaryItem('Total\nBimbingan', totalBimbingan.toString(), AppColors.primary),
          _buildVerticalDivider(),
          _buildSummaryItem('Selesai\nSeminar', selesaiSeminar.toString(), Colors.green),
          _buildVerticalDivider(),
          _buildSummaryItem('Laporan\nFinal Fix', laporanFinal.toString(), Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.h2.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.border.withValues(alpha: 0.5),
    );
  }

  Widget _buildStudentSection() {
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
              Text('MAHASISWA BIMBINGAN', style: AppTextStyles.h4.copyWith(fontSize: 14)),
              Text('${_students.length}', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _students.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _students.length,
                  separatorBuilder: (context, index) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final name = student['studentName'] ?? 'Mahasiswa';
                    final nim = student['studentNim'] ?? '-';
                    final status = student['status'] ?? 'ONGOING';

                    return InkWell(
                      onTap: () {
                        final id = student['internshipId'];
                        if (id != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InternshipStudentGuidanceDetailScreen(
                                internshipId: id.toString(),
                                studentName: name,
                                user: widget.user,
                              ),
                            ),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                                Text('NIM: $nim', style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                          _buildStatusBadge(status),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isOngoing = status == 'ONGOING';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isOngoing ? AppColors.success : AppColors.info).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isOngoing ? AppColors.success : AppColors.info,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 48, color: AppColors.textTertiary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('Belum ada mahasiswa bimbingan', style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovals() {
    final List<Map<String, dynamic>> pendingItems = [];

    for (var student in _students) {
      // 1. Check for Seminar Requests
      if (student['seminar'] != null && student['seminar']['status'] == 'REQUESTED') {
        pendingItems.add({
          'studentName': student['studentName'] ?? 'Mahasiswa',
          'type': 'Seminar',
          'internshipId': student['internshipId'],
          'data': student['seminar'],
          'icon': Icons.groups_outlined,
          'color': Colors.orange,
        });
      }

      // 2. Check for new Bimbingan entries (Student initiated and no lecturer note)
      final guidances = student['guidances'] as List? ?? [];
      if (guidances.isNotEmpty) {
        final last = guidances.first;
        if (last['isStudentInitiated'] == true && (last['lecturerNote'] == null || last['lecturerNote'].toString().isEmpty)) {
          pendingItems.add({
            'studentName': student['studentName'] ?? 'Mahasiswa',
            'type': 'Bimbingan',
            'internshipId': student['internshipId'],
            'data': last,
            'icon': Icons.forum_outlined,
            'color': AppColors.primary,
          });
        }
      }
    }

    if (pendingItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Antrean Persetujuan', style: AppTextStyles.h4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.destructive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${pendingItems.length} Menunggu',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.destructive),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pendingItems.length,
            itemBuilder: (context, index) {
              final item = pendingItems[index];
              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 16, bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InternshipStudentGuidanceDetailScreen(
                        internshipId: item['internshipId'],
                        studentName: item['studentName'],
                        user: widget.user,
                      ),
                    ),
                  ).then((_) => _loadData()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: item['color'].withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item['icon'], size: 16, color: item['color']),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item['type'],
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: item['color']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['studentName'],
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item['type'] == 'Seminar' ? 'Mengajukan Jadwal' : 'Mengisi Bimbingan',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
