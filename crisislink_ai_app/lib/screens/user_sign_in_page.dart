import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../services/location_service.dart';
import '../services/sos_api_service.dart';
import '../services/user_session_service.dart';
import '../theme/app_theme.dart';
import '../utils/phone_number.dart';
import 'sos_home_page.dart';

class UserSignInPage extends StatefulWidget {
  const UserSignInPage({
    super.key,
    required this.connectivityService,
    required this.locationService,
    required this.sosApiService,
    required this.userSessionService,
  });

  final ConnectivityService connectivityService;
  final LocationService locationService;
  final SosApiService sosApiService;
  final UserSessionService userSessionService;

  @override
  State<UserSignInPage> createState() => _UserSignInPageState();
}

class _UserSignInPageState extends State<UserSignInPage> {
  final TextEditingController _phoneController = TextEditingController();

  bool _isSaving = false;
  String? _phoneError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continueWithPhone() async {
    if (_isSaving) {
      return;
    }

    final phoneError = validatePhoneNumber(_phoneController.text);
    if (phoneError != null) {
      setState(() {
        _phoneError = phoneError;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _phoneError = null;
    });

    try {
      final profile = await widget.userSessionService.signIn(
        phoneNumber: normalizePhoneNumber(_phoneController.text),
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SosHomePage(
            connectivityService: widget.connectivityService,
            locationService: widget.locationService,
            sosApiService: widget.sosApiService,
            userProfile: profile,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'We could not save your profile right now. Please try again.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.08),
            radius: 1.02,
            colors: [Color(0xFF220A0C), Color(0xFF0F090A), AppTheme.background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 28),
                    const Text(
                      'One-time Sign In',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Enter your phone number before using SOS. After this, the app will reuse your saved profile automatically on supported device restores.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17181E),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Phone Number',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _phoneController,
                            enabled: !_isSaving,
                            keyboardType: TextInputType.phone,
                            onChanged: (_) {
                              if (_phoneError == null) {
                                return;
                              }

                              setState(() {
                                _phoneError = null;
                              });
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter your phone number',
                              hintStyle: const TextStyle(
                                color: Color(0xFF7D7984),
                              ),
                              errorText: _phoneError,
                              filled: true,
                              fillColor: const Color(0xFF111216),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppTheme.accentRed,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF20150E),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.warning.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'This number will be attached to every live SOS alert, so you do not have to enter it after pressing the SOS button.',
                              style: TextStyle(
                                color: Color(0xFFF0D5AA),
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSaving ? null : _continueWithPhone,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentRed,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.accentRed.withValues(
                          alpha: 0.4,
                        ),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Continue to SOS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
