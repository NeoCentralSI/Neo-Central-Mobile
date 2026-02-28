import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/lecturer_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import 'student_detail_screen.dart';

/// List of supervised students for a lecturer - fetches from backend
class StudentListScreen extends StatefulWidget {
  final bool isTab;
  const StudentListScreen({super.key, this.isTab = false});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _api = LecturerApiService();

  bool _isLoading = true;
  String? _error;
  List<dynamic> _students = [];
  String _searchQuery = '';

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
      _students = await _api.getMyStudents();
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

  List<dynamic> get _filtered => _students.where((s) {
    final name = (s['fullName'] ?? s['studentName'] ?? '')
        .toString()
        .toLowerCase();
    final thesis = (s['thesisTitle'] ?? '').toString().toLowerCase();
    final query = _searchQuery.toLowerCase();
    return name.contains(query) || thesis.contains(query);
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mahasiswa Bimbingan', style: AppTextStyles.h4),
        automaticallyImplyLeading: !widget.isTab,
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  Text('Gagal memuat data', style: AppTextStyles.h4),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Coba Lagi',
                    icon: Icons.refresh,
                    onPressed: _loadData,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  // Search bar
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      0,
                      AppSpacing.pagePadding,
                      AppSpacing.md,
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Cari mahasiswa...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textTertiary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _filtered.isEmpty
                        ? Center(
                            child: Text(
                              'Tidak ada mahasiswa ditemukan',
                              style: AppTextStyles.body,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(
                              AppSpacing.pagePadding,
                            ),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final student = _filtered[index];
                              return _StudentCard(
                                student: student,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        StudentDetailScreen(student: student),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final dynamic student;
  final VoidCallback onTap;

  const _StudentCard({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = (student['fullName'] ?? student['studentName'] ?? '-')
        .toString();
    final nim = (student['identityNumber'] ?? student['studentNim'] ?? '-')
        .toString();
    final thesis = (student['thesisTitle'] ?? '-').toString();
    final rating = (student['thesisRating'] ?? 'ONGOING').toString();
    final milestoneProgressRaw = student['milestoneProgress'];
    final double milestone = milestoneProgressRaw is int
        ? milestoneProgressRaw / 100
        : (milestoneProgressRaw is double ? milestoneProgressRaw : 0.0);
    final int guidance = (student['completedGuidanceCount'] ?? 0) is int
        ? (student['completedGuidanceCount'] ?? 0) as int
        : 0;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: AppTextStyles.h4.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.label),
                    Text(nim, style: AppTextStyles.caption),
                  ],
                ),
              ),
              AppBadge(
                label: _ratingLabel(rating),
                variant: _ratingVariant(rating),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            thesis,
            style: AppTextStyles.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Milestone', style: AppTextStyles.caption),
                        Text(
                          '${(milestone * 100).round()}%',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AppProgressBar(value: milestone, height: 6),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Bimbingan', style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.chat_outlined,
                        size: 12,
                        color: guidance >= 8
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$guidance/8',
                        style: AppTextStyles.caption.copyWith(
                          color: guidance >= 8
                              ? AppColors.success
                              : AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  BadgeVariant _ratingVariant(String rating) {
    switch (rating) {
      case 'AT_RISK':
        return BadgeVariant.destructive;
      case 'SLOW':
        return BadgeVariant.warning;
      case 'ONGOING':
        return BadgeVariant.success;
      default:
        return BadgeVariant.outline;
    }
  }

  String _ratingLabel(String rating) {
    switch (rating) {
      case 'AT_RISK':
        return 'Beresiko';
      case 'SLOW':
        return 'Lambat';
      case 'ONGOING':
        return 'On Track';
      default:
        return rating;
    }
  }
}
