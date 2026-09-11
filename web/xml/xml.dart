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
final xpathOutput = document.querySelector('#xpath-output') as HTMLElement;

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
  late final List<Object> results;
  try {
    results = document.xpathEvaluate(xpathInput.value).toList();
    xpathError.innerText = '';
    xpathError.style.display = 'none';
  } catch (error) {
    xpathError.innerText = error.toString();
    xpathError.style.display = 'inline-block';
  }
  // Render the highlighted document.
  HighlightWriter(
    HtmlBuffer(domOutput),
    results.whereType<XmlNode>().toSet(),
  ).visit(document);
  // Render the XPath results.
  updateXPath(results);
}

void updateXPath(List<Object> results) {
  final list = document.createElement('ol');
  for (final result in results) {
    final element = document.createElement('li');
    element.appendChild(document.createTextNode(result.toString()));
    list.appendChild(element);
  }
  xpathOutput.replaceChildren(list);
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

const xmlPresets = {
  'books': (
    xml: '''<?xml version="1.0"?>
<bookshelf>
  <book>
    <title lang="en" pages="328" year="1949">Nineteen Eighty-Four</title>
    <author>George Orwell</author>
  </book>
  <book>
    <title lang="en" pages="234" year="1951">The Catcher in the Rye</title>
    <author>J. D. Salinger</author>
  </book>
  <book>
    <title lang="de" year="2005">
      Die Vermessung der Welt
    </title>
    <author>Daniel Kehlmann</author><publisher>Rowohlt</publisher>
  </book>
</bookshelf>''',
    xpath: '//book[title/@lang="en"]/author/text()',
  ),
  'store': (
    xml: '''<?xml version="1.0" encoding="UTF-8"?>
<store name="Tech Depot">
  <category name="Laptops">
    <item id="101" stock="15">
      <name>Pro Laptop 15"</name>
      <price currency="USD">1299.99</price>
    </item>
    <item id="102" stock="0">
      <name>Air Ultrabook 13"</name>
      <price currency="USD">999.00</price>
    </item>
  </category>
  <category name="Accessories">
    <item id="201" stock="42">
      <name>Wireless Mouse</name>
      <price currency="USD">29.99</price>
    </item>
  </category>
</store>''',
    xpath: '//item[@stock > 0 and price < 1000]/name/text()',
  ),
  'svg': (
    xml: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">
  <circle cx="50" cy="50" r="40" stroke="green" stroke-width="4" fill="yellow" />
  <rect x="20" y="20" width="30" height="30" fill="blue" id="rect1" />
  <text x="50" y="55" font-size="12" text-anchor="middle" fill="red">PetitParser</text>
</svg>''',
    xpath: '//@fill',
  ),
};

void setupTabs() {
  final tabButtons = document.querySelectorAll('.tab-btn');
  final panels = document.querySelectorAll('.output-panel');

  for (var i = 0; i < tabButtons.length; i++) {
    final btn = tabButtons.item(i) as HTMLButtonElement;
    btn.onClick.listen((_) {
      for (var j = 0; j < tabButtons.length; j++) {
        (tabButtons.item(j) as HTMLElement).classList.remove('active');
      }
      for (var j = 0; j < panels.length; j++) {
        (panels.item(j) as HTMLElement).classList.remove('active');
      }

      btn.classList.add('active');
      final tabId = btn.getAttribute('data-tab');
      final targetPanel =
          document.querySelector('#panel-$tabId') as HTMLElement?;
      targetPanel?.classList.add('active');
    });
  }
}

void loadPreset(String key) {
  final data = xmlPresets[key];
  if (data != null) {
    xmlInput.value = data.xml;
    xpathInput.value = data.xpath;
    update();
  }
}

class HtmlBuffer implements StringSink {
  new(Element root) {
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
  new(this.htmlBuffer, this.matches) : super(htmlBuffer);

  final HtmlBuffer htmlBuffer;

  final Set<XmlNode> matches;

  @override
  void visit(XmlHasVisitor node) => htmlBuffer.nest({
    'class': matches.contains(node) ? 'selection' : null,
    'title': node is XmlNode ? node.xpathGenerate() : null,
  }, () => super.visit(node));
}

void main() {
  setupTabs();

  final btnBooks =
      document.querySelector('#preset-books') as HTMLButtonElement?;
  final btnStore =
      document.querySelector('#preset-store') as HTMLButtonElement?;
  final btnSvg = document.querySelector('#preset-svg') as HTMLButtonElement?;

  btnBooks?.onClick.listen((_) => loadPreset('books'));
  btnStore?.onClick.listen((_) => loadPreset('store'));
  btnSvg?.onClick.listen((_) => loadPreset('svg'));

  xmlInput.onInput.listen((event) => update());
  xpathInput.onInput.listen((event) => update());
  domPretty.onInput.listen((event) => update());
  domOutput.onClick.listen(selectDom);
  update();
}
