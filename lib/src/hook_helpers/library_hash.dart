import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:onnxruntime_builds/src/hook_helpers/environment.dart';

class LibraryHash {
  /// Computes a hash uniquely identifying content. This takes into account
  /// content .onnxruntime_version.
  static String compute() {
    return LibraryHash._()._compute();
  }

  LibraryHash._();

  String _compute() {
    final files = getFiles();
    return _computeHash(files);
  }

  String _computeHash(List<File> files) {
    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);

    void addTextFile(File file) {
      // text Files are hashed by lines in case we're dealing with github checkout
      // that auto-converts line endings.
      final splitter = LineSplitter();
      if (file.existsSync()) {
        final data = file.readAsStringSync();
        final lines = splitter.convert(data);
        for (final line in lines) {
          input.add(utf8.encode(line));
        }
      }
    }

    for (final file in files) {
      addTextFile(file);
    }

    input.close();
    final res = output.events.single;

    // Truncate to 128bits.
    final hash = res.bytes.sublist(0, 16);
    return hex.encode(hash);
  }

  List<File> getFiles() => [
    File(Environment.onnxruntimeVersionFile),
  ];
}
