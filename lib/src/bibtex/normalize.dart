/// Normalizes a BibTeX field name by capitalizing the first letter and any
/// letter immediately following a hyphen, lowercasing all other characters.
///
/// ```dart
/// normalizeFieldName('TITLE') == 'Title'
/// normalizeFieldName('archiveprefix') == 'Archiveprefix'
/// normalizeFieldName('booktitle') == 'Booktitle'
/// ```
String normalizeFieldName(String name) => name.toLowerCase().replaceAllMapped(
  _fieldNameBoundary,
  (m) => '${m[1]}${m[2]!.toUpperCase()}',
);

/// Normalizes a raw BibTeX field value to a clean display string.
///
/// The following transformations are applied:
/// - Outer braces `{...}` or quotes `"..."` are stripped.
/// - `---` is replaced with an em dash (`—`).
/// - `--` is replaced with an en dash (`–`).
/// - Common LaTeX accent sequences (e.g., `\'e` → `é`) are expanded.
/// - Remaining unmatched `{` and `}` are removed.
///
/// ```dart
/// normalizeFieldValue('{pages 10--20}') == 'pages 10–20'
/// normalizeFieldValue('"A---B"') == 'A—B'
/// normalizeFieldValue("{Lukas Renggli and St\\'ephane Ducasse}") ==
///     'Lukas Renggli and Stéphane Ducasse'
/// ```
String normalizeFieldValue(String value) {
  var text = value.trim();
  if ((text.startsWith('{') && text.endsWith('}')) ||
      (text.startsWith('"') && text.endsWith('"'))) {
    text = text.substring(1, text.length - 1).trim();
  }
  return text
      .replaceAll('---', '\u2014') // em dash first, before en dash
      .replaceAll('--', '\u2013') // en dash
      .replaceAll(r"\'a", 'á')
      .replaceAll(r'\"a', 'ä')
      .replaceAll(r'\`a', 'à')
      .replaceAll(r'\^a', 'â')
      .replaceAll(r"\'e", 'é')
      .replaceAll(r'\"e', 'ë')
      .replaceAll(r'\`e', 'è')
      .replaceAll(r'\^e', 'ê')
      .replaceAll(r"\'i", 'í')
      .replaceAll(r'\"i', 'ï')
      .replaceAll(r'\`i', 'ì')
      .replaceAll(r'\^i', 'î')
      .replaceAll(r"\'o", 'ó')
      .replaceAll(r'\"o', 'ö')
      .replaceAll(r'\`o', 'ò')
      .replaceAll(r'\^o', 'ô')
      .replaceAll(r"\'u", 'ú')
      .replaceAll(r'\"u', 'ü')
      .replaceAll(r'\`u', 'ù')
      .replaceAll(r'\^u', 'û')
      .replaceAll(r"\'c", 'ć')
      .replaceAll(r'\c{c}', 'ç')
      .replaceAll(r'\ss{}', 'ß')
      .replaceAll(r'\ss', 'ß')
      .replaceAll(r'{\em ', '') // italic markup
      .replaceAll(r'\{', '{')
      .replaceAll(r'\}', '}')
      .replaceAll(_remainingBraces, '');
}

/// Pattern matching the first character and any character after a hyphen,
/// used by [normalizeFieldName] to capitalize field name boundaries.
final _fieldNameBoundary = RegExp(r'(^|-)([a-z])');

/// Pattern matching unescaped braces left after LaTeX expansion,
/// used by [normalizeFieldValue] to strip structural BibTeX markup.
final _remainingBraces = RegExp(r'[{}]');
