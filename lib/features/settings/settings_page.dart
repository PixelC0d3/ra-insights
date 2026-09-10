library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';

const _appVersion = '0.1.0';

/// Endonyms, so the option is readable even when the app is in another
/// language. A new locale needs one line here plus its `.arb`.
const _languageNames = {'pt': 'Português', 'en': 'English'};

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider).valueOrNull;
    final locale = ref.watch(localeProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(session?.username ?? '—'),
                  subtitle: Text(l.settingsAccountConnected),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.vpn_key_outlined),
                  title: Text(l.settingsApiKey),
                  subtitle: Text(l.settingsApiKeySubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editApiKey(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.translate),
              title: Text(l.settingsLanguage),
              subtitle: Text(locale == null
                  ? l.settingsLanguageSystem
                  : _languageNames[locale.languageCode] ?? locale.languageCode),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickLanguage(context, ref, locale),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l.settingsClearCache),
                  subtitle: Text(l.settingsClearCacheSubtitle),
                  onTap: () async {
                    await ref.read(databaseProvider).clearCache();
                    await refreshAll(ref);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.settingsCacheCleared)),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(l.settingsSignOut),
                  subtitle: Text(l.settingsSignOutSubtitle),
                  onTap: () => ref.read(sessionProvider.notifier).signOut(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l.settingsAbout),
                  subtitle: Text(l.settingsAboutText),
                  isThreeLine: true,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: const Text('retroachievements.org'),
                  onTap: () => launchUrl(
                    Uri.parse('https://retroachievements.org'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(l.settingsVersion(_appVersion),
                style: const TextStyle(fontSize: 11, color: RaColors.muted)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLanguage(
      BuildContext context, WidgetRef ref, Locale? current) async {
    final l = AppLocalizations.of(context);

    Widget option(String title, Locale? value) {
      final selected = value?.languageCode == current?.languageCode;
      return ListTile(
        leading: Icon(selected ? Icons.check_circle : Icons.circle_outlined,
            color: selected ? RaColors.achievements : RaColors.muted),
        title: Text(title),
        onTap: () {
          ref.read(localeProvider.notifier).set(value);
          Navigator.of(context).pop();
        },
      );
    }

    await showDialog<void>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(l.settingsLanguage),
        children: [
          option(l.settingsLanguageSystem, null),
          // Driven by the generated list, so a new .arb shows up here for free.
          for (final locale in AppLocalizations.supportedLocales)
            option(_languageNames[locale.languageCode] ?? locale.languageCode,
                locale),
        ],
      ),
    );
  }

  Future<void> _editApiKey(BuildContext context, WidgetRef ref) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const _ApiKeyDialog(),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).settingsApiKeyUpdated)),
      );
    }
  }
}

/// Replacing the key keeps the session; the new key is validated against the
/// API before it is stored, exactly like at sign-in.
class _ApiKeyDialog extends ConsumerStatefulWidget {
  const _ApiKeyDialog();

  @override
  ConsumerState<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends ConsumerState<_ApiKeyDialog> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res =
        await ref.read(sessionProvider.notifier).replaceApiKey(_controller.text);
    if (!mounted) return;
    final error = res.errorOrNull;
    if (error == null) {
      await refreshAll(ref);
      if (mounted) Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = localizedError(AppLocalizations.of(context), error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.settingsApiKey),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autocorrect: false,
            enableSuggestions: false,
            obscureText: true,
            decoration: InputDecoration(labelText: l.fieldApiKey),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFFCA5A5))),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l.actionSave),
        ),
      ],
    );
  }
}
