/// Local game search.
///
/// The Web API has no search-by-title endpoint, so the index is what the user
/// already has cached: every game they ever played, from
/// `API_GetUserCompletionProgress`. That also makes search work offline.
library;

import '../models/models.dart';

/// Case- and accent-insensitive contains, with a prefix match ranking first.
List<CompletionEntry> searchGames(
  List<CompletionEntry> entries,
  String query, {
  int limit = 50,
}) {
  final q = normalizeForSearch(query);
  if (q.isEmpty) return const [];

  final matches = <(int, CompletionEntry)>[];
  for (final e in entries) {
    final title = normalizeForSearch(e.title);
    final at = title.indexOf(q);
    if (at < 0) {
      // Fall back to the console name so "snes" lists the SNES library.
      if (!normalizeForSearch(e.consoleName).contains(q)) continue;
      matches.add((2, e));
      continue;
    }
    matches.add((at == 0 ? 0 : 1, e));
  }

  matches.sort((a, b) {
    final byRank = a.$1.compareTo(b.$1);
    if (byRank != 0) return byRank;
    final byProgress = b.$2.progress.compareTo(a.$2.progress);
    if (byProgress != 0) return byProgress;
    return a.$2.title.compareTo(b.$2.title);
  });

  final out = matches.map((m) => m.$2).toList();
  return out.length > limit ? out.sublist(0, limit) : out;
}

const _accents = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
const _plain = 'aaaaaeeeeiiiiooooouuuucn';

String normalizeForSearch(String value) {
  final lower = value.toLowerCase().trim();
  final buf = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final at = _accents.indexOf(ch);
    buf.write(at >= 0 ? _plain[at] : ch);
  }
  return buf.toString();
}
