/// Stores the user's own API key in the platform keystore — never in
/// SharedPreferences, and never bundled in the binary.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/ra_api.dart';
import '../api/ra_client.dart';
import '../result.dart';
import '../../domain/models/models.dart';

const _kUser = 'ra_username';
const _kKey = 'ra_api_key';

class AuthRepository {
  AuthRepository({required this.storage, required this.api});

  final FlutterSecureStorage storage;
  final RaApi api;

  Future<RaCredentials?> load() async {
    final user = await storage.read(key: _kUser);
    final key = await storage.read(key: _kKey);
    if (user == null || key == null || user.isEmpty || key.isEmpty) return null;
    final creds = RaCredentials(username: user, apiKey: key);
    api.client.credentials = creds;
    return creds;
  }

  /// Validates against `API_GetUserProfile` before persisting, so a wrong key
  /// never reaches the dashboard.
  Future<Result<UserProfile>> signIn(String username, String apiKey) async {
    final creds = RaCredentials(username: username.trim(), apiKey: apiKey.trim());
    if (!creds.isValid) {
      return const Err(
          AppError(AppErrorKind.unauthorized, 'usuário e chave são obrigatórios'));
    }
    final res = await api.getUserProfile(credentials: creds);
    switch (res) {
      case Err(:final error):
        return Err(error);
      case Ok(:final value):
        // The API echoes an empty profile for a user that does not exist.
        if (value.user.trim().isEmpty) {
          return const Err(AppError(AppErrorKind.notFound, 'usuário inexistente'));
        }
        await storage.write(key: _kUser, value: creds.username);
        await storage.write(key: _kKey, value: creds.apiKey);
        api.client.credentials = creds;
        return Ok(value);
    }
  }

  Future<void> signOut() async {
    await storage.delete(key: _kUser);
    await storage.delete(key: _kKey);
    api.client.credentials = null;
  }
}
