import 'package:flutter_test/flutter_test.dart';
import 'package:ra_insights/domain/insights/search.dart';
import 'package:ra_insights/domain/models/models.dart';

void main() {
  CompletionEntry entry(String title,
          {String console = 'SNES', int awarded = 5, int max = 10}) =>
      CompletionEntry.fromJson({
        'GameID': title.hashCode & 0xffff,
        'Title': title,
        'ConsoleID': 1,
        'ConsoleName': console,
        'MaxPossible': max,
        'NumAwarded': awarded,
        'NumAwardedHardcore': awarded,
      });

  final library = [
    entry('Super Mario World'),
    entry('Super Metroid', awarded: 9),
    entry('Sonic the Hedgehog', console: 'Mega Drive'),
    entry('Chrono Trigger'),
  ];

  test('an empty query returns nothing rather than everything', () {
    expect(searchGames(library, ''), isEmpty);
    expect(searchGames(library, '   '), isEmpty);
  });

  test('matches are case-insensitive and partial', () {
    final out = searchGames(library, 'metroid');
    expect(out.single.title, 'Super Metroid');
  });

  test('prefix matches rank above mid-string matches', () {
    final out = searchGames(library, 'super');
    expect(out.length, 2);
    // Both are prefix matches, so the more advanced one wins the tie.
    expect(out.first.title, 'Super Metroid');
  });

  test('console name is searchable too', () {
    final out = searchGames(library, 'mega drive');
    expect(out.single.title, 'Sonic the Hedgehog');
  });

  test('accents are normalised on both sides', () {
    final out = searchGames([entry('Pokémon Ruby')], 'pokemon');
    expect(out, isNotEmpty);
    expect(normalizeForSearch('Ação'), 'acao');
  });

  test('no match yields an empty list', () {
    expect(searchGames(library, 'zelda'), isEmpty);
  });
}
