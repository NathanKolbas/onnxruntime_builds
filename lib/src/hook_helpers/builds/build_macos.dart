import 'build.dart';

/// A helper class for [Build] for MacOS specific builds.
class BuildMacOS extends Build {
  // TODO
  static final x86_64AndArm64 = BuildMacOS(
    name: 'dual x86_64 and arm64 binary',
  );

  static final macosBuilds = [x86_64AndArm64];

  final String name;

  BuildMacOS({
    required this.name,
  });
}
