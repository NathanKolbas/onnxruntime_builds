import 'package:onnxruntime_builds/src/hook_helpers/environment.dart';
import 'package:path/path.dart' as path;

import 'build.dart';

/// A helper class for [Build] for Windows specific builds.
class BuildWindows extends Build {
  static final x86_64 = BuildWindows(
    name: 'x86_64',
    buildDir: path.join(Environment.onnxRuntimeBuildDir, 'Windows-x86_64'),
  );

  static final arm64 = BuildWindows(
    name: 'arm64',
    buildDir: path.join(Environment.onnxRuntimeBuildDir, 'Windows-arm64'),
    compileForArm64: true,
  );

  static final windowsBuilds = [x86_64, arm64];

  final String name;

  BuildWindows({
    required this.name,
    super.buildDir,
    super.compileForArm64,
  });
}
