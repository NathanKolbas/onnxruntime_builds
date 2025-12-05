import 'package:onnxruntime_builds/src/hook_helpers/environment.dart';
import 'package:path/path.dart' as path;

import 'build.dart';

/// A helper class for [Build] for Android specific builds.
class BuildAndroid extends Build {
  static final armeabiV7a = BuildAndroid(
    name: 'armeabi-v7a',
    buildDir: path.join(Environment.onnxRuntimeBuildDir, 'Android-armeabi-v7a'),
    androidAbi: 'armeabi-v7a',
  );
  static final arm64V8a = BuildAndroid(
    name: 'arm64-v8a',
    buildDir: path.join(Environment.onnxRuntimeBuildDir, 'Android-arm64-v8a'),
    androidAbi: 'arm64-v8a',
  );
  static final x86 = BuildAndroid(
    name: 'x86',
    buildDir: path.join(Environment.onnxRuntimeBuildDir, 'Android-x86'),
    androidAbi: 'x86',
  );
  static final x86_64 = BuildAndroid(
    name: 'x86_64',
    buildDir: path.join(Environment.onnxRuntimeBuildDir, 'Android-x86_64'),
    androidAbi: 'x86_64',
  );

  static final androidBuilds = [
    armeabiV7a, arm64V8a, x86, x86_64,
  ];

  final String name;

  BuildAndroid({
    required this.name,
    super.buildDir,
    super.android = true,
    required super.androidAbi,
  });
}
