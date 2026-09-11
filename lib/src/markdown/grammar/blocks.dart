import 'package:petitparser/petitparser.dart';

import '../ast.dart';
import '../grammar.dart';
import 'inlines.dart';
import 'lexical.dart';

/// Grammar mixin for block-level Markdown constructs.
mixin MarkdownBlockGrammar
    on
        GrammarDefinition<DocumentNode>,
        MarkdownLexicalGrammar,
        MarkdownInlineGrammar {
  /// The root document consisting of zero or more blocks.
  Parser<DocumentNode> document() =>
      seq4(
        position(),
        ref0(blockItem).star(),
        ref0(blankLine).star(),
        position(),
      ).map4(
        (start, blocks, _, stop) =>
            DocumentNode(blocks, start: start, stop: stop),
      );

  /// A single block preceded by optional blank lines.
  Parser<BlockNode> blockItem() =>
      seq2(ref0(blankLine).star(), ref0(block)).map2((_, block) => block);

  /// Choice of all block types ordered by precedence.
  Parser<BlockNode> block() => [
    ref0(atxHeading),
    ref0(thematicBreak),
    ref0(fencedCodeBlock),
    ref0(indentedCodeBlock),
    ref0(table),
    ref0(blockquote),
    ref0(bulletList),
    ref0(orderedList),
    ref0(linkReferenceDefinition),
    ref0(paragraph),
  ].toChoiceParser();

  /// ATX heading (`# Heading` up to `###### Heading`).
  Parser<HeadingNode> atxHeading() =>
      seq7(
        position(),
        ref0(nonIndentSpace),
        pattern('#').repeatString(1, 6),
        ref0(spPlus),
        ref0(atxHeadingInlines),
        seq4(
          ref0(sp),
          pattern('#').star(),
          ref0(sp),
          [ref0(newlineSequence), endOfInput()].toChoiceParser(),
        ),
        position(),
      ).map7(
        (start, _, hashes, _, content, _, stop) => HeadingNode(
          hashes.length,
          _trimTrailing(content),
          start: start,
          stop: stop,
        ),
      );

  static InlineNode _trimTrailing(InlineNode node) {
    if (node is TextNode) {
      return TextNode(node.text.trimRight());
    }
    if (node is CompositeInlineNode && node.children.isNotEmpty) {
      final last = node.children.last;
      if (last is TextNode) {
        final newLast = TextNode(last.text.trimRight());
        final newChildren = [
          ...node.children.sublist(0, node.children.length - 1),
        ];
        if (newLast.text.isNotEmpty) {
          newChildren.add(newLast);
        }
        return newChildren.length == 1
            ? newChildren.first
            : CompositeInlineNode(newChildren);
      }
    }
    return node;
  }

  /// Content of an ATX heading, stopping before trailing `#` and newline.
  Parser<InlineNode> atxHeadingInlines() =>
      ref0(atxHeadingItem).star().map(_combineInlines);

  Parser<InlineNode> atxHeadingItem() => seq2(
    [
      ref0(newlineSequence),
      seq3(
        ref0(sp),
        pattern('#').plus(),
        seq2(ref0(sp), [ref0(newlineSequence), endOfInput()].toChoiceParser()),
      ),
    ].toChoiceParser().not(),
    [
      ref0(codeSpan),
      ref0(directImage),
      ref0(directLink),
      ref0(autolink),
      ref0(strong),
      ref0(strikethrough),
      ref0(emphasis),
      ref0(escapedCharNode),
      noneOf('#\r\n*_~`[]!<\\').plusString().map((t) => TextNode(t)),
      any().map((c) => TextNode(c)),
    ].toChoiceParser(),
  ).map2((_, node) => node);

  /// Horizontal rule / thematic break (`---`, `***`, `___`).
  Parser<ThematicBreakNode> thematicBreak() =>
      seq6(
        position(),
        ref0(nonIndentSpace),
        [
          seq3(
            char('*'),
            ref0(sp),
            char('*'),
          ).then(seq2(ref0(sp), char('*')).repeat(1, 100)),
          seq3(
            char('-'),
            ref0(sp),
            char('-'),
          ).then(seq2(ref0(sp), char('-')).repeat(1, 100)),
          seq3(
            char('_'),
            ref0(sp),
            char('_'),
          ).then(seq2(ref0(sp), char('_')).repeat(1, 100)),
        ].toChoiceParser(),
        ref0(sp),
        [ref0(newlineSequence), endOfInput()].toChoiceParser(),
        position(),
      ).map6(
        (start, _, _, _, _, stop) =>
            ThematicBreakNode(start: start, stop: stop),
      );

  /// Fenced code block (``` or ~~~).
  Parser<FencedCodeBlockNode> fencedCodeBlock() => [
    ref0(fencedCodeBlockBacktick),
    ref0(fencedCodeBlockTilde),
  ].toChoiceParser();

  Parser<FencedCodeBlockNode> fencedCodeBlockBacktick() =>
      seq7(
        position(),
        ref0(nonIndentSpace),
        string('```'),
        noneOf('`\r\n').starString(),
        ref0(newlineSequence),
        any()
            .starLazy(
              seq3(
                ref0(nonIndentSpace),
                string('```'),
                seq2(
                  ref0(sp),
                  [ref0(newlineSequence), endOfInput()].toChoiceParser(),
                ),
              ),
            )
            .flatten(),
        seq4(
          ref0(nonIndentSpace),
          string('```'),
          seq2(
            ref0(sp),
            [ref0(newlineSequence), endOfInput()].toChoiceParser(),
          ),
          position(),
        ),
      ).map7((start, _, _, infoRaw, _, code, close) {
        final info = infoRaw.trim();
        final stop = close.$4;
        return FencedCodeBlockNode(
          code,
          info: info.isEmpty ? null : info,
          start: start,
          stop: stop,
        );
      });

  Parser<FencedCodeBlockNode> fencedCodeBlockTilde() =>
      seq7(
        position(),
        ref0(nonIndentSpace),
        string('~~~'),
        noneOf('~\r\n').starString(),
        ref0(newlineSequence),
        any()
            .starLazy(
              seq3(
                ref0(nonIndentSpace),
                string('~~~'),
                seq2(
                  ref0(sp),
                  [ref0(newlineSequence), endOfInput()].toChoiceParser(),
                ),
              ),
            )
            .flatten(),
        seq4(
          ref0(nonIndentSpace),
          string('~~~'),
          seq2(
            ref0(sp),
            [ref0(newlineSequence), endOfInput()].toChoiceParser(),
          ),
          position(),
        ),
      ).map7((start, _, _, infoRaw, _, code, close) {
        final info = infoRaw.trim();
        final stop = close.$4;
        return FencedCodeBlockNode(
          code,
          info: info.isEmpty ? null : info,
          start: start,
          stop: stop,
        );
      });

  /// Indented code block (4 spaces or tab).
  Parser<IndentedCodeBlockNode> indentedCodeBlock() =>
      seq3(position(), ref0(indentedCodeLine).plus(), position()).map3(
        (start, lines, stop) =>
            IndentedCodeBlockNode(lines.join(), start: start, stop: stop),
      );

  Parser<String> indentedCodeLine() => seq2(
    ref0(indent),
    noneOf('\r\n')
        .starString()
        .then([ref0(newlineSequence), endOfInput()].toChoiceParser().flatten()),
  ).map2((_, line) => '${line.$1}${line.$2}');

  /// Blockquote (`> text`).
  Parser<BlockquoteNode> blockquote() =>
      seq3(position(), ref0(blockquoteLine).plus(), position()).map3((
        start,
        lines,
        stop,
      ) {
        final innerText = lines.join();
        final innerDoc = MarkdownGrammarDefinition.defaultParser.parse(
          innerText,
        );
        final children = innerDoc is Success<DocumentNode>
            ? innerDoc.value.blocks
            : <BlockNode>[];
        return BlockquoteNode(children, start: start, stop: stop);
      });

  Parser<String> blockquoteLine() =>
      seq3(ref0(nonIndentSpace), char('>'), char(' ').optional())
          .then(
            noneOf('\r\n').starString().then(
              [ref0(newlineSequence), endOfInput()].toChoiceParser().flatten(),
            ),
          )
          .map((res) => '${res.$2.$1}${res.$2.$2}');

  /// GFM Table (`| col 1 | col 2 |` with delimiter and data rows).
  Parser<TableNode> table() =>
      seq5(
        position(),
        ref0(tableHeaderRow),
        ref0(tableDelimiterRow),
        ref0(tableDataRow).star(),
        position(),
      ).map5((start, header, alignments, dataRows, stop) {
        final allRows = [header, ...dataRows];
        return TableNode(allRows, alignments, start: start, stop: stop);
      });

  Parser<TableRowNode> tableHeaderRow() =>
      seq5(
        position(),
        ref0(sp),
        ref0(tableRowCells),
        seq2(ref0(sp), ref0(newlineSequence)),
        position(),
      ).map5(
        (start, _, cells, _, stop) =>
            TableRowNode(cells, isHeader: true, start: start, stop: stop),
      );

  Parser<List<TableCellNode>> tableRowCells() => [
    // Form 1: starts with |
    seq3(
      char('|'),
      ref0(tableCellContent).plusSeparated(char('|')),
      char('|').optional(),
    ).map3((_, cells, _) => _cleanCells(cells.elements)),
    // Form 2: at least 2 cells separated by | without leading |
    seq2(
      ref0(tableCellContent),
      char('|').then(ref0(tableCellContent)).plus(),
    ).map2(
      (first, rest) =>
          [first, ...rest.map((r) => r.$2)].map(TableCellNode.new).toList(),
    ),
  ].toChoiceParser();

  static List<TableCellNode> _cleanCells(List<InlineNode> elements) {
    var list = elements;
    if (list.isNotEmpty &&
        list.last is TextNode &&
        (list.last as TextNode).text.trim().isEmpty) {
      list = list.sublist(0, list.length - 1);
    }
    return list.map(TableCellNode.new).toList();
  }

  Parser<List<TableAlignment>> tableDelimiterRow() => seq3(
    ref0(sp),
    [
      seq3(
        char('|'),
        ref0(tableDelimiterCell).plusSeparated(char('|')),
        char('|').optional(),
      ).map3((_, cells, _) {
        final elements = cells.elements;
        return elements;
      }),
      seq2(
        ref0(tableDelimiterCell),
        char('|').then(ref0(tableDelimiterCell)).plus(),
      ).map2((first, rest) => [first, ...rest.map((r) => r.$2)]),
    ].toChoiceParser(),
    seq2(ref0(sp), [ref0(newlineSequence), endOfInput()].toChoiceParser()),
  ).map3((_, alignments, _) => alignments);

  Parser<TableAlignment> tableDelimiterCell() =>
      seq4(
        ref0(sp),
        char(':').optional(),
        char('-').plus(),
        seq2(char(':').optional(), ref0(sp)),
      ).map4((_, leftColon, _, right) {
        final left = leftColon != null;
        final rightHasColon = right.$1 != null;
        if (left && rightHasColon) return TableAlignment.center;
        if (left) return TableAlignment.left;
        if (rightHasColon) return TableAlignment.right;
        return TableAlignment.none;
      });

  Parser<TableRowNode> tableDataRow() =>
      seq5(
        position(),
        ref0(sp),
        ref0(tableRowCells),
        seq2(ref0(sp), [ref0(newlineSequence), endOfInput()].toChoiceParser()),
        position(),
      ).map5(
        (start, _, cells, _, stop) =>
            TableRowNode(cells, isHeader: false, start: start, stop: stop),
      );

  Parser<InlineNode> tableCellContent() =>
      seq3(ref0(sp), ref0(tableCellItem).star(), ref0(sp)).map3((_, items, _) {
        final combined = _combineInlines(items);
        if (combined is TextNode) {
          return TextNode(
            combined.text.trim(),
            start: combined.start,
            stop: combined.stop,
          );
        }
        return combined;
      });

  Parser<InlineNode> tableCellItem() => seq2(
    [char('|'), ref0(newlineSequence)].toChoiceParser().not(),
    [
      ref0(codeSpan),
      ref0(directImage),
      ref0(directLink),
      ref0(autolink),
      ref0(strong),
      ref0(strikethrough),
      ref0(emphasis),
      ref0(escapedCharNode),
      noneOf('|\r\n*_~`[]!<\\').plusString().map((t) => TextNode(t)),
      any().map((c) => TextNode(c)),
    ].toChoiceParser(),
  ).map2((_, node) => node);

  /// Bullet list (`-`, `*`, `+`).
  Parser<BulletListNode> bulletList() =>
      seq3(position(), ref0(bulletListItem).plus(), position()).map3(
        (start, items, stop) =>
            BulletListNode(items, isTight: true, start: start, stop: stop),
      );

  Parser<ListItemNode> bulletListItem() =>
      seq6(
        position(),
        ref0(nonIndentSpace),
        pattern('-*+'),
        ref0(spPlus),
        ref0(listItemContent),
        position(),
      ).map6(
        (start, _, _, _, item, stop) => ListItemNode(
          item.children,
          isTask: item.isTask,
          isChecked: item.isChecked,
          start: start,
          stop: stop,
        ),
      );

  /// Ordered list (`1.`, `2.`).
  Parser<OrderedListNode> orderedList() =>
      seq3(position(), ref0(orderedListItem).plus(), position()).map3((
        start,
        items,
        stop,
      ) {
        final startNum = items.first.$1;
        final listItems = items.map((i) => i.$2).toList();
        return OrderedListNode(
          listItems,
          startNumber: startNum,
          isTight: true,
          start: start,
          stop: stop,
        );
      });

  Parser<(int, ListItemNode)> orderedListItem() =>
      seq6(
        position(),
        ref0(nonIndentSpace),
        digit().plusString().map(int.parse),
        char('.').then(ref0(spPlus)),
        ref0(listItemContent),
        position(),
      ).map6(
        (start, _, number, _, item, stop) => (
          number,
          ListItemNode(
            item.children,
            isTask: item.isTask,
            isChecked: item.isChecked,
            start: start,
            stop: stop,
          ),
        ),
      );

  /// Content of a list item, including optional GFM task checkbox `[ ]` or `[x]`.
  Parser<ListItemNode> listItemContent() =>
      seq5(
        position(),
        ref0(taskCheckbox).optional(),
        ref0(listItemInlines),
        seq2(ref0(sp), [ref0(newlineSequence), endOfInput()].toChoiceParser()),
        position(),
      ).map5((start, task, content, _, stop) {
        final p = ParagraphNode(
          content,
          start: content.start,
          stop: content.stop,
        );
        return ListItemNode(
          [p],
          isTask: task != null,
          isChecked: task,
          start: start,
          stop: stop,
        );
      });

  Parser<bool> taskCheckbox() => seq3(
    string('['),
    pattern(' xX'),
    string('] ').then(ref0(sp)),
  ).map3((_, check, _) => check.trim().toLowerCase() == 'x');

  /// Inlines for a single list item line, stopping before newline.
  Parser<InlineNode> listItemInlines() =>
      ref0(listItemInlineItem).plus().map(_combineInlines);

  Parser<InlineNode> listItemInlineItem() => seq2(
    ref0(newlineSequence).not(),
    [
      ref0(codeSpan),
      ref0(directImage),
      ref0(directLink),
      ref0(autolink),
      ref0(strong),
      ref0(strikethrough),
      ref0(emphasis),
      ref0(rawHtmlInline),
      ref0(escapedCharNode),
      noneOf('*_~`[]!<\\\r\n').plusString().map((t) => TextNode(t)),
      any().map((c) => TextNode(c)),
    ].toChoiceParser(),
  ).map2((_, node) => node);

  /// Link reference definition (`[label]: url "title"`).
  Parser<LinkReferenceDefinitionNode> linkReferenceDefinition() =>
      seq8(
        position(),
        ref0(nonIndentSpace),
        char('['),
        noneOf(']\r\n').plusString(),
        string(']:').then(ref0(sp)),
        ref0(linkDestinationAndTitle),
        seq2(ref0(sp), [ref0(newlineSequence), endOfInput()].toChoiceParser()),
        position(),
      ).map8(
        (start, _, _, label, _, dest, _, stop) => LinkReferenceDefinitionNode(
          label.toLowerCase(),
          dest.$1,
          title: dest.$2,
          start: start,
          stop: stop,
        ),
      );

  /// Standard paragraph of text.
  Parser<ParagraphNode> paragraph() =>
      seq4(
        position(),
        ref0(paragraphInlines),
        seq2(ref0(sp), [ref0(newlineSequence), endOfInput()].toChoiceParser()),
        position(),
      ).map4(
        (start, content, _, stop) =>
            ParagraphNode(content, start: start, stop: stop),
      );

  /// Inlines within a paragraph, spanning multiple lines until a blank line or block break.
  Parser<InlineNode> paragraphInlines() =>
      ref0(paragraphInlineItem).plus().map(_combineInlines);

  Parser<InlineNode> paragraphInlineItem() => seq2(
    [
      ref0(blankLine),
      ref0(atxHeading),
      ref0(thematicBreak),
      ref0(fencedCodeBlock),
      ref0(tableHeaderRow),
      ref0(blockquoteLine),
      ref0(bulletListItem),
      ref0(orderedListItem),
    ].toChoiceParser().not(),
    [
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
      noneOf('*_~`[]!<\\\r\n').plusString().map((t) => TextNode(t)),
      any().map((c) => TextNode(c)),
    ].toChoiceParser(),
  ).map2((_, node) => node);

  /// Helper to combine inlines and merge consecutive text nodes.
  static InlineNode _combineInlines(List<InlineNode> items) {
    if (items.isEmpty) return const TextNode('');
    final merged = <InlineNode>[];
    for (final item in items) {
      if (item is TextNode && item.text.isEmpty) {
        continue;
      }
      if (item is TextNode && merged.isNotEmpty && merged.last is TextNode) {
        final last = merged.removeLast() as TextNode;
        merged.add(TextNode('${last.text}${item.text}'));
      } else {
        merged.add(item);
      }
    }
    if (merged.isEmpty) return const TextNode('');
    if (merged.length == 1) return merged.first;
    return CompositeInlineNode(merged);
  }
}
