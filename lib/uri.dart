/// A simple URI parser based on RFC-3986.
///
/// The accepted inputs and decomposition matches the example given in
/// Appendix B of the standard: https://tools.ietf.org/html/rfc3986#appendix-B.
///
/// For example:
///
/// ```dart
/// final result = uri.parse('https://example.com/foo?bar=baz#frag');
/// print(result.value.scheme); // https
/// print(result.value.hostname); // example.com
/// print(result.value.path); // /foo
/// print(result.value.fragment); // frag
/// ```
library;

import 'package:petitparser/petitparser.dart';

import 'src/uri/authority.dart' as lib_authority;
import 'src/uri/query.dart' as lib_query;

final uri =
    seq5(
      _scheme.skip(after: ':'.toParser()).optional(),
      _authority.skip(before: '//'.toParser()).optional(),
      _path,
      _query.skip(before: '?'.toParser()).optional(),
      _fragment.skip(before: '#'.toParser()).optional(),
    ).map5((scheme, authority, path, query, fragment) {
      final auth = lib_authority.authority.parse(authority ?? '').value;
      final params = lib_query.query.parse(query ?? '').value;
      return (
        scheme: scheme,
        authority: authority,
        username: auth.username,
        password: auth.password,
        hostname: auth.hostname,
        port: auth.port,
        path: path,
        query: query,
        params: params,
        fragment: fragment,
      );
    });

final _scheme = pattern('^:/?#').plusString(message: 'scheme');

final _authority = pattern('^/?#').starString(message: 'authority');

final _path = pattern('^?#').starString(message: 'path');

final _query = pattern('^#').starString(message: 'query');

final _fragment = any().starString(message: 'fragment');
