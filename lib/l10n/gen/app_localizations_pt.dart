// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'RA Insights';

  @override
  String get appTagline =>
      'Análise do seu perfil RetroAchievements. App não oficial.';

  @override
  String get navInsights => 'Início';

  @override
  String get navGames => 'Jogos';

  @override
  String get navActivity => 'Atividade';

  @override
  String get navProgression => 'Progressão';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navChallenges => 'Desafios';

  @override
  String get actionRefresh => 'Atualizar';

  @override
  String get actionRetry => 'Tentar de novo';

  @override
  String get actionSearch => 'Buscar';

  @override
  String get actionSettings => 'Ajustes';

  @override
  String get actionPaste => 'Colar';

  @override
  String get actionSignIn => 'Entrar';

  @override
  String get actionSave => 'Salvar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionExpand => 'Ver conquistas';

  @override
  String get actionCollapse => 'Recolher';

  @override
  String get errorUnauthorized =>
      'Chave de API inválida. Confira em Settings → Web API Key no site do RetroAchievements.';

  @override
  String get errorNotFound => 'Não encontrado no RetroAchievements.';

  @override
  String get errorNetwork =>
      'Sem conexão com o RetroAchievements. Tente de novo.';

  @override
  String get errorRateLimited =>
      'A API está limitando as requisições. Aguarde alguns instantes.';

  @override
  String get errorParse => 'A resposta da API veio em um formato inesperado.';

  @override
  String get notFoundTitle => 'Nada encontrado';

  @override
  String get cachedData => 'dados em cache';

  @override
  String get updatedNever => 'nunca atualizado';

  @override
  String get updatedNow => 'atualizado agora';

  @override
  String updatedMinutes(int count) {
    return 'atualizado há $count min';
  }

  @override
  String updatedHours(int count) {
    return 'atualizado há $count h';
  }

  @override
  String updatedDays(int count) {
    return 'atualizado há $count d';
  }

  @override
  String get onboardingWhyTitle => 'Por que uma Web API Key?';

  @override
  String get onboardingWhyText =>
      'A Web API do RetroAchievements autentica cada requisição com o seu usuário mais a sua chave pessoal — não existe endpoint anônimo. Sem ela nenhuma tela do app consegue carregar dados.';

  @override
  String get onboardingWhereTitle => 'Onde achar a chave';

  @override
  String get onboardingSteps =>
      '1. Abra retroachievements.org/settings\n2. Role até \"Web API Key\"\n3. Copie a chave e cole aqui';

  @override
  String get onboardingOpenSettings => 'Abrir as configurações do RA';

  @override
  String get fieldUsername => 'Usuário do RetroAchievements';

  @override
  String get fieldApiKey => 'Web API Key';

  @override
  String get onboardingPrivacy =>
      'A chave fica só no seu aparelho, no keystore do Android. Não há servidor nem coleta de dados.';

  @override
  String get statGamesPlayed => 'Jogos jogados';

  @override
  String get statMasteries => 'Masteries';

  @override
  String get statMasteryRate => 'Taxa de mastery';

  @override
  String get statPoints => 'Pontos';

  @override
  String get cardPlayNow => 'O QUE JOGAR AGORA';

  @override
  String get cardStreak => 'STREAK';

  @override
  String get cardAlmostThere => 'QUASE LÁ';

  @override
  String get cardRarest => 'MAIS RARAS';

  @override
  String get streakAtRisk => 'em risco hoje';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dias seguidos',
      one: 'dia seguido',
      zero: 'dias seguidos',
    );
    return '$_temp0';
  }

  @override
  String streakSummary(int best, int active, int total) {
    return 'Melhor: $best dias · $active dias ativos · $total conquistas (365d)';
  }

  @override
  String get emptyStreak => 'Sem conquistas nos últimos 365 dias.';

  @override
  String get emptyAlmostThere => 'Nenhum jogo perto do mastery.';

  @override
  String get emptyRarest => 'Sem dados de raridade no período.';

  @override
  String remainingLine(int count, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'faltam $count conquistas',
      one: 'falta $count conquista',
      zero: 'nada faltando',
    );
    return '$_temp0 ($percent%)';
  }

  @override
  String playNowReason(int count, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltam $count conquistas ($percent%)',
      one: 'Falta $count conquista para o mastery',
      zero: 'Mastery completo',
    );
    return '$_temp0';
  }

  @override
  String activityEvents(int count) {
    return '$count eventos nos últimos 365 dias';
  }

  @override
  String get chipAchievements => 'Conquistas';

  @override
  String get chipMastered => 'Mastered';

  @override
  String get chipBeaten => 'Beaten';

  @override
  String get legendLess => 'menos';

  @override
  String get legendMore => 'mais';

  @override
  String get activityDayHint =>
      'Toque em um dia para ver só aquele dia. Toque de novo para limpar.';

  @override
  String activityShowingDay(String date) {
    return 'Mostrando $date';
  }

  @override
  String get activityClearDay => 'Limpar dia';

  @override
  String tabGamesCount(int count) {
    return 'Jogos ($count)';
  }

  @override
  String tabAchievementsCount(int count) {
    return 'Conquistas ($count)';
  }

  @override
  String get emptyActivityGames => 'Nenhum jogo neste filtro.';

  @override
  String get emptyActivityAchievements =>
      'Nenhuma conquista neste filtro. Masteries e beaten não têm conquistas próprias.';

  @override
  String achievementCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conquistas',
      one: '$count conquista',
      zero: '$count conquistas',
    );
    return '$_temp0';
  }

  @override
  String pointsShort(int count) {
    return '$count pts';
  }

  @override
  String get recentGamesTitle => 'Jogos recentes';

  @override
  String get gamesTabRecent => 'Recentes';

  @override
  String get gamesTabByConsole => 'Por console';

  @override
  String get recentShow => 'Mostrar';

  @override
  String recentPage(int page) {
    return 'página $page';
  }

  @override
  String recentAchievementsOf(int earned, int total) {
    return '$earned de $total conquistas';
  }

  @override
  String recentPointsOf(int earned, int total) {
    return '$earned de $total pontos';
  }

  @override
  String get recentNoAchievements => 'Sem conquistas ainda';

  @override
  String recentPlayedOn(String date) {
    return 'jogado em $date';
  }

  @override
  String get recentEmptyPage => 'Nenhum jogo nesta página.';

  @override
  String get pagerFirst => 'Primeira';

  @override
  String get pagerPrevious => 'Anterior';

  @override
  String get pagerNext => 'Próxima';

  @override
  String get seeFullList => 'Ver lista completa';

  @override
  String get badgeNoAchievements => 'Sem conquistas cadastradas.';

  @override
  String badgePointsAndRatio(int points, int ratio) {
    return '$points pts · TrueRatio $ratio';
  }

  @override
  String badgeUnlockedOn(String date) {
    return 'Desbloqueada em $date';
  }

  @override
  String get badgeHardcoreSuffix => ' (hardcore)';

  @override
  String get badgeStillLocked => 'Ainda bloqueada';

  @override
  String get rarityCommon => 'Comum';

  @override
  String get rarityUncommon => 'Incomum';

  @override
  String get rarityRare => 'Rara';

  @override
  String get rarityVeryRare => 'Muito rara';

  @override
  String get rarityUltraRare => 'Ultra rara';

  @override
  String rarityOfPlayers(String rate) {
    return '$rate dos jogadores desbloquearam';
  }

  @override
  String get rarityEstimated => 'estimada pelo TrueRatio';

  @override
  String get gameFallbackTitle => 'Jogo';

  @override
  String get gameOpenOnSite => 'Abrir no site';

  @override
  String get gameFilterAll => 'Todas';

  @override
  String get gameFilterEarned => '✅ Obtidas';

  @override
  String get gameFilterLocked => '🔒 Faltam';

  @override
  String gameProgressLine(int earned, int total, int percent) {
    return '$earned/$total conquistas · $percent%';
  }

  @override
  String gameRemainingSuffix(int count) {
    return ' · faltam $count';
  }

  @override
  String gamePointsLine(int earned, int total) {
    return '$earned/$total pontos';
  }

  @override
  String gameDifficultySuffix(int ratio) {
    return ' · dificuldade do que falta: $ratio TrueRatio médio';
  }

  @override
  String get gameEmptyFilter => 'Nenhuma conquista neste filtro.';

  @override
  String get achievementSearchHint => 'Buscar conquista';

  @override
  String get achievementEarned => 'obtida';

  @override
  String achievementEarnedOn(String date) {
    return 'obtida em $date';
  }

  @override
  String achievementEarnedOnCasual(String date) {
    return 'obtida em $date (casual)';
  }

  @override
  String get progressionTitle => 'Progressão';

  @override
  String get metricGames => 'jogos';

  @override
  String get metricMastered => 'mastered';

  @override
  String get metricBeaten => 'beaten';

  @override
  String get metricRate => 'taxa';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterWithProgress => 'Com progresso';

  @override
  String get filterMastered => 'Mastered';

  @override
  String consoleGameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogos',
      one: '$count jogo',
      zero: '$count jogos',
    );
    return '$_temp0';
  }

  @override
  String consoleBreakdown(int mastered, int beaten, int open) {
    return '$mastered mastered · $beaten beaten · $open em aberto';
  }

  @override
  String get emptyConsoles => 'Nenhum console neste filtro.';

  @override
  String get emptyConsoleGames => 'Nenhum jogo neste filtro.';

  @override
  String get searchTitle => 'Buscar';

  @override
  String get searchTabGames => 'Jogos';

  @override
  String get searchTabPlayers => 'Jogadores';

  @override
  String get searchGameHint => 'Nome do jogo ou do console';

  @override
  String get searchGameHelp =>
      'Busca entre os jogos que você já jogou — funciona offline. A API do RetroAchievements não expõe busca no catálogo completo.';

  @override
  String get searchGameEmpty => 'Nenhum jogo encontrado.';

  @override
  String get searchPlayerHint => 'Nome exato do jogador';

  @override
  String get searchPlayerHelp =>
      'A API só responde por nome exato — não há busca parcial de usuários. Abra o perfil para comparar pontos e rank com os seus, ver o mural e enviar uma mensagem.';

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
    return 'membro desde $year';
  }

  @override
  String get sectionMessage => 'MENSAGEM';

  @override
  String get messageHelp =>
      'A API oficial é somente leitura para mensagens: o envio acontece no site, já com o destinatário preenchido.';

  @override
  String get sendMessage => 'Enviar mensagem';

  @override
  String get openProfileOnSite => 'Abrir perfil no site';

  @override
  String get followPlayer => 'Seguir';

  @override
  String get followHelp =>
      'A API não expõe seguir: toque para abrir o perfil no site, onde o botão real fica.';

  @override
  String get sectionComparison => 'COMPARAÇÃO';

  @override
  String get comparisonNeedsDashboard =>
      'Abra o dashboard primeiro para comparar.';

  @override
  String get comparePoints => 'Pontos';

  @override
  String get compareRank => 'Rank';

  @override
  String get compareTie => 'Vocês estão empatados em pontos.';

  @override
  String compareAhead(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Você está $countString pontos à frente.';
  }

  @override
  String compareBehind(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Você está $countString pontos atrás.';
  }

  @override
  String get sectionWall => 'MURAL';

  @override
  String get emptyWall => 'Sem comentários no mural.';

  @override
  String get sectionAwards => 'PRÊMIOS';

  @override
  String get emptyAwards => 'Nenhum prêmio ainda.';

  @override
  String get profileTitle => 'Meu perfil';

  @override
  String profileMemberSince(String date) {
    return 'membro desde $date';
  }

  @override
  String get sectionScore => 'PONTUAÇÃO';

  @override
  String get profileRankPosition => 'Posição no ranking';

  @override
  String profileRankValue(int rank, int total) {
    final intl.NumberFormat rankNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rankString = rankNumberFormat.format(rank);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '#$rankString de $totalString';
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
  String get profilePoints => 'Pontos';

  @override
  String get profileWeightedPoints => 'Pontos ponderados (TrueRatio)';

  @override
  String get sectionCollection => 'COLEÇÃO';

  @override
  String get profileBeaten => 'Beaten';

  @override
  String get sectionActivity => 'ATIVIDADE';

  @override
  String get profileCurrentStreak => 'Streak atual';

  @override
  String get profileBestStreak => 'Melhor streak';

  @override
  String get profileActiveDays => 'Dias ativos (365d)';

  @override
  String get profileAchievements365 => 'Conquistas (365d)';

  @override
  String get activitySeeFull => 'Ver atividade completa';

  @override
  String profileDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '$count dia',
      zero: '$count dias',
    );
    return '$_temp0';
  }

  @override
  String get profileOpenOnSite => 'Abrir meu perfil no site';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAccountConnected => 'Conta conectada';

  @override
  String get settingsApiKey => 'Chave da Web API';

  @override
  String get settingsApiKeySubtitle => 'Trocar a chave guardada neste aparelho';

  @override
  String get settingsApiKeyUpdated => 'Chave atualizada';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Idioma do sistema';

  @override
  String get settingsClearCache => 'Limpar cache';

  @override
  String get settingsClearCacheSubtitle =>
      'Força uma releitura completa da API';

  @override
  String get settingsCacheCleared => 'Cache limpo';

  @override
  String get settingsSignOut => 'Sair';

  @override
  String get settingsSignOutSubtitle => 'Apaga a chave do aparelho';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get settingsAboutText =>
      'RA Insights é um app não oficial, sem vínculo com o RetroAchievements. Dados vindos da Web API oficial. Nada sai do seu aparelho.';

  @override
  String settingsVersion(String version) {
    return 'v$version';
  }

  @override
  String get rarestWindowAll => 'Tudo';

  @override
  String get rarestWindow90 => '90 dias';

  @override
  String get rarestWindow30 => '30 dias';

  @override
  String get cardChallenges => 'DESAFIOS';

  @override
  String get challengesTitle => 'Desafios';

  @override
  String get challengesSubtitle => 'Events do RetroAchievements';

  @override
  String get challengeFilterAll => 'Todos';

  @override
  String get challengeFilterInProgress => 'Em andamento';

  @override
  String get challengeFilterNotStarted => 'Não começados';

  @override
  String get challengeFilterCompleted => 'Concluídos';

  @override
  String challengeProgress(int earned, int total) {
    return '$earned/$total conquistas';
  }

  @override
  String get challengeEmpty => 'Nenhum desafio neste filtro.';

  @override
  String get challengeNotStarted => 'Não começado';

  @override
  String get challengeCompleted => 'Concluído';

  @override
  String get challengeNextUp => 'O QUE FAZER A SEGUIR';

  @override
  String get challengeAllDone =>
      'Todas as conquistas deste evento estão feitas.';

  @override
  String get challengeSeeAll => 'Ver todas as conquistas';

  @override
  String get challengeOpenOnSite => 'Abrir no site';

  @override
  String get challengeInLibrary => 'Você já joga';

  @override
  String get challengeNewGame => 'Jogo novo';

  @override
  String get challengeGuessNote =>
      'O jogo de cada linha é inferido do texto da conquista — a API não liga a conquista do evento ao jogo de origem, então trate como palpite. A interrogação marca os casos incertos.';

  @override
  String get challengeRulesNote =>
      'Events não exigem inscrição. Alguns, como a Challenge League, têm acompanhamento manual: poste seu progresso no tópico do fórum do evento para validação.';

  @override
  String challengePointsLeft(int points) {
    return 'faltam $points pontos';
  }

  @override
  String get challengeSearchHint => 'Buscar desafios';

  @override
  String get challengeSortClosest => 'Mais perto';

  @override
  String get challengeSortRecent => 'Recentes';

  @override
  String get challengeSortBiggest => 'Maiores';

  @override
  String get challengeBuildPlan => 'Montar um plano';

  @override
  String get challengePlanTitle => 'Seu plano';

  @override
  String challengePlanSummary(int count, int percent, int points) {
    return 'Estas $count te levam a $percent% e rendem $points pontos.';
  }

  @override
  String challengePlanMore(int count) {
    return 'Depois disso ainda faltam $count.';
  }

  @override
  String get challengePlanEmpty => 'Não há nada para planejar.';

  @override
  String get challengeRarityAvg => 'raridade média do que você fez aqui';

  @override
  String get rememberMe => 'Lembrar meus dados';

  @override
  String get rememberMeNote =>
      'Mantém seu usuário preenchido na próxima vez. A chave fica no keystore do aparelho.';

  @override
  String get splashTagline => 'Carregando seu perfil…';

  @override
  String get offlineBanner => 'Offline — mostrando dados salvos';

  @override
  String get achievementOpenOnSite => 'Abrir conquista no site';
}
