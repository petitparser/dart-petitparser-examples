import 'dart:js_interop';

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/regexp.dart';
import 'package:web/web.dart' hide Node;

final regexpInput = document.querySelector('#regexp-input') as HTMLInputElement;
final testInput = document.querySelector('#test-input') as HTMLTextAreaElement;
final errorBox = document.querySelector('#error-box') as HTMLElement;
final matchResultsBox =
    document.querySelector('#match-results-box') as HTMLElement;
final highlightContainer =
    document.querySelector('#highlight-container') as HTMLElement;
final matchCount = document.querySelector('#match-count') as HTMLElement;
final matchList = document.querySelector('#match-list') as HTMLElement;
final astContainer = document.querySelector('#ast-container') as HTMLElement;
final nfaTableBody = document.querySelector('#nfa-table-body') as HTMLElement;

/// Returns a collection of all NFA states reachable from the [nfa]'s start state.
List<NfaState> _collectNfaStates(Nfa nfa) {
  final allStates = <NfaState>[];
  final visited = <NfaState>{};

  void collect(NfaState state) {
    if (!visited.add(state)) return;
    allStates.add(state);
    for (final next in state.epsilons) {
      collect(next);
    }
    for (final next in state.transitions.values) {
      collect(next);
    }
    for (final next in state.dots) {
      collect(next);
    }
    for (final next in state.startAnchors) {
      collect(next);
    }
    for (final next in state.endAnchors) {
      collect(next);
    }
  }

  collect(nfa.start);
  // Ensure the end state is included even if it was somehow skipped.
  collect(nfa.end);

  return allStates;
}

/// Formats a single character code point into a human-readable string.
String _formatChar(int codePoint) {
  if (codePoint >= 32 && codePoint <= 126) {
    return "'${String.fromCharCode(codePoint)}'";
  }
  return '0x${codePoint.toRadixString(16).toUpperCase()}';
}

/// Escapes HTML special characters in the input [text].
String _escapeHtml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

/// Renders the given [node] AST as an HTML string.
String _renderAst(Node node) {
  final buffer = StringBuffer();
  _renderAstNode(node, buffer);
  return buffer.toString();
}

/// Recursively renders the given AST [node] into the [buffer].
void _renderAstNode(Node node, StringBuffer buffer) {
  buffer.write('<div class="ast-item">');
  if (node is EmptyNode) {
    buffer.write('<span class="ast-badge badge-empty">Empty</span>');
  } else if (node is LiteralNode) {
    final literalChar = String.fromCharCode(node.codePoint);
    buffer.write(
      '<span class="ast-badge badge-literal">Literal: <strong>${_escapeHtml(literalChar)}</strong></span>',
    );
  } else if (node is RangeNode) {
    final startChar = String.fromCharCode(node.startCodePoint);
    final endChar = String.fromCharCode(node.endCodePoint);
    buffer.write(
      '<span class="ast-badge badge-range">Range: <strong>${_escapeHtml(startChar)} - ${_escapeHtml(endChar)}</strong></span>',
    );
  } else if (node is DotNode) {
    buffer.write('<span class="ast-badge badge-dot">Dot (.)</span>');
  } else if (node is StartAnchorNode) {
    buffer.write(
      '<span class="ast-badge badge-anchor">Start Anchor (^)</span>',
    );
  } else if (node is EndAnchorNode) {
    buffer.write('<span class="ast-badge badge-anchor">End Anchor (\$)</span>');
  } else if (node is QuantificationNode) {
    final rangeStr = node.max == null
        ? '${node.min}+'
        : '${node.min} - ${node.max}';
    buffer.write(
      '<span class="ast-badge badge-quantifier">Quantifier: <strong>$rangeStr</strong></span>',
    );
    buffer.write('<div class="ast-node">');
    _renderAstNode(node.child, buffer);
    buffer.write('</div>');
  } else if (node is AlternationNode) {
    buffer.write(
      '<span class="ast-badge badge-alternation">Alternation (|)</span>',
    );
    buffer.write('<div class="ast-node">');
    _renderAstNode(node.left, buffer);
    buffer.write('</div>');
    buffer.write('<div class="ast-node">');
    _renderAstNode(node.right, buffer);
    buffer.write('</div>');
  } else if (node is ConcatenationNode) {
    buffer.write(
      '<span class="ast-badge badge-concatenation">Concatenation</span>',
    );
    buffer.write('<div class="ast-node">');
    _renderAstNode(node.left, buffer);
    buffer.write('</div>');
    buffer.write('<div class="ast-node">');
    _renderAstNode(node.right, buffer);
    buffer.write('</div>');
  } else if (node is ComplementNode) {
    buffer.write(
      '<span class="ast-badge badge-complement">Complement (!)</span>',
    );
    buffer.write('<div class="ast-node">');
    _renderAstNode(node.child, buffer);
    buffer.write('</div>');
  } else if (node is IntersectionNode) {
    buffer.write(
      '<span class="ast-badge badge-intersection">Intersection (&amp;)</span>',
    );
    buffer.write('<div class="ast-node">');
    _renderAstNode(node.left, buffer);
    buffer.write('</div>');
    buffer.write('<div class="ast-node">');
    _renderAstNode(node.right, buffer);
    buffer.write('</div>');
  } else {
    buffer.write(
      '<span class="ast-badge badge-empty">Unknown Node: ${node.runtimeType}</span>',
    );
  }
  buffer.write('</div>');
}

/// Selects the match highlight at the specified [index].
void _selectMatch(int index) {
  final activeHighlights = document.querySelectorAll('.match-highlight.active');
  for (var i = 0; i < activeHighlights.length; i++) {
    (activeHighlights.item(i) as HTMLElement).classList.remove('active');
  }

  final targetHighlight =
      document.querySelector('#match-$index') as HTMLElement?;
  targetHighlight?.classList.add('active');
}

/// Highlights the NFA state row at the specified [stateIdx] and scrolls it into view.
void _highlightNfaState(int stateIdx) {
  final activeRows = nfaTableBody.querySelectorAll('.state-row-active');
  for (var i = 0; i < activeRows.length; i++) {
    (activeRows.item(i) as HTMLElement).classList.remove('state-row-active');
  }

  final targetRow =
      document.querySelector('#state-row-$stateIdx') as HTMLElement?;
  if (targetRow != null) {
    targetRow.classList.add('state-row-active');
    targetRow.scrollIntoView();
  }
}

/// Updates the regular expression visualizations and match results.
void update() {
  final regexText = regexpInput.value;
  final testStr = testInput.value;

  // Clear previous state and hide/show sections
  errorBox.style.display = 'none';
  matchResultsBox.style.display = 'block';
  highlightContainer.textContent = '';
  matchList.textContent = '';
  astContainer.textContent = '';
  nfaTableBody.textContent = '';
  matchCount.textContent = '0';

  if (regexText.isEmpty) {
    highlightContainer.textContent = testStr;
    return;
  }

  try {
    // 1. Parse into AST
    final parseResult = nodeParser.parse(regexText);
    if (parseResult is Failure) {
      throw FormatException(
        'Parsing failed at position ${parseResult.position}: ${parseResult.message}',
      );
    }
    final node = parseResult.value;

    // Render AST structure
    astContainer.innerHTML = _renderAst(node).toJS;

    // 2. Convert to NFA
    Nfa nfa;
    try {
      nfa = node.toNfa();
    } on UnsupportedError catch (e) {
      throw FormatException('NFA Compilation Error: ${e.message}');
    }

    // Render NFA transitions table
    final allStates = _collectNfaStates(nfa);
    final stateIndices = <NfaState, int>{};
    for (var i = 0; i < allStates.length; i++) {
      stateIndices[allStates[i]] = i;
    }

    final nfaRows = StringBuffer();
    for (var i = 0; i < allStates.length; i++) {
      final state = allStates[i];
      final isStart = state == nfa.start;
      final isEnd = state.isEnd || state == nfa.end;

      var badgeClass = 'normal';
      var badgeLabel = 'S$i';
      if (isStart && isEnd) {
        badgeClass = 'start';
        badgeLabel = 'S$i (Start/End)';
      } else if (isStart) {
        badgeClass = 'start';
        badgeLabel = 'S$i (Start)';
      } else if (isEnd) {
        badgeClass = 'end';
        badgeLabel = 'S$i (Accept)';
      }

      final transitionsBuf = StringBuffer();
      for (final next in state.epsilons) {
        final targetIdx = stateIndices[next];
        transitionsBuf.write(
          '<span class="transition-item" data-target="$targetIdx">&epsilon; &rarr; <strong>S$targetIdx</strong></span> ',
        );
      }
      state.transitions.forEach((char, next) {
        final targetIdx = stateIndices[next];
        final charStr = _formatChar(char);
        transitionsBuf.write(
          '<span class="transition-item" data-target="$targetIdx">${_escapeHtml(charStr)} &rarr; <strong>S$targetIdx</strong></span> ',
        );
      });
      for (final next in state.dots) {
        final targetIdx = stateIndices[next];
        transitionsBuf.write(
          '<span class="transition-item" data-target="$targetIdx">. &rarr; <strong>S$targetIdx</strong></span> ',
        );
      }
      for (final next in state.startAnchors) {
        final targetIdx = stateIndices[next];
        transitionsBuf.write(
          '<span class="transition-item" data-target="$targetIdx">^ &rarr; <strong>S$targetIdx</strong></span> ',
        );
      }
      for (final next in state.endAnchors) {
        final targetIdx = stateIndices[next];
        transitionsBuf.write(
          '<span class="transition-item" data-target="$targetIdx">\$ &rarr; <strong>S$targetIdx</strong></span> ',
        );
      }

      if (transitionsBuf.isEmpty) {
        transitionsBuf.write('<em>(none)</em>');
      }

      nfaRows.write('''
        <tr id="state-row-$i">
          <td><span class="state-badge $badgeClass">$badgeLabel</span></td>
          <td><ul class="transition-list"><li>$transitionsBuf</li></ul></td>
        </tr>
      ''');
    }
    nfaTableBody.innerHTML = nfaRows.toString().toJS;

    // Attach click listeners to NFA transition items
    final transitionItems = nfaTableBody.querySelectorAll('.transition-item');
    for (var i = 0; i < transitionItems.length; i++) {
      final item = transitionItems.item(i) as HTMLElement;
      item.addEventListener(
        'click',
        (Event event) {
          final targetVal = item.getAttribute('data-target');
          if (targetVal != null) {
            final targetIdx = int.parse(targetVal);
            _highlightNfaState(targetIdx);
          }
        }.toJS,
      );
    }

    // 3. Find and Highlight Matches
    final matches = nfa.allMatches(testStr).toList();
    matchCount.textContent = matches.length.toString();

    final highlightHtml = StringBuffer();
    var lastIndex = 0;
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      if (match.start > lastIndex) {
        highlightHtml.write(
          _escapeHtml(testStr.substring(lastIndex, match.start)),
        );
      }
      final matchText = testStr.substring(match.start, match.end);
      highlightHtml.write(
        '<span class="match-highlight" id="match-$i" data-index="$i">${_escapeHtml(matchText.isEmpty ? "ε" : matchText)}</span>',
      );
      lastIndex = match.end;
    }
    if (lastIndex < testStr.length) {
      highlightHtml.write(_escapeHtml(testStr.substring(lastIndex)));
    }
    highlightContainer.innerHTML = highlightHtml.toString().toJS;

    // Render Match list items
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final matchText = testStr.substring(match.start, match.end);
      final item = document.createElement('li') as HTMLElement;
      item.style.padding = '0.3rem 0';
      item.style.borderBottom = '1px solid #eee';
      item.style.cursor = 'pointer';
      item.setAttribute('data-index', i.toString());

      final displayVal = matchText.isEmpty ? 'ε (empty match)' : matchText;
      item.innerHTML =
          '<strong>Match #$i:</strong> "${_escapeHtml(displayVal)}" (Range: ${match.start} to ${match.end})'
              .toJS;

      item.addEventListener(
        'click',
        (Event event) {
          _selectMatch(i);
        }.toJS,
      );
      matchList.appendChild(item);
    }

    // Attach click listeners to match highlight spans
    final highlights = document.querySelectorAll('.match-highlight');
    for (var i = 0; i < highlights.length; i++) {
      final hl = highlights.item(i) as HTMLElement;
      hl.addEventListener(
        'click',
        (Event event) {
          final indexStr = hl.getAttribute('data-index');
          if (indexStr != null) {
            final index = int.parse(indexStr);
            _selectMatch(index);
          }
        }.toJS,
      );
    }

    window.location.hash =
        '#${Uri.encodeComponent(regexText)}&${Uri.encodeComponent(testStr)}';
  } on Object catch (exception) {
    matchResultsBox.style.display = 'none';
    errorBox.textContent = exception.toString();
    errorBox.style.display = 'block';
  }
}

void main() {
  // Parse initial state from hash if present
  if (window.location.hash.startsWith('#')) {
    final hash = window.location.hash.substring(1);
    final parts = hash.split('&');
    if (parts.length >= 2) {
      regexpInput.value = Uri.decodeComponent(parts[0]);
      testInput.value = Uri.decodeComponent(parts[1]);
    } else if (parts.isNotEmpty) {
      regexpInput.value = Uri.decodeComponent(parts[0]);
    }
  }

  update();

  regexpInput.onInput.listen((event) => update());
  testInput.onInput.listen((event) => update());

  // Quick examples setup
  final buttons = document.querySelectorAll('.example-btn');
  for (var i = 0; i < buttons.length; i++) {
    final btn = buttons.item(i) as HTMLButtonElement;
    btn.addEventListener(
      'click',
      (Event event) {
        final regex = btn.getAttribute('data-regex');
        final test = btn.getAttribute('data-test');
        if (regex != null && test != null) {
          regexpInput.value = regex;
          testInput.value = test;
          update();
        }
      }.toJS,
    );
  }
}
