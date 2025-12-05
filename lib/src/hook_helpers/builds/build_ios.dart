import 'build.dart';

/// A helper class for [Build] for iOS specific builds.
class BuildIos extends Build {
  static final arm64 = BuildIos(
    name: 'iphoneos - arm64',
    appleSysroot: 'iphoneos',
    osxArch: 'arm64',
  );

  static final x86_64 = BuildIos(
    name: 'iphonesimulator - x86_64',
    appleSysroot: 'iphonesimulator',
    osxArch: 'x86_64',
  );

  static final iosBuilds = [arm64, x86_64];

  final String name;

  BuildIos({
    required this.name,
    super.ios = true,
    required super.appleSysroot,
    required super.osxArch,
  });
}
