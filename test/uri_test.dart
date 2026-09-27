import 'package:meta/meta.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/uri.dart';
import 'package:test/test.dart';

import 'utils/expect.dart';

final parser = uri.end();

@isTest
void uriTest(
  String source, {
  String? scheme,
  String? authority,
  String? username,
  String? password,
  String? hostname,
  String? port,
  required String path,
  String? query,
  List<(String, String?)> params = const [],
  String? fragment,
}) {
  test(source, () {
    final result = parser.parse(source);
    expect(result.position, source.length);
    final value = result.value;
    expect(value.scheme, scheme);
    expect(value.authority, authority);
    expect(value.username, username);
    expect(value.password, password);
    expect(value.hostname, hostname);
    expect(value.port, port);
    expect(value.path, path);
    expect(value.query, query);
    expect(value.params, params);
    expect(value.fragment, fragment);
  });
}

void main() {
  test('linter', () {
    expect(linter(parser), isEmpty);
    expect(linter(authority), isEmpty);
    expect(linter(query), isEmpty);
  });
  uriTest(
    'http://www.ics.uci.edu/pub/ietf/uri/#Related',
    scheme: 'http',
    authority: 'www.ics.uci.edu',
    hostname: 'www.ics.uci.edu',
    path: '/pub/ietf/uri/',
    fragment: 'Related',
  );
  uriTest(
    'http://a/b/c/d;e?f&g=h',
    scheme: 'http',
    authority: 'a',
    hostname: 'a',
    path: '/b/c/d;e',
    query: 'f&g=h',
    params: [('f', null), ('g', 'h')],
  );
  uriTest(
    r'ftp://www.example.org:22/foo bar/zork<>?\^`{|}',
    scheme: 'ftp',
    authority: 'www.example.org:22',
    hostname: 'www.example.org',
    port: '22',
    path: '/foo bar/zork<>',
    query: r'\^`{|}',
    params: [(r'\^`{|}', null)],
  );
  uriTest(
    'data:text/plain;charset=iso-8859-7,hallo',
    scheme: 'data',
    path: 'text/plain;charset=iso-8859-7,hallo',
  );
  uriTest(
    'https://www.übermäßig.de/müßiggänger',
    scheme: 'https',
    authority: 'www.übermäßig.de',
    hostname: 'www.übermäßig.de',
    path: '/müßiggänger',
  );
  uriTest('http:test', scheme: 'http', path: 'test');
  uriTest(
    r'file:c:\\foo\\bar.html',
    scheme: 'file',
    path: r'c:\\foo\\bar.html',
  );
  uriTest(
    'file://foo:bar@localhost/test',
    scheme: 'file',
    authority: 'foo:bar@localhost',
    username: 'foo',
    password: 'bar',
    hostname: 'localhost',
    path: '/test',
  );
  group('https://mathiasbynens.be/demo/url-regex', () {
    for (final input in const [
      'http://foo.com/blah_blah',
      'http://foo.com/blah_blah/',
      'http://foo.com/blah_blah_(wikipedia)',
      'http://foo.com/blah_blah_(wikipedia)_(again)',
      'http://www.example.com/wpstyle/?p=364',
      'https://www.example.com/foo/?bar=baz&inga=42&quux',
      'http://✪df.ws/123',
      'http://userid:password@example.com:8080',
      'http://userid:password@example.com:8080/',
      'http://userid@example.com',
      'http://userid@example.com/',
      'http://userid@example.com:8080',
      'http://userid@example.com:8080/',
      'http://userid:password@example.com',
      'http://userid:password@example.com/',
      'http://142.42.1.1/',
      'http://142.42.1.1:8080/',
      'http://➡.ws/䨹',
      'http://⌘.ws',
      'http://⌘.ws/',
      'http://foo.com/blah_(wikipedia)#cite-1',
      'http://foo.com/blah_(wikipedia)_blah#cite-1',
      'http://foo.com/unicode_(✪)_in_parens',
      'http://foo.com/(something)?after=parens',
      'http://☺.damowmow.com/',
      'http://code.google.com/events/#&product=browser',
      'http://j.mp',
      'ftp://foo.bar/baz',
      'http://foo.bar/?q=Test%20URL-encoded%20stuff',
      'http://مثال.إختبار',
      'http://例子.测试',
      'http://उदाहरण.परीक्षा',
      'http://-.~_!\$&\'()*+,;=:%40:80%2f::::::@example.com',
      'http://1337.net',
      'http://a.b-c.de',
      'http://223.255.255.254',
    ]) {
      test(input, () => expect(parser, isSuccess(input)));
    }
  });
  group('authority failure edge-cases', () {
    final authParser = authority.end();

    test('malformed port with non-digits', () {
      expect(authParser, isFailure('example.com:abc'));
      expect(authParser, isFailure('example.com:80a'));
      expect(authParser, isFailure('example.com:80b9'));
      expect(authParser, isFailure('example.com:x1y2'));
    });

    test('malformed port with trailing colon and no digits', () {
      expect(authParser, isFailure('example.com:'));
      expect(authParser, isFailure('user:pass@example.com:'));
    });

    test('malformed port with negative sign or whitespace', () {
      expect(authParser, isFailure('example.com:-80'));
      expect(authParser, isFailure('example.com:+80'));
      expect(authParser, isFailure('example.com: 80'));
      expect(authParser, isFailure('example.com:80 '));
    });

    test('multiple port delimiters', () {
      expect(authParser, isFailure('example.com:80:80'));
      expect(authParser, isFailure('example.com:80:'));
    });

    test('missing username before password colon', () {
      expect(authParser, isFailure(':secret@example.com'));
      expect(authParser, isFailure(':secret@example.com:8080'));
    });

    test('malformed port with user credentials', () {
      expect(authParser, isFailure('user:pass@example.com:abc'));
      expect(authParser, isFailure('user:pass@example.com:80xyz'));
      expect(authParser, isFailure('user@example.com:invalid'));
    });

    test('malformed IPv6 host port separation', () {
      expect(authParser, isFailure('[::1]:abc'));
      expect(authParser, isFailure('[::1]:'));
      expect(authParser, isFailure('[2001:db8::1]:badport'));
    });

    test('trailing path or query delimiters unconsumed', () {
      expect(authParser, isFailure('example.com:80/path'));
      expect(authParser, isFailure('example.com:80?query'));
      expect(authParser, isFailure('example.com:80#frag'));
    });
  });

  group('query', () {
    test('parses multiple parameters', () {
      final result = query.parse('key1=val1&key2=val2&noval&empty=');
      expect(result, isA<Success<dynamic>>());
      final entries = (result.value as List).cast<(String, String?)>();
      expect(
        entries,
        equals([
          ('key1', 'val1'),
          ('key2', 'val2'),
          ('noval', null),
          ('empty', ''),
        ]),
      );
    });

    test('handles empty input and separator edge cases', () {
      final resultEmpty = query.parse('');
      expect(resultEmpty, isA<Success<dynamic>>());
      expect(resultEmpty.value, isEmpty);

      final resultSeparators = query.parse('&a=1&&b=2&');
      expect(resultSeparators, isA<Success<dynamic>>());
      final entries = (resultSeparators.value as List)
          .cast<(String, String?)>();
      expect(entries, equals([('a', '1'), ('b', '2')]));
    });
  });
}
