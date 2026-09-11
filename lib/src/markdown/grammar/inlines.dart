import 'package:petitparser/petitparser.dart';

import '../ast.dart';
import 'lexical.dart';

/// Grammar mixin for inline Markdown constructs.
mixin MarkdownInlineGrammar
    on GrammarDefinition<DocumentNode>, MarkdownLexicalGrammar {
  /// Top-level sequence of inline nodes with consecutive text nodes merged.
  Parser<InlineNode> inlines() => ref0(inlineItem).plus().map(_combineInlines);

  /// Single inline item choice.
  Parser<InlineNode> inlineItem() => [
    ref0(codeSpan),
    ref0(directImage),
    ref0(directLink),
    ref0(autolink),
    ref0(strong),
    ref0(strikethrough),
    ref0(emphasis),
    ref0(rawHtmlInline),
    ref0(escapedCharNode),
    ref0(hardLineBreak),
    ref0(softLineBreak),
    ref0(plainTextRun),
    ref0(singleSpecialChar),
  ].toChoiceParser();

  /// Inline code span delimited by single, double, or triple backticks.
  Parser<CodeSpanNode> codeSpan() => [
    seq5(
      position(),
      string('```'),
      any().starLazy(string('```')).flatten(),
      string('```'),
      position(),
    ).map5(
      (start, _, code, _, stop) =>
          CodeSpanNode(_cleanCodeSpan(code), start: start, stop: stop),
    ),
    seq5(
      position(),
      string('``'),
      any().starLazy(string('``')).flatten(),
      string('``'),
      position(),
    ).map5(
      (start, _, code, _, stop) =>
          CodeSpanNode(_cleanCodeSpan(code), start: start, stop: stop),
    ),
    seq5(
      position(),
      char('`'),
      noneOf('`\r\n').plusString(),
      char('`'),
      position(),
    ).map5(
      (start, _, code, _, stop) =>
          CodeSpanNode(_cleanCodeSpan(code), start: start, stop: stop),
    ),
  ].toChoiceParser();

  static String _cleanCodeSpan(String code) {
    var s = code.replaceAll('\r\n', ' ').replaceAll('\n', ' ');
    if (s.length >= 2 &&
        s.startsWith(' ') &&
        s.endsWith(' ') &&
        s.trim().isNotEmpty) {
      s = s.substring(1, s.length - 1);
    }
    return s;
  }

  /// Autolink in angle brackets (`<http:...>` or `<email:...>`).
  Parser<AutolinkNode> autolink() =>
      [ref0(uriAutolink), ref0(emailAutolink)].toChoiceParser();

  /// URI autolink (`<scheme:...>`).
  Parser<AutolinkNode> uriAutolink() =>
      seq5(
        position(),
        char('<'),
        seq3(
          letter(),
          pattern('a-zA-Z0-9+.-').repeatString(1, 31),
          seq2(char(':'), pattern('^<>\r\n \t').plusString()).flatten(),
        ).flatten(),
        char('>'),
        position(),
      ).map5(
        (start, _, uri, _, stop) =>
            AutolinkNode(uri, isEmail: false, start: start, stop: stop),
      );

  /// Email autolink (`<name@domain>`).
  Parser<AutolinkNode> emailAutolink() =>
      seq5(
        position(),
        char('<'),
        seq3(
          pattern(r"a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-").plusString(),
          char('@'),
          pattern('a-zA-Z0-9.-').plusString(),
        ).flatten(),
        char('>'),
        position(),
      ).map5(
        (start, _, email, _, stop) =>
            AutolinkNode(email, isEmail: true, start: start, stop: stop),
      );

  /// Direct link (`[text](url "title")`).
  Parser<LinkNode> directLink() =>
      seq8(
        position(),
        char('['),
        ref0(linkText),
        char(']'),
        char('('),
        ref0(linkDestinationAndTitle),
        char(')'),
        position(),
      ).map8(
        (start, _, text, _, _, dest, _, stop) =>
            LinkNode(text, dest.$1, title: dest.$2, start: start, stop: stop),
      );

  /// Direct image (`![alt](url "title")`).
  Parser<ImageNode> directImage() =>
      seq8(
        position(),
        string('!['),
        ref0(linkText),
        char(']'),
        char('('),
        ref0(linkDestinationAndTitle),
        char(')'),
        position(),
      ).map8(
        (start, _, alt, _, _, dest, _, stop) =>
            ImageNode(alt, dest.$1, title: dest.$2, start: start, stop: stop),
      );

  /// Link text inside brackets.
  Parser<InlineNode> linkText() =>
      ref0(linkTextItem).star().map(_combineInlines);

  /// Single item inside link brackets (rejects unescaped `]`).
  Parser<InlineNode> linkTextItem() => seq2(
    char(']').not(),
    [
      ref0(directImage),
      ref0(codeSpan),
      ref0(strong),
      ref0(strikethrough),
      ref0(emphasis),
      ref0(escapedCharNode),
      ref0(bracketPlainTextRun),
      ref0(singleSpecialChar),
    ].toChoiceParser(),
  ).map2((_, node) => node);

  /// Destination URL and optional title inside parentheses.
  Parser<(String, String?)> linkDestinationAndTitle() => seq3(
    ref0(sp),
    ref0(linkUrl),
    seq2(ref0(spPlus), ref0(linkTitle)).map2((_, title) => title).optional(),
  ).map3((_, url, title) => (url, title));

  /// URL part of a link destination.
  Parser<String> linkUrl() => [
    seq3(
      char('<'),
      any().starLazy(char('>')).flatten(),
      char('>'),
    ).map3((_, u, _) => u),
    pattern('^ \t\r\n()').plusString(),
  ].toChoiceParser();

  /// Title part of a link destination.
  Parser<String> linkTitle() => [
    seq3(
      char('"'),
      any().starLazy(char('"')).flatten(),
      char('"'),
    ).map3((_, t, _) => t),
    seq3(
      char("'"),
      any().starLazy(char("'")).flatten(),
      char("'"),
    ).map3((_, t, _) => t),
    seq3(
      char('('),
      any().starLazy(char(')')).flatten(),
      char(')'),
    ).map3((_, t, _) => t),
  ].toChoiceParser();

  /// Strong emphasis (`**bold**` or `__bold__`).
  Parser<StrongNode> strong() => [
    seq5(
      position(),
      string('**'),
      ref0(strongAsteriskContent),
      string('**'),
      position(),
    ).map5(
      (start, _, content, _, stop) =>
          StrongNode(content, start: start, stop: stop),
    ),
    seq5(
      position(),
      string('__'),
      ref0(strongUnderscoreContent),
      string('__'),
      position(),
    ).map5(
      (start, _, content, _, stop) =>
          StrongNode(content, start: start, stop: stop),
    ),
  ].toChoiceParser();

  /// Content inside `**...**`.
  Parser<InlineNode> strongAsteriskContent() =>
      ref0(strongAsteriskItem).plus().map(_combineInlines);

  Parser<InlineNode> strongAsteriskItem() => seq2(
    string('**').not(),
    [
      ref0(codeSpan),
      ref0(strikethrough),
      ref0(emphasis),
      ref0(escapedCharNode),
      ref0(strongAsteriskTextRun),
      ref0(singleSpecialChar),
    ].toChoiceParser(),
  ).map2((_, node) => node);

  /// Content inside `__...__`.
  Parser<InlineNode> strongUnderscoreContent() =>
      ref0(strongUnderscoreItem).plus().map(_combineInlines);

  Parser<InlineNode> strongUnderscoreItem() => seq2(
    string('__').not(),
    [
      ref0(codeSpan),
      ref0(strikethrough),
      ref0(emphasis),
      ref0(escapedCharNode),
      ref0(strongUnderscoreTextRun),
      ref0(singleSpecialChar),
    ].toChoiceParser(),
  ).map2((_, node) => node);

  /// Regular emphasis (`*italic*` or `_italic_`).
  Parser<EmphasisNode> emphasis() => [
    seq5(
      position(),
      char('*'),
      ref0(emphasisAsteriskContent),
      char('*'),
      position(),
    ).map5(
      (start, _, content, _, stop) =>
          EmphasisNode(content, start: start, stop: stop),
    ),
    seq5(
      position(),
      char('_'),
      ref0(emphasisUnderscoreContent),
      char('_'),
      position(),
    ).map5(
      (start, _, content, _, stop) =>
          EmphasisNode(content, start: start, stop: stop),
    ),
  ].toChoiceParser();

  /// Content inside `*...*`.
  Parser<InlineNode> emphasisAsteriskContent() =>
      ref0(emphasisAsteriskItem).plus().map(_combineInlines);

  Parser<InlineNode> emphasisAsteriskItem() => seq2(
    char('*').not(),
    [
      ref0(codeSpan),
      ref0(strikethrough),
      ref0(escapedCharNode),
      ref0(emphasisAsteriskTextRun),
      ref0(singleSpecialChar),
    ].toChoiceParser(),
  ).map2((_, node) => node);

  /// Content inside `_..._`.
  Parser<InlineNode> emphasisUnderscoreContent() =>
      ref0(emphasisUnderscoreItem).plus().map(_combineInlines);

  Parser<InlineNode> emphasisUnderscoreItem() => seq2(
    char('_').not(),
    [
      ref0(codeSpan),
      ref0(strikethrough),
      ref0(escapedCharNode),
      ref0(emphasisUnderscoreTextRun),
      ref0(singleSpecialChar),
    ].toChoiceParser(),
  ).map2((_, node) => node);

  /// GFM strikethrough (`~~deleted~~`).
  Parser<StrikethroughNode> strikethrough() =>
      seq5(
        position(),
        string('~~'),
        ref0(strikethroughContent),
        string('~~'),
        position(),
      ).map5(
        (start, _, content, _, stop) =>
            StrikethroughNode(content, start: start, stop: stop),
      );

  Parser<InlineNode> strikethroughContent() =>
      ref0(strikethroughItem).plus().map(_combineInlines);

  Parser<InlineNode> strikethroughItem() => seq2(
    string('~~').not(),
    [
      ref0(codeSpan),
      ref0(strong),
      ref0(emphasis),
      ref0(escapedCharNode),
      ref0(strikethroughTextRun),
      ref0(singleSpecialChar),
    ].toChoiceParser(),
  ).map2((_, node) => node);

  /// Escaped character returning a [TextNode].
  Parser<TextNode> escapedCharNode() => seq3(
    position(),
    ref0(escapedChar),
    position(),
  ).map3((start, c, stop) => TextNode(c, start: start, stop: stop));

  /// Hard line break (2 trailing spaces or backslash before newline).
  Parser<LineBreakNode> hardLineBreak() => [
    seq3(
      position(),
      seq2(string('  ').plus(), ref0(newlineSequence)),
      position(),
    ).map3(
      (start, _, stop) => LineBreakNode(isHard: true, start: start, stop: stop),
    ),
    seq3(position(), seq2(char(r'\'), ref0(newlineSequence)), position()).map3(
      (start, _, stop) => LineBreakNode(isHard: true, start: start, stop: stop),
    ),
  ].toChoiceParser();

  /// Soft line break (simple newline).
  Parser<LineBreakNode> softLineBreak() =>
      seq3(position(), ref0(newlineSequence), position()).map3(
        (start, _, stop) =>
            LineBreakNode(isHard: false, start: start, stop: stop),
      );

  /// Raw inline HTML element.
  Parser<RawHtmlInlineNode> rawHtmlInline() =>
      seq3(
        position(),
        seq4(
          char('<'),
          char('/').optional(),
          pattern('a-zA-Z').plus(),
          any().starLazy(char('>')),
        ).flatten().then(char('>')).map((res) => '${res.$1}>'),
        position(),
      ).map3(
        (start, html, stop) =>
            RawHtmlInlineNode(html, start: start, stop: stop),
      );

  /// Plain non-special text run.
  Parser<TextNode> plainTextRun() => seq3(
    position(),
    noneOf('*_~`[]!<\\\r\n').plusString(),
    position(),
  ).map3((start, t, stop) => TextNode(t, start: start, stop: stop));

  Parser<TextNode> bracketPlainTextRun() => seq3(
    position(),
    noneOf(r'\]*_~`').plusString(),
    position(),
  ).map3((start, t, stop) => TextNode(t, start: start, stop: stop));

  Parser<TextNode> strongAsteriskTextRun() => seq3(
    position(),
    noneOf(r'*~`\').plusString(),
    position(),
  ).map3((start, t, stop) => TextNode(t, start: start, stop: stop));

  Parser<TextNode> strongUnderscoreTextRun() => seq3(
    position(),
    noneOf(r'_~`\').plusString(),
    position(),
  ).map3((start, t, stop) => TextNode(t, start: start, stop: stop));

  Parser<TextNode> emphasisAsteriskTextRun() => seq3(
    position(),
    noneOf(r'*~`\').plusString(),
    position(),
  ).map3((start, t, stop) => TextNode(t, start: start, stop: stop));

  Parser<TextNode> emphasisUnderscoreTextRun() => seq3(
    position(),
    noneOf(r'_~`\').plusString(),
    position(),
  ).map3((start, t, stop) => TextNode(t, start: start, stop: stop));

  Parser<TextNode> strikethroughTextRun() => seq3(
    position(),
    noneOf(r'~*`\').plusString(),
    position(),
  ).map3((start, t, stop) => TextNode(t, start: start, stop: stop));

  /// Fallback for standalone special characters (e.g. isolated `*` or `[`).
  Parser<TextNode> singleSpecialChar() => seq3(
    position(),
    any(),
    position(),
  ).map3((start, c, stop) => TextNode(c, start: start, stop: stop));

  /// Merges consecutive [TextNode]s into a single [TextNode] and unwraps single-item lists.
  static InlineNode _combineInlines(List<InlineNode> items) {
    if (items.isEmpty) return const TextNode('');
    final merged = <InlineNode>[];
    for (final item in items) {
      if (item is TextNode && item.text.isEmpty) {
        continue;
      }
      if (item is TextNode && merged.isNotEmpty && merged.last is TextNode) {
        final last = merged.removeLast() as TextNode;
        final start = last.start ?? item.start;
        final stop = item.stop ?? last.stop;
        merged.add(
          TextNode('${last.text}${item.text}', start: start, stop: stop),
        );
      } else {
        merged.add(item);
      }
    }
    if (merged.isEmpty) return const TextNode('');
    if (merged.length == 1) return merged.first;
    final firstStart = merged.first.start;
    final lastStop = merged.last.stop;
    return CompositeInlineNode(merged, start: firstStart, stop: lastStop);
  }
}
