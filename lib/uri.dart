/// A simple URI parser based on RFC-3986.
///
/// The accepted inputs and decomposition matches the example given in
/// Appendix B of the standard: https://tools.ietf.org/html/rfc3986#appendix-B.
library;

import 'package:petitparser/petitparser.dart';

import 'src/uri/authority.dart' as lib_authority;
import 'src/uri/query.dart' as lib_query;

final uri =
    seq5(
      seq2(_scheme, ':'.toParser()).optional(),
      seq2('//'.toParser(), _authority).optional(),
      _path,
      seq2('?'.toParser(), _query).optional(),
      seq2('#'.toParser(), _fragment).optional(),
    ).map5(
      (scheme, authority, path, query, fragment) => <Symbol, dynamic>{
        #scheme: scheme?.$1,
        #authority: authority?.$2,
        ...lib_authority.authority.parse(authority?.$2 ?? '').value,
        #path: path,
        #query: query?.$2,
        #params: lib_query.query.parse(query?.$2 ?? '').value,
        #fragment: fragment?.$2,
      },
    );

final _scheme = pattern('^:/?#').plusString(message: 'scheme');

final _authority = pattern('^/?#').starString(message: 'authority');

final _path = pattern('^?#').starString(message: 'path');

final _query = pattern('^#').starString(message: 'query');

final _fragment = any().starString(message: 'fragment');
