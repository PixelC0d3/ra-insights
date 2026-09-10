/// Turning "291 achievements left" into a short, ordered list of next moves.
///
/// Easiest first, by unlock rate: the share of the event's players who already
/// have it is the only difficulty signal the API gives, and it beats guessing
/// from points.
library;

import '../models/models.dart';

class PlanStep {
  const PlanStep({
    required this.achievement,
    required this.unlockRate,
    required this.cumulativePoints,
    required this.cumulativePercent,
  });

  final GameAchievement achievement;

  /// Percentage of the event's players holding it, or null when the payload
  /// carried no player counts.
  final double? unlockRate;

  /// Points banked once every step up to and including this one is done.
  final int cumulativePoints;

  /// Where the event's completion lands after this step.
  final int cumulativePercent;
}

class ChallengePlan {
  const ChallengePlan({
    required this.steps,
    required this.remainingAfter,
    required this.pointsGained,
    required this.percentAfter,
  });

  final List<PlanStep> steps;

  /// Achievements still locked once the plan is done.
  final int remainingAfter;
  final int pointsGained;
  final int percentAfter;

  bool get isEmpty => steps.isEmpty;
}

/// Builds the plan from a game payload. [limit] keeps it to something a person
/// will actually sit down and do.
ChallengePlan buildChallengePlan(GameProgress game, {int limit = 10}) {
  final locked = game.achievements.where((a) => !a.isEarned).toList()
    ..sort((a, b) {
      // Highest unlock rate first; an unknown rate is treated as hardest.
      final rateA = game.unlockRate(a) ?? -1;
      final rateB = game.unlockRate(b) ?? -1;
      final byRate = rateB.compareTo(rateA);
      if (byRate != 0) return byRate;
      // Same rate: the cheaper achievement is the quicker win.
      final byPoints = a.points.compareTo(b.points);
      return byPoints != 0 ? byPoints : a.title.compareTo(b.title);
    });

  final picked = locked.length > limit ? locked.sublist(0, limit) : locked;

  final steps = <PlanStep>[];
  var points = 0;
  var done = game.earned;
  for (final a in picked) {
    points += a.points;
    done++;
    steps.add(PlanStep(
      achievement: a,
      unlockRate: game.unlockRate(a),
      cumulativePoints: points,
      cumulativePercent: game.numAchievements > 0
          ? (done / game.numAchievements * 100).round()
          : 0,
    ));
  }

  return ChallengePlan(
    steps: steps,
    remainingAfter: locked.length - picked.length,
    pointsGained: points,
    percentAfter: steps.isEmpty ? game.percent : steps.last.cumulativePercent,
  );
}
