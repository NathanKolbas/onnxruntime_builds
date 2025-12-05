import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:github/github.dart';
import 'package:hex/hex.dart';
import 'package:logging/logging.dart';
import 'package:onnxruntime_builds/src/hook_helpers/builds/build_android.dart';
import 'package:onnxruntime_builds/src/hook_helpers/builds/build_ios.dart';
import 'package:onnxruntime_builds/src/hook_helpers/builds/build_linux.dart';
import 'package:onnxruntime_builds/src/hook_helpers/builds/build_macos.dart';
import 'package:onnxruntime_builds/src/hook_helpers/builds/build_windows.dart';
import 'package:onnxruntime_builds/src/hook_helpers/precompile_binaries.dart';
import 'package:onnxruntime_builds/src/hook_helpers/target.dart';
import 'package:onnxruntime_builds/src/hook_helpers/verify_binaries.dart';

import 'util.dart';
import 'builds/build.dart';
import 'environment.dart';
import 'logging.dart';

final log = Logger('build_tool');

class BuildCommand extends Command {
  BuildCommand() {
    argParser
      ..addFlag(
        "verbose",
        abbr: "v",
        defaultsTo: false,
        help: "Enable verbose logging",
      )

      ..addOption(
        'build_dir',
        help: 'Path to the build directory.',
        valueHelp: 'BUILD_DIR',
      )
      ..addOption(
        'config',
        allowed: {'Debug', 'MinSizeRel', 'Release', 'RelWithDebInfo'},
        defaultsTo: Build.dConfig,
        help: 'Type of build configuration',
      )
      ..addFlag(
        'update',
        defaultsTo: Build.dUpdate,
        help: 'Update makefiles.',
      )
      ..addFlag(
        'build',
        defaultsTo: Build.dBuild,
        help: 'Build.',
      )
      ..addOption(
        'parallel',
        defaultsTo: Build.dParallel,
        help: 'Use parallel build. Optional value specifies max jobs (0=num CPUs).',
        valueHelp: '[PARALLEL]',
      )
      ..addFlag(
        'skip_tests',
        defaultsTo: Build.dSkipTests,
        help: 'Skip all tests.',
      )
      ..addFlag(
        'build_shared_lib',
        defaultsTo: Build.dBuildSharedLib,
        help: 'Build a shared library for ONNXRuntime.',
      )

      // Windows config
      ..addFlag(
        'arm64',
        defaultsTo: Build.dCompileForArm64,
        help: '[Windows cross-compiling] Target Windows ARM64.',
      )

      // Android config
      ..addFlag(
        'android',
        defaultsTo: Build.dAndroid,
        help: 'Build for Android.',
      )
      ..addOption(
        'android_abi',
        allowed: {'armeabi-v7a', 'arm64-v8a', 'x86', 'x86_64'},
        help: 'Target Android ABI.',
      )
      ..addOption(
        'android_api',
        defaultsTo: Build.dAndroidApi,
        help: 'Android API Level (e.g., 21).',
        valueHelp: 'ANDROID_API',
      )
      ..addOption(
        'android_sdk_path',
        help: 'Path to Android SDK.',
        valueHelp: 'ANDROID_SDK_PATH',
      )
      ..addOption(
        'android_ndk_version',
        defaultsTo: Build.dAndroidNdkVersion,
        help: 'The version of Android NDK.',
      )
      ..addFlag(
        'android_cpp_shared',
        defaultsTo: Build.dAndroidCppShared,
        help: 'Link shared libc++ instead of static (default).',
      )

      // iOS config
      ..addFlag(
        'ios',
        defaultsTo: Build.dIos,
        help: 'Build for iOS.'
      )
      ..addFlag(
        'use_xcode',
        defaultsTo: Build.dUseXcode,
        help: 'Should xcode be used for build (Apple platforms).'
      )
      ..addOption(
        'apple_sysroot',
        allowed: {'iphonesimulator', 'iphoneos'},
        help: 'The apple device to build for.',
      )
      ..addOption(
        'osx_arch',
        allowed: {'x86_64', 'arm64'},
        help: 'The apple device architecture to build for.',
      )
      ..addOption(
        'apple_deploy_target',
        help: 'The target minimum version number.',
      )

      // Apple Platforms
      ..addFlag(
        'use_coreml',
        defaultsTo: Build.dUseCoreMl,
        help: 'Enable CoreML EP (Apple platforms). Defaults to true.',
      );
  }

  @override
  String get name => 'build';

  @override
  String get description => 'On-off build for onnxruntime binary.';

  @override
  Future<void> run() async {
    final argResults = this.argResults!;
    final verbose = argResults['verbose'] as bool;
    if (verbose) {
      enableVerboseLogging();
    }

    await Build(
      buildDir: argResults['build_dir'],
      config: argResults['config'],
      update: argResults['update'],
      build: argResults['build'],
      parallel: argResults['parallel'],
      skipTests: argResults['skip_tests'],
      buildSharedLib: argResults['build_shared_lib'],

      // Windows specific
      compileForArm64: argResults['arm64'],

      // Android specific
      android: argResults['android'],
      androidAbi: argResults['android_abi'],
      androidApi: argResults['android_api'],
      androidSdkPath: argResults['android_sdk_path'],
      androidNdkVersion: argResults['android_ndk_version'],
      androidCppShared: argResults['android_cpp_shared'],

      // iOS specific
      ios: argResults['ios'],
      useXcode: argResults['use_xcode'],
      appleSysroot: argResults['apple_sysroot'],
      osxArch: argResults['osx_arch'],
      appleDeployTarget: argResults['apple_deploy_target'],

      // Apple Platforms
      useCoreMl: argResults['use_coreml'],
    ).compile();
  }
}

class BuildWindowsCommand extends BuildCommand {
  @override
  String get name => 'build-windows';

  @override
  String get description => 'Build binaries for all the Windows platforms.';

  @override
  Future<void> run() async {
    if (!Platform.isWindows) {
      throw StateError('Unable to build Windows binaries when running on a non-Windows machine.');
    }

    final argResults = this.argResults!;
    final verbose = argResults['verbose'] as bool;
    if (verbose) {
      enableVerboseLogging();
    }

    for (final windowsBuild in BuildWindows.windowsBuilds) {
      log.info('Running Windows build for ${windowsBuild.name}');
      log.info(kDoubleSeparator);
      await windowsBuild.compile();
      log.info(kDoubleSeparator);
    }
  }
}

class BuildMacOSCommand extends BuildCommand {
  @override
  String get name => 'build-macos';

  @override
  String get description => 'Build binaries for all the MacOS platforms.';

  @override
  Future<void> run() async {
    if (!Platform.isMacOS) {
      throw StateError('Unable to build MacOS binaries when running on a non-MacOS machine.');
    }

    final argResults = this.argResults!;
    final verbose = argResults['verbose'] as bool;
    if (verbose) {
      enableVerboseLogging();
    }

    for (final macosBuild in BuildMacOS.macosBuilds) {
      log.info('Running Linux build for ${macosBuild.name}');
      log.info(kDoubleSeparator);
      await macosBuild.compile();
      log.info(kDoubleSeparator);
    }
  }
}

class BuildLinuxCommand extends BuildCommand {
  @override
  String get name => 'build-linux';

  @override
  String get description => 'Build binaries for all the Linux platforms.';

  @override
  Future<void> run() async {
    if (!Platform.isLinux) {
      throw StateError('Unable to build Linux binaries when running on a non-Linux machine.');
    }

    final argResults = this.argResults!;
    final verbose = argResults['verbose'] as bool;
    if (verbose) {
      enableVerboseLogging();
    }

    for (final linuxBuild in BuildLinux.linuxBuilds) {
      log.info('Running Linux build for ${linuxBuild.name}');
      log.info(kDoubleSeparator);
      await linuxBuild.compile();
      log.info(kDoubleSeparator);
    }
  }
}

class BuildAndroidCommand extends BuildCommand {
  @override
  final name = 'build-android';

  @override
  final description = 'Build binaries for all the Android platforms.';

  @override
  Future<void> run() async {
    final argResults = this.argResults!;
    final verbose = argResults['verbose'] as bool;
    if (verbose) {
      enableVerboseLogging();
    }

    for (final androidBuild in BuildAndroid.androidBuilds) {
      log.info('Running Android build for ${androidBuild.name}');
      log.info(kDoubleSeparator);
      await androidBuild.compile();
      log.info(kDoubleSeparator);
    }
  }
}

class BuildIOSCommand extends BuildCommand {
  @override
  String get name => 'build-ios';

  @override
  String get description => 'Build binaries for all the iOS platforms.';

  @override
  Future<void> run() async {
    if (!Platform.isMacOS) {
      throw StateError('Unable to build iOS binaries when running on a non-MacOS machine.');
    }

    final argResults = this.argResults!;
    final verbose = argResults['verbose'] as bool;
    if (verbose) {
      enableVerboseLogging();
    }

    for (final iosBuild in BuildIos.iosBuilds) {
      log.info('Running iOS build for ${iosBuild.name}');
      log.info(kDoubleSeparator);
      await iosBuild.compile();
      log.info(kDoubleSeparator);
    }
  }
}

// abstract class AbstractBuildCommand extends Command {
//   Future<void> runBuildCommand(CargokitUserOptions options);
//
//   @override
//   Future<void> run() async {
//     final options = CargokitUserOptions.load();
//
//     if (options.verboseLogging ||
//         Platform.environment['CARGOKIT_VERBOSE'] == '1') {
//       enableVerboseLogging();
//     }
//
//     await runBuildCommand(options);
//   }
// }
//
// class BuildPodCommand extends AbstractBuildCommand {
//   @override
//   final name = 'build-pod';
//
//   @override
//   final description = 'Build cocoa pod library';
//
//   @override
//   Future<void> runBuildCommand(CargokitUserOptions options) async {
//     final build = BuildPod(userOptions: options);
//     await build.build();
//   }
// }
//
// class BuildGradleCommand extends AbstractBuildCommand {
//   @override
//   final name = 'build-gradle';
//
//   @override
//   final description = 'Build android library';
//
//   @override
//   Future<void> runBuildCommand(CargokitUserOptions options) async {
//     final build = BuildGradle(userOptions: options);
//     await build.build();
//   }
// }
//
// class BuildCMakeCommand extends AbstractBuildCommand {
//   @override
//   final name = 'build-cmake';
//
//   @override
//   final description = 'Build CMake library';
//
//   @override
//   Future<void> runBuildCommand(CargokitUserOptions options) async {
//     final build = BuildCMake(userOptions: options);
//     await build.build();
//   }
// }

class GenKeyCommand extends Command {
  @override
  final name = 'gen-key';

  @override
  final description = 'Generate key pair for signing precompiled binaries.';

  @override
  void run() {
    final kp = generateKey();
    final private = HEX.encode(kp.privateKey.bytes);
    final public = HEX.encode(kp.publicKey.bytes);
    print("Private Key: $private");
    print("Public Key: $public");
  }
}

class SetOnnxruntimeVersionCommand extends Command {
  SetOnnxruntimeVersionCommand() {
    argParser
      ..addFlag(
        "verbose",
        abbr: "v",
        defaultsTo: false,
        help: "Enable verbose logging",
      )
      ..addOption(
        'version',
        mandatory: true,
        help: 'commit/branch/tag/version',
      );
  }

  @override
  final name = 'set-onnxruntime';

  @override
  final description = 'Set the version of onnxruntime to use.';

  @override
  Future<void> run() async {
    final argResults = this.argResults!;
    final verbose = argResults['verbose'] as bool;
    if (verbose) {
      enableVerboseLogging();
    }

    final version = argResults['version'];

    log.info('Checking out onnxruntime version: $version');
    runCommand('git', [
      'checkout',
      version,
    ], workingDirectory: Environment.onnxRuntimeDir);

    log.info('Successfully set onnxruntime version and saved to .onnxruntime_version');
    await File(Environment.onnxruntimeVersionFile).writeAsString(version);
  }
}

class PrecompileBinariesCommand extends Command {
  PrecompileBinariesCommand() {
    argParser
      ..addOption(
        'repository',
        mandatory: true,
        help: 'Github repository slug in format owner/name',
      )
      ..addMultiOption('target',
          help: 'Name of target artifacts to build.\n'
              'Can be specified multiple times or omitted in which case\n'
              'all targets for current platform will be built.')
      ..addFlag(
        'android',
        defaultsTo: false,
        help: 'Includes Android targets in build.',
      )
      ..addOption(
        'temp-dir',
        help: 'Directory to store temporary build artifacts',
      )
      ..addFlag(
        "verbose",
        abbr: "v",
        defaultsTo: false,
        help: "Enable verbose logging",
      );
  }

  @override
  final name = 'precompile-binaries';

  @override
  final description = 'Prebuild and upload binaries\n'
      'Private key must be passed through PRIVATE_KEY environment variable. '
      'Use gen_key to generate private key.\n'
      'Github token must be passed as GITHUB_TOKEN environment variable.\n';

  @override
  Future<void> run() async {
    final argResults = this.argResults!;
    final verbose = argResults['verbose'] as bool;
    if (verbose) {
      enableVerboseLogging();
    }

    final privateKeyString = Platform.environment['PRIVATE_KEY'];
    if (privateKeyString == null) {
      throw ArgumentError('Missing PRIVATE_KEY environment variable');
    }
    final githubToken = Platform.environment['GITHUB_TOKEN'];
    if (githubToken == null) {
      throw ArgumentError('Missing GITHUB_TOKEN environment variable');
    }
    final privateKey = HEX.decode(privateKeyString);
    if (privateKey.length != 64) {
      throw ArgumentError('Private key must be 64 bytes long');
    }
    final targetStrings = argResults['target'] as List<String>;
    final targets = targetStrings.map((target) {
      final res = Target.forName(target);
      if (res == null) {
        throw ArgumentError('Invalid target: $target');
      }
      return res;
    }).toList(growable: false);
    final precompileBinaries = PrecompileBinaries(
      privateKey: PrivateKey(privateKey),
      githubToken: githubToken,
      repositorySlug: RepositorySlug.full(argResults['repository'] as String),
      targets: targets,
      includeAndroid: argResults['android'] as bool,
      tempDir: argResults['temp-dir'] as String?,
    );

    await precompileBinaries.run();
  }
}

class VerifyBinariesCommand extends Command {
  VerifyBinariesCommand();

  @override
  final name = "verify-binaries";

  @override
  final description = 'Verifies published binaries\n'
      'Checks whether there is a binary published for each targets\n'
      'and checks the signature.';

  @override
  Future<void> run() async {
    await VerifyBinaries().run();
  }
}

Future<void> runMain(List<String> args) async {
  try {
    // Init logging before options are loaded
    initLogging();

    final runner = CommandRunner('build_tool', 'tool for onnxruntime binaries')
      ..addCommand(BuildCommand())
      ..addCommand(BuildWindowsCommand())
      ..addCommand(BuildMacOSCommand())
      ..addCommand(BuildLinuxCommand())
      ..addCommand(BuildAndroidCommand())
      ..addCommand(BuildIOSCommand())
      ..addCommand(GenKeyCommand())
      ..addCommand(SetOnnxruntimeVersionCommand())
      ..addCommand(PrecompileBinariesCommand())
      ..addCommand(VerifyBinariesCommand());

    await runner.run(args);
  } on ArgumentError catch (e) {
    stderr.writeln(e.toString());
    exit(1);
  } catch (e, s) {
    log.severe(kDoubleSeparator);
    log.severe('BuildTool failed with error:');
    log.severe(kSeparator);
    log.severe(e);
    log.severe(kSeparator);
    log.severe(s);
    log.severe(kSeparator);
    log.severe('BuildTool arguments: $args');
    log.severe(kDoubleSeparator);
    exit(1);
  }
}
