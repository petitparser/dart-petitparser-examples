/// Type definition for JSON data.
typedef Json = Object? /* Map<String, Json>|List<Json>|String|bool|num|Null */;

/// Backwards-compatibility alias for [Json].
// ignore: remove_deprecations_in_breaking_versions
@Deprecated('Use Json instead')
typedef JSON = Json;
