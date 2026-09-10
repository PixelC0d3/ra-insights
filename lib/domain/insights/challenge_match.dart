/// Guessing which game an event achievement is asking you to play.
///
/// The Web API does not link an event achievement to its source game — the
/// payload is only `Title`, `Description`, `Points`, `TrueRatio` and unlock
/// counts. Events do, however, name the game in their text, in the shape
/// `"<Wonder> - <Game>: <task>"`. This file is the whole heuristic, kept apart
/// so it can be deleted the day the API exposes the real link.
///
/// Every result carries its [MatchConfidence]; the UI must never present a
/// guess as fact.
library;

import '../models/models.dart';
import 'search.dart';

enum MatchConfidence {
  /// No game name could be pulled out of the text, or it matches nothing.
  none,

  /// The candidate is contained in a library title, or vice versa.
  weak,

  /// The candidate and a library title are the same once normalized.
  strong,
}

class ChallengeTarget {
  const ChallengeTarget({
    required this.achievement,
    required this.candidateTitle,
    required this.match,
    required this.confidence,
  });

  final GameAchievement achievement;

  /// The game name read out of the achievement text, or null when the text
  /// does not follow the expected shape.
  final String? candidateTitle;

  /// The library entry the candidate was matched to, if any.
  final CompletionEntry? match;

  final MatchConfidence confidence;

  bool get isInLibrary => match != null;
}

/// Pulls the game name out of `"<Wonder> - <Game>: <task>"`.
///
/// Returns null when either separator is missing — an empty answer beats an
/// invented one.
String? candidateGameFrom(String text) {
  final colon = text.indexOf(':');
  if (colon <= 0) return null;
  final left = text.substring(0, colon);

  final dash = left.lastIndexOf(' - ');
  if (dash < 0) return null;

  final candidate = left.substring(dash + 3).trim();
  return candidate.isEmpty ? null : candidate;
}

/// Pairs each achievement with the library game it seems to point at.
List<ChallengeTarget> matchTargets(
  List<GameAchievement> achievements,
  List<CompletionEntry> library,
) {
  final index = <String, CompletionEntry>{};
  for (final entry in library) {
    // First writer wins, so the earliest-played game keeps an exact title.
    index.putIfAbsent(normalizeForSearch(entry.title), () => entry);
  }

  return [
    for (final a in achievements) _match(a, index),
  ];
}

ChallengeTarget _match(
  GameAchievement achievement,
  Map<String, CompletionEntry> index,
) {
  // The description carries the task and usually the fuller name; the title is
  // the fallback for events that put the game there instead.
  final candidate = candidateGameFrom(achievement.description) ??
      candidateGameFrom(achievement.title);

  if (candidate == null) {
    return ChallengeTarget(
      achievement: achievement,
      candidateTitle: null,
      match: null,
      confidence: MatchConfidence.none,
    );
  }

  final needle = normalizeForSearch(candidate);
  final exact = index[needle];
  if (exact != null) {
    return ChallengeTarget(
      achievement: achievement,
      candidateTitle: candidate,
      match: exact,
      confidence: MatchConfidence.strong,
    );
  }

  if (needle.isNotEmpty) {
    for (final entry in index.entries) {
      if (entry.key.contains(needle) || needle.contains(entry.key)) {
        return ChallengeTarget(
          achievement: achievement,
          candidateTitle: candidate,
          match: entry.value,
          confidence: MatchConfidence.weak,
        );
      }
    }
  }

  // A name was found but the user has never played it: still useful, it is the
  // "new game" case.
  return ChallengeTarget(
    achievement: achievement,
    candidateTitle: candidate,
    match: null,
    confidence: MatchConfidence.none,
  );
}
