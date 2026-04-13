import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/online_chip.dart';
import '../widgets/sos_emergency_button.dart';
import '../widgets/staff_access_sheet.dart';

class SosHomePage extends StatefulWidget {
  const SosHomePage({super.key});

  static const routeName = '/sos';

  @override
  State<SosHomePage> createState() => _SosHomePageState();
}

class _SosHomePageState extends State<SosHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _staffExpanded = false;
  bool _sosActivated = false;
  bool _isHoldingSos = false;
  StaffRole _selectedRole = StaffRole.responder;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final glowStrength = 0.4 + (_pulseController.value * 0.6);

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.05),
                radius: 0.95,
                colors: [
                  Color(0xFF2B090B),
                  Color(0xFF12080A),
                  AppTheme.background,
                ],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final expandedHeight = constraints.maxHeight * 0.56;
                  final collapsedHeight = 64.0;

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0, 0.08),
                                radius: 0.55,
                                colors: [
                                  AppTheme.accentRed
                                      .withValues(alpha: 0.2 * glowStrength),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          20,
                          6,
                          20,
                          (_staffExpanded ? expandedHeight : collapsedHeight) +
                              24,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight -
                                ((_staffExpanded
                                        ? expandedHeight
                                        : collapsedHeight) +
                                    24),
                          ),
                          child: Column(
                            children: [
                              const Align(
                                alignment: Alignment.topRight,
                                child: OnlineChip(),
                              ),
                              const SizedBox(height: 96),
                              const Text(
                                'CrisisLink-AI',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'EMERGENCY RESPONSE SYSTEM',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 15,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 36),
                              SosEmergencyButton(
                                glowStrength: glowStrength,
                                activated: _sosActivated,
                                onHoldStateChanged: (isHolding) {
                                  if (!mounted) {
                                    return;
                                  }

                                  setState(() {
                                    _isHoldingSos = isHolding;
                                  });
                                },
                                onActivated: () {
                                  if (!mounted) {
                                    return;
                                  }

                                  setState(() {
                                    _sosActivated = true;
                                    _isHoldingSos = false;
                                  });

                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Emergency alert activated. Dispatch has been notified.',
                                        ),
                                      ),
                                    );
                                },
                              ),
                              const SizedBox(height: 22),
                              Text(
                                _sosActivated
                                    ? 'Emergency alert is active. Stay on this screen for updates.'
                                    : _isHoldingSos
                                        ? 'Keep pressing until the ring completes to send the alert.'
                                        : 'Hold for 3 seconds to activate emergency alert',
                                key: const Key('sos-hint-text'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF23150C),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.warning.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: AppTheme.warning,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Emergency services only. Misuse is punishable.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFFF3D1A0),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: StaffAccessSheet(
                          expanded: _staffExpanded,
                          selectedRole: _selectedRole,
                          onToggle: () {
                            setState(() {
                              _staffExpanded = !_staffExpanded;
                            });
                          },
                          onRoleChanged: (role) {
                            setState(() {
                              _selectedRole = role;
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
