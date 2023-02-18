import 'dart:html';

import 'package:more/collection.dart';
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

final input = querySelector('#input')! as TextAreaElement;

final saxOutput = querySelector('#output #sax')!;
final domOutput = querySelector('#output #dom')!;

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
  domOutput.innerHtml = '';
  saxOutput.innerHtml = '';

  // Process the XML event stream
  final eventStream = Stream.value(input.value ?? '')
      .toXmlEvents(withLocation: true)
      .tapEachEvent(
        onCDATA: (event) => appendSax('CDATA', event.text),
        onComment: (event) => appendSax('Comment', event.text),
        onDeclaration: (event) => appendSax(
            'Declaration',
            event.attributes
                .map((attr) => '${attr.name}=${attr.value}')
                .join('\n')),
        onDoctype: (event) =>
            appendSax('Doctype', event.name, event.externalId?.toString()),
        onEndElement: (event) => appendSax('End Element', event.name),
        onProcessing: (event) =>
            appendSax('Processing', event.target, event.text),
        onStartElement: (event) => appendSax(
            'Element${event.isSelfClosing ? ' (self-closing)' : ''}',
            event.name,
            event.attributes
                .map((attr) => '${attr.name}=${attr.value}')
                .join('\n')),
        onText: (event) => appendSax('Text', event.text),
      )
      .handleError((error) =>
          appendLine(saxOutput, error.toString(), classes: ['error']));

  // Process the DOM stream
  eventStream
      .toXmlNodes()
      .flatten()
      .handleError((error) =>
          appendLine(domOutput, error.toString(), classes: ['error']))
      .where((node) => node is! XmlText || node.text.trim().isNotEmpty)
      .listen((node) => appendLine(domOutput, node.toXmlString(pretty: true)));
}

void main() {
  input.onInput.listen((event) => update());
  update();
}
