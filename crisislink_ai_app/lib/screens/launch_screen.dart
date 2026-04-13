import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';
import 'sos_home_page.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({
    super.key,
    required this.connectivityService,
  });

  static const Duration displayDuration = Duration(seconds: 5);

  final ConnectivityService connectivityService;

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: LaunchScreen.displayDuration,
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    Future<void>.delayed(LaunchScreen.displayDuration, _goToSosScreen);

  }

  void _goToSosScreen() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) =>
            SosHomePage(connectivityService: widget.connectivityService),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_progressController, _pulseController]),
        builder: (context, child) {
          final progress =
              Curves.easeOutCubic.transform(_progressController.value);
          final pulse = 0.55 + (_pulseController.value * 0.45);

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.1),
                radius: 0.95,
                colors: [
                  Color(0xFF120606),
                  Color(0xFF070707),
                  AppTheme.background,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 18,
                    ),
                    child: Column(
                      children: [
                        const Spacer(flex: 7),
                        _LogoMark(pulse: pulse),
                        const SizedBox(height: 36),
                        const _BrandTitle(),
                        const SizedBox(height: 18),
                        const Text(
                          'EMERGENCY NEURAL NETWORK V4.0',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF76717C),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 5.8,
                          ),
                        ),
                        const Spacer(flex: 8),
                        _ProgressSection(progress: progress, pulse: pulse),
                        const SizedBox(height: 18),
                        const Text(
                          'LAT:34.0522 N | LON:118.2437 W | PING:12MS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF46414A),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const Spacer(flex: 5),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 172,
      height: 172,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF1010), Color(0xFFF40000)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF1D1D).withValues(alpha: 0.22 * pulse),
            blurRadius: 60,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: const Color(0xFF0A0000).withValues(alpha: 0.8),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.shield_rounded,
          color: Colors.white,
          size: 76,
        ),
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
          children: [
            TextSpan(
              text: 'CRISIS',
              style: TextStyle(color: Color(0xFFF3F1F3)),
            ),
            TextSpan(
              text: 'LINK',
              style: TextStyle(color: Color(0xFFFF1B1B)),
            ),
            TextSpan(
              text: '-AI',
              style: TextStyle(color: Color(0xFFF3F1F3)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.progress, required this.pulse});

  final double progress;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 4,
            child: Stack(
              children: [
                Container(color: const Color(0xFF212121)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF3B30),
                            const Color(0xFFFF1C14).withValues(alpha: pulse),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2B23)
                                .withValues(alpha: 0.45 * pulse),
                            blurRadius: 16,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '*',
              style: TextStyle(
                color: const Color(0xFFFF2B23),
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1,
                shadows: [
                  Shadow(
                    color: const Color(0xFFFF2B23).withValues(alpha: 0.6),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            const Flexible(
              child: Text(
                'INITIALIZING SECURE CONNECTION...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8A858C),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
