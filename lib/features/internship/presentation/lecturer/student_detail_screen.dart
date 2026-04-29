import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/internship_api_service.dart';

class InternshipStudentGuidanceDetailScreen extends StatefulWidget {
  final String internshipId;
  final String studentName;
  final UserModel? user;

  const InternshipStudentGuidanceDetailScreen({
    super.key,
    required this.internshipId,
    required this.studentName,
    this.user,
  });

  @override
  State<InternshipStudentGuidanceDetailScreen> createState() => _InternshipStudentGuidanceDetailScreenState();
}

class _InternshipStudentGuidanceDetailScreenState extends State<InternshipStudentGuidanceDetailScreen> with SingleTickerProviderStateMixin {
  final _api = InternshipApiService();
  late TabController _tabController;
  
  bool _isLoading = true;
  String? _error;
  List<dynamic> _timeline = [];
  Map<String, dynamic>? _seminar;
  List<dynamic> _audiences = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // 1. Fetch guidance timeline
      final guidanceRes = await _api.getSupervisedStudentTimeline(widget.internshipId);
      final guidanceData = guidanceRes['data'] ?? {};
      
      // 2. Fetch basic student info to get seminar basic data
      final students = await _api.getSupervisedStudents();
      final studentData = students.firstWhere(
        (s) => s['internshipId'] == widget.internshipId,
        orElse: () => null,
      );

      // 3. If seminar exists, fetch full detail to get audiences
      Map<String, dynamic>? seminarDetail;
      if (studentData?['seminar'] != null) {
        final detailRes = await _api.getSeminarDetail(studentData['seminar']['id']);
        seminarDetail = detailRes['data'];
      }

      setState(() {
        _timeline = guidanceData['timeline'] ?? [];
        _seminar = seminarDetail ?? studentData?['seminar'];
        _audiences = seminarDetail?['audiences'] ?? [];
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
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.studentName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Detail Kegiatan', style: AppTextStyles.label.copyWith(color: Colors.white70, fontSize: 12)),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: const [
            Tab(text: 'Bimbingan'),
            Tab(text: 'Seminar'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGuidanceTab(),
                    _buildSeminarTab(),
                  ],
                ),
    );
  }

  Widget _buildGuidanceTab() {
    if (_timeline.isEmpty) return _buildEmptyState('Belum ada jadwal bimbingan', Icons.forum_outlined);
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: _timeline.length,
      itemBuilder: (context, index) {
        final week = _timeline[index];
        final weekNum = week['weekNumber'];
        final status = week['status'] ?? 'NOT_AVAILABLE';
        final submissionDate = week['submissionDate'];
        
        Color statusColor;
        String statusText;
        
        switch (status) {
          case 'SUBMITTED':
            statusColor = Colors.orange;
            statusText = 'Menunggu Evaluasi';
            break;
          case 'APPROVED':
            statusColor = AppColors.success;
            statusText = 'Sudah Dievaluasi';
            break;
          case 'LATE':
            statusColor = AppColors.destructive;
            statusText = 'Terlambat';
            break;
          case 'OPEN':
            statusColor = AppColors.primary;
            statusText = 'Belum Mengisi';
            break;
          default:
            statusColor = Colors.grey;
            statusText = 'Belum Tersedia';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
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
                  Text('Minggu $weekNum', style: AppTextStyles.h4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (submissionDate != null)
                Text(
                  'Dikirim pada: ${submissionDate.toString().split('T').first}',
                  style: AppTextStyles.bodySmall,
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showEvaluationDialog(weekNum),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(status == 'APPROVED' ? 'Lihat Evaluasi' : 'Beri Feedback / Evaluasi'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeminarTab() {
    if (_seminar == null) return _buildEmptyState('Belum ada pengajuan seminar', Icons.groups_outlined);

    final status = _seminar!['status'] ?? 'REQUESTED';
    final date = _seminar!['seminarDate']?.toString().split('T').first ?? '-';
    final startTime = _seminar!['startTime']?.toString().split('T').last.substring(0, 5) ?? '-';
    final endTime = _seminar!['endTime']?.toString().split('T').last.substring(0, 5) ?? '-';
    final room = _seminar!['room']?['name'] ?? 'TBD';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status Pengajuan', style: AppTextStyles.label),
                    _buildStatusBadge(status),
                  ],
                ),
                const Divider(height: 32),
                _buildInfoRow(Icons.event, 'Tanggal', date),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.access_time, 'Waktu', '$startTime - $endTime'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on_outlined, 'Ruangan', room),
                
                if (status == 'REQUESTED') ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleReject(_seminar!['id']),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: AppColors.destructive,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Tolak'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleApprove(_seminar!['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary, 
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Setujui'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('DAFTAR PENONTON (${_audiences.length})', style: AppTextStyles.h4.copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          _buildAudienceList(),
        ],
      ),
    );
  }

  Widget _buildAudienceList() {
    if (_audiences.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.people_outline, color: AppColors.textTertiary.withValues(alpha: 0.3), size: 40),
            const SizedBox(height: 8),
            Text('Belum ada penonton terdaftar', style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _audiences.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final aud = _audiences[index];
          final s = aud['student']?['user'] ?? {};
          final isValidated = aud['status'] == 'VALIDATED';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                (s['fullName'] ?? 'M')[0].toUpperCase(),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            title: Text(s['fullName'] ?? 'Mahasiswa', style: AppTextStyles.body.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text(s['identityNumber'] ?? '-', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
            trailing: isValidated
                ? const Icon(Icons.check_circle, color: AppColors.success, size: 18)
                : const Icon(Icons.pending_outlined, color: Colors.orange, size: 18),
          );
        },
      ),
    );
  }

  Widget _buildRoleBadge(bool isStudent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isStudent ? Colors.amber : AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isStudent ? 'MAHASISWA' : 'DOSEN',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isStudent ? Colors.amber[800] : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textTertiary)),
            Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'APPROVED': color = AppColors.success; break;
      case 'REJECTED': color = AppColors.destructive; break;
      case 'COMPLETED': color = Colors.blue; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Future<void> _handleApprove(String id) async {
    try {
      await _api.approveSeminar(id);
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _handleReject(String id) async {
    final controller = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Seminar'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Alasan penolakan')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Tolak')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _api.rejectSeminar(id, controller.text);
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textTertiary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }

  Future<void> _showEvaluationDialog(int weekNumber) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await _api.getSupervisedStudentWeekDetail(widget.internshipId, weekNumber);
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      final data = res;
      final studentAnswers = data['studentAnswers'] as List? ?? [];
      final lecturerEvaluation = data['lecturerEvaluation'] as List? ?? [];
      final sessionStatus = data['sessionStatus'];

      // Controllers for lecturer feedback
      final Map<String, TextEditingController> textControllers = {};
      final Map<String, String?> valueSelections = {};

      for (var e in lecturerEvaluation) {
        textControllers[e['criteriaId']] = TextEditingController(text: e['answerText'] ?? '');
        valueSelections[e['criteriaId']] = e['evaluationValue']?.toString();
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Evaluasi Minggu $weekNumber', style: AppTextStyles.h4),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Student Section
                        Text('Laporan Mahasiswa', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                        const SizedBox(height: 12),
                        if (studentAnswers.isEmpty)
                          const Text('Mahasiswa belum mengisi laporan.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                        else
                          ...studentAnswers.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a['questionText'] ?? '-', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(a['answerText'] ?? '-', style: AppTextStyles.body),
                              ],
                            ),
                          )),
                        
                        const Divider(height: 40),
                        
                        // Lecturer Section
                        Text('Evaluasi Dosen', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                        const SizedBox(height: 12),
                        ...lecturerEvaluation.map((e) {
                          final criteriaId = e['criteriaId'];
                          final inputType = e['inputType']; // TEXT or SELECT
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e['criteriaName'] ?? '-', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                if (inputType == 'SELECT')
                                  Wrap(
                                    spacing: 8,
                                    children: (e['options'] as List? ?? []).map((opt) {
                                      final isSelected = valueSelections[criteriaId] == opt['optionText'];
                                      return ChoiceChip(
                                        label: Text(opt['optionText']),
                                        selected: isSelected,
                                        onSelected: sessionStatus == 'APPROVED' ? null : (selected) {
                                          if (selected) {
                                            setModalState(() {
                                              valueSelections[criteriaId] = opt['optionText'];
                                            });
                                          }
                                        },
                                      );
                                    }).toList(),
                                  )
                                else
                                  TextField(
                                    controller: textControllers[criteriaId],
                                    maxLines: 3,
                                    enabled: sessionStatus != 'APPROVED',
                                    decoration: InputDecoration(
                                      hintText: 'Masukkan feedback...',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                
                // Footer
                if (sessionStatus != 'APPROVED')
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final evaluations = <String, dynamic>{};
                          for (var e in lecturerEvaluation) {
                            final id = e['criteriaId'];
                            evaluations[id] = {
                              'evaluationValue': valueSelections[id],
                              'answerText': textControllers[id]?.text,
                            };
                          }
                          
                          try {
                            Navigator.pop(context); // Close sheet
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(child: CircularProgressIndicator()),
                            );
                            
                            await _api.submitLecturerEvaluation(widget.internshipId, weekNumber, evaluations);
                            
                            if (mounted) {
                              Navigator.pop(context); // Close loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Evaluasi berhasil disimpan')),
                              );
                              _loadData();
                            }
                          } catch (err) {
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal: $err')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Simpan Evaluasi'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }
}
