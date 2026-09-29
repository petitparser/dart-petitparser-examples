import 'package:petitparser/petitparser.dart';

/// Normalizes a raw BibTeX field value to a clean display string.
///
/// The following transformations are applied:
/// - Outer braces `{...}` or quotes `"..."` are stripped.
/// - LaTeX formatting commands (`\emph{...}`, `\url{...}`, etc.) and font switches are unwrapped.
/// - LaTeX accent sequences in braced (e.g., `\"{o}`, `\'{e}`) or unbraced (e.g., `\"o`, `\'e`, `\c s`) forms are expanded.
/// - LaTeX special characters (e.g., `\&` → `&`, `\%` → `%`, `\_` → `_`) are unescaped.
/// - Standard HTML entities (e.g., `&#38;` → `&`, `&mdash;` → `—`) are decoded.
/// - Unless [key] is `'url'` or `'doi'`, `---` is replaced with an em dash (`—`)
///   and `--` with an en dash (`–`).
/// - Remaining unmatched `{` and `}` are removed.
///
/// ```dart
/// normalizeFieldValue('{pages 10--20}') == 'pages 10–20'
/// normalizeFieldValue('"A---B"') == 'A—B'
/// normalizeFieldValue(r'{D\"{o}derlein}') == 'Döderlein'
/// normalizeFieldValue(r'{Chi\c{s}}') == 'Chiș'
/// normalizeFieldValue(r'{Journal of Systems \& Software}') == 'Journal of Systems & Software'
/// ```
String normalizeFieldValue(String value, {String? key}) {
  var text = value.trim();
  while (_isEnclosed(text, '{', '}') || _isEnclosed(text, '"', '"')) {
    text = text.substring(1, text.length - 1).trim();
  }
  if (text.isEmpty) return '';

  final effectiveKey = key?.toLowerCase();
  final isUrlOrDoi = effectiveKey == 'url' || effectiveKey == 'doi';

  if (!text.contains(r'\') &&
      !text.contains('&') &&
      !text.contains('{') &&
      !text.contains('}') &&
      (isUrlOrDoi || !text.contains('--'))) {
    return text;
  }

  final decoder = isUrlOrDoi ? _urlDecoder : _normalDecoder;
  final result = decoder.parse(text);
  return result is Success ? result.value : text;
}

bool _isEnclosed(String text, String open, String close) {
  if (!text.startsWith(open) || !text.endsWith(close) || text.length < 2) {
    return false;
  }
  if (open == '"') {
    for (var i = 1; i < text.length - 1; i++) {
      if (text[i] == '"' && text[i - 1] != r'\') {
        return false;
      }
    }
    return true;
  }
  var depth = 0;
  for (var i = 0; i < text.length; i++) {
    if (text[i] == open && (i == 0 || text[i - 1] != r'\')) {
      depth++;
    } else if (text[i] == close && (i == 0 || text[i - 1] != r'\')) {
      depth--;
      if (depth == 0 && i < text.length - 1) {
        return false;
      }
    }
  }
  return depth == 0;
}

/// Grammar definition for decoding LaTeX field values into plain display strings.
class LatexDecoderDefinition extends GrammarDefinition<String> {
  /// Creates a decoder definition with optional [convertDashes] support.
  const new({this.convertDashes = true});

  /// Whether `---` and `--` should be converted to em and en dashes.
  final bool convertDashes;

  @override
  Parser<String> start() =>
      ref0(element).star().map((list) => list.join()).end();

  /// A single decoded element, allowing unmatched braces at top level.
  Parser<String> element() =>
      [ref0(safeElement), ref0(unmatchedBrace)].toChoiceParser();

  /// A decoded element inside braced structures where closing braces are preserved for delimiters.
  Parser<String> safeElement() => [
    if (convertDashes) ref0(dashes),
    ref0(htmlEntity),
    ref0(backslashCommand),
    ref0(bracedGroup),
    ref0(plainChunk),
    ref0(plainChar),
  ].toChoiceParser();

  /// Dashes.
  Parser<String> dashes() => [
    string('---').map((_) => '\u2014'),
    string('--').map((_) => '\u2013'),
  ].toChoiceParser();

  /// HTML entities: `&#38;`, `&#x26;`, `&mdash;`, `&ouml;`, and `\&#38;`.
  Parser<String> htmlEntity() => seq4(
    char(r'\').optional(),
    char('&'),
    [
      seq2(
        char('#'),
        [
          pattern('0-9a-fA-F')
              .plusString(message: 'hex digits')
              .skip(before: anyOf('xX'))
              .map(
                (hex) => _decodeCode(int.tryParse(hex, radix: 16), '&#x$hex;'),
              ),
          digit()
              .plusString(message: 'decimal digits')
              .map((dec) => _decodeCode(int.tryParse(dec), '&#$dec;')),
        ].toChoiceParser(),
      ).map2((_, decoded) => decoded),
      letter()
          .plusString(message: 'entity name')
          .map((name) => _htmlNamedEntities[name] ?? '&$name;'),
    ].toChoiceParser(),
    char(';'),
  ).map4((_, _, decoded, _) => decoded);

  /// All LaTeX commands and escapes starting with a backslash.
  Parser<String> backslashCommand() => [
    ref0(escapedBrace),
    ref0(escapedSymbol),
    ref0(singlePunctuation),
    ref0(troffFont),
    ref0(latexFontSwitch),
    ref0(formattingCommand),
    ref0(macroCommand),
    ref0(accent),
  ].toChoiceParser().skip(before: char(r'\'));

  /// Escaped literal braces `\{` and `\}`.
  Parser<String> escapedBrace() => anyOf('{}');

  /// Escaped LaTeX symbols like `\&`, `\%`, `\$`, `\#`, `\_`.
  Parser<String> escapedSymbol() => anyOf(r'&%$#_');

  /// Single-character punctuation escapes like `\\`, `\:`, `\-`, `\/`, `\–`.
  Parser<String> singlePunctuation() => [
    char(r'\').skip(after: whitespace().star()).map((_) => ' '),
    char(':').map((_) => ':'),
    char('–').map((_) => '\u2013'),
    anyOf('/-').map((_) => ''),
  ].toChoiceParser();

  /// Troff font switches like `\fI`, `\fR`.
  Parser<String> troffFont() => char('f').seq(anyOf('IRPB')).map((_) => '');

  /// LaTeX font switches like `\em`, `\it`, `\bf`, etc.
  Parser<String> latexFontSwitch() => seq2(
    [
      string('em'),
      string('it'),
      string('bf'),
      string('rm'),
      string('sf'),
      string('tt'),
    ].toChoiceParser(),
    string('{}').or(letter().not().seq(whitespace().star())),
  ).map((_) => '');

  /// Formatting commands unwrapping inner content: `\emph{...}`, `\textbf{...}`, `\url{...}`.
  Parser<String> formattingCommand() => seq4(
    [
      string('textbf'),
      string('textit'),
      string('texttt'),
      string('textsf'),
      string('textsc'),
      string('emph'),
      string('url'),
      string('path'),
      string('cite'),
    ].toChoiceParser(),
    char('{'),
    ref0(safeElement).star().map((list) => list.join()),
    char('}'),
  ).map4((_, _, content, _) => content);

  /// Target character for an accent, supporting dotless `\i`, `\j`, or regular letters.
  Parser<String> accentTarget() {
    final charParser = [
      anyOf('ij').skip(before: char(r'\')),
      letter(),
    ].toChoiceParser();
    return [
      charParser.trim().skip(before: char('{'), after: char('}')),
      charParser,
    ].toChoiceParser();
  }

  /// General LaTeX accents like `\"{o}`, `\"o`, `\c{s}`, `\cs`, `\'{\i}`, `\'\i`.
  Parser<String> accent() => seq2(
    anyOf("`'\"~^=c,vu.Hrkdb"),
    ref0(accentTarget).skip(before: whitespace().star()),
  ).map2((cmd, c) => _accents[cmd]?[c] ?? c);

  /// Word macros like `\ss`, `\ae`, `\alpha`, `\textemdash`, `\ldots`.
  Parser<String> macroCommand() => seq2(
    (_latexMacros.keys.toList()..sort((a, b) => b.length.compareTo(a.length)))
        .map(string)
        .toList()
        .toChoiceParser(),
    string('{}').or(letter().not()),
  ).map2((name, _) => _latexMacros[name] ?? name);

  /// Balanced curly braces `{...}` unwrapping inner content.
  Parser<String> bracedGroup() => seq3(
    char('{'),
    ref0(safeElement).star().map((list) => list.join()),
    char('}'),
  ).map3((_, content, _) => content);

  /// Stray unmatched curly braces removed.
  Parser<String> unmatchedBrace() => anyOf('{}').map((_) => '');

  /// Run of characters that do not start LaTeX escapes or delimiters.
  Parser<String> plainChunk() =>
      pattern(convertDashes ? r'^\&{}-' : r'^\&{}').plusString();

  /// Plain character matcher.
  Parser<String> plainChar() => pattern('^{}');
}

String _decodeCode(int? code, String fallback) =>
    code != null ? String.fromCharCode(code) : fallback;

final _normalDecoder = const LatexDecoderDefinition(convertDashes: true)
    .build();
final _urlDecoder = const LatexDecoderDefinition(convertDashes: false).build();

final _accents = <String, Map<String, String>>{
  '`': {
    'a': 'à',
    'A': 'À',
    'e': 'è',
    'E': 'È',
    'i': 'ì',
    'I': 'Ì',
    'o': 'ò',
    'O': 'Ò',
    'u': 'ù',
    'U': 'Ù',
  },
  "'": {
    'a': 'á',
    'A': 'Á',
    'e': 'é',
    'E': 'É',
    'i': 'í',
    'I': 'Í',
    'o': 'ó',
    'O': 'Ó',
    'u': 'ú',
    'U': 'Ú',
    'c': 'ć',
    'C': 'Ć',
    'y': 'ý',
    'Y': 'Ý',
    'n': 'ń',
    'N': 'Ń',
    'l': 'ĺ',
    'L': 'Ĺ',
    'r': 'ŕ',
    'R': 'Ŕ',
    's': 'ś',
    'S': 'Ś',
    'z': 'ź',
    'Z': 'Ź',
  },
  '^': {
    'a': 'â',
    'A': 'Â',
    'e': 'ê',
    'E': 'Ê',
    'i': 'î',
    'I': 'Î',
    'o': 'ô',
    'O': 'Ô',
    'u': 'û',
    'U': 'Û',
    'c': 'ĉ',
    'C': 'Ĉ',
    'g': 'ĝ',
    'G': 'Ĝ',
    'h': 'ĥ',
    'H': 'Ĥ',
    'j': 'ĵ',
    'J': 'Ĵ',
    's': 'ŝ',
    'S': 'Ŝ',
    'w': 'ŵ',
    'W': 'Ŵ',
    'y': 'ŷ',
    'Y': 'Ŷ',
  },
  '"': {
    'a': 'ä',
    'A': 'Ä',
    'e': 'ë',
    'E': 'Ë',
    'i': 'ï',
    'I': 'Ï',
    'o': 'ö',
    'O': 'Ö',
    'u': 'ü',
    'U': 'Ü',
    'y': 'ÿ',
    'Y': 'Ÿ',
    's': 'ß',
  },
  '~': {
    'a': 'ã',
    'A': 'Ã',
    'n': 'ñ',
    'N': 'Ñ',
    'o': 'õ',
    'O': 'Õ',
    'i': 'ĩ',
    'I': 'Ĩ',
    'u': 'ũ',
    'U': 'Ũ',
  },
  'c': {'c': 'ç', 'C': 'Ç', 's': 'ș', 'S': 'Ș', 't': 'ț', 'T': 'Ț'},
  ',': {'c': 'ç', 'C': 'Ç', 's': 'ș', 'S': 'Ș', 't': 'ț', 'T': 'Ț'},
  'v': {
    'c': 'č',
    'C': 'Č',
    's': 'š',
    'S': 'Š',
    'z': 'ž',
    'Z': 'Ž',
    'r': 'ř',
    'R': 'Ř',
    'd': 'ď',
    'D': 'Ď',
    't': 'ť',
    'T': 'Ť',
    'n': 'ň',
    'N': 'Ň',
    'e': 'ě',
    'E': 'Ě',
    'l': 'ľ',
    'L': 'Ľ',
    'a': 'ǎ',
    'A': 'Ǎ',
    'i': 'ǐ',
    'I': 'Ǐ',
    'o': 'ǒ',
    'O': 'Ǒ',
    'u': 'ǔ',
    'U': 'Ǔ',
  },
  'u': {
    'a': 'ă',
    'A': 'Ă',
    'g': 'ğ',
    'G': 'Ğ',
    'u': 'ŭ',
    'U': 'Ŭ',
    'e': 'ĕ',
    'E': 'Ĕ',
    'i': 'ĭ',
    'I': 'Ĭ',
    'o': 'ŏ',
    'O': 'Ŏ',
  },
  '=': {
    'a': 'ā',
    'A': 'Ā',
    'e': 'ē',
    'E': 'Ē',
    'i': 'ī',
    'I': 'Ī',
    'o': 'ō',
    'O': 'Ō',
    'u': 'ū',
    'U': 'Ū',
  },
  '.': {
    'z': 'ż',
    'Z': 'Ż',
    'c': 'ċ',
    'C': 'Ċ',
    'e': 'ė',
    'E': 'Ė',
    'g': 'ġ',
    'G': 'Ġ',
    'i': 'i',
    'I': 'İ',
  },
  'H': {'o': 'ő', 'O': 'Ő', 'u': 'ű', 'U': 'Ű'},
  'r': {'a': 'å', 'A': 'Å', 'u': 'ů', 'U': 'Ů'},
  'k': {
    'a': 'ą',
    'A': 'Ą',
    'e': 'ę',
    'E': 'Ę',
    'i': 'į',
    'I': 'Į',
    'u': 'ų',
    'U': 'Ų',
  },
  'd': {
    'a': 'ạ',
    'A': 'Ạ',
    'e': 'ẹ',
    'E': 'Ẹ',
    'i': 'ị',
    'I': 'Ị',
    'o': 'ọ',
    'O': 'Ọ',
    'u': 'ụ',
    'U': 'Ụ',
  },
  'b': {'a': 'ḇ', 'A': 'Ḇ'},
};

final _latexMacros = <String, String>{
  'ss': 'ß',
  'aa': 'å',
  'AA': 'Å',
  'o': 'ø',
  'O': 'Ø',
  'ae': 'æ',
  'AE': 'Æ',
  'oe': 'œ',
  'OE': 'Œ',
  'l': 'ł',
  'L': 'Ł',
  'i': 'ı',
  'j': 'ȷ',
  'LaTeX': 'LaTeX',
  'TeX': 'TeX',
  'BibTeX': 'BibTeX',
  'textquoteleft': '‘',
  'textquoteright': '’',
  'textquotedblleft': '“',
  'textquotedblright': '”',
  'textemdash': '—',
  'textendash': '–',
  'slash': '/',
  'ldots': '…',
  'dots': '…',
  'alpha': 'α',
  'beta': 'β',
  'gamma': 'γ',
  'lambda': 'λ',
  'omega': 'ω',
  'Theta': 'Θ',
  'times': '×',
  'wedge': '∧',
  'sim': '~',
  'neq': '≠',
  'tau': 'τ',
  'pi': 'π',
  'nu': 'ν',
  'pm': '±',
  'le': '≤',
  'ge': '≥',
  'ie': 'i.e.',
  'eg': 'e.g.',
};

final _htmlNamedEntities = <String, String>{
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'rsquo': '’',
  'lsquo': '‘',
  'rdquo': '”',
  'ldquo': '“',
  'mdash': '—',
  'ndash': '–',
  'hellip': '…',
  'nbsp': ' ',
  'ouml': 'ö',
  'Ouml': 'Ö',
  'auml': 'ä',
  'Auml': 'Ä',
  'uuml': 'ü',
  'Uuml': 'Ü',
  'eacute': 'é',
  'Eacute': 'É',
};
