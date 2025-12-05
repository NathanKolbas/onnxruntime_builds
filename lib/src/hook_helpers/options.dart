import 'dart:io';

import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:hex/hex.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

import 'environment.dart';

/// A class for exceptions that have source span information attached.
class SourceSpanException implements Exception {
  // This is a getter so that subclasses can override it.
  /// A message describing the exception.
  String get message => _message;
  final String _message;

  // This is a getter so that subclasses can override it.
  /// The span associated with this exception.
  ///
  /// This may be `null` if the source location can't be determined.
  SourceSpan? get span => _span;
  final SourceSpan? _span;

  SourceSpanException(this._message, this._span);

  /// Returns a string representation of `this`.
  ///
  /// [color] may either be a [String], a [bool], or `null`. If it's a string,
  /// it indicates an ANSI terminal color escape that should be used to
  /// highlight the span's text. If it's `true`, it indicates that the text
  /// should be highlighted using the default color. If it's `false` or `null`,
  /// it indicates that the text shouldn't be highlighted.
  @override
  String toString({Object? color}) {
    if (span == null) return message;
    return 'Error on ${span!.message(message, color: color)}';
  }
}

extension on YamlMap {
  /// Map that extracts keys so that we can do map case check on them.
  Map<dynamic, YamlNode> get valueMap =>
      nodes.map((key, value) => MapEntry(key.value, value));
}

class PrecompiledBinaries {
  final String uriPrefix;
  final PublicKey publicKey;

  PrecompiledBinaries({
    required this.uriPrefix,
    required this.publicKey,
  });

  static PublicKey _publicKeyFromHex(String key, SourceSpan? span) {
    final bytes = HEX.decode(key);
    if (bytes.length != 32) {
      throw SourceSpanException(
          'Invalid public key. Must be 32 bytes long.', span);
    }
    return PublicKey(bytes);
  }

  static PrecompiledBinaries parse(YamlNode node) {
    if (node case YamlMap(valueMap: Map<dynamic, YamlNode> map)) {
      if (map
          case {
            'url_prefix': YamlNode urlPrefixNode,
            'public_key': YamlNode publicKeyNode,
          }) {
        final urlPrefix = switch (urlPrefixNode) {
          YamlScalar(value: String urlPrefix) => urlPrefix,
          _ => throw SourceSpanException(
              'Invalid URL prefix value.', urlPrefixNode.span),
        };
        final publicKey = switch (publicKeyNode) {
          YamlScalar(value: String publicKey) =>
            _publicKeyFromHex(publicKey, publicKeyNode.span),
          _ => throw SourceSpanException(
              'Invalid public key value.', publicKeyNode.span),
        };
        return PrecompiledBinaries(
          uriPrefix: urlPrefix,
          publicKey: publicKey,
        );
      }
    }
    throw SourceSpanException(
        'Invalid precompiled binaries value. '
        'Expected Map with "url_prefix" and "public_key".',
        node.span);
  }

  static PrecompiledBinaries load() {
    final uri = Uri.file(Environment.precompiledBinariesConfigFile);
    final file = File.fromUri(uri);
    if (file.existsSync()) {
      final contents = loadYamlNode(file.readAsStringSync(), sourceUrl: uri);
      return parse(contents);
    } else {
      throw StateError('Missing ${Environment.precompiledBinariesConfigFile}');
    }
  }
}
