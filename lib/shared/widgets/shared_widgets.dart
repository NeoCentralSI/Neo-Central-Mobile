import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/thesis_labels.dart';

// ─── AppCard ─────────────────────────────────────────────────
/// Standard surface card with shadow + border
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(radius ?? 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

// ─── StatusBadge ─────────────────────────────────────────────
enum BadgeVariant {
  primary,
  success,
  warning,
  destructive,
  outline,
  secondary,
  info,
}

class AppBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final double? fontSize;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.secondary,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color? borderColor;

    switch (variant) {
      case BadgeVariant.primary:
        bg = AppColors.primary;
        fg = AppColors.white;
        borderColor = null;
        break;
      case BadgeVariant.success:
        bg = AppColors.successLight;
        fg = AppColors.successDark;
        borderColor = null;
        break;
      case BadgeVariant.warning:
        bg = AppColors.warningLight;
        fg = AppColors.warningDark;
        borderColor = null;
        break;
      case BadgeVariant.destructive:
        bg = AppColors.destructiveLight;
        fg = AppColors.destructiveDark;
        borderColor = null;
        break;
      case BadgeVariant.outline:
        bg = AppColors.transparent;
        fg = AppColors.textSecondary;
        borderColor = AppColors.divider;
        break;
      case BadgeVariant.secondary:
        bg = AppColors.surfaceSecondary;
        fg = AppColors.textSecondary;
        borderColor = AppColors.border.withValues(alpha: 0.5);
        break;
      case BadgeVariant.info:
        bg = AppColors.infoLight;
        fg = AppColors.infoDark;
        borderColor = null;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ─── AppProgressBar ──────────────────────────────────────────
class AppProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color? color;
  final double height;

  const AppProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);
    final barColor =
        color ?? (clampedValue >= 1.0 ? AppColors.success : AppColors.primary);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(height),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clampedValue,
        child: Container(
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(height),
          ),
        ),
      ),
    );
  }
}

// ─── SectionHeader ───────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.h4)),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!, style: AppTextStyles.primaryLabel),
          ),
      ],
    );
  }
}

// ─── AppButton ───────────────────────────────────────────────
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutline;
  final Color? color;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutline = false,
    this.color,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutline ? effectiveColor : AppColors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );

    if (isOutline) {
      return SizedBox(
        width: width ?? double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: effectiveColor,
            side: BorderSide(color: effectiveColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveColor,
          foregroundColor: AppColors.white,
          elevation: 3,
          shadowColor: effectiveColor.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
        child: child,
      ),
    );
  }
}

// ─── Divider with Spacing ─────────────────────────────────────
class AppDivider extends StatelessWidget {
  final double verticalPadding;
  const AppDivider({super.key, this.verticalPadding = AppSpacing.base});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }
}

// ─── Info Row ────────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.label.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── GradientHeader ──────────────────────────────────────────
/// Page header used across the app, matching the Bimbingan and Milestone
/// screens: orange gradient, rounded bottom corners, white title.
///
/// [leading] is usually [HeaderIconButton.back] or [HeaderIconButton.menu].
/// [bottom] holds an optional [HeaderTabBar].
class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottom;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            bottom == null ? AppSpacing.xl : 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    trailing!,
                  ],
                ],
              ),
              if (bottom != null) ...[
                const SizedBox(height: AppSpacing.sm),
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Round translucent icon button for [GradientHeader].
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  /// Back arrow that pops the current route.
  static Widget back(BuildContext context) => HeaderIconButton(
    icon: Icons.arrow_back_ios_new,
    tooltip: 'Kembali',
    onPressed: () => Navigator.maybePop(context),
  );

  /// Menu button that opens the nearest [Scaffold] drawer.
  static Widget menu() => Builder(
    builder: (context) => HeaderIconButton(
      icon: Icons.menu,
      tooltip: 'Menu',
      onPressed: () => Scaffold.of(context).openDrawer(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: AppColors.white, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

/// Tab bar for [GradientHeader]. Tabs share the width equally, so two tabs
/// sit centred and balanced.
class HeaderTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<String> labels;

  const HeaderTabBar({
    super.key,
    required this.controller,
    required this.labels,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: false,
      labelColor: AppColors.white,
      unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
      indicatorColor: AppColors.white,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: AppColors.transparent,
      labelPadding: EdgeInsets.zero,
      labelStyle: AppTextStyles.label.copyWith(fontSize: 14),
      unselectedLabelStyle: AppTextStyles.body.copyWith(fontSize: 14),
      tabs: [for (final label in labels) Tab(text: label)],
    );
  }
}

// ─── EmptyStateView ──────────────────────────────────────────
/// Centered icon + text used when a list has nothing to show.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.base),
          Text(title, style: AppTextStyles.h4, textAlign: TextAlign.center),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Failed load with the reason and a retry button.
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Gagal memuat data',
            style: AppTextStyles.h4,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.base),
          AppButton(
            label: 'Coba Lagi',
            icon: Icons.refresh,
            onPressed: onRetry,
            width: 160,
          ),
        ],
      ),
    );
  }
}

/// Scrollable wrapper so empty and error states still allow pull-to-refresh.
class ScrollableCenter extends StatelessWidget {
  final Widget child;

  const ScrollableCenter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// ─── PhaseBadge ──────────────────────────────────────────────
/// "Jenis" badge of a guidance session or milestone: Proposal or Penelitian.
/// Renders nothing for a missing or unknown phase.
class PhaseBadge extends StatelessWidget {
  final Object? phase;

  const PhaseBadge({super.key, required this.phase});

  @override
  Widget build(BuildContext context) {
    final value = phase?.toString();
    if (!isKnownThesisPhase(value)) return const SizedBox.shrink();
    final isProposal = value == 'proposal';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isProposal ? AppColors.surfaceSecondary : AppColors.infoLight,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        border: Border.all(
          color: isProposal
              ? AppColors.border.withValues(alpha: 0.7)
              : AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        thesisPhaseLabel(value),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isProposal ? AppColors.textSecondary : AppColors.infoDark,
        ),
      ),
    );
  }
}

// ─── FootnoteText ────────────────────────────────────────────
/// One small centred line at the bottom of a page, like a copyright line.
class FootnoteText extends StatelessWidget {
  final String text;

  const FootnoteText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
      ),
    );
  }
}

// ─── AppSearchField ──────────────────────────────────────────
/// Search box styled like the one on the Mahasiswa Bimbingan list.
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodySmall,
        prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.primary),
        filled: true,
        fillColor: AppColors.white,
      ),
    );
  }
}
