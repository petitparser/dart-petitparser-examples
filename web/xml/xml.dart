import 'dart:js_interop';

import 'package:more/collection.dart';
import 'package:web/web.dart';
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';
import 'package:xml/xpath.dart';

final xmlInput = document.querySelector('#xml-input') as HTMLInputElement;
final xpathInput = document.querySelector('#xpath-input') as HTMLInputElement;
final xpathError = document.querySelector('#xpath-error') as HTMLElement;
final domPretty = document.querySelector('#dom-pretty') as HTMLInputElement;
final saxOutput = document.querySelector('#sax-output') as HTMLElement;
final domOutput = document.querySelector('#dom-output') as HTMLElement;

Element appendString(Element element, String object) {
  object
      .split('\n')
      .where((data) => data.trim().isNotEmpty)
      .map<Node>((data) => document.createTextNode(data))
      .separatedBy(() => document.createElement('br'))
      .forEach((node) => element.append(node));
  return element;
}

void appendLine(Element target, String? data, {Iterable<String>? classes}) {
  final element = document.createElement('div');
  if (classes != null) element.classList.value = classes.join(' ');
  element.append(document.createTextNode(data.toString()));
  target.append(element);
}

void appendSax(String type, [String? first, String? second]) {
  final element = document.createElement('div');
  element.append(appendString(document.createElement('span'), type));
  element.append(appendString(document.createElement('span'), first ?? ''));
  element.append(appendString(document.createElement('span'), second ?? ''));
  saxOutput.append(element);
}

void update() {
  // Clear the output
  domOutput.innerText = '';
  saxOutput.innerText = '';

  // Process the XML event stream
  final eventStream = Stream.value(xmlInput.value)
      .toXmlEvents(withLocation: true)
      .tapEachEvent(
        onCDATA: (event) => appendSax('CDATA', event.value),
        onComment: (event) => appendSax('Comment', event.value),
        onDeclaration: (event) => appendSax(
          'Declaration',
          event.attributes
              .map((attr) => '${attr.name}=${attr.value}')
              .join('\n'),
        ),
        onDoctype: (event) =>
            appendSax('Doctype', event.name, event.externalId?.toString()),
        onEndElement: (event) => appendSax('End Element', event.name),
        onProcessing: (event) =>
            appendSax('Processing', event.target, event.value),
        onStartElement: (event) => appendSax(
          'Element${event.isSelfClosing ? ' (self-closing)' : ''}',
          event.name,
          event.attributes
              .map((attr) => '${attr.name}=${attr.value}')
              .join('\n'),
        ),
        onText: (event) => appendSax('Text', event.value),
      )
      .handleError(
        (error) => appendLine(saxOutput, error.toString(), classes: ['error']),
      );

  // Process the DOM stream
  eventStream.toXmlNodes().flatten().toList().then(
    (elements) => updateDom(XmlDocument(elements)..normalize()),
    onError: (error) =>
        appendLine(saxOutput, error.toString(), classes: ['error']),
  );
}

void updateDom(XmlDocument document) {
  // If desired, pretty print the document.
  if (domPretty.checked == true) {
    document = XmlDocument.parse(document.toXmlString(pretty: true));
  }
  // Find the XPath matches.
  final matches = <XmlNode>{};
  try {
    matches.addAll(document.xpath(xpathInput.value));
    xpathError.innerText = '';
  } catch (error) {
    xpathError.innerText = error.toString();
  }
  // Render the highlighted document.
  HighlightWriter(HtmlBuffer(domOutput), matches).visit(document);
}

void selectDom(MouseEvent event) {
  for (
    var node = event.target as Node?;
    node != null && node != domOutput;
    node = node.parentNode
  ) {
    if (node.isA<HTMLElement>()) {
      final element = node as HTMLElement;
      final path = element.getAttribute('title');
      if (path != null && path.isNotEmpty) {
        xpathInput.value = path;
        update();
        break;
      }
    }
  }
}

class HtmlBuffer implements StringSink {
  HtmlBuffer(Element root) {
    stack.add(root);
  }

  final List<Node> stack = [];

  void nest(Map<String, String?> attributes, void Function() function) {
    final element = document.createElement('span');
    for (final MapEntry(:key, :value) in attributes.entries) {
      if (value != null && value.isNotEmpty) {
        element.setAttribute(key, value);
      }
    }
    stack.last.appendChild(element);
    stack.add(element);
    function();
    stack.removeLast();
  }

  @override
  void write(Object? object) {
    object
        .toString()
        .split('\n')
        .map<Node>((data) => document.createTextNode(data))
        .separatedBy(() => document.createElement('br'))
        .forEach((node) => stack.last.appendChild(node));
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) =>
      throw UnimplementedError();

  @override
  void writeCharCode(int charCode) => throw UnimplementedError();

  @override
  void writeln([Object? object = ""]) => throw UnimplementedError();
}

class HighlightWriter extends XmlWriter {
  HighlightWriter(this.htmlBuffer, this.matches) : super(htmlBuffer);

  final HtmlBuffer htmlBuffer;

  final Set<XmlNode> matches;

  @override
  void visit(XmlHasVisitor node) => htmlBuffer.nest({
    'class': matches.contains(node) ? 'selection' : null,
    'title': node is XmlNode ? node.xpathGenerate() : null,
  }, () => super.visit(node));
}

void main() {
  xmlInput.onInput.listen((event) => update());
  xpathInput.onInput.listen((event) => update());
  domPretty.onInput.listen((event) => update());
  domOutput.onClick.listen(selectDom);
  update();
}
