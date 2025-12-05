import 'build.dart';

/// A helper class for [Build] for MacOS specific builds.
class BuildMacOS extends Build {
  static final x86_64 = BuildMacOS(
    name: 'x86_64',
    cmakeExtraDefines: ['CMAKE_OSX_ARCHITECTURES=x86_64'],
  );
  static final arm64 = BuildMacOS(
    name: 'arm64',
    cmakeExtraDefines: ['CMAKE_OSX_ARCHITECTURES=arm64'],
  );
  static final dual = BuildMacOS(
    name: 'arm64_x86_64',
    cmakeExtraDefines: ['CMAKE_OSX_ARCHITECTURES=arm64;x86_64'],
  );

  static final macosBuilds = [x86_64, arm64, dual];

  final String name;

  BuildMacOS({
    required this.name,
    required super.cmakeExtraDefines,
  });
}
