import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/video_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';

class LivePreviewScreen extends StatefulWidget {
  const LivePreviewScreen({super.key});

  @override
  State<LivePreviewScreen> createState() => _LivePreviewScreenState();
}

class _LivePreviewScreenState extends State<LivePreviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  int _refreshKey = 0;       // Incremented to force Video widget teardown
  bool _isRefreshing = false; // Shows loading overlay during reconnect

  // Separate VideoControllers per camera — prevents shared-surface black screens
  final Map<int, VideoController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Initialise preview players after the first frame so the provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPreviews();
    });
  }

  Future<void> _initPreviews() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);

    try {
      final provider = context.read<VideoProvider>();

      // Dispose old controllers before reinitialising players
      await provider.initializePreviewPlayers();

      // Increment key — forces every Video widget to be fully recreated
      // (new rendering surface, new texture) rather than reusing the stale one.
      _videoControllers.clear();
      for (int camIdx in [1, 2]) {
        final player = provider.getPreviewPlayer(camIdx);
        if (player != null) {
          _videoControllers[camIdx] = VideoController(player);
        }
      }

      if (mounted) {
        setState(() {
          _refreshKey++; // Key change forces Video widget rebuild
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // VideoControllers don't need explicit disposal — Players are owned by provider
    super.dispose();
  }

  double _s(
    BuildContext context,
    double value, {
    double minScale = 0.9,
    double maxScale = 1.18,
  }) {
    return context.scale(
      value,
      minScale: minScale,
      maxScale: maxScale,
    );
  }

  Widget _buildGlassPanel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppTheme.spacingMD),
    BorderRadius? borderRadius,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(28);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.22),
                Colors.white.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  void _showReballConfirmation(BuildContext context, VideoProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Confirm Reball',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to reball?',
          style: GoogleFonts.montserrat(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'NO',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: AppTheme.neutralColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.startRecording(isReball: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: Text(
              'YES',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPauseConfirmation(BuildContext context, VideoProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: Row(
          children: [
            const Icon(Icons.pause_circle_filled, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pause Match',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'The match will be paused and all progress saved.\n\nYou can resume from the same ball when you return.',
          style: GoogleFonts.montserrat(
            color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await provider.pauseMatch();
            },
            icon: const Icon(Icons.pause, size: 18),
            label: Text(
              'PAUSE',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEndMatchConfirmation(BuildContext context, VideoProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: Row(
          children: [
            const Icon(Icons.flag, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'End Match',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to end this match? You will be taken back to the setup screen.',
          style: GoogleFonts.montserrat(
            color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.endMatch();
            },
            icon: const Icon(Icons.flag, size: 18),
            label: Text(
              'END MATCH',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInningsOverlay(VideoProvider provider) {
    final matchDetails = provider.matchDetails;
    if (matchDetails == null) return const SizedBox.shrink();

    final bufferStatus = provider.bufferStatus;
    final innings = provider.currentInnings;
    final overBall = provider.currentOverBall;
    final totalOvers = matchDetails.numberOfOvers;
    final isInningsOver = provider.isInningsOver;
    final isMatchOver = provider.isMatchOver;
    final usedBalls = bufferStatus?.usedBufferSize ?? 0;
    final totalBalls = bufferStatus?.totalBufferSize ?? 6;
    final bufferPercent = bufferStatus?.percentageUsed ?? 0;
    final currentBall = bufferStatus?.currentBall ?? overBall;

    final statusColor = isMatchOver
        ? Colors.greenAccent
        : isInningsOver
            ? Colors.orangeAccent
            : const Color(0xFF8CCBFF);
    final statusText = isMatchOver
        ? 'Match Over'
        : isInningsOver
            ? 'Innings Complete'
            : 'Live';
    final statusIcon = isMatchOver
        ? Icons.flag_rounded
        : isInningsOver
            ? Icons.done_all_rounded
            : Icons.bolt_rounded;

    final bufferColor = bufferPercent >= 80
        ? const Color(0xFFFF7A7A)
        : bufferPercent >= 50
            ? const Color(0xFFFFD36C)
            : const Color(0xFFA8FFB5);

    Widget compactStat({
      required IconData icon,
      required String label,
      required String value,
      Color accentColor = Colors.white,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: accentColor, size: 12),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.60),
                        letterSpacing: 0.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${matchDetails.team1Name} vs ${matchDetails.team2Name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.32),
                                width: 0.9,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, color: statusColor, size: 10),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          compactStat(
                            icon: Icons.layers_rounded,
                            label: 'Innings',
                            value: '$innings',
                          ),
                          const SizedBox(width: 6),
                          compactStat(
                            icon: Icons.sports_baseball_rounded,
                            label: 'Over',
                            value: '$overBall/$totalOvers',
                          ),
                          const SizedBox(width: 6),
                          compactStat(
                            icon: Icons.radio_button_checked_rounded,
                            label: 'Ball',
                            value: currentBall.toString(),
                          ),
                          const SizedBox(width: 6),
                          compactStat(
                            icon: Icons.stacked_bar_chart_rounded,
                            label: 'Buffer',
                            value: '$usedBalls/$totalBalls',
                            accentColor: bufferColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 320.ms)
      .slideY(begin: -0.18, end: 0.0, duration: 360.ms, curve: Curves.easeOutCubic);
  }

  // ── Unified Liquid-Glass Action Button ──────────────────────────────────────
  Widget _buildLiquidActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    double size = 48,
    bool isPrimary = false,
    bool isRecordingPulse = false,
  }) {
    final enabled = onPressed != null;
    final primaryColor = isPrimary ? color : color.withValues(alpha: 0.85);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isPrimary ? 100 : 18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: isPrimary ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: isPrimary ? null : BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: enabled
                          ? [
                              primaryColor.withValues(alpha: 0.14),
                              primaryColor.withValues(alpha: 0.025),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.035),
                              Colors.white.withValues(alpha: 0.01),
                            ],
                    ),
                    border: Border.all(
                      color: enabled
                          ? primaryColor.withValues(alpha: 0.24)
                          : Colors.white.withValues(alpha: 0.07),
                      width: 1.0,
                    ),
                    boxShadow: [
                      if (enabled && isPrimary)
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.10),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: enabled ? primaryColor : Colors.white30,
                      size: isPrimary ? 32 : 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
            .animate(target: enabled ? 1 : 0)
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              duration: 400.ms,
              curve: Curves.elasticOut,
            )
            .animate(onPlay: (c) => isRecordingPulse ? c.repeat(reverse: true) : null)
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.08, 1.08),
              duration: 800.ms,
              curve: Curves.easeInOutSine,
            ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: enabled ? Colors.white : Colors.white30,
            letterSpacing: 0.8,
            shadows: [
              const Shadow(blurRadius: 4, color: Colors.black45),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls(VideoProvider provider) {
    final showNextInnings = provider.isInningsOver && !provider.isMatchOver;
    final isRecording = provider.isRecording;
    final isMatchOver = provider.isMatchOver;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Main Controller Strip ──────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // PAUSE 
                        _buildLiquidActionButton(
                          onPressed: isRecording ? null : () => _showPauseConfirmation(context, provider),
                          icon: Icons.pause_rounded,
                          label: 'Pause',
                          color: Colors.orangeAccent,
                          size: 40,
                        ),
                        const SizedBox(width: 10),

                        // REBALL
                        _buildLiquidActionButton(
                          onPressed: provider.canReball && !isRecording ? () => _showReballConfirmation(context, provider) : null,
                          icon: Icons.replay_rounded,
                          label: 'Reball',
                          color: Colors.amber,
                          size: 40,
                        ),
                        const SizedBox(width: 12),

                        // MAIN RECORD/ACTION
                        _buildLiquidActionButton(
                          onPressed: isMatchOver
                              ? () => _showEndMatchConfirmation(context, provider)
                              : showNextInnings
                                  ? () => provider.switchToNextInnings()
                                  : isRecording
                                      ? () => provider.stopRecording()
                                      : () => provider.startRecording(),
                          icon: isMatchOver
                              ? Icons.flag_rounded
                              : showNextInnings
                                  ? Icons.skip_next_rounded
                                  : isRecording
                                      ? Icons.stop_rounded
                                      : Icons.videocam_rounded,
                          label: isMatchOver ? 'Done' : showNextInnings ? 'Next' : isRecording ? 'Stop' : 'Rec',
                          color: isMatchOver ? Colors.greenAccent : showNextInnings ? Colors.orange : isRecording ? Colors.redAccent : const Color(0xFF381DA8),
                          size: 62,
                          isPrimary: true,
                          isRecordingPulse: isRecording,
                        ).animate(onPlay: (c) => c.repeat(reverse: true))
                         .shimmer(duration: 2.seconds, color: Colors.white12),

                        const SizedBox(width: 12),

                        // SYNC / REFRESH
                        _buildLiquidActionButton(
                          onPressed: _isRefreshing ? null : () => _initPreviews(),
                          icon: Icons.sync_rounded,
                          label: _isRefreshing ? 'Syncing' : 'Sync',
                          color: Colors.blueAccent,
                          size: 48,
                        ),
                        const SizedBox(width: 10),

                        // END MATCH
                        _buildLiquidActionButton(
                          onPressed: () => _showEndMatchConfirmation(context, provider),
                          icon: Icons.close_rounded,
                          label: 'End',
                          color: Colors.red,
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms, delay: 200.ms)
              .slideY(begin: 0.4, end: 0, duration: 600.ms, curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, provider, _) {
        final hasDual = provider.matchDetails?.hasDualCameras ?? false;
        final hasIpCamera =
            provider.matchDetails?.cameraIp.isNotEmpty ?? false;

        // Auto-trigger reball if requested from review screen
        if (provider.shouldAutoReball) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.shouldAutoReball) { // Double check
              provider.clearAutoReball();
              provider.startRecording(isReball: true);
            }
          });
        }

        return Stack(
          children: [
            // ── Preview Area ─────────────────────────────────────────────
            Positioned.fill(
              child: hasIpCamera
                  ? _buildPreviewArea(provider, hasDual)
                  : _buildDeviceCameraPreview(provider),
            ),

            // ── Overlays ─────────────────────────────────────────────────
            Column(
              children: [
                // Match details overlay at the top
                _buildInningsOverlay(provider),

                const Spacer(),

                // Floating controls kept clear of preview center
                _buildBottomControls(provider),
              ],
            ),
          ],
        );
      },
    );
  }

  // ── Preview builders ───────────────────────────────────────────────────────

  /// Builds the preview area: single or dual depending on configuration.
  Widget _buildPreviewArea(VideoProvider provider, bool hasDual) {
    if (!hasDual) {
      // Single camera — full screen
      return _buildCameraView(1);
    }

    // Dual camera — split screen (vertical on portrait, horizontal on landscape)
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return isLandscape
        ? Row(
            children: [
              Expanded(child: _buildCameraView(1)),
              const SizedBox(width: 2),
              Expanded(child: _buildCameraView(2)),
            ],
          )
        : Column(
            children: [
              Expanded(child: _buildCameraView(1)),
              const SizedBox(height: 2),
              Expanded(child: _buildCameraView(2)),
            ],
          );
  }

  /// Renders a single camera's live preview using its isolated VideoController.
  Widget _buildCameraView(int cameraIndex) {
    final controller = _videoControllers[cameraIndex];

    if (controller == null) {
      return _buildLoadingState('Connecting to Camera $cameraIndex…');
    }

    return Stack(
      // Key change forces Flutter to fully destroy and recreate the
      // Video widget (new GPU texture) instead of reusing the stale surface.
      key: ValueKey('cam_${cameraIndex}_$_refreshKey'),
      fit: StackFit.expand,
      children: [
        Video(
          controller: controller,
          controls: NoVideoControls,
          fit: BoxFit.cover,
        ),
        // Camera label badge
        Positioned(
          bottom: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_rounded, color: Colors.white, size: 13),
                const SizedBox(width: 4),
                Text(
                  'CAM $cameraIndex',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCameraPreview(VideoProvider provider) {
    if (!provider.cameraService.isInitialized) {
      return _buildLoadingState('Initializing Camera…');
    }
    final controller = provider.cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return _buildLoadingState('Initializing Camera…');
    }

    // Device camera uses the camera package — unchanged
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: controller.buildPreview(),
    );
  }

  Widget _buildLoadingState(String message) {
    final outerPadding = _s(context, 28, minScale: 0.9, maxScale: 1.2);
    final panelRadius = _s(context, 32, minScale: 0.92, maxScale: 1.14);
    final heroSize = _s(context, 118, minScale: 0.88, maxScale: 1.18);
    final logoSize = _s(context, 72, minScale: 0.9, maxScale: 1.16);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF07111F),
            Color(0xFF0E2238),
            Color(0xFF132E4B),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: outerPadding),
          child: _buildGlassPanel(
            padding: EdgeInsets.symmetric(
              horizontal: outerPadding,
              vertical: _s(context, 30),
            ),
            borderRadius: BorderRadius.circular(panelRadius),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: heroSize,
                      height: heroSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.blueAccent.withValues(alpha: 0.26),
                            Colors.cyanAccent.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .scale(
                          begin: const Offset(0.86, 0.86),
                          end: const Offset(1.08, 1.08),
                          duration: 1800.ms,
                          curve: Curves.easeInOut,
                        )
                        .fadeIn(duration: 700.ms),
                    Image.asset(
                      'assets/images/logo.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .rotate(
                          begin: 0,
                          end: 1,
                          duration: 2200.ms,
                          curve: Curves.linear,
                        ),
                  ],
                ),
                SizedBox(height: _s(context, 24)),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: _s(context, 18, minScale: 0.94, maxScale: 1.14),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: _s(context, 10)),
                Text(
                  'Preparing live preview with a smoother, cleaner experience.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: _s(context, 13, minScale: 0.94, maxScale: 1.12),
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: _s(context, 22)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: _s(context, 5, minScale: 0.9, maxScale: 1.08),
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.lightBlueAccent.withValues(alpha: 0.95),
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(duration: 500.ms)
                    .shimmer(
                      duration: 1400.ms,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

