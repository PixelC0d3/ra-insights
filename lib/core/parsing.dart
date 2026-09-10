/// Tolerant coercions for the RetroAchievements Web API.
///
/// The API mixes types across endpoints (`"0"` vs `0`, `null` vs missing,
/// dates as `"2026-08-29 21:33:12"`), so every DTO goes through here instead
/// of relying on a cast that would blow up mid-parse.
library;

int asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is String) return int.tryParse(v.trim()) ?? double.tryParse(v.trim())?.round() ?? fallback;
  if (v is bool) return v ? 1 : 0;
  return fallback;
}

int? asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is String) {
    final t = v.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t) ?? double.tryParse(t)?.round();
  }
  return null;
}

double asDouble(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim()) ?? fallback;
  return fallback;
}

String asStr(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  if (v is String) return v;
  return v.toString();
}

bool asBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final t = v.trim().toLowerCase();
    return t == '1' || t == 'true';
  }
  return false;
}

/// The API returns `"YYYY-MM-DD HH:MM:SS"` (server time, UTC).
DateTime? asDate(dynamic v) {
  final s = asStr(v).trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s.replaceFirst(' ', 'T'));
}

/// `"YYYY-MM-DD"` slice of a raw API date string — the same key the userscript
/// groups by, so day bucketing stays byte-identical to the reference behaviour.
String? dayKeyOf(dynamic v) {
  final s = asStr(v).trim();
  if (s.length < 10) return null;
  return s.substring(0, 10);
}

String dayKeyOfDate(DateTime d) {
  final u = d;
  final m = u.month.toString().padLeft(2, '0');
  final day = u.day.toString().padLeft(2, '0');
  return '${u.year}-$m-$day';
}

/// Badge/icon paths come back relative (`/Badge/12345.png`).
String mediaUrl(String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return 'https://media.retroachievements.org$path';
}
