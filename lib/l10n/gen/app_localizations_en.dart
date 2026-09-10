// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RA Insights';

  @override
  String get appTagline =>
      'Insights on your RetroAchievements profile. Unofficial app.';

  @override
  String get navInsights => 'Home';

  @override
  String get navGames => 'Games';

  @override
  String get navActivity => 'Activity';

  @override
  String get navProgression => 'Progression';

  @override
  String get navProfile => 'Profile';

  @override
  String get navChallenges => 'Challenges';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionSettings => 'Settings';

  @override
  String get actionPaste => 'Paste';

  @override
  String get actionSignIn => 'Sign in';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionExpand => 'See achievements';

  @override
  String get actionCollapse => 'Collapse';

  @override
  String get errorUnauthorized =>
      'Invalid API key. Check Settings → Web API Key on the RetroAchievements site.';

  @override
  String get errorNotFound => 'Not found on RetroAchievements.';

  @override
  String get errorNetwork => 'No connection to RetroAchievements. Try again.';

  @override
  String get errorRateLimited =>
      'The API is rate limiting requests. Wait a moment.';

  @override
  String get errorParse => 'The API replied in an unexpected format.';

  @override
  String get notFoundTitle => 'Nothing found';

  @override
  String get cachedData => 'cached data';

  @override
  String get updatedNever => 'never updated';

  @override
  String get updatedNow => 'updated just now';

  @override
  String updatedMinutes(int count) {
    return 'updated $count min ago';
  }

  @override
  String updatedHours(int count) {
    return 'updated $count h ago';
  }

  @override
  String updatedDays(int count) {
    return 'updated $count d ago';
  }

  @override
  String get onboardingWhyTitle => 'Why a Web API key?';

  @override
  String get onboardingWhyText =>
      'The RetroAchievements Web API authenticates every single request with your username plus your personal key — there is no anonymous endpoint. Without it no screen in this app can load data.';

  @override
  String get onboardingWhereTitle => 'Where to find the key';

  @override
  String get onboardingSteps =>
      '1. Open retroachievements.org/settings\n2. Scroll to \"Web API Key\"\n3. Copy the key and paste it here';

  @override
  String get onboardingOpenSettings => 'Open RA settings';

  @override
  String get fieldUsername => 'RetroAchievements username';

  @override
  String get fieldApiKey => 'Web API Key';

  @override
  String get onboardingPrivacy =>
      'The key stays on your device, in the Android keystore. There is no server and no data collection.';

  @override
  String get statGamesPlayed => 'Games played';

  @override
  String get statMasteries => 'Masteries';

  @override
  String get statMasteryRate => 'Mastery rate';

  @override
  String get statPoints => 'Points';

  @override
  String get cardPlayNow => 'WHAT TO PLAY NOW';

  @override
  String get cardStreak => 'STREAK';

  @override
  String get cardAlmostThere => 'ALMOST THERE';

  @override
  String get cardRarest => 'RAREST';

  @override
  String get streakAtRisk => 'at risk today';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days in a row',
      one: 'day in a row',
      zero: 'days in a row',
    );
    return '$_temp0';
  }

  @override
  String streakSummary(int best, int active, int total) {
    return 'Best: $best days · $active active days · $total achievements (365d)';
  }

  @override
  String get emptyStreak => 'No achievements in the last 365 days.';

  @override
  String get emptyAlmostThere => 'No game close to mastery.';

  @override
  String get emptyRarest => 'No rarity data in this period.';

  @override
  String remainingLine(int count, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count achievements left',
      one: '$count achievement left',
      zero: 'nothing left',
    );
    return '$_temp0 ($percent%)';
  }

  @override
  String playNowReason(int count, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count achievements left ($percent%)',
      one: '$count achievement left for mastery',
      zero: 'Mastery complete',
    );
    return '$_temp0';
  }

  @override
  String activityEvents(int count) {
    return '$count events in the last 365 days';
  }

  @override
  String get chipAchievements => 'Achievements';

  @override
  String get chipMastered => 'Mastered';

  @override
  String get chipBeaten => 'Beaten';

  @override
  String get legendLess => 'less';

  @override
  String get legendMore => 'more';

  @override
  String get activityDayHint =>
      'Tap a day to see only that day. Tap again to clear.';

  @override
  String activityShowingDay(String date) {
    return 'Showing $date';
  }

  @override
  String get activityClearDay => 'Clear day';

  @override
  String tabGamesCount(int count) {
    return 'Games ($count)';
  }

  @override
  String tabAchievementsCount(int count) {
    return 'Achievements ($count)';
  }

  @override
  String get emptyActivityGames => 'No game matches this filter.';

  @override
  String get emptyActivityAchievements =>
      'No achievement matches this filter. Mastered and beaten awards have no achievements of their own.';

  @override
  String achievementCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count achievements',
      one: '$count achievement',
      zero: '$count achievements',
    );
    return '$_temp0';
  }

  @override
  String pointsShort(int count) {
    return '$count pts';
  }

  @override
  String get recentGamesTitle => 'Recent games';

  @override
  String get gamesTabRecent => 'Recent';

  @override
  String get gamesTabByConsole => 'By console';

  @override
  String get recentShow => 'Show';

  @override
  String recentPage(int page) {
    return 'page $page';
  }

  @override
  String recentAchievementsOf(int earned, int total) {
    return '$earned of $total achievements';
  }

  @override
  String recentPointsOf(int earned, int total) {
    return '$earned of $total points';
  }

  @override
  String get recentNoAchievements => 'No achievements yet';

  @override
  String recentPlayedOn(String date) {
    return 'played on $date';
  }

  @override
  String get recentEmptyPage => 'No game on this page.';

  @override
  String get pagerFirst => 'First';

  @override
  String get pagerPrevious => 'Previous';

  @override
  String get pagerNext => 'Next';

  @override
  String get seeFullList => 'See full list';

  @override
  String get badgeNoAchievements => 'No achievements registered.';

  @override
  String badgePointsAndRatio(int points, int ratio) {
    return '$points pts · TrueRatio $ratio';
  }

  @override
  String badgeUnlockedOn(String date) {
    return 'Unlocked on $date';
  }

  @override
  String get badgeHardcoreSuffix => ' (hardcore)';

  @override
  String get badgeStillLocked => 'Still locked';

  @override
  String get rarityCommon => 'Common';

  @override
  String get rarityUncommon => 'Uncommon';

  @override
  String get rarityRare => 'Rare';

  @override
  String get rarityVeryRare => 'Very rare';

  @override
  String get rarityUltraRare => 'Ultra rare';

  @override
  String rarityOfPlayers(String rate) {
    return '$rate of players unlocked it';
  }

  @override
  String get rarityEstimated => 'estimated from TrueRatio';

  @override
  String get gameFallbackTitle => 'Game';

  @override
  String get gameOpenOnSite => 'Open on the site';

  @override
  String get gameFilterAll => 'All';

  @override
  String get gameFilterEarned => '✅ Earned';

  @override
  String get gameFilterLocked => '🔒 Missing';

  @override
  String gameProgressLine(int earned, int total, int percent) {
    return '$earned/$total achievements · $percent%';
  }

  @override
  String gameRemainingSuffix(int count) {
    return ' · $count to go';
  }

  @override
  String gamePointsLine(int earned, int total) {
    return '$earned/$total points';
  }

  @override
  String gameDifficultySuffix(int ratio) {
    return ' · difficulty left: $ratio average TrueRatio';
  }

  @override
  String get gameEmptyFilter => 'No achievement in this filter.';

  @override
  String get achievementSearchHint => 'Search achievement';

  @override
  String get achievementEarned => 'earned';

  @override
  String achievementEarnedOn(String date) {
    return 'earned on $date';
  }

  @override
  String achievementEarnedOnCasual(String date) {
    return 'earned on $date (casual)';
  }

  @override
  String get progressionTitle => 'Progression';

  @override
  String get metricGames => 'games';

  @override
  String get metricMastered => 'mastered';

  @override
  String get metricBeaten => 'beaten';

  @override
  String get metricRate => 'rate';

  @override
  String get filterAll => 'All';

  @override
  String get filterWithProgress => 'With progress';

  @override
  String get filterMastered => 'Mastered';

  @override
  String consoleGameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games',
      one: '$count game',
      zero: '$count games',
    );
    return '$_temp0';
  }

  @override
  String consoleBreakdown(int mastered, int beaten, int open) {
    return '$mastered mastered · $beaten beaten · $open open';
  }

  @override
  String get emptyConsoles => 'No console in this filter.';

  @override
  String get emptyConsoleGames => 'No game in this filter.';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchTabGames => 'Games';

  @override
  String get searchTabPlayers => 'Players';

  @override
  String get searchGameHint => 'Game or console name';

  @override
  String get searchGameHelp =>
      'Searches the games you have already played — works offline. The RetroAchievements API does not expose a search over the full catalogue.';

  @override
  String get searchGameEmpty => 'No game found.';

  @override
  String get searchPlayerHint => 'Exact player name';

  @override
  String get searchPlayerHelp =>
      'The API only answers by exact name — there is no partial user search. Open a profile to compare points and rank with yours, read the wall and send a message.';

  @override
  String playerPointsRank(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString pts';
  }

  @override
  String playerRankSuffix(int rank) {
    final intl.NumberFormat rankNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rankString = rankNumberFormat.format(rank);

    return ' · rank $rankString';
  }

  @override
  String playerMemberSinceYear(int year) {
    return 'member since $year';
  }

  @override
  String get sectionMessage => 'MESSAGE';

  @override
  String get messageHelp =>
      'The official API is read-only for messages: sending happens on the site, with the recipient already filled in.';

  @override
  String get sendMessage => 'Send message';

  @override
  String get openProfileOnSite => 'Open profile on the site';

  @override
  String get followPlayer => 'Follow';

  @override
  String get followHelp =>
      'The API has no follow endpoint: tap to open the profile on the site, where the real button lives.';

  @override
  String get sectionComparison => 'COMPARISON';

  @override
  String get comparisonNeedsDashboard => 'Open the dashboard first to compare.';

  @override
  String get comparePoints => 'Points';

  @override
  String get compareRank => 'Rank';

  @override
  String get compareTie => 'You are tied on points.';

  @override
  String compareAhead(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'You are $countString points ahead.';
  }

  @override
  String compareBehind(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'You are $countString points behind.';
  }

  @override
  String get sectionWall => 'WALL';

  @override
  String get emptyWall => 'No comments on the wall.';

  @override
  String get sectionAwards => 'AWARDS';

  @override
  String get emptyAwards => 'No awards yet.';

  @override
  String get profileTitle => 'My profile';

  @override
  String profileMemberSince(String date) {
    return 'member since $date';
  }

  @override
  String get sectionScore => 'SCORE';

  @override
  String get profileRankPosition => 'Rank position';

  @override
  String profileRankValue(int rank, int total) {
    final intl.NumberFormat rankNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rankString = rankNumberFormat.format(rank);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '#$rankString of $totalString';
  }

  @override
  String profileRankValueShort(int rank) {
    final intl.NumberFormat rankNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rankString = rankNumberFormat.format(rank);

    return '#$rankString';
  }

  @override
  String get profilePoints => 'Points';

  @override
  String get profileWeightedPoints => 'Weighted points (TrueRatio)';

  @override
  String get sectionCollection => 'COLLECTION';

  @override
  String get profileBeaten => 'Beaten';

  @override
  String get sectionActivity => 'ACTIVITY';

  @override
  String get profileCurrentStreak => 'Current streak';

  @override
  String get profileBestStreak => 'Best streak';

  @override
  String get profileActiveDays => 'Active days (365d)';

  @override
  String get profileAchievements365 => 'Achievements (365d)';

  @override
  String get activitySeeFull => 'See full activity';

  @override
  String profileDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
      zero: '$count days',
    );
    return '$_temp0';
  }

  @override
  String get profileOpenOnSite => 'Open my profile on the site';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccountConnected => 'Connected account';

  @override
  String get settingsApiKey => 'Web API key';

  @override
  String get settingsApiKeySubtitle => 'Replace the key stored on this device';

  @override
  String get settingsApiKeyUpdated => 'Key updated';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System language';

  @override
  String get settingsClearCache => 'Clear cache';

  @override
  String get settingsClearCacheSubtitle => 'Forces a full re-read from the API';

  @override
  String get settingsCacheCleared => 'Cache cleared';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutSubtitle => 'Erases the key from this device';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutText =>
      'RA Insights is an unofficial app, not affiliated with RetroAchievements. Data comes from the official Web API. Nothing leaves your device.';

  @override
  String settingsVersion(String version) {
    return 'v$version';
  }

  @override
  String get rarestWindowAll => 'All time';

  @override
  String get rarestWindow90 => '90 days';

  @override
  String get rarestWindow30 => '30 days';

  @override
  String get cardChallenges => 'CHALLENGES';

  @override
  String get challengesTitle => 'Challenges';

  @override
  String get challengesSubtitle => 'RetroAchievements events';

  @override
  String get challengeFilterAll => 'All';

  @override
  String get challengeFilterInProgress => 'In progress';

  @override
  String get challengeFilterNotStarted => 'Not started';

  @override
  String get challengeFilterCompleted => 'Completed';

  @override
  String challengeProgress(int earned, int total) {
    return '$earned/$total achievements';
  }

  @override
  String get challengeEmpty => 'No challenge in this filter.';

  @override
  String get challengeNotStarted => 'Not started';

  @override
  String get challengeCompleted => 'Completed';

  @override
  String get challengeNextUp => 'WHAT TO DO NEXT';

  @override
  String get challengeAllDone => 'Every achievement in this event is done.';

  @override
  String get challengeSeeAll => 'See every achievement';

  @override
  String get challengeOpenOnSite => 'Open on the site';

  @override
  String get challengeInLibrary => 'You already play this';

  @override
  String get challengeNewGame => 'New game';

  @override
  String get challengeGuessNote =>
      'The game on each line is inferred from the achievement text — the API does not link an event achievement to its source game, so treat it as a hint. A question mark means the match is uncertain.';

  @override
  String get challengeRulesNote =>
      'Events need no sign-up. Some, including Challenge League, are tracked manually: post your progress in the event forum topic to have it validated.';

  @override
  String challengePointsLeft(int points) {
    return '$points points left';
  }

  @override
  String get challengeSearchHint => 'Search challenges';

  @override
  String get challengeSortClosest => 'Closest';

  @override
  String get challengeSortRecent => 'Recent';

  @override
  String get challengeSortBiggest => 'Biggest';

  @override
  String get challengeBuildPlan => 'Build a plan';

  @override
  String get challengePlanTitle => 'Your plan';

  @override
  String challengePlanSummary(int count, int percent, int points) {
    return 'These $count take you to $percent% and bank $points points.';
  }

  @override
  String challengePlanMore(int count) {
    return '$count more left after that.';
  }

  @override
  String get challengePlanEmpty => 'Nothing left to plan.';

  @override
  String get challengeRarityAvg => 'avg rarity of what you earned here';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get rememberMeNote =>
      'Keeps your username filled in next time. The key stays in the device keystore.';

  @override
  String get splashTagline => 'Loading your profile…';

  @override
  String get offlineBanner => 'Offline — showing saved data';

  @override
  String get achievementOpenOnSite => 'Open achievement on the site';
}
