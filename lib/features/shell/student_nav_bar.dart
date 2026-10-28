import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// One tab of [StudentNavBar].
class StudentNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const StudentNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Student bottom bar: four tabs with a raised round "Ajukan Bimbingan"
/// button in the middle. The button is an action, not a tab.
///
/// Styled like the lecturer [NavigationBar] (same colours and indicator),
/// and the labels shrink to fit on narrow phones.
class StudentNavBar extends StatelessWidget {
  /// Exactly four tabs: two left of the button, two right.
  final List<StudentNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onCenterPressed;
  final String centerLabel;

  const StudentNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onCenterPressed,
    this.centerLabel = 'Ajukan',
  }) : assert(items.length == 4);

  static const double barHeight = 68;
  static const double buttonSize = 56;

  /// How far the round button rises above the top of the bar.
  static const double raise = 14;

  @override
  Widget build(BuildContext context) {
    Widget tab(int index) => Expanded(
      child: _Tab(
        item: items[index],
        selected: index == selectedIndex,
        onTap: () => onSelected(index),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: barHeight,
          child: Row(
            children: [
              tab(0),
              tab(1),
              SizedBox(
                width: 76,
                child: _CenterButton(
                  label: centerLabel,
                  onPressed: onCenterPressed,
                ),
              ),
              tab(2),
              tab(3),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final StudentNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryDark : AppColors.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        highlightShape: BoxShape.rectangle,
        containedInkWell: true,
        child: Column(
          // Icons stay aligned even when a long label is scaled down.
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 30,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _CenterButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: StudentNavBar.buttonSize,
      height: StudentNavBar.buttonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        // White ring separates the raised button from the page behind it.
        border: Border.all(color: AppColors.surface, width: 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('student-nav-center'),
          onTap: onPressed,
          child: const Icon(
            Icons.add_rounded,
            color: AppColors.white,
            size: 28,
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: 'Ajukan Bimbingan',
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Raised: the top of the button rises above the bar.
          Positioned(top: -StudentNavBar.raise, child: button),
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
