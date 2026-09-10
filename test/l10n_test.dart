// ignore_for_file: dangling_library_doc_comments
/// Guards the promise that adding a language is only "drop in an .arb":
/// every locale file must answer the same set of keys as the template.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _keysOf(File file) {
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  // `@@locale` is metadata; `@key` entries are placeholder descriptions.
  return json.keys.where((k) => !k.startsWith('@')).toSet();
}

void main() {
  final dir = Directory('lib/l10n');
  final template = File('lib/l10n/app_en.arb');

  test('the template exists and is not empty', () {
    expect(template.existsSync(), isTrue);
    expect(_keysOf(template), isNotEmpty);
  });

  test('every locale defines exactly the template keys', () {
    final expected = _keysOf(template);
    final others = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb') && f.path != template.path);

    expect(others, isNotEmpty, reason: 'no translated locale found');

    for (final file in others) {
      final keys = _keysOf(file);
      expect(keys.difference(expected), isEmpty,
          reason: '${file.path} has keys the template does not');
      expect(expected.difference(keys), isEmpty,
          reason: '${file.path} is missing translations');
    }
  });

  test('every plural spells out its zero case', () {
    // CLDR puts 0 in the `one` bucket for pt, so a message with only `=1` and
    // `other` renders the singular for zero — and a `=1` branch with a
    // hardcoded "1" renders "1 dia" for a zero streak.
    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.arb')) continue;
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final entry in json.entries) {
        if (entry.key.startsWith('@')) continue;
        final value = entry.value;
        if (value is! String || !value.contains('plural,')) continue;
        expect(value, contains('=0{'),
            reason: '${file.path}: ${entry.key} has no zero case');
      }
    }
  });

  test('every locale declares its @@locale', () {
    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.arb')) continue;
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(json['@@locale'], isA<String>(), reason: file.path);
    }
  });
}
