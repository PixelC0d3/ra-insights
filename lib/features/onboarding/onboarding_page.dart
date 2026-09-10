/// Single-screen onboarding: the key is the user's own, pasted once.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/api/ra_client.dart';
import '../../core/result.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';

const raSettingsUrl = 'https://retroachievements.org/settings';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _user = TextEditingController();
  final _key = TextEditingController();
  bool _busy = false;
  bool _prefilled = false;
  AppError? _error;

  /// Fills the username from the last sign-in, once, without stomping on
  /// anything the user has already typed.
  void _prefill(String? remembered) {
    if (_prefilled || remembered == null || _user.text.isNotEmpty) return;
    _prefilled = true;
    _user.text = remembered;
  }

  @override
  void dispose() {
    _user.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res =
        await ref.read(authRepositoryProvider).signIn(_user.text, _key.text);
    if (!mounted) return;
    switch (res) {
      case Ok():
        await ref.read(sessionProvider.notifier).signIn(
              RaCredentials(
                  username: _user.text.trim(), apiKey: _key.text.trim()),
            );
      case Err(:final error):
        setState(() {
          _busy = false;
          _error = error;
        });
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) _key.text = text;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final remember = ref.watch(rememberMeProvider).valueOrNull ?? true;
    if (remember) _prefill(ref.watch(lastUsernameProvider).valueOrNull);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset('assets/branding/logo.png',
                    width: 108, height: 108, filterQuality: FilterQuality.medium),
              ),
              const SizedBox(height: 14),
              Text(l.appTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                l.appTagline,
                textAlign: TextAlign.center,
                style: const TextStyle(color: RaColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 28),
              const _Steps(),
              const SizedBox(height: 20),
              TextField(
                controller: _user,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l.fieldUsername,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _key,
                autocorrect: false,
                enableSuggestions: false,
                obscureText: true,
                onSubmitted: (_) => _busy ? null : _submit(),
                decoration: InputDecoration(
                  labelText: l.fieldApiKey,
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  suffixIcon: IconButton(
                    tooltip: l.actionPaste,
                    icon: const Icon(Icons.content_paste),
                    onPressed: _paste,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                value: remember,
                contentPadding: EdgeInsets.zero,
                title: Text(l.rememberMe,
                    style: const TextStyle(fontSize: 13)),
                subtitle: Text(l.rememberMeNote,
                    style: const TextStyle(
                        fontSize: 11.5, color: RaColors.muted)),
                onChanged: (value) async {
                  await ref.read(prefsRepositoryProvider).setRememberMe(value);
                  ref.invalidate(rememberMeProvider);
                  ref.invalidate(lastUsernameProvider);
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1114),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7F1D1D)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 18, color: Color(0xFFF87171)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(localizedError(l, _error!),
                            style: const TextStyle(
                                fontSize: 12.5, color: Color(0xFFFCA5A5))),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l.actionSignIn),
              ),
              const SizedBox(height: 16),
              Text(
                l.onboardingPrivacy,
                textAlign: TextAlign.center,
                style: const TextStyle(color: RaColors.muted, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.onboardingWhyTitle,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            l.onboardingWhyText,
            style: const TextStyle(
                color: RaColors.muted, fontSize: 12.5, height: 1.45),
          ),
          const Divider(height: 24, color: RaColors.border),
          Text(l.onboardingWhereTitle,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          Text(
            l.onboardingSteps,
            style: const TextStyle(
                color: RaColors.muted, fontSize: 12.5, height: 1.6),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(raSettingsUrl),
                  mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(l.onboardingOpenSettings),
            ),
          ),
        ],
      ),
    );
  }
}
