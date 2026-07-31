import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Global Loading Indicator – rotating logo with glass/glow aesthetic.
class CricketLoadingIndicator extends StatefulWidget {
  final String? message;
  final double size;
  final Color? ringColor;

  const CricketLoadingIndicator({
    Key? key,
    this.message,
    this.size = 64.0,
    this.ringColor,
  }) : super(key: key);

  @override
  State<CricketLoadingIndicator> createState() =>
      _CricketLoadingIndicatorState();
}

class _CricketLoadingIndicatorState extends State<CricketLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double sz = widget.size;
    final Color ring =
        widget.ringColor ?? AppTheme.primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Spinning logo inside frosted-glass disc ──────────────
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow halo
            Container(
              width: sz * 1.55,
              height: sz * 1.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ring.withOpacity(0.22),
                    ring.withOpacity(0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 0.90,
                  end: 1.10,
                  duration: 1400.ms,
                  curve: Curves.easeInOut,
                ),

            // Spinning arc ring
            SizedBox(
              width: sz * 1.18,
              height: sz * 1.18,
              child: AnimatedBuilder(
                animation: _rotateController,
                builder: (_, __) => Transform.rotate(
                  angle: _rotateController.value * 6.2832,
                  child: CircularProgressIndicator(
                    value: 0.75,
                    strokeWidth: 2.8,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ring.withOpacity(0.9),
                    ),
                    backgroundColor: ring.withOpacity(0.12),
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
            ),

            // Frosted-glass disc
            Container(
              width: sz,
              height: sz,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.18),
                    Colors.white.withOpacity(0.06),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.20),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ring.withOpacity(0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: EdgeInsets.all(sz * 0.18),
              // Rotating logo
              child: AnimatedBuilder(
                animation: _rotateController,
                builder: (_, child) => Transform.rotate(
                  angle: _rotateController.value * 6.2832,
                  child: child,
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),

        // ── Optional message ─────────────────────────────────────
        if (widget.message != null) ...[
          const SizedBox(height: 18),
          Text(
            widget.message!,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.85),
              letterSpacing: 0.3,
            ),
          )
              .animate()
              .fadeIn(duration: 450.ms, delay: 200.ms)
              .slideY(begin: 0.15, end: 0.0, duration: 450.ms, delay: 200.ms),
        ],
      ],
    ).animate().fadeIn(duration: 500.ms).scaleXY(
          begin: 0.85,
          end: 1.0,
          duration: 500.ms,
          curve: Curves.easeOutBack,
        );
  }
}



/// Global Error Display with Retry Option
class CricketErrorDisplay extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const CricketErrorDisplay({
    Key? key,
    required this.title,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingXL),
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppTheme.accentColor,
          ).animate()
           .scaleXY(begin: 0.5, end: 1.0, duration: 500.ms)
           .then()
           .shake(duration: 500.ms),
          const SizedBox(height: AppTheme.spacingLG),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ).animate()
           .fadeIn(duration: 400.ms, delay: 200.ms),
          const SizedBox(height: AppTheme.spacingMD),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ).animate()
           .fadeIn(duration: 400.ms, delay: 400.ms),
          if (onRetry != null) ...[
            const SizedBox(height: AppTheme.spacingXL),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXL,
                  vertical: AppTheme.spacingMD,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
            ).animate()
             .fadeIn(duration: 400.ms, delay: 600.ms)
             .scaleXY(begin: 0.8, end: 1.0, duration: 400.ms, delay: 600.ms),
          ],
        ],
      ),
    );
  }
}

/// Global Empty State Display
class CricketEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const CricketEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
          ).animate()
           .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut)
           .then()
           .shimmer(delay: 800.ms, duration: 800.ms),
          const SizedBox(height: AppTheme.spacingLG),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ).animate()
           .fadeIn(delay: 400.ms, duration: 500.ms)
           .slideY(begin: 0.3, end: 0.0, delay: 400.ms, duration: 500.ms),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
          ).animate()
           .fadeIn(delay: 600.ms, duration: 500.ms)
           .slideY(begin: 0.3, end: 0.0, delay: 600.ms, duration: 500.ms),
          if (action != null) ...[
            const SizedBox(height: AppTheme.spacingXL),
            action!.animate()
             .fadeIn(delay: 800.ms, duration: 500.ms)
             .slideY(begin: 0.3, end: 0.0, delay: 800.ms, duration: 500.ms),
          ],
        ],
      ),
    );
  }
}

/// Global Success Message Display
class CricketSuccessMessage extends StatelessWidget {
  final String message;
  final Duration autoHideDuration;

  const CricketSuccessMessage({
    Key? key,
    required this.message,
    this.autoHideDuration = const Duration(seconds: 3),
  }) : super(key: key);

  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppTheme.secondaryColor,
            ),
            const SizedBox(width: AppTheme.spacingSM),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLG,
        vertical: AppTheme.spacingMD,
      ),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Global Info Card Component
class CricketInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? accentColor;
  final VoidCallback? onTap;

  const CricketInfoCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.primaryColor;

    return Card(
      elevation: 2,
      shadowColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSM),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
            ],
          ),
        ),
      ),
    ).animate()
     .fadeIn(duration: 500.ms)
     .slideX(begin: -0.1, end: 0.0, duration: 500.ms);
  }
}

/// Global Status Badge Component
class CricketStatusBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const CricketStatusBadge({
    Key? key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMD,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: textColor,
            ),
            const SizedBox(width: AppTheme.spacingXS),
          ],
          Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Global Gradient Background Container
class CricketGradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final Alignment begin;
  final Alignment end;

  const CricketGradientBackground({
    Key? key,
    required this.child,
    this.colors = const [
      Color(0xFF1A73E8),
      Color(0xFF1565C0),
      Color(0xFF0D47A1),
    ],
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: begin,
          end: end,
        ),
      ),
      child: child,
    );
  }
}

/// Global Glassmorphism Container
class CricketGlassContainer extends StatelessWidget {
  final Widget child;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const CricketGlassContainer({
    Key? key,
    required this.child,
    this.opacity = 0.1,
    this.borderRadius,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}