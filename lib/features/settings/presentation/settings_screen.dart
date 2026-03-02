import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isWidgetEnabled = false;
  bool _isNotificationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSecondary,
        elevation: 0,
        title: Text('Pengaturan', style: AppTextStyles.h4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Text('Settings', style: AppTextStyles.h1),
          const SizedBox(height: 32),
          Text(
            'Preferensi',
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Aktifkan Widget',
            subtitle: 'Tampilkan widget di home screen',
            value: _isWidgetEnabled,
            onChanged: (value) {
              setState(() {
                _isWidgetEnabled = value;
              });
            },
          ),
          const Divider(height: 32),
          _buildSwitchTile(
            title: 'Notifikasi',
            subtitle: 'Terima notifikasi dari aplikasi',
            value: _isNotificationEnabled,
            onChanged: (value) {
              setState(() {
                _isNotificationEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      // activeColor: AppColors.primary, // Deprecated, using theme default
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
