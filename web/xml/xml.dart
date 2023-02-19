import 'dart:html';

import 'package:more/collection.dart';
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';
import 'package:xml/xpath.dart';

final xmlInput = querySelector('#input') as TextAreaElement;
final xpathInput = querySelector('#xpath') as TextInputElement;

final saxOutput = querySelector('#sax') as Element;
final domOutput = querySelector('#dom') as Element;
final xpathError = querySelector('#xpath-error') as Element;

Element appendString(Element element, String object) {
  object
      .split('\n')
      .where((each) => each.trim().isNotEmpty)
      .map<Node>((each) => Text(each))
      .separatedBy(() => Element.br())
      .forEach(element.append);
  return element;
}

void appendLine(Element target, String? data, {Iterable<String>? classes}) {
  final element = Element.div();
  if (classes != null) element.classes = classes;
  element.appendText(data.toString());
  target.append(element);
}

void appendSax(String type, [String? first, String? second]) {
  final element = Element.div();
  element.append(appendString(Element.span(), type));
  element.append(appendString(Element.span(), first ?? ''));
  element.append(appendString(Element.span(), second ?? ''));
  saxOutput.append(element);
}

void update() {
  // Clear the output
  domOutput.innerText = '';
  saxOutput.innerText = '';

  // Process the XML event stream
  final eventStream = Stream.value(xmlInput.value ?? '')
      .toXmlEvents(withLocation: true)
      .tapEachEvent(
        onCDATA: (event) => appendSax('CDATA', event.value),
        onComment: (event) => appendSax('Comment', event.value),
        onDeclaration: (event) => appendSax(
            'Declaration',
            event.attributes
                .map((attr) => '${attr.name}=${attr.value}')
                .join('\n')),
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
                .join('\n')),
        onText: (event) => appendSax('Text', event.value),
      )
      .handleError((error) =>
          appendLine(saxOutput, error.toString(), classes: ['error']));

  // Process the DOM stream
  eventStream.toXmlNodes().flatten().toList().then(
        (elements) => updateDom(elements),
        onError: (error) =>
            appendLine(domOutput, error.toString(), classes: ['error']),
      );
}

void updateDom(List<XmlNode> elements) {
  final document = XmlDocument(elements);

  final matches = <XmlNode>{};
  try {
    matches.addAll(document.xpath(xpathInput.value ?? ''));
    xpathError.innerText = '';
  } catch (error) {
    xpathError.innerText = error.toString();
  }

  HtmlPrettyWriter(HtmlBuffer(domOutput), matches).visit(document);
}

class HtmlBuffer extends StringSink {
  HtmlBuffer(Element root) {
    stack.add(root);
  }

  final List<Node> stack = [];

  void nest(String tag, void Function() function) {
    final element = Element.tag(tag);
    stack.last.append(element);
    stack.add(element);
    function();
    stack.removeLast();
  }

  @override
  void write(Object? object) {
    object
        .toString()
        .split('\n')
        .map<Node>((each) => Text(each))
        .separatedBy(() => Element.br())
        .forEach(stack.last.append);
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) =>
      throw UnimplementedError();

  @override
  void writeCharCode(int charCode) => throw UnimplementedError();

  @override
  void writeln([Object? object = ""]) => throw UnimplementedError();
}

class HtmlPrettyWriter extends XmlPrettyWriter {
  HtmlPrettyWriter(this.htmlBuffer, this.matches) : super(htmlBuffer);

  final HtmlBuffer htmlBuffer;

  final Set<XmlNode> matches;

  @override
  void visit(XmlHasVisitor node) {
    if (matches.contains(node)) {
      htmlBuffer.nest('strong', () => super.visit(node));
    } else {
      super.visit(node);
    }
  }
}

void main() {
  xmlInput.onInput.listen((event) => update());
  xpathInput.onInput.listen((event) => update());
  update();
}
