/// The comment list rendered on both the signed-in user's own wall (Profile
/// tab) and another player's wall (Player page) — same shape, same endpoint,
/// only the username differs.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../app/theme.dart';
import '../../domain/models/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/ui.dart';

final _urlPattern = RegExp(r'https?://\S+', caseSensitive: false);
final _imageExtension =
    RegExp(r'\.(png|jpe?g|gif|webp)(\?\S*)?$', caseSensitive: false);

/// A small, fixed palette so every avatar matches the app's own accents
/// instead of picking arbitrary Material colors.
const _avatarPalette = [
  RaColors.achievements,
  RaColors.mastered,
  RaColors.points,
  RaColors.streak,
  RaColors.rarityUncommon,
  RaColors.beaten,
];

Color _colorFor(String name) =>
    _avatarPalette[name.hashCode.abs() % _avatarPalette.length];

class WallComments extends StatelessWidget {
  const WallComments({super.key, required this.comments});
  final List<UserComment> comments;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (comments.isEmpty) return EmptyView(l.emptyWall);

    return Column(
      children: [
        for (final c in comments.take(15))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CommentBubble(comment: c),
          ),
      ],
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({required this.comment});
  final UserComment comment;

  @override
  Widget build(BuildContext context) {
    final c = comment;
    final color = _colorFor(c.user);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RaColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        // A hairline in the commenter's own color reads as identity at a
        // glance, the same trick RarityChip and the badge borders already use
        // elsewhere in the app.
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: color.withValues(alpha: 0.22),
                child: Text(
                  c.user.isEmpty ? '?' : c.user[0].toUpperCase(),
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: color),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(c.user,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
              if (c.submitted != null)
                Text(formatShortDate(context, c.submitted!),
                    style:
                        const TextStyle(fontSize: 10.5, color: RaColors.muted)),
            ],
          ),
          const SizedBox(height: 6),
          _LinkifiedText(c.commentText),
        ],
      ),
    );
  }
}

/// Splits the comment into plain text and tappable links, and loads what a
/// link actually points to instead of leaving it as raw text to copy
/// elsewhere: a YouTube link gets an embedded, playable player; a direct
/// image link gets rendered inline. Anything else opens with
/// [LaunchMode.inAppBrowserView] — a Custom Tab / SFSafariViewController that
/// stays inside the app's task instead of switching to a separate browser app.
///
/// Parsing (and creating the YouTube controllers) happens once in [initState],
/// not on every [build] — a [YoutubePlayerController] owns a WebView, and
/// recreating one per rebuild would reload the player each time.
class _LinkifiedText extends StatefulWidget {
  const _LinkifiedText(this.text);
  final String text;

  @override
  State<_LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<_LinkifiedText> {
  final _recognizers = <TapGestureRecognizer>[];
  final _images = <String>[];
  final _videoControllers = <YoutubePlayerController>[];
  late final List<InlineSpan> _spans;

  @override
  void initState() {
    super.initState();
    _spans = _parse(widget.text);
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    for (final c in _videoControllers) {
      c.close();
    }
    super.dispose();
  }

  void _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);

  List<InlineSpan> _parse(String text) {
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in _urlPattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      // Trailing punctuation ("check this out: https://x.com/a.png.") reads
      // as part of the sentence, not the link.
      var url = match.group(0)!;
      var trail = '';
      while (url.isNotEmpty && '.,;:!?)'.contains(url[url.length - 1])) {
        trail = url[url.length - 1] + trail;
        url = url.substring(0, url.length - 1);
      }

      final recognizer = TapGestureRecognizer()..onTap = () => _open(url);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: url,
        style: const TextStyle(
            color: RaColors.achievements, decoration: TextDecoration.underline),
        recognizer: recognizer,
      ));
      if (trail.isNotEmpty) spans.add(TextSpan(text: trail));

      final videoId = YoutubePlayerController.convertUrlToId(url);
      if (videoId != null) {
        _videoControllers.add(YoutubePlayerController.fromVideoId(
          videoId: videoId,
          // Loaded but not playing: a wall of auto-playing videos would be
          // both a data cost and a racket. One tap on the thumbnail starts it.
          autoPlay: false,
          params: const YoutubePlayerParams(showControls: true),
        ));
      } else if (_imageExtension.hasMatch(url)) {
        _images.add(url);
      }
      cursor = match.end;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
                fontSize: 12, height: 1.35, color: Colors.white),
            children: _spans,
          ),
        ),
        for (final controller in _videoControllers)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: YoutubePlayer(controller: controller),
            ),
          ),
        for (final url in _images)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onTap: () => _open(url),
                child: Image.network(
                  url,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
