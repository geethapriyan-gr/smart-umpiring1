import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/video_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../widgets/animated_bottom_nav.dart';
import '../widgets/match_setup_dialog.dart';
import 'live_preview_screen.dart';
import 'replay_screen.dart';

// Brand palette
const _brand = Color(0xFF381DA8);
const _brandLight = Color(0xFF6C4FDB);
const _brandGlow = Color(0xFF8B6FFF);
const _accentGreen = Color(0xFF1DE9B6);
const _accentAmber = Color(0xFFFFAB40);

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _navController;
  late Animation<double> _navAnimation;
  late AnimationController _bgController;

  bool _resumeExpanded = true;

  final List<Widget> _screens = [
    const LivePreviewScreen(),
    const ReplayScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _navController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _navAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _navController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoProvider>().initializeCamera();
      _navController.forward();
    });
  }

  Future<void> _resumeMatch(String folderName) async {
    final provider = context.read<VideoProvider>();
    final success = await provider.resumeMatch(folderName);
    if (success && mounted) {
      setState(() => _selectedIndex = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.play_circle_filled, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Resumed: ${folderName.replaceAll('_', ' ')}',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
            ),
          ]),
          backgroundColor: _accentGreen.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to resume match',
              style: GoogleFonts.montserrat()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _navController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (index != _selectedIndex) setState(() => _selectedIndex = index);
  }

  void _showEditMatchDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const MatchSetupDialog());
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
            color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.8),
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

  // ── Animated deep-space background ─────────────────────────────
  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (_, __) {
        final t = _bgController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 0.4, -1),
              end: Alignment(1 - t * 0.3, 1),
              colors: const [
                Color(0xFF060818),
                Color(0xFF0D1230),
                Color(0xFF1A0D3D),
                Color(0xFF0A1628),
              ],
              stops: const [0.0, 0.35, 0.70, 1.0],
            ),
          ),
        );
      },
    );
  }

  // ── Floating orbs ───────────────────────────────────────────────
  Widget _buildOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: _Orb(size: 260, color: _brand.withOpacity(0.30), duration: 7),
        ),
        Positioned(
          bottom: 100,
          left: -80,
          child: _Orb(size: 220, color: _brandLight.withOpacity(0.20), duration: 9),
        ),
        Positioned(
          top: 200,
          left: 40,
          child: _Orb(size: 100, color: _accentGreen.withOpacity(0.12), duration: 6),
        ),
      ],
    );
  }

  // ── Home: no match setup yet ────────────────────────────────────
  Widget _buildMatchDetailsSection() {
    return Consumer<VideoProvider>(builder: (context, provider, _) {
      return Stack(
        children: [
          _buildBackground(),
          _buildOrbs(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _s(context, 24, minScale: 0.9, maxScale: 1.22),
                  vertical: _s(context, 20, minScale: 0.9, maxScale: 1.18),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: context.adaptiveContentWidth(maxWidth: 760),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: _s(context, 10)),

                        // ── Logo cluster ──────────────────────────
                        _buildHeroLogo(),

                        SizedBox(height: _s(context, 15)),

                        // ── Title ────────────────────────────────
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [_brandGlow, Colors.white, _accentGreen],
                            stops: [0.0, 0.5, 1.0],
                          ).createShader(bounds),
                          child: Text(
                            'SMART UMPIRE',
                            style: GoogleFonts.montserrat(
                              fontSize: _s(context, 30, minScale: 0.88, maxScale: 1.22),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: _s(context, 3, minScale: 0.88, maxScale: 1.1),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),

                        SizedBox(height: _s(context, 6)),

                        Text(
                          'PRECISION IN EVERY DECISION',
                          style: GoogleFonts.montserrat(
                            fontSize: _s(context, 11, minScale: 0.9, maxScale: 1.15),
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.45),
                            letterSpacing: _s(context, 3, minScale: 0.88, maxScale: 1.08),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 300.ms),

                        SizedBox(height: _s(context, 25)),

                        // ── Action buttons ────────────────────────
                        _buildGlassButton(
                          label: 'Setup New Match',
                          icon: Icons.add_circle_outline_rounded,
                          gradient: const LinearGradient(
                            colors: [_brand, _brandLight],
                          ),
                          onTap: () => _showEditMatchDialog(context),
                        ),

                        SizedBox(height: _s(context, 14)),

                        _buildGlassButton(
                          label: 'Review Clips',
                          icon: Icons.movie_filter_rounded,
                          gradient: LinearGradient(
                            colors: [
                              _accentGreen.withOpacity(0.85),
                              const Color(0xFF00B686),
                            ],
                          ),
                          onTap: () async {
                            await context.read<VideoProvider>().loadMatchFolders();
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ReplayScreen()),
                            );
                          },
                        ),

                        SizedBox(height: _s(context, 10)),

                        // ── Resume match section ──────────────────
                        FutureBuilder<List<String>>(
                          future: provider.getResumableMatches(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              final spinnerSize =
                                  _s(context, 24, minScale: 0.9, maxScale: 1.15);
                              return SizedBox(
                                height: _s(context, 40),
                                child: Center(
                                  child: SizedBox(
                                    width: spinnerSize,
                                    height: spinnerSize,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _brandGlow,
                                    ),
                                  ),
                                ),
                              );
                            }
                            final resumable = snapshot.data ?? [];
                            if (resumable.isNotEmpty) {
                              return _buildResumePanel(resumable);
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        SizedBox(height: _s(context, 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  // ── Hero logo with layered glow ─────────────────────────────────
  Widget _buildHeroLogo() {
    final outerSize = _s(context, 160, minScale: 0.88, maxScale: 1.2);
    final innerSize = _s(context, 110, minScale: 0.88, maxScale: 1.18);
    final padding = _s(context, 18, minScale: 0.9, maxScale: 1.15);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulse ring
        Container(
          width: outerSize,
          height: outerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _brandGlow.withOpacity(0.22),
                _brand.withOpacity(0.08),
                Colors.transparent,
              ],
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 0.9, end: 1.12, duration: 2200.ms,
                curve: Curves.easeInOut),

        // Glass disc
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: innerSize,
              height: innerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.18),
                    Colors.white.withOpacity(0.04),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                  width: _s(context, 1.5, minScale: 0.9, maxScale: 1.08),
                ),
              ),
              padding: EdgeInsets.all(padding),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
          ),
        )
            .animate()
            .scale(delay: 200.ms, duration: 800.ms, curve: Curves.elasticOut)
            .then()
            .shimmer(delay: 1000.ms, duration: 1200.ms),
      ],
    );
  }

  // ── Liquid glass action button ──────────────────────────────────
  Widget _buildGlassButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    final buttonHeight = _s(context, 58, minScale: 0.94, maxScale: 1.1);
    final radius = _s(context, 18, minScale: 0.92, maxScale: 1.12);
    final iconSize = _s(context, 22, minScale: 0.92, maxScale: 1.12);
    final labelSpacing = _s(context, 10, minScale: 0.92, maxScale: 1.1);

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                    width: _s(context, 1, minScale: 0.9, maxScale: 1.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.30),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: iconSize),
                    SizedBox(width: labelSpacing),
                    Text(
                      label,
                      style: GoogleFonts.montserrat(
                        fontSize: _s(context, 16, minScale: 0.94, maxScale: 1.12),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: _s(context, 0.5, minScale: 1, maxScale: 1.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  // ── Resume match glass panel ────────────────────────────────────
  Widget _buildResumePanel(List<String> matches) {
    final panelRadius = _s(context, 20, minScale: 0.92, maxScale: 1.12);
    final tilePadding = _s(context, 16, minScale: 0.92, maxScale: 1.12);

    return ClipRRect(
      borderRadius: BorderRadius.circular(panelRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _accentGreen.withOpacity(0.10),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(panelRadius),
            border: Border.all(
              color: _accentGreen.withOpacity(0.30),
              width: _s(context, 1.2, minScale: 0.9, maxScale: 1.08),
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: _resumeExpanded,
              onExpansionChanged: (v) => setState(() => _resumeExpanded = v),
              tilePadding: EdgeInsets.symmetric(
                horizontal: tilePadding,
                vertical: _s(context, 4),
              ),
              childrenPadding: EdgeInsets.zero,
              leading: Container(
                padding: EdgeInsets.all(_s(context, 7)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    _accentGreen.withOpacity(0.30),
                    _accentGreen.withOpacity(0.10),
                  ]),
                  borderRadius: BorderRadius.circular(_s(context, 10)),
                ),
                child: Icon(
                  Icons.play_circle_filled_rounded,
                  color: _accentGreen,
                  size: _s(context, 20),
                ),
              ),
              title: Row(children: [
                Text(
                  'Resume Match',
                  style: GoogleFonts.montserrat(
                    fontSize: _s(context, 14, minScale: 0.94, maxScale: 1.1),
                    fontWeight: FontWeight.w700,
                    color: _accentGreen,
                  ),
                ),
                SizedBox(width: _s(context, 8)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _s(context, 8),
                    vertical: _s(context, 2),
                  ),
                  decoration: BoxDecoration(
                    color: _accentGreen,
                    borderRadius: BorderRadius.circular(panelRadius),
                  ),
                  child: Text(
                    '${matches.length}',
                    style: GoogleFonts.montserrat(
                      fontSize: _s(context, 11, minScale: 0.94, maxScale: 1.08),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF060818),
                    ),
                  ),
                ),
              ]),
              trailing: Icon(
                _resumeExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: _accentGreen,
              ),
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: matches.length > 3
                        ? _s(context, 240, minScale: 0.95, maxScale: 1.15)
                        : matches.length *
                            _s(context, 80, minScale: 0.95, maxScale: 1.12),
                  ),
                  child: RawScrollbar(
                    thumbColor: _accentGreen.withOpacity(0.3),
                    radius: const Radius.circular(20),
                    thickness: _s(context, 3, minScale: 0.9, maxScale: 1.08),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        tilePadding,
                        0,
                        tilePadding,
                        tilePadding,
                      ),
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: matches.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: _s(context, 8)),
                      itemBuilder: (context, index) =>
                          _buildResumeItem(matches[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms);
  }

  Widget _buildResumeItem(String folder) {
    final radius = _s(context, 14, minScale: 0.92, maxScale: 1.1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _accentGreen.withOpacity(0.18)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _resumeMatch(folder),
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _s(context, 14),
              vertical: _s(context, 10),
            ),
            child: Row(children: [
              SizedBox(
                width: _s(context, 20),
                height: _s(context, 20),
                child:
                    Image.asset('assets/images/logo.png', fit: BoxFit.contain),
              ),
              SizedBox(width: _s(context, 10)),
              Expanded(
                child: Text(
                  folder.replaceAll('_', ' '),
                  style: GoogleFonts.montserrat(
                    fontSize: _s(context, 13, minScale: 0.94, maxScale: 1.08),
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.90),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _s(context, 12),
                  vertical: _s(context, 5),
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accentGreen, Color(0xFF00B686)],
                  ),
                  borderRadius: BorderRadius.circular(_s(context, 10)),
                ),
                child: Text(
                  'Resume',
                  style: GoogleFonts.montserrat(
                    fontSize: _s(context, 11, minScale: 0.94, maxScale: 1.08),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF060818),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final provider = context.watch<VideoProvider>();
    final showLiveBackButton =
        provider.matchDetails != null && _selectedIndex == 0;

    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: showLiveBackButton ? 44 : 0,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0D1230).withOpacity(0.85),
                  Colors.transparent,
                ],
              ),
              border: const Border(
                bottom: BorderSide(color: Colors.white10, width: 0.5),
              ),
            ),
          ),
        ),
      ),
      leading: showLiveBackButton
          ? Padding(
              padding: const EdgeInsets.only(left: 10),
              child: IconButton(
                onPressed: provider.isRecording
                    ? null
                    : () => _showPauseConfirmation(context, provider),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                splashRadius: 22,
              ),
            )
          : null,
      titleSpacing: showLiveBackButton ? 0 : NavigationToolbar.kMiddleSpacing,
      title: Row(children: [
        SizedBox(
          width: _s(context, 34),
          height: _s(context, 34),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        )
            .animate()
            .scale(delay: 200.ms, duration: 500.ms)
            .then()
            .shimmer(delay: 700.ms, duration: 800.ms),
        SizedBox(width: _s(context, 12)),
        Expanded(
          child: Text(
            (provider.matchDetails?.matchName.trim().isNotEmpty ?? false)
                ? provider.matchDetails!.matchName
                : 'SMART UMPIRE',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: _s(context, 17, minScale: 0.94, maxScale: 1.12),
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: _s(context, 0.5, minScale: 1, maxScale: 1.08),
            ),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 500.ms)
              .slideX(begin: -0.2, end: 0.0, delay: 300.ms, duration: 500.ms),
        ),
      ]),
      actions: [
        if (provider.matchDetails != null && _selectedIndex == 0)
          _GlassIconButton(
            icon: Icons.edit_rounded,
            onTap: () => _showEditMatchDialog(context),
          ).animate().scale(delay: 600.ms, duration: 400.ms),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── In-match stats area ─────────────────────────────────────────
  // ignore: unused_element
  Widget _buildMatchStatsSection() {
    return Consumer<VideoProvider>(builder: (context, provider, _) {
      final bufferStatus = provider.bufferStatus;
      final isRecording = provider.isRecording;
      final bufferedClipsCount = provider.bufferedClips.length;

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: _s(context, 16),
          vertical: _s(context, 10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: EdgeInsets.only(
              left: _s(context, 4),
              bottom: _s(context, 10),
            ),
            child: Text(
              'MATCH OVERVIEW',
              style: GoogleFonts.montserrat(
                fontSize: _s(context, 11, minScale: 0.94, maxScale: 1.08),
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.45),
                letterSpacing: _s(context, 2, minScale: 0.9, maxScale: 1.06),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _buildGlassStatCard(
                icon: isRecording ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                title: isRecording ? 'Recording' : 'Standby',
                value: isRecording ? 'LIVE' : 'READY',
                color: isRecording ? const Color(0xFFFF4560) : _brandGlow,
                subtitle: isRecording ? 'Capturing' : 'Tap record',
              ),
              const SizedBox(width: 12),
              if (bufferStatus != null) ...[
                _buildGlassStatCard(
                  icon: Icons.memory_rounded,
                  title: 'Buffer',
                  value: '${bufferStatus.percentageUsed}%',
                  color: bufferStatus.percentageUsed > 80
                      ? const Color(0xFFFF4560)
                      : bufferStatus.percentageUsed > 50
                          ? _accentAmber
                          : _accentGreen,
                  subtitle: '${bufferStatus.currentBall} balls',
                ),
                const SizedBox(width: 12),
              ],
              _buildGlassStatCard(
                icon: Icons.video_library_rounded,
                title: 'Clips',
                value: '$bufferedClipsCount',
                color: _brandGlow,
                subtitle: 'For review',
              ),
              if (provider.matchDetails != null) ...[
                const SizedBox(width: 12),
                _buildGlassStatCard(
                  icon: Icons.timeline_rounded,
                  title: 'Over',
                  value: '${provider.currentOver}/${provider.matchDetails!.numberOfOvers}',
                  color: provider.isMatchOver ? _accentAmber : _accentGreen,
                  subtitle: provider.isMatchOver
                      ? 'Match Over'
                      : 'Inn ${provider.currentInnings}',
                ),
              ],
            ]),
          ),
        ]),
      )
          .animate()
          .fadeIn(duration: 500.ms, delay: 200.ms)
          .slideY(begin: 0.1, end: 0, duration: 500.ms, delay: 200.ms);
    });
  }

  Widget _buildGlassStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String subtitle,
  }) {
    final cardWidth = _s(context, 130, minScale: 0.94, maxScale: 1.16);

    return ClipRRect(
      borderRadius: BorderRadius.circular(_s(context, 16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: cardWidth,
          padding: EdgeInsets.all(_s(context, 14)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.14),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(_s(context, 16)),
            border: Border.all(color: color.withOpacity(0.25), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Container(
                  padding: EdgeInsets.all(_s(context, 6)),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(_s(context, 8)),
                  ),
                  child: Icon(icon, color: color, size: _s(context, 16)),
                ),
                SizedBox(width: _s(context, 8)),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: _s(context, 11, minScale: 0.94, maxScale: 1.08),
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              SizedBox(height: _s(context, 10)),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: _s(context, 22, minScale: 0.94, maxScale: 1.14),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: _s(context, 2)),
              Text(
                subtitle,
                style: GoogleFonts.montserrat(
                  fontSize: _s(context, 10, minScale: 0.94, maxScale: 1.08),
                  color: Colors.white.withOpacity(0.45),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        final provider = context.read<VideoProvider>();
        if (_selectedIndex == 1) {
          // On replay tab — switch to live preview
          setState(() => _selectedIndex = 0);
        } else if (provider.matchDetails != null && !provider.isRecording) {
          // On live tab with match — show pause confirmation
          _showPauseConfirmation(context, provider);
        }
        // No match and on home — do nothing (prevent app exit)
      },
      child: Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF060818),
      appBar: _buildAppBar(),
      body: Consumer<VideoProvider>(builder: (context, provider, _) {
        if (provider.shouldAutoReball && _selectedIndex != 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedIndex = 0);
          });
        }

        if (provider.matchDetails == null) {
          return _buildMatchDetailsSection();
        }

        return Stack(children: [
          _buildBackground(),
          _buildOrbs(),
          Column(children: [
            Expanded(
              child: Stack(
                children: List.generate(_screens.length, (index) {
                  final isActive = _selectedIndex == index;
                  // Use IgnorePointer and AnimatedOpacity so inactive screens don't block taps
                  return IgnorePointer(
                    ignoring: !isActive,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      opacity: isActive ? 1.0 : 0.0,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        offset: isActive ? Offset.zero : const Offset(0.05, 0),
                        child: _screens[index],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ]),
        ]);
      }),
      bottomNavigationBar: Consumer<VideoProvider>(
        builder: (context, provider, _) {
          if (provider.matchDetails == null) return const SizedBox();
          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: AnimatedBottomNav(
                currentIndex: _selectedIndex,
                onTap: _onNavItemTapped,
                animation: _navAnimation,
                items: const [
                  BottomNavItem(
                      icon: Icons.sensors_rounded,
                      label: 'LIVE',
                      activeColor: Color(0xFF381DA8)),
                  BottomNavItem(
                      icon: Icons.movie_filter_rounded,
                      label: 'REPLAY',
                      activeColor: Color(0xFF381DA8)),
                ],
              ),
            ),
          );
        },
      ),
    ),
    ); // closes PopScope
  }
}

// ── Helper: Floating orb widget ────────────────────────────────────
class _Orb extends StatefulWidget {
  final double size;
  final Color color;
  final int duration;
  const _Orb({required this.size, required this.color, required this.duration});
  @override
  State<_Orb> createState() => _OrbState();
}

class _OrbState extends State<_Orb> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.scale(
        scale: 0.92 + _c.value * 0.16,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [widget.color, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper: glass icon button ───────────────────────────────────────
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
