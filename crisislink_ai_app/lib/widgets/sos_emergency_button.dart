import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SosEmergencyButton extends StatefulWidget {
  const SosEmergencyButton({
    super.key,
    this.size = 270,
    required this.glowStrength,
    required this.onActivated,
    this.onHoldStateChanged,
    this.onHoldProgressChanged,
    this.holdDuration = const Duration(seconds: 3),
    this.activated = false,
  });

  final double size;
  final double glowStrength;
  final Duration holdDuration;
  final FutureOr<void> Function() onActivated;
  final ValueChanged<bool>? onHoldStateChanged;
  final ValueChanged<double>? onHoldProgressChanged;
  final bool activated;

  @override
  State<SosEmergencyButton> createState() => _SosEmergencyButtonState();
}

class _SosEmergencyButtonState extends State<SosEmergencyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;
  bool _isHolding = false;
  bool _didTrigger = false;

  int get _holdSeconds => widget.holdDuration.inSeconds;

  @override
  void initState() {
    super.initState();
    _holdController =
        AnimationController(vsync: this, duration: widget.holdDuration)
          ..addListener(() {
            widget.onHoldProgressChanged?.call(_holdController.value);
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && !_didTrigger) {
              _didTrigger = true;
              _isHolding = false;
              widget.onHoldStateChanged?.call(false);
              widget.onActivated();
            }
          });
  }

  @override
  void didUpdateWidget(covariant SosEmergencyButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.holdDuration != widget.holdDuration) {
      _holdController.duration = widget.holdDuration;
    }
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  void _startHold() {
    if (_isHolding || widget.activated) {
      return;
    }

    _didTrigger = false;
    _isHolding = true;
    widget.onHoldStateChanged?.call(true);
    _holdController.forward(from: 0);
  }

  void _cancelHold() {
    if (!_isHolding) {
      return;
    }

    _isHolding = false;
    widget.onHoldStateChanged?.call(false);

    if (_holdController.status != AnimationStatus.completed) {
      _holdController.reset();
      widget.onHoldProgressChanged?.call(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _startHold(),
      onPointerUp: (_) => _cancelHold(),
      onPointerCancel: (_) => _cancelHold(),
      child: AnimatedBuilder(
        animation: _holdController,
        builder: (context, child) {
          final holdProgress = widget.activated ? 1.0 : _holdController.value;
          final innerScale = 1 + (holdProgress * 0.02);

          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.size * 0.9,
                  height: widget.size * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentRed.withValues(
                          alpha:
                              0.25 +
                              (widget.glowStrength * 0.25) +
                              (holdProgress * 0.2),
                        ),
                        blurRadius: 54,
                        spreadRadius: 8 + (holdProgress * 4),
                      ),
                    ],
                  ),
                ),
                CustomPaint(
                  size: Size.square(widget.size),
                  painter: _OuterRingPainter(
                    glowStrength: widget.glowStrength,
                    holdProgress: holdProgress,
                    activated: widget.activated,
                  ),
                ),
                Transform.scale(
                  scale: innerScale,
                  child: Container(
                    width: widget.size * 0.84,
                    height: widget.size * 0.84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: widget.activated
                            ? const [Color(0xFFFF3434), Color(0xFFE30018)]
                            : const [Color(0xFFFF080E), Color(0xFFD2000B)],
                      ),
                      border: Border.all(
                        color: const Color(
                          0xFFFF3C3C,
                        ).withValues(alpha: 0.5 + (holdProgress * 0.3)),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: widget.size * 0.22,
                          height: widget.size * 0.22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.priority_high_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          widget.activated ? 'LIVE' : 'SOS',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.activated
                              ? 'Emergency Alert Sent'
                              : _isHolding
                              ? 'Keep holding...'
                              : 'Hold for $_holdSeconds seconds',
                          key: const Key('sos-button-status'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFF0F0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OuterRingPainter extends CustomPainter {
  const _OuterRingPainter({
    required this.glowStrength,
    required this.holdProgress,
    required this.activated,
  });

  final double glowStrength;
  final double holdProgress;
  final bool activated;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - 8;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4
      ..color = const Color(0xFFFF2A2A).withValues(alpha: 0.35);

    canvas.drawCircle(center, radius - 8, basePaint);

    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5
      ..color = Colors.white.withValues(alpha: 0.92 + (0.08 * glowStrength));

    const segmentAngle = 0.52;
    const starts = [-2.75, -0.92, -0.12, 1.08, 2.24, 3.52];
    for (final start in starts) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 8),
        start,
        segmentAngle,
        false,
        segmentPaint,
      );
    }

    if (holdProgress <= 0 && !activated) {
      return;
    }

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF3F3), Color(0xFFFF3B30)],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 8));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      -1.5708,
      6.28318 * holdProgress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OuterRingPainter oldDelegate) {
    return oldDelegate.glowStrength != glowStrength ||
        oldDelegate.holdProgress != holdProgress ||
        oldDelegate.activated != activated;
  }
}
