import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/shared_widgets.dart';

/// Student screen to schedule a new guidance session (bimbingan)
class GuidanceScheduleScreen extends StatefulWidget {
  final bool isTab;
  const GuidanceScheduleScreen({super.key, this.isTab = false});

  @override
  State<GuidanceScheduleScreen> createState() => _GuidanceScheduleScreenState();
}

class _GuidanceScheduleScreenState extends State<GuidanceScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSupervisor = 'Pembimbing 1';
  DateTime? _selectedDate;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      setState(() => _isSubmitting = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permintaan bimbingan berhasil dikirim!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      });
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal bimbingan terlebih dahulu.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Jadwalkan Bimbingan', style: AppTextStyles.h4),
        automaticallyImplyLeading: !widget.isTab,
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        Text('Bimbingan Baru', style: AppTextStyles.h4),
                      ],
                    ),
                    const AppDivider(),

                    // Supervisor
                    Text('Pembimbing', style: AppTextStyles.labelSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: ['Pembimbing 1', 'Pembimbing 2'].map((sup) {
                        final isSelected = _selectedSupervisor == sup;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedSupervisor = sup),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.only(
                                right: sup == 'Pembimbing 1' ? 8 : 0,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                                    sup,
                                    style: AppTextStyles.label.copyWith(
                                      color: isSelected
                                          ? AppColors.white
                                          : AppColors.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    sup == 'Pembimbing 1'
                                        ? 'Dr. Ricky Akbar'
                                        : 'Dr. Hira Meidia',
                                    style: AppTextStyles.caption.copyWith(
                                      color: isSelected
                                          ? AppColors.white.withValues(
                                              alpha: 0.8,
                                            )
                                          : AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.base),

                    // Date picker
                    Text(
                      'Tanggal yang Diinginkan',
                      style: AppTextStyles.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.smallRadius,
                          ),
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
                                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              style: AppTextStyles.body.copyWith(
                                color: _selectedDate == null
                                    ? AppColors.textTertiary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.base),

                    // Notes
                    Text('Topik / Catatan', style: AppTextStyles.labelSmall),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText:
                            'Tuliskan topik yang ingin dibahas atau pertanyaan yang ingin disampaikan...',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Mohon isi topik bimbingan'
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

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

              AppButton(
                label: 'Kirim Permintaan',
                icon: Icons.send_outlined,
                onPressed: _submit,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
