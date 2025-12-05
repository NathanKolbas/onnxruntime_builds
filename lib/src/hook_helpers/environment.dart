import 'dart:io';

import 'package:path/path.dart' as path;

class Environment {
  /// Path to the root of the project (containing pubspec.yaml).
  static String get projectRootDir => Directory.current.resolveSymbolicLinksSync();

  /// The compiled library name (which will always be onnxruntime).
  static String get libraryName => 'onnxruntime';

  /// The file that contains information about the current onnxruntime submodule.
  static String get onnxruntimeVersionFile => path.join(projectRootDir, '.onnxruntime_version');

  /// The file that contains precompiled binary config.
  static String get precompiledBinariesConfigFile => path.join(projectRootDir, 'precompiled_binaries.yaml');

  /// The onnxruntime directory.
  static String get onnxRuntimeDir => path.join(Environment.projectRootDir, 'onnxruntime');

  /// The onnxruntime build directory.
  static String get onnxRuntimeBuildDir => path.join(onnxRuntimeDir, 'build');

  /// Android SDK path from environment.
  static String? get androidSdkDir => Platform.environment['ANDROID_HOME'] ?? Platform.environment['ANDROID_SDK_ROOT'];

  /// Android NDK path from environment.
  static String? get androidNdkDir => Platform.environment['ANDROID_NDK']
      ?? Platform.environment['ANDROID_NDK_HOME']
      ?? Platform.environment['ANDROID_NDK_ROOT'];
}
