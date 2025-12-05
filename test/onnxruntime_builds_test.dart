import 'dart:ffi';

import 'package:onnxruntime_builds/onnxruntime_builds.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    test('First Test', () {
      final libPath = MyLibrary.initializeOrt();

      // final process = DynamicLibrary.open('package:onnxruntime_builds/onnxruntime.dll');
      // final process = DynamicLibrary.open('onnxruntime.dll');
      // final process = DynamicLibrary.open('libonnxruntime.so');
      final process = DynamicLibrary.open(libPath);
      // final process = DynamicLibrary.process();
      final hasSymbol = process.providesSymbol('OrtGetApiBase');

      expect(hasSymbol, isTrue);
      expect(true, isTrue);
    });
  });
}
