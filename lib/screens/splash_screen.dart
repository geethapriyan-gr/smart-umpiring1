import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;
  bool _hasNavigated = false;
  late AnimationController _fadeOutController;
  late Animation<double> _fadeOutAnimation;

  @override
  void initState() {
    super.initState();

    // Hide system UI for immersive splash experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _fadeOutController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeOutController,
        curve: Curves.easeOut,
      ),
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset('assets/SPLASH_SCREEN.mp4');

    try {
      await _videoController.initialize();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      // Listen for video completion
      _videoController.addListener(_onVideoUpdate);

      // Start playing
      _videoController.play();
    } catch (e) {
      // If video fails to load, navigate directly to home
      debugPrint('Splash video failed to load: $e');
      _navigateToHome();
    }
  }

  void _onVideoUpdate() {
    if (!mounted || _hasNavigated) return;

    final position = _videoController.value.position;
    final duration = _videoController.value.duration;

    // Navigate when video finishes (or is within 200ms of finishing)
    if (duration.inMilliseconds > 0 &&
        position.inMilliseconds >= duration.inMilliseconds - 200) {
      _navigateToHome();
    }
  }

  void _navigateToHome() async {
    if (_hasNavigated) return;
    _hasNavigated = true;

    // Fade out the splash video
    await _fadeOutController.forward();

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.removeListener(_onVideoUpdate);
    _videoController.dispose();
    _fadeOutController.dispose();
    // Ensure system UI is restored
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Allow tapping to skip the splash
        onTap: _navigateToHome,
        child: AnimatedBuilder(
          animation: _fadeOutAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeOutAnimation.value,
              child: child,
            );
          },
          child: _isInitialized
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
        ),
      ),
    );
  }
}
