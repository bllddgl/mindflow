import 'package:flutter/material.dart';
import 'package:reading_engine/reading_engine.dart';

/// Renders the current [WordChunk]: an image if the chunk is an image
/// block, an ORP-highlighted single word (the classic pivot-letter
/// technique) if there's exactly one word, or the chunk's words wrapped
/// across a configurable number of lines otherwise.
class RsvpDisplay extends StatelessWidget {
  final WordChunk? chunk;
  final int lineCount;
  final double fontSize;

  const RsvpDisplay({super.key, required this.chunk, required this.lineCount, this.fontSize = 42});

  /// The font size is the user's own choice (see Settings / the reader's
  /// tune sheet) -- this only shrinks it further, automatically, when
  /// more lines or more words-per-group are requested, so a busier
  /// layout still fits the screen instead of overflowing. Single-word
  /// chunks always render at the exact chosen size.
  double _effectiveFontSize(int wordsInChunk) {
    if (wordsInChunk <= 1) return fontSize;
    final lineFactor = 1 - (lineCount - 1) * 0.08;
    final densityFactor = 1 - (wordsInChunk.clamp(0, 20) * 0.015);
    final factor = (lineFactor * densityFactor).clamp(0.35, 1.0);
    return fontSize * factor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = chunk;

    if (current == null) {
      return Text('...', style: theme.textTheme.headlineSmall);
    }

    if (current.isImage) {
      final ref = current.imageRef;
      if (ref != null && (ref.startsWith('http://') || ref.startsWith('https://'))) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(ref, height: 220, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 64)),
        );
      }
      return const Icon(Icons.image_outlined, size: 64);
    }

    final words = current.words;
    if (words.isEmpty) {
      return Text('Ready.', style: theme.textTheme.headlineSmall);
    }

    if (words.length == 1) {
      return _OrpWord(word: words.first, fontSize: fontSize);
    }

    final effectiveSize = _effectiveFontSize(words.length);
    final lines = _wrapIntoLines(words, lineCount);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: lines
          .map((line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  line.join(' '),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontSize: effectiveSize, fontWeight: FontWeight.w600),
                ),
              ))
          .toList(),
    );
  }

  List<List<String>> _wrapIntoLines(List<String> words, int lineCount) {
    final effective = lineCount.clamp(1, words.length);
    final base = words.length ~/ effective;
    final remainder = words.length % effective;
    final lines = <List<String>>[];
    var cursor = 0;
    for (var i = 0; i < effective; i++) {
      final size = base + (i < remainder ? 1 : 0);
      lines.add(words.sublist(cursor, cursor + size));
      cursor += size;
    }
    return lines;
  }
}

class _OrpWord extends StatelessWidget {
  final String word;
  final double fontSize;
  const _OrpWord({required this.word, required this.fontSize});

  int get _pivotIndex {
    if (word.isEmpty) return 0;
    return (word.length * 0.35).round().clamp(0, word.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pivot = _pivotIndex;
    final before = word.substring(0, pivot);
    final pivotChar = word.substring(pivot, pivot + 1);
    final after = word.substring(pivot + 1);

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 0,
          bottom: 0,
          child: Container(width: 2, color: theme.colorScheme.primary.withOpacity(0.25)),
        ),
        RichText(
          text: TextSpan(
            style: theme.textTheme.displaySmall?.copyWith(fontSize: fontSize, fontWeight: FontWeight.w600),
            children: [
              TextSpan(text: before, style: TextStyle(color: theme.colorScheme.onSurface)),
              TextSpan(text: pivotChar, style: TextStyle(color: theme.colorScheme.primary)),
              TextSpan(text: after, style: TextStyle(color: theme.colorScheme.onSurface)),
            ],
          ),
        ),
      ],
    );
  }
}
