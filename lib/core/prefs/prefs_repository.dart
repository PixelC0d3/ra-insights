/// Small, non-secret preferences. They live next to the credentials in secure
/// storage only because it is already wired — nothing here is sensitive.
library;

import 'dart:ui';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kLocale = 'app_locale';
const _kLastUser = 'last_username';
const _kRemember = 'remember_me';

class PrefsRepository {
  PrefsRepository(this.storage);

  final FlutterSecureStorage storage;

  /// `null` means "follow the system language".
  Future<Locale?> loadLocale() async {
    final code = await storage.read(key: _kLocale);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  Future<void> saveLocale(Locale? locale) async {
    if (locale == null) {
      await storage.delete(key: _kLocale);
    } else {
      await storage.write(key: _kLocale, value: locale.languageCode);
    }
  }

  /// The username to prefill on the sign-in screen. Kept across sign-out on
  /// purpose — it is not a secret, and retyping it is the annoying part.
  Future<String?> loadLastUsername() async {
    if (!await rememberMe()) return null;
    final user = await storage.read(key: _kLastUser);
    return (user == null || user.isEmpty) ? null : user;
  }

  Future<void> saveLastUsername(String username) =>
      storage.write(key: _kLastUser, value: username.trim());

  /// Defaults to on: the switch exists to turn remembering off, not on.
  Future<bool> rememberMe() async =>
      (await storage.read(key: _kRemember)) != 'false';

  Future<void> setRememberMe(bool value) async {
    await storage.write(key: _kRemember, value: value ? 'true' : 'false');
    if (!value) await storage.delete(key: _kLastUser);
  }
}
