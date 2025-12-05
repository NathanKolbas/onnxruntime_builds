import 'build.dart';

/// A helper class for [Build] for Linux specific builds.
class BuildLinux extends Build {
  static final x86_64 = BuildLinux(
    name: 'x86_64',
  );

  static final linuxBuilds = [x86_64];

  final String name;

  BuildLinux({
    required this.name,
  });
}
