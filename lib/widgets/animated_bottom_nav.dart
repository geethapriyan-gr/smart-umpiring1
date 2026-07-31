import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';

class BottomNavItem {
  final IconData icon;
  final String label;
  final Color activeColor;

  const BottomNavItem({
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}

class AnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Animation<double> animation;
  final List<BottomNavItem> items;

  const AnimatedBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.animation,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final horizontalMargin = context.scale(16, minScale: 0.9, maxScale: 1.2);
    final verticalMargin = context.scale(
      AppTheme.spacingSM,
      minScale: 0.9,
      maxScale: 1.15,
    );
    final maxWidth = context.adaptiveContentWidth(
      mobileFraction: 0.94,
      tabletFraction: 0.72,
      desktopFraction: 0.56,
      maxWidth: 760,
    );

    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: horizontalMargin,
          vertical: verticalMargin,
        ),
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
          child: BackdropFilter(
            filter: ColorFilter.mode(
              Colors.white.withOpacity(0.05),
              BlendMode.srcOver,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.scale(8, minScale: 0.9, maxScale: 1.12),
                vertical: context.scale(4, minScale: 0.9, maxScale: 1.1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  items.length,
                  (index) => Expanded(
                    child: _buildNavItem(context, index),
                  ),
                ),
              ),
            ),
          ),
        ),
      ).animate()
       .fadeIn(duration: 600.ms, delay: 200.ms)
       .slideY(begin: 1.0, end: 0.0, duration: 600.ms, delay: 200.ms, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildNavItem(BuildContext context, int index) {
    final item = items[index];
    final isSelected = index == currentIndex;
    final horizontalPadding = context.scale(
      isSelected ? AppTheme.spacingMD : AppTheme.spacingSM,
      minScale: 0.9,
      maxScale: 1.12,
    );
    final verticalPadding = context.scale(
      AppTheme.spacingSM,
      minScale: 0.9,
      maxScale: 1.1,
    );
    final minWidth = context.scale(60, minScale: 0.9, maxScale: 1.15);
    final iconSize = context.scale(
      isSelected ? 22 : 18,
      minScale: 0.92,
      maxScale: 1.12,
    );
    final labelFontSize = context.scale(10, minScale: 0.95, maxScale: 1.08);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        margin: EdgeInsets.symmetric(
          horizontal: context.scale(2, minScale: 0.9, maxScale: 1.1),
        ),
        constraints: BoxConstraints(minWidth: minWidth),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    item.activeColor,
                    item.activeColor.withOpacity(0.8),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: iconSize,
            ).animate(target: isSelected ? 1 : 0)
             .scaleXY(end: 1.1, duration: 200.ms),

            if (isSelected) ...[
              SizedBox(height: context.scale(2, minScale: 0.9, maxScale: 1.08)),
              Text(
                item.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ).animate()
               .fadeIn(duration: 200.ms)
               .slideY(begin: 0.5, end: 0.0, duration: 200.ms),
            ],
          ],
        ),
      ),
    );
  }
}
