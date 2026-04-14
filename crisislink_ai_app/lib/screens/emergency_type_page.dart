import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../services/sos_api_service.dart';
import '../services/user_session_service.dart';
import '../theme/app_theme.dart';

enum EmergencyType { medical, safety, fire }

enum EmergencyFlowStep { type, situation, sending }

class EmergencyTypePage extends StatefulWidget {
  const EmergencyTypePage({
    super.key,
    required this.locationService,
    required this.sosApiService,
    required this.userProfile,
  });

  static const routeName = '/emergency-type';

  final LocationService locationService;
  final SosApiService sosApiService;
  final UserProfile userProfile;

  @override
  State<EmergencyTypePage> createState() => _EmergencyTypePageState();
}

class _EmergencyTypePageState extends State<EmergencyTypePage> {
  static const Map<EmergencyType, List<String>> _situationChips = {
    EmergencyType.medical: [
      'Unconscious',
      'Injury',
      'Breathing problem',
      'Chest pain',
    ],
    EmergencyType.safety: [
      'Assault',
      'Robbery',
      'Suspicious activity',
      'Trapped',
    ],
    EmergencyType.fire: [
      'Fire spreading',
      'Smoke detected',
      'Building fire',
      'Explosion',
    ],
  };

  EmergencyFlowStep _step = EmergencyFlowStep.type;
  EmergencyType? _selectedType;
  String? _selectedSituation;
  AppLocation? _currentPosition;
  String? _locationError;
  bool _isFetchingLocation = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  void _selectType(EmergencyType type) {
    setState(() {
      _selectedType = type;
      _selectedSituation = null;
      _step = EmergencyFlowStep.situation;
    });
  }

  Future<void> _loadLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _locationError = null;
    });

    try {
      final position = await widget.locationService.getCurrentLocation();

      if (!mounted) {
        return;
      }

      setState(() {
        _isFetchingLocation = false;
        _currentPosition = position;
        _locationError = null;
      });
    } on LocationServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isFetchingLocation = false;
        _currentPosition = null;
        _locationError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isFetchingLocation = false;
        _currentPosition = null;
        _locationError =
            'Unable to read your current location right now. Try again in a moment.';
      });
    }
  }

  Future<void> _sendReport({String? situation}) async {
    final type = _selectedType;
    if (type == null || _isSubmitting) {
      return;
    }

    final position = _currentPosition;
    if (position == null) {
      setState(() {
        _locationError =
            _locationError ??
            'Live location is required before the SOS can be sent.';
      });
      _showSnackBar(_locationError!);
      return;
    }

    setState(() {
      _selectedSituation = situation;
      _isSubmitting = true;
      _step = EmergencyFlowStep.sending;
    });

    try {
      final response = await widget.sosApiService.createSosReport(
        SosCreateRequest(
          latitude: position.latitude,
          longitude: position.longitude,
          phoneNumber: widget.userProfile.phoneNumber,
          type: _apiTypeFor(type),
        ),
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Alert sent. Incident ${response.incidentId} is ${response.priority} priority with ${response.uniqueReporters} reporter(s).',
      );
      Navigator.of(context).maybePop();
    } on SosApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _step = EmergencyFlowStep.situation;
      });
      _showSnackBar(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _step = EmergencyFlowStep.situation;
      });
      _showSnackBar(
        'The alert could not be submitted. Check your connection and try again.',
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleExit() {
    if (_isSubmitting) {
      return;
    }

    if (_step == EmergencyFlowStep.situation) {
      setState(() {
        _step = EmergencyFlowStep.type;
        _selectedType = null;
        _selectedSituation = null;
      });
      return;
    }

    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final gpsReady = _currentPosition != null;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.05),
            radius: 1.05,
            colors: [Color(0xFF210C0D), Color(0xFF0C090A), AppTheme.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: _handleExit,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFC9C5CF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'Exit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _StatusTag(
                      icon: gpsReady
                          ? Icons.location_on_outlined
                          : Icons.location_searching_rounded,
                      label: gpsReady
                          ? 'GPS Ready'
                          : _isFetchingLocation
                          ? 'Locating'
                          : 'GPS Needed',
                      color: gpsReady
                          ? AppTheme.success
                          : const Color(0xFFFFB454),
                    ),
                    const SizedBox(width: 10),
                    const _StatusTag(
                      icon: Icons.wifi_rounded,
                      label: 'Online',
                      color: AppTheme.success,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: switch (_step) {
                    EmergencyFlowStep.type => _TypeStep(
                      onTypeSelected: _selectType,
                    ),
                    EmergencyFlowStep.situation => _SituationStep(
                      emergencyType: _selectedType!,
                      situations: _situationChips[_selectedType!]!,
                      phoneNumber: widget.userProfile.phoneNumber,
                      isFetchingLocation: _isFetchingLocation,
                      locationLabel: _locationLabel,
                      locationError: _locationError,
                      isSubmitting: _isSubmitting,
                      onRefreshLocation: _loadLocation,
                      onSendWithoutDescription: () => _sendReport(),
                      onSituationSelected: (situation) =>
                          _sendReport(situation: situation),
                    ),
                    EmergencyFlowStep.sending => _SendingStep(
                      emergencyType: _selectedType!,
                      situation: _selectedSituation,
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _locationLabel {
    final position = _currentPosition;
    if (position == null) {
      return _isFetchingLocation
          ? 'Reading your current GPS coordinates.'
          : 'Location not available yet.';
    }

    return 'Lat ${position.latitude.toStringAsFixed(5)} | Lng ${position.longitude.toStringAsFixed(5)}';
  }
}

class _TypeStep extends StatelessWidget {
  const _TypeStep({required this.onTypeSelected});

  final ValueChanged<EmergencyType> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('type-step'),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      child: Column(
        children: [
          const SizedBox(height: 120),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'Select Emergency Type',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Choose the type of emergency',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _EmergencyTypeCard(
            title: 'Medical Emergency',
            color: const Color(0xFF2961F2),
            icon: Icons.medical_services_outlined,
            onTap: () => onTypeSelected(EmergencyType.medical),
          ),
          const SizedBox(height: 12),
          _EmergencyTypeCard(
            title: 'Safety/Security',
            color: const Color(0xFFF08400),
            icon: Icons.shield_outlined,
            onTap: () => onTypeSelected(EmergencyType.safety),
          ),
          const SizedBox(height: 12),
          _EmergencyTypeCard(
            title: 'Fire Emergency',
            color: const Color(0xFFFF0012),
            icon: Icons.local_fire_department_outlined,
            onTap: () => onTypeSelected(EmergencyType.fire),
          ),
        ],
      ),
    );
  }
}

class _SituationStep extends StatelessWidget {
  const _SituationStep({
    required this.emergencyType,
    required this.situations,
    required this.phoneNumber,
    required this.isFetchingLocation,
    required this.locationLabel,
    required this.locationError,
    required this.isSubmitting,
    required this.onRefreshLocation,
    required this.onSituationSelected,
    required this.onSendWithoutDescription,
  });

  final EmergencyType emergencyType;
  final List<String> situations;
  final String phoneNumber;
  final bool isFetchingLocation;
  final String locationLabel;
  final String? locationError;
  final bool isSubmitting;
  final Future<void> Function() onRefreshLocation;
  final ValueChanged<String> onSituationSelected;
  final VoidCallback onSendWithoutDescription;

  @override
  Widget build(BuildContext context) {
    final locationReady = locationError == null && !isFetchingLocation;
    final locationColor = locationReady
        ? AppTheme.success
        : const Color(0xFFFFB454);

    return SingleChildScrollView(
      key: const ValueKey('situation-step'),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      child: Column(
        children: [
          const Text(
            'Describe Situation',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your signed-in phone number and live location will be attached before sending.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            _labelForType(emergencyType),
            style: const TextStyle(
              color: Color(0xFFD4CFD8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF17181E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Signed-in Phone Number',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111216),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_android_rounded,
                        color: AppTheme.accentRed,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          phoneNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
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
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF17181E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: locationColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: locationColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    locationReady
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                    color: locationColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationReady
                            ? 'Live Location Ready'
                            : 'Live Location Needed',
                        style: TextStyle(
                          color: locationColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        locationError ?? locationLabel,
                        style: const TextStyle(
                          color: Color(0xFFD1CCD5),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: isSubmitting || isFetchingLocation
                      ? null
                      : () {
                          onRefreshLocation();
                        },
                  icon: isFetchingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  color: Colors.white,
                  tooltip: 'Refresh location',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            itemCount: situations.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.65,
            ),
            itemBuilder: (context, index) {
              final situation = situations[index];
              return _SituationChip(
                label: situation,
                onTap: isSubmitting
                    ? null
                    : () => onSituationSelected(situation),
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSubmitting ? null : onSendWithoutDescription,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.accentRed.withValues(
                  alpha: 0.4,
                ),
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Send Live Alert',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SendingStep extends StatelessWidget {
  const _SendingStep({required this.emergencyType, required this.situation});

  final EmergencyType emergencyType;
  final String? situation;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('sending-step'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 86,
              height: 86,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: AppTheme.accentRed,
                backgroundColor: Color(0xFF2A2A2F),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Sending Emergency Alert...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              situation == null
                  ? '${_labelForType(emergencyType)} report is being sent to responders.'
                  : '$situation reported under ${_labelForType(emergencyType).toLowerCase()}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 16,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PulsingDot(),
                SizedBox(width: 10),
                Text(
                  'Transmitting live backend request',
                  style: TextStyle(
                    color: AppTheme.success,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EmergencyTypeCard extends StatelessWidget {
  const _EmergencyTypeCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.24),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.16),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SituationChip extends StatelessWidget {
  const _SituationChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF18191F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF33333B)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: onTap == null
                ? const Color(0xFF8B8790)
                : const Color(0xFFF3EFF4),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1).animate(_controller),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.success,
          shape: BoxShape.circle,
        ),
        child: SizedBox(width: 10, height: 10),
      ),
    );
  }
}

String _labelForType(EmergencyType type) {
  switch (type) {
    case EmergencyType.medical:
      return 'Medical Emergency';
    case EmergencyType.safety:
      return 'Safety/Security';
    case EmergencyType.fire:
      return 'Fire Emergency';
  }
}

String _apiTypeFor(EmergencyType type) {
  switch (type) {
    case EmergencyType.medical:
      return 'medical';
    case EmergencyType.safety:
      return 'police';
    case EmergencyType.fire:
      return 'fire';
  }
}
