import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  const UserProfile({required this.phoneNumber, required this.signedInAt});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      phoneNumber: (json['phone_number'] ?? '').toString(),
      signedInAt:
          DateTime.tryParse((json['signed_in_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String phoneNumber;
  final DateTime signedInAt;

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'signed_in_at': signedInAt.toUtc().toIso8601String(),
    };
  }
}

abstract class UserSessionService {
  const UserSessionService();

  Future<UserProfile?> fetchProfile();
  Future<UserProfile> signIn({required String phoneNumber});
  Future<void> clearProfile();
}

class DefaultUserSessionService extends UserSessionService {
  const DefaultUserSessionService();

  static const _profileKey = 'crisislink.user_profile.v1';

  @override
  Future<UserProfile?> fetchProfile() async {
    final preferences = await SharedPreferences.getInstance();
    final rawProfile = preferences.getString(_profileKey);

    if (rawProfile == null || rawProfile.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawProfile);
      if (decoded is! Map<String, dynamic>) {
        await preferences.remove(_profileKey);
        return null;
      }

      final profile = UserProfile.fromJson(decoded);
      if (profile.phoneNumber.isEmpty) {
        await preferences.remove(_profileKey);
        return null;
      }

      return profile;
    } catch (_) {
      await preferences.remove(_profileKey);
      return null;
    }
  }

  @override
  Future<UserProfile> signIn({required String phoneNumber}) async {
    final profile = UserProfile(
      phoneNumber: phoneNumber,
      signedInAt: DateTime.now().toUtc(),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_profileKey, jsonEncode(profile.toJson()));
    return profile;
  }

  @override
  Future<void> clearProfile() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_profileKey);
  }
}
