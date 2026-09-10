import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'RA Insights'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Insights on your RetroAchievements profile. Unofficial app.'**
  String get appTagline;

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navInsights;

  /// No description provided for @navGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get navGames;

  /// No description provided for @navActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// No description provided for @navProgression.
  ///
  /// In en, this message translates to:
  /// **'Progression'**
  String get navProgression;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navChallenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get navChallenges;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// No description provided for @actionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// No description provided for @actionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get actionSettings;

  /// No description provided for @actionPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get actionPaste;

  /// No description provided for @actionSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get actionSignIn;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionExpand.
  ///
  /// In en, this message translates to:
  /// **'See achievements'**
  String get actionExpand;

  /// No description provided for @actionCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get actionCollapse;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Invalid API key. Check Settings → Web API Key on the RetroAchievements site.'**
  String get errorUnauthorized;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found on RetroAchievements.'**
  String get errorNotFound;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection to RetroAchievements. Try again.'**
  String get errorNetwork;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'The API is rate limiting requests. Wait a moment.'**
  String get errorRateLimited;

  /// No description provided for @errorParse.
  ///
  /// In en, this message translates to:
  /// **'The API replied in an unexpected format.'**
  String get errorParse;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get notFoundTitle;

  /// No description provided for @cachedData.
  ///
  /// In en, this message translates to:
  /// **'cached data'**
  String get cachedData;

  /// No description provided for @updatedNever.
  ///
  /// In en, this message translates to:
  /// **'never updated'**
  String get updatedNever;

  /// No description provided for @updatedNow.
  ///
  /// In en, this message translates to:
  /// **'updated just now'**
  String get updatedNow;

  /// No description provided for @updatedMinutes.
  ///
  /// In en, this message translates to:
  /// **'updated {count} min ago'**
  String updatedMinutes(int count);

  /// No description provided for @updatedHours.
  ///
  /// In en, this message translates to:
  /// **'updated {count} h ago'**
  String updatedHours(int count);

  /// No description provided for @updatedDays.
  ///
  /// In en, this message translates to:
  /// **'updated {count} d ago'**
  String updatedDays(int count);

  /// No description provided for @onboardingWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why a Web API key?'**
  String get onboardingWhyTitle;

  /// No description provided for @onboardingWhyText.
  ///
  /// In en, this message translates to:
  /// **'The RetroAchievements Web API authenticates every single request with your username plus your personal key — there is no anonymous endpoint. Without it no screen in this app can load data.'**
  String get onboardingWhyText;

  /// No description provided for @onboardingWhereTitle.
  ///
  /// In en, this message translates to:
  /// **'Where to find the key'**
  String get onboardingWhereTitle;

  /// No description provided for @onboardingSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Open retroachievements.org/settings\n2. Scroll to \"Web API Key\"\n3. Copy the key and paste it here'**
  String get onboardingSteps;

  /// No description provided for @onboardingOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open RA settings'**
  String get onboardingOpenSettings;

  /// No description provided for @fieldUsername.
  ///
  /// In en, this message translates to:
  /// **'RetroAchievements username'**
  String get fieldUsername;

  /// No description provided for @fieldApiKey.
  ///
  /// In en, this message translates to:
  /// **'Web API Key'**
  String get fieldApiKey;

  /// No description provided for @onboardingPrivacy.
  ///
  /// In en, this message translates to:
  /// **'The key stays on your device, in the Android keystore. There is no server and no data collection.'**
  String get onboardingPrivacy;

  /// No description provided for @statGamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Games played'**
  String get statGamesPlayed;

  /// No description provided for @statMasteries.
  ///
  /// In en, this message translates to:
  /// **'Masteries'**
  String get statMasteries;

  /// No description provided for @statMasteryRate.
  ///
  /// In en, this message translates to:
  /// **'Mastery rate'**
  String get statMasteryRate;

  /// No description provided for @statPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get statPoints;

  /// No description provided for @cardPlayNow.
  ///
  /// In en, this message translates to:
  /// **'WHAT TO PLAY NOW'**
  String get cardPlayNow;

  /// No description provided for @cardStreak.
  ///
  /// In en, this message translates to:
  /// **'STREAK'**
  String get cardStreak;

  /// No description provided for @cardAlmostThere.
  ///
  /// In en, this message translates to:
  /// **'ALMOST THERE'**
  String get cardAlmostThere;

  /// No description provided for @cardRarest.
  ///
  /// In en, this message translates to:
  /// **'RAREST'**
  String get cardRarest;

  /// No description provided for @streakAtRisk.
  ///
  /// In en, this message translates to:
  /// **'at risk today'**
  String get streakAtRisk;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{days in a row} =1{day in a row} other{days in a row}}'**
  String streakDays(int count);

  /// No description provided for @streakSummary.
  ///
  /// In en, this message translates to:
  /// **'Best: {best} days · {active} active days · {total} achievements (365d)'**
  String streakSummary(int best, int active, int total);

  /// No description provided for @emptyStreak.
  ///
  /// In en, this message translates to:
  /// **'No achievements in the last 365 days.'**
  String get emptyStreak;

  /// No description provided for @emptyAlmostThere.
  ///
  /// In en, this message translates to:
  /// **'No game close to mastery.'**
  String get emptyAlmostThere;

  /// No description provided for @emptyRarest.
  ///
  /// In en, this message translates to:
  /// **'No rarity data in this period.'**
  String get emptyRarest;

  /// No description provided for @remainingLine.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{nothing left} =1{{count} achievement left} other{{count} achievements left}} ({percent}%)'**
  String remainingLine(int count, int percent);

  /// No description provided for @playNowReason.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Mastery complete} =1{{count} achievement left for mastery} other{{count} achievements left ({percent}%)}}'**
  String playNowReason(int count, int percent);

  /// No description provided for @activityEvents.
  ///
  /// In en, this message translates to:
  /// **'{count} events in the last 365 days'**
  String activityEvents(int count);

  /// No description provided for @chipAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get chipAchievements;

  /// No description provided for @chipMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get chipMastered;

  /// No description provided for @chipBeaten.
  ///
  /// In en, this message translates to:
  /// **'Beaten'**
  String get chipBeaten;

  /// No description provided for @legendLess.
  ///
  /// In en, this message translates to:
  /// **'less'**
  String get legendLess;

  /// No description provided for @legendMore.
  ///
  /// In en, this message translates to:
  /// **'more'**
  String get legendMore;

  /// No description provided for @activityDayHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a day to see only that day. Tap again to clear.'**
  String get activityDayHint;

  /// No description provided for @activityShowingDay.
  ///
  /// In en, this message translates to:
  /// **'Showing {date}'**
  String activityShowingDay(String date);

  /// No description provided for @activityClearDay.
  ///
  /// In en, this message translates to:
  /// **'Clear day'**
  String get activityClearDay;

  /// No description provided for @tabGamesCount.
  ///
  /// In en, this message translates to:
  /// **'Games ({count})'**
  String tabGamesCount(int count);

  /// No description provided for @tabAchievementsCount.
  ///
  /// In en, this message translates to:
  /// **'Achievements ({count})'**
  String tabAchievementsCount(int count);

  /// No description provided for @emptyActivityGames.
  ///
  /// In en, this message translates to:
  /// **'No game matches this filter.'**
  String get emptyActivityGames;

  /// No description provided for @emptyActivityAchievements.
  ///
  /// In en, this message translates to:
  /// **'No achievement matches this filter. Mastered and beaten awards have no achievements of their own.'**
  String get emptyActivityAchievements;

  /// No description provided for @achievementCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{{count} achievements} =1{{count} achievement} other{{count} achievements}}'**
  String achievementCount(int count);

  /// No description provided for @pointsShort.
  ///
  /// In en, this message translates to:
  /// **'{count} pts'**
  String pointsShort(int count);

  /// No description provided for @recentGamesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent games'**
  String get recentGamesTitle;

  /// No description provided for @gamesTabRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get gamesTabRecent;

  /// No description provided for @gamesTabByConsole.
  ///
  /// In en, this message translates to:
  /// **'By console'**
  String get gamesTabByConsole;

  /// No description provided for @recentShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get recentShow;

  /// No description provided for @recentPage.
  ///
  /// In en, this message translates to:
  /// **'page {page}'**
  String recentPage(int page);

  /// No description provided for @recentAchievementsOf.
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total} achievements'**
  String recentAchievementsOf(int earned, int total);

  /// No description provided for @recentPointsOf.
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total} points'**
  String recentPointsOf(int earned, int total);

  /// No description provided for @recentNoAchievements.
  ///
  /// In en, this message translates to:
  /// **'No achievements yet'**
  String get recentNoAchievements;

  /// No description provided for @recentPlayedOn.
  ///
  /// In en, this message translates to:
  /// **'played on {date}'**
  String recentPlayedOn(String date);

  /// No description provided for @recentEmptyPage.
  ///
  /// In en, this message translates to:
  /// **'No game on this page.'**
  String get recentEmptyPage;

  /// No description provided for @pagerFirst.
  ///
  /// In en, this message translates to:
  /// **'First'**
  String get pagerFirst;

  /// No description provided for @pagerPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get pagerPrevious;

  /// No description provided for @pagerNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get pagerNext;

  /// No description provided for @seeFullList.
  ///
  /// In en, this message translates to:
  /// **'See full list'**
  String get seeFullList;

  /// No description provided for @badgeNoAchievements.
  ///
  /// In en, this message translates to:
  /// **'No achievements registered.'**
  String get badgeNoAchievements;

  /// No description provided for @badgePointsAndRatio.
  ///
  /// In en, this message translates to:
  /// **'{points} pts · TrueRatio {ratio}'**
  String badgePointsAndRatio(int points, int ratio);

  /// No description provided for @badgeUnlockedOn.
  ///
  /// In en, this message translates to:
  /// **'Unlocked on {date}'**
  String badgeUnlockedOn(String date);

  /// No description provided for @badgeHardcoreSuffix.
  ///
  /// In en, this message translates to:
  /// **' (hardcore)'**
  String get badgeHardcoreSuffix;

  /// No description provided for @badgeStillLocked.
  ///
  /// In en, this message translates to:
  /// **'Still locked'**
  String get badgeStillLocked;

  /// No description provided for @rarityCommon.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get rarityCommon;

  /// No description provided for @rarityUncommon.
  ///
  /// In en, this message translates to:
  /// **'Uncommon'**
  String get rarityUncommon;

  /// No description provided for @rarityRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get rarityRare;

  /// No description provided for @rarityVeryRare.
  ///
  /// In en, this message translates to:
  /// **'Very rare'**
  String get rarityVeryRare;

  /// No description provided for @rarityUltraRare.
  ///
  /// In en, this message translates to:
  /// **'Ultra rare'**
  String get rarityUltraRare;

  /// No description provided for @rarityOfPlayers.
  ///
  /// In en, this message translates to:
  /// **'{rate} of players unlocked it'**
  String rarityOfPlayers(String rate);

  /// No description provided for @rarityEstimated.
  ///
  /// In en, this message translates to:
  /// **'estimated from TrueRatio'**
  String get rarityEstimated;

  /// No description provided for @gameFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get gameFallbackTitle;

  /// No description provided for @gameOpenOnSite.
  ///
  /// In en, this message translates to:
  /// **'Open on the site'**
  String get gameOpenOnSite;

  /// No description provided for @gameFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get gameFilterAll;

  /// No description provided for @gameFilterEarned.
  ///
  /// In en, this message translates to:
  /// **'✅ Earned'**
  String get gameFilterEarned;

  /// No description provided for @gameFilterLocked.
  ///
  /// In en, this message translates to:
  /// **'🔒 Missing'**
  String get gameFilterLocked;

  /// No description provided for @gameProgressLine.
  ///
  /// In en, this message translates to:
  /// **'{earned}/{total} achievements · {percent}%'**
  String gameProgressLine(int earned, int total, int percent);

  /// No description provided for @gameRemainingSuffix.
  ///
  /// In en, this message translates to:
  /// **' · {count} to go'**
  String gameRemainingSuffix(int count);

  /// No description provided for @gamePointsLine.
  ///
  /// In en, this message translates to:
  /// **'{earned}/{total} points'**
  String gamePointsLine(int earned, int total);

  /// No description provided for @gameDifficultySuffix.
  ///
  /// In en, this message translates to:
  /// **' · difficulty left: {ratio} average TrueRatio'**
  String gameDifficultySuffix(int ratio);

  /// No description provided for @gameEmptyFilter.
  ///
  /// In en, this message translates to:
  /// **'No achievement in this filter.'**
  String get gameEmptyFilter;

  /// No description provided for @achievementSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search achievement'**
  String get achievementSearchHint;

  /// No description provided for @achievementEarned.
  ///
  /// In en, this message translates to:
  /// **'earned'**
  String get achievementEarned;

  /// No description provided for @achievementEarnedOn.
  ///
  /// In en, this message translates to:
  /// **'earned on {date}'**
  String achievementEarnedOn(String date);

  /// No description provided for @achievementEarnedOnCasual.
  ///
  /// In en, this message translates to:
  /// **'earned on {date} (casual)'**
  String achievementEarnedOnCasual(String date);

  /// No description provided for @progressionTitle.
  ///
  /// In en, this message translates to:
  /// **'Progression'**
  String get progressionTitle;

  /// No description provided for @metricGames.
  ///
  /// In en, this message translates to:
  /// **'games'**
  String get metricGames;

  /// No description provided for @metricMastered.
  ///
  /// In en, this message translates to:
  /// **'mastered'**
  String get metricMastered;

  /// No description provided for @metricBeaten.
  ///
  /// In en, this message translates to:
  /// **'beaten'**
  String get metricBeaten;

  /// No description provided for @metricRate.
  ///
  /// In en, this message translates to:
  /// **'rate'**
  String get metricRate;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterWithProgress.
  ///
  /// In en, this message translates to:
  /// **'With progress'**
  String get filterWithProgress;

  /// No description provided for @filterMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get filterMastered;

  /// No description provided for @consoleGameCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{{count} games} =1{{count} game} other{{count} games}}'**
  String consoleGameCount(int count);

  /// No description provided for @consoleBreakdown.
  ///
  /// In en, this message translates to:
  /// **'{mastered} mastered · {beaten} beaten · {open} open'**
  String consoleBreakdown(int mastered, int beaten, int open);

  /// No description provided for @emptyConsoles.
  ///
  /// In en, this message translates to:
  /// **'No console in this filter.'**
  String get emptyConsoles;

  /// No description provided for @emptyConsoleGames.
  ///
  /// In en, this message translates to:
  /// **'No game in this filter.'**
  String get emptyConsoleGames;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchTabGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get searchTabGames;

  /// No description provided for @searchTabPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get searchTabPlayers;

  /// No description provided for @searchGameHint.
  ///
  /// In en, this message translates to:
  /// **'Game or console name'**
  String get searchGameHint;

  /// No description provided for @searchGameHelp.
  ///
  /// In en, this message translates to:
  /// **'Searches the games you have already played — works offline. The RetroAchievements API does not expose a search over the full catalogue.'**
  String get searchGameHelp;

  /// No description provided for @searchGameEmpty.
  ///
  /// In en, this message translates to:
  /// **'No game found.'**
  String get searchGameEmpty;

  /// No description provided for @searchPlayerHint.
  ///
  /// In en, this message translates to:
  /// **'Exact player name'**
  String get searchPlayerHint;

  /// No description provided for @searchPlayerHelp.
  ///
  /// In en, this message translates to:
  /// **'The API only answers by exact name — there is no partial user search. Open a profile to compare points and rank with yours, read the wall and send a message.'**
  String get searchPlayerHelp;

  /// No description provided for @playerPointsRank.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String playerPointsRank(int points);

  /// No description provided for @playerRankSuffix.
  ///
  /// In en, this message translates to:
  /// **' · rank {rank}'**
  String playerRankSuffix(int rank);

  /// No description provided for @playerMemberSinceYear.
  ///
  /// In en, this message translates to:
  /// **'member since {year}'**
  String playerMemberSinceYear(int year);

  /// No description provided for @sectionMessage.
  ///
  /// In en, this message translates to:
  /// **'MESSAGE'**
  String get sectionMessage;

  /// No description provided for @messageHelp.
  ///
  /// In en, this message translates to:
  /// **'The official API is read-only for messages: sending happens on the site, with the recipient already filled in.'**
  String get messageHelp;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @openProfileOnSite.
  ///
  /// In en, this message translates to:
  /// **'Open profile on the site'**
  String get openProfileOnSite;

  /// No description provided for @followPlayer.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get followPlayer;

  /// No description provided for @followHelp.
  ///
  /// In en, this message translates to:
  /// **'The API has no follow endpoint: tap to open the profile on the site, where the real button lives.'**
  String get followHelp;

  /// No description provided for @sectionComparison.
  ///
  /// In en, this message translates to:
  /// **'COMPARISON'**
  String get sectionComparison;

  /// No description provided for @comparisonNeedsDashboard.
  ///
  /// In en, this message translates to:
  /// **'Open the dashboard first to compare.'**
  String get comparisonNeedsDashboard;

  /// No description provided for @comparePoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get comparePoints;

  /// No description provided for @compareRank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get compareRank;

  /// No description provided for @compareTie.
  ///
  /// In en, this message translates to:
  /// **'You are tied on points.'**
  String get compareTie;

  /// No description provided for @compareAhead.
  ///
  /// In en, this message translates to:
  /// **'You are {count} points ahead.'**
  String compareAhead(int count);

  /// No description provided for @compareBehind.
  ///
  /// In en, this message translates to:
  /// **'You are {count} points behind.'**
  String compareBehind(int count);

  /// No description provided for @sectionWall.
  ///
  /// In en, this message translates to:
  /// **'WALL'**
  String get sectionWall;

  /// No description provided for @emptyWall.
  ///
  /// In en, this message translates to:
  /// **'No comments on the wall.'**
  String get emptyWall;

  /// No description provided for @sectionAwards.
  ///
  /// In en, this message translates to:
  /// **'AWARDS'**
  String get sectionAwards;

  /// No description provided for @emptyAwards.
  ///
  /// In en, this message translates to:
  /// **'No awards yet.'**
  String get emptyAwards;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get profileTitle;

  /// No description provided for @profileMemberSince.
  ///
  /// In en, this message translates to:
  /// **'member since {date}'**
  String profileMemberSince(String date);

  /// No description provided for @sectionScore.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get sectionScore;

  /// No description provided for @profileRankPosition.
  ///
  /// In en, this message translates to:
  /// **'Rank position'**
  String get profileRankPosition;

  /// No description provided for @profileRankValue.
  ///
  /// In en, this message translates to:
  /// **'#{rank} of {total}'**
  String profileRankValue(int rank, int total);

  /// No description provided for @profileRankValueShort.
  ///
  /// In en, this message translates to:
  /// **'#{rank}'**
  String profileRankValueShort(int rank);

  /// No description provided for @profilePoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get profilePoints;

  /// No description provided for @profileWeightedPoints.
  ///
  /// In en, this message translates to:
  /// **'Weighted points (TrueRatio)'**
  String get profileWeightedPoints;

  /// No description provided for @sectionCollection.
  ///
  /// In en, this message translates to:
  /// **'COLLECTION'**
  String get sectionCollection;

  /// No description provided for @profileBeaten.
  ///
  /// In en, this message translates to:
  /// **'Beaten'**
  String get profileBeaten;

  /// No description provided for @sectionActivity.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY'**
  String get sectionActivity;

  /// No description provided for @profileCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get profileCurrentStreak;

  /// No description provided for @profileBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get profileBestStreak;

  /// No description provided for @profileActiveDays.
  ///
  /// In en, this message translates to:
  /// **'Active days (365d)'**
  String get profileActiveDays;

  /// No description provided for @profileAchievements365.
  ///
  /// In en, this message translates to:
  /// **'Achievements (365d)'**
  String get profileAchievements365;

  /// No description provided for @activitySeeFull.
  ///
  /// In en, this message translates to:
  /// **'See full activity'**
  String get activitySeeFull;

  /// No description provided for @profileDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{{count} days} =1{{count} day} other{{count} days}}'**
  String profileDays(int count);

  /// No description provided for @profileOpenOnSite.
  ///
  /// In en, this message translates to:
  /// **'Open my profile on the site'**
  String get profileOpenOnSite;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAccountConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected account'**
  String get settingsAccountConnected;

  /// No description provided for @settingsApiKey.
  ///
  /// In en, this message translates to:
  /// **'Web API key'**
  String get settingsApiKey;

  /// No description provided for @settingsApiKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace the key stored on this device'**
  String get settingsApiKeySubtitle;

  /// No description provided for @settingsApiKeyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Key updated'**
  String get settingsApiKeyUpdated;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingsClearCache;

  /// No description provided for @settingsClearCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Forces a full re-read from the API'**
  String get settingsClearCacheSubtitle;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get settingsCacheCleared;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Erases the key from this device'**
  String get settingsSignOutSubtitle;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutText.
  ///
  /// In en, this message translates to:
  /// **'RA Insights is an unofficial app, not affiliated with RetroAchievements. Data comes from the official Web API. Nothing leaves your device.'**
  String get settingsAboutText;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'v{version}'**
  String settingsVersion(String version);

  /// No description provided for @rarestWindowAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get rarestWindowAll;

  /// No description provided for @rarestWindow90.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get rarestWindow90;

  /// No description provided for @rarestWindow30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get rarestWindow30;

  /// No description provided for @cardChallenges.
  ///
  /// In en, this message translates to:
  /// **'CHALLENGES'**
  String get cardChallenges;

  /// No description provided for @challengesTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challengesTitle;

  /// No description provided for @challengesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'RetroAchievements events'**
  String get challengesSubtitle;

  /// No description provided for @challengeFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get challengeFilterAll;

  /// No description provided for @challengeFilterInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get challengeFilterInProgress;

  /// No description provided for @challengeFilterNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get challengeFilterNotStarted;

  /// No description provided for @challengeFilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get challengeFilterCompleted;

  /// No description provided for @challengeProgress.
  ///
  /// In en, this message translates to:
  /// **'{earned}/{total} achievements'**
  String challengeProgress(int earned, int total);

  /// No description provided for @challengeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No challenge in this filter.'**
  String get challengeEmpty;

  /// No description provided for @challengeNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get challengeNotStarted;

  /// No description provided for @challengeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get challengeCompleted;

  /// No description provided for @challengeNextUp.
  ///
  /// In en, this message translates to:
  /// **'WHAT TO DO NEXT'**
  String get challengeNextUp;

  /// No description provided for @challengeAllDone.
  ///
  /// In en, this message translates to:
  /// **'Every achievement in this event is done.'**
  String get challengeAllDone;

  /// No description provided for @challengeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See every achievement'**
  String get challengeSeeAll;

  /// No description provided for @challengeOpenOnSite.
  ///
  /// In en, this message translates to:
  /// **'Open on the site'**
  String get challengeOpenOnSite;

  /// No description provided for @challengeInLibrary.
  ///
  /// In en, this message translates to:
  /// **'You already play this'**
  String get challengeInLibrary;

  /// No description provided for @challengeNewGame.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get challengeNewGame;

  /// No description provided for @challengeGuessNote.
  ///
  /// In en, this message translates to:
  /// **'The game on each line is inferred from the achievement text — the API does not link an event achievement to its source game, so treat it as a hint. A question mark means the match is uncertain.'**
  String get challengeGuessNote;

  /// No description provided for @challengeRulesNote.
  ///
  /// In en, this message translates to:
  /// **'Events need no sign-up. Some, including Challenge League, are tracked manually: post your progress in the event forum topic to have it validated.'**
  String get challengeRulesNote;

  /// No description provided for @challengePointsLeft.
  ///
  /// In en, this message translates to:
  /// **'{points} points left'**
  String challengePointsLeft(int points);

  /// No description provided for @challengeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search challenges'**
  String get challengeSearchHint;

  /// No description provided for @challengeSortClosest.
  ///
  /// In en, this message translates to:
  /// **'Closest'**
  String get challengeSortClosest;

  /// No description provided for @challengeSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get challengeSortRecent;

  /// No description provided for @challengeSortBiggest.
  ///
  /// In en, this message translates to:
  /// **'Biggest'**
  String get challengeSortBiggest;

  /// No description provided for @challengeBuildPlan.
  ///
  /// In en, this message translates to:
  /// **'Build a plan'**
  String get challengeBuildPlan;

  /// No description provided for @challengePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get challengePlanTitle;

  /// No description provided for @challengePlanSummary.
  ///
  /// In en, this message translates to:
  /// **'These {count} take you to {percent}% and bank {points} points.'**
  String challengePlanSummary(int count, int percent, int points);

  /// No description provided for @challengePlanMore.
  ///
  /// In en, this message translates to:
  /// **'{count} more left after that.'**
  String challengePlanMore(int count);

  /// No description provided for @challengePlanEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing left to plan.'**
  String get challengePlanEmpty;

  /// No description provided for @challengeRarityAvg.
  ///
  /// In en, this message translates to:
  /// **'avg rarity of what you earned here'**
  String get challengeRarityAvg;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @rememberMeNote.
  ///
  /// In en, this message translates to:
  /// **'Keeps your username filled in next time. The key stays in the device keystore.'**
  String get rememberMeNote;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Loading your profile…'**
  String get splashTagline;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing saved data'**
  String get offlineBanner;

  /// No description provided for @achievementOpenOnSite.
  ///
  /// In en, this message translates to:
  /// **'Open achievement on the site'**
  String get achievementOpenOnSite;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
