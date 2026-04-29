import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/internship_api_service.dart';
import '../../../../core/utils/formatters.dart' as fmt;
import '../../../../core/widgets/app_drawer.dart';
import '../../../notifications/presentation/notification_screen.dart';

class InternshipGuidanceScreen extends StatefulWidget {
  final UserModel? user;
  const InternshipGuidanceScreen({super.key, this.user});

  @override
  State<InternshipGuidanceScreen> createState() => _InternshipGuidanceScreenState();
}

class _InternshipGuidanceScreenState extends State<InternshipGuidanceScreen> {
  final InternshipApiService _api = InternshipApiService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _guidanceData = {};

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
      final res = await _api.getGuidanceTimeline();
      if (res['success'] == true) {
        setState(() {
          _guidanceData = res['data'] ?? {};
          _isLoading = false;
        });
      } else {
        throw Exception(res['message'] ?? 'Gagal memuat data bimbingan');
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
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      drawer: AppDrawer(user: widget.user, activeRoute: 'internship'),
      appBar: AppBar(
        title: const Text('Bimbingan KP'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildErrorState()
              : _buildTimeline(),
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.destructive),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Gagal memuat data',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final timeline = _guidanceData['timeline'] as List? ?? [];
    
    if (timeline.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Belum ada jadwal bimbingan', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Text(
              'Hubungi admin jika jadwal bimbingan belum muncul.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        itemCount: timeline.length,
        itemBuilder: (context, index) {
          final week = timeline[index];
          return _buildWeekCard(week);
        },
      ),
    );
  }

  Widget _buildWeekCard(Map<String, dynamic> week) {
    final weekNumber = week['weekNumber'];
    final status = week['status'] as String;
    final startDate = DateTime.tryParse(week['startDate']?.toString() ?? '') ?? DateTime.now();
    final endDate = DateTime.tryParse(week['endDate']?.toString() ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: _buildWeekIndicator(weekNumber, status),
          title: Text(
            'Minggu Ke-$weekNumber',
            style: AppTextStyles.h4,
          ),
          subtitle: Text(
            '${fmt.formatDateIndonesian(startDate)} - ${fmt.formatDateIndonesian(endDate)}',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildStatusBadge(status),
                  const SizedBox(height: 16),
                  if (status == 'OPEN')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showGuidanceForm(week),
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Isi Laporan Bimbingan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    )
                  else if (status == 'SUBMITTED' || status == 'APPROVED' || status == 'LATE')
                    _buildGuidanceDetail(week)
                  else
                    Text(
                      'Bimbingan belum dibuka untuk minggu ini.',
                      style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekIndicator(int weekNumber, String status) {
    Color color = Colors.grey;
    IconData icon = Icons.timer_outlined;

    switch (status) {
      case 'APPROVED':
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'SUBMITTED':
        color = AppColors.info;
        icon = Icons.send;
        break;
      case 'LATE':
        color = AppColors.destructive;
        icon = Icons.warning;
        break;
      case 'OPEN':
        color = AppColors.primary;
        icon = Icons.edit;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildStatusBadge(String status) {
    String label = 'Belum Tersedia';
    Color color = Colors.grey;

    switch (status) {
      case 'APPROVED':
        label = 'Sudah Disetujui';
        color = AppColors.success;
        break;
      case 'SUBMITTED':
        label = 'Menunggu Verifikasi';
        color = AppColors.info;
        break;
      case 'LATE':
        label = 'Terlambat';
        color = AppColors.destructive;
        break;
      case 'OPEN':
        label = 'Terbuka';
        color = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildGuidanceDetail(Map<String, dynamic> week) {
    final questions = week['questions'] as List? ?? [];
    final evaluations = week['lecturerEvaluation'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (questions.isNotEmpty) ...[
          Text('Jawaban Mahasiswa:', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...questions.map((q) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q['questionText'] ?? '', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(q['answer'] ?? '-', style: AppTextStyles.bodySmall),
              ],
            ),
          )),
        ],
        if (evaluations.isNotEmpty) ...[
          const Divider(height: 32),
          Text('Evaluasi Dosen:', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...evaluations.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e['criteriaName'] ?? '', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                if (e['inputType'] == 'EVALUATION')
                  _buildEvaluationStars(e['evaluationValue'])
                else
                  Text(e['answerText'] ?? '-', style: AppTextStyles.bodySmall),
              ],
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildEvaluationStars(dynamic value) {
    final int score = int.tryParse(value?.toString() ?? '0') ?? 0;
    return Row(
      children: List.generate(5, (index) => Icon(
        index < score ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 16,
      )),
    );
  }

  void _showGuidanceForm(Map<String, dynamic> week) {
    final questions = week['questions'] as List? ?? [];
    final weekNumber = week['weekNumber'];
    final controllers = <String, TextEditingController>{};
    
    for (var q in questions) {
      controllers[q['id']] = TextEditingController(text: q['answer'] ?? '');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Laporan Minggu $weekNumber', style: AppTextStyles.h4),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: questions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, i) {
                    final q = questions[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q['questionText'] ?? '', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controllers[q['id']],
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Tulis jawaban Anda...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final answers = controllers.map((key, value) => MapEntry(key, value.text.trim()));
                    Navigator.pop(context);
                    _submitGuidance(weekNumber, answers);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Kirim Laporan'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitGuidance(int weekNumber, Map<String, String> answers) async {
    setState(() => _isLoading = true);
    try {
      await _api.submitStudentGuidance(weekNumber, answers);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bimbingan berhasil dikirim'), backgroundColor: AppColors.success),
      );
      _loadData();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim bimbingan: $e'), backgroundColor: AppColors.destructive),
      );
    }
  }
}
