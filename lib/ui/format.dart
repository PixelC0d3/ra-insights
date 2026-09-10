/// Locale-aware formatting. Every number and date in the UI goes through here,
/// so a new language never needs a new `_months` list.
library;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String _localeOf(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// `5798` → `5.798` in pt, `5,798` in en.
String formatThousands(BuildContext context, int value) =>
    NumberFormat.decimalPattern(_localeOf(context)).format(value);

/// `30 de agosto de 2026` / `August 30, 2026`.
String formatLongDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMMd(_localeOf(context)).format(date);

/// `outubro de 2021` / `October 2021`.
String formatMonthYear(BuildContext context, DateTime date) =>
    DateFormat.yMMMM(_localeOf(context)).format(date);

/// `30/08/2026` / `8/30/2026`.
String formatShortDate(BuildContext context, DateTime date) =>
    DateFormat.yMd(_localeOf(context)).format(date);

/// `30/08` / `8/30` — the compact form used in dense list rows.
String formatDayMonth(BuildContext context, DateTime date) =>
    DateFormat.Md(_localeOf(context)).format(date);

/// `9.2%` / `9,2%`. One decimal below 10, none above — at 63% the tenth is
/// noise, at 0.4% it is the whole story.
String formatPercent(BuildContext context, double value) {
  final format = NumberFormat.decimalPatternDigits(
    locale: _localeOf(context),
    decimalDigits: value < 10 ? 1 : 0,
  );
  return '${format.format(value)}%';
}

/// A `YYYY-MM-DD` heatmap key rendered in the user's date format.
String formatDayKey(BuildContext context, String dayKey) {
  final parsed = DateTime.tryParse(dayKey);
  return parsed == null ? dayKey : formatShortDate(context, parsed);
}
