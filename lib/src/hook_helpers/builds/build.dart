import 'dart:io';

import 'package:logging/logging.dart';
import 'package:onnxruntime_builds/src/hook_helpers/environment.dart';
import 'package:onnxruntime_builds/src/hook_helpers/util.dart';
import 'package:path/path.dart' as path;

final log = Logger("build");

/// Builds onnxruntime.
class Build {
  // --- DEFAULTS ---
  static const dConfig = 'Release';
  static const dUpdate = true;
  static const dBuild = true;
  static const dParallel = '0';
  static const dSkipTests = true;
  static const dBuildSharedLib = true;
  static const dCompileNoWarningAsError = true;
  static const dSkipSubmoduleSync = true;

  // --- WINDOWS DEFAULTS ---
  static const dCompileForArm64 = false;

  // --- ANDROID DEFAULTS ---
  static const dAndroid = false;
  static const dAndroidApi = '28';
  static const dAndroidNdkVersion = '27.3.13750724';
  static const dAndroidCppShared = true;

  // --- iOS DEFAULTS ---
  static const dIos = false;
  static const dUseXcode = false;

  // -- Apple platforms ---
  static const dUseCoreMl = true;

  // ----------------------

  // --- COMMON CONFIG ---
  final String? buildDir;
  final String config;
  final bool update;
  final bool build;
  final String parallel;
  final bool skipTests;
  final bool buildSharedLib;
  final bool compileNoWarningAsError;
  final bool skipSubmoduleSync;
  final List<String>? cmakeExtraDefines;

  // --- WINDOWS CONFIG ---
  final bool compileForArm64;

  // --- ANDROID CONFIG ---
  final bool android;
  final String? androidAbi;
  final String androidApi;
  final String? androidSdkPath;
  final String androidNdkVersion;
  final bool androidCppShared;

  // --- iOS CONFIG ---
  final bool ios;
  final bool useXcode;
  final String? appleSysroot;
  final String? osxArch;
  final String? appleDeployTarget;

  // --- Apple Platforms --
  final bool useCoreMl;

  Build({
    this.buildDir,
    String? config,
    bool? update,
    bool? build,
    String? parallel,
    bool? skipTests,
    bool? buildSharedLib,
    bool? compileNoWarningAsError,
    bool? skipSubmoduleSync,
    this.cmakeExtraDefines,

    // Windows specific
    bool? compileForArm64,

    // Android specific
    bool? android,
    this.androidAbi,
    String? androidApi,
    this.androidSdkPath,
    String? androidNdkVersion,
    bool? androidCppShared,

    // iOS specific
    bool? ios,
    bool? useXcode,
    this.appleSysroot,
    this.osxArch,
    this.appleDeployTarget,

    // Apple Platforms
    bool? useCoreMl,
  }) : config = config ?? dConfig,
        update = update ?? dUpdate,
        build = build ?? dBuild,
        parallel = parallel ?? dParallel,
        skipTests = skipTests ?? dSkipTests,
        buildSharedLib = buildSharedLib ?? dBuildSharedLib,
        compileNoWarningAsError = compileNoWarningAsError ?? dCompileNoWarningAsError,
        skipSubmoduleSync = skipSubmoduleSync ?? dSkipSubmoduleSync,

        // Windows specific
        compileForArm64 = compileForArm64 ?? dCompileForArm64,

        // Android specific
        android = android ?? dAndroid,
        androidApi = androidApi ?? dAndroidApi,
        androidNdkVersion = androidNdkVersion ?? dAndroidNdkVersion,
        androidCppShared = androidCppShared ?? dAndroidCppShared,

        // iOS specific
        ios = ios ?? dIos,
        useXcode = useXcode ?? dUseXcode,

        // Apple Platforms
        useCoreMl = useCoreMl ?? dUseCoreMl;

  /// Compile onnxruntime.
  ///
  /// Returns path to output directory.
  Future<String> compile() async {
    // Make sure git submodules are setup
    runCommand('git', [
      'submodule',
      'update',
      '--init',
      '--recursive',
    ], workingDirectory: Environment.projectRootDir);

    String? buildDir = this.buildDir;
    // Android targets need to separate the build outputs otherwise they will
    // all be under "Android" which will cause failures when building multiple
    // different architectures
    if (android && buildDir == null) {
      buildDir = 'Android-$androidAbi';
    }

    await runCommandStreamStdout(
      Platform.isWindows ? '.\\build.bat' : './build.sh',
      [
        if (buildDir != null) ...['--build_dir', buildDir],
        ...['--config', config],
        if (update) '--update',
        if (build) '--build',
        ...['--parallel', parallel],
        if (skipTests) '--skip_tests',
        if (buildSharedLib) '--build_shared_lib',

        ..._desktopBuildArgs(),
        ..._androidBuildArgs(),
        ..._iosBuildArgs(),
      ],
      workingDirectory: Environment.onnxRuntimeDir,
      runInShell: true,
    );

    // If the output dir is specified then the compiled files will be here
    String? outputDir = buildDir;
    if (outputDir == null) {
      // Otherwise we use the default build dir
      outputDir = Environment.onnxRuntimeBuildDir;
      // We now need to append the name of the platform to the build path
      String platformName;
      if (android) {
        platformName = 'Android';
      } else if (ios) {
        platformName = 'iOS';
      } else if (Platform.isWindows) {
        platformName = 'Windows';
      } else if (Platform.isLinux) {
        platformName = 'Linux';
      } else if (Platform.isMacOS) {
        platformName = 'MacOS';
      } else {
        throw StateError('Unable to determine the output build dir');
      }
      outputDir = path.join(outputDir, platformName);
    }

    // Add the config to the path
    outputDir = path.join(outputDir, config);

    // Depending on the platform the compiled files are contained under
    // different paths in the build dir
    if (android) {
      // Android is correct at this point
    } else if (ios) {
      // Contained under a separate folder depending on if it is a simulator
      outputDir = path.join(outputDir, '$config-$appleSysroot');
    } else if (Platform.isWindows) {
      // I have no idea why put it is nested under another config dir
      outputDir = path.join(outputDir, config);
    } else if (Platform.isLinux) {
      // Linux is correct at this point
    } else if (Platform.isMacOS) {
      // MacOS is correct at this point
    } else {
      throw StateError('Unable to determine the output build dir');
    }

    return outputDir;
  }

  /// Gets the build arguments for desktop (Windows, MacOS, Linux).
  List<String> _desktopBuildArgs() {
    if (android) return [];

    return [
      if (compileNoWarningAsError) '--compile_no_warning_as_error',
      if (skipSubmoduleSync) '--skip_submodule_sync',
      if (cmakeExtraDefines != null) ...cmakeExtraDefines!.fold<Iterable<String>>(
        [],
        (defs, d) => [...defs, '--cmake_extra_defines', d],
      ),

      if (Platform.isWindows) ...[
        if (compileForArm64) '--arm64',
      ],

      if (Platform.isMacOS) ...[
        if (useCoreMl) '--use_coreml',
      ],

      if (Platform.isLinux) ...[],
    ];
  }

  /// Gets the build arguments for Android (if the flag is present).
  List<String> _androidBuildArgs() {
    if (!android) return [];

    final androidSdkPath = this.androidSdkPath ?? Environment.androidSdkDir;
    if (androidSdkPath == null) {
      throw ArgumentError('Missing android_sdk_path. Either pass as argument or add environment variable.');
    }
    final androidAbi = this.androidAbi;
    if (androidAbi == null) {
      throw ArgumentError('Missing android_abi.');
    }

    final androidNdkPath = _getNdk(androidSdkPath);

    return [
      '--android',
      ...['--android_sdk_path', androidSdkPath],
      ...['--android_ndk_path', androidNdkPath],
      ...['--android_abi', androidAbi],
      ...['--android_api', androidApi],
      if (androidCppShared) '--android_cpp_shared',
      if (Platform.isWindows) ...['--cmake_generator', 'Ninja'],
    ];
  }

  /// Gets the path to the specified NDK version.
  String _getNdk(String sdkPath) {
    if (!_ndkIsInstalled(sdkPath)) {
      _installNdk(sdkPath);
    }

    return path.join(sdkPath, 'ndk', androidNdkVersion);
  }

  /// Checks if the specified NDK version is installed.
  bool _ndkIsInstalled(String sdkPath) {
    final ndkPath = path.join(sdkPath, 'ndk', androidNdkVersion);
    final ndkPackageXml = File(path.join(ndkPath, 'package.xml'));
    return ndkPackageXml.existsSync();
  }

  /// Installs the specified NDK version.
  void _installNdk(String sdkPath) {
    final sdkManagerExtension = Platform.isWindows ? '.bat' : '';
    final sdkManager = path.join(
      sdkPath,
      'cmdline-tools',
      'latest',
      'bin',
      'sdkmanager$sdkManagerExtension',
    );

    log.info('Installing NDK $androidNdkVersion');
    runCommand(sdkManager, [
      '--install',
      'ndk;$androidNdkVersion',
    ]);
  }

  /// Gets the build arguments for iOS (if the flag is present).
  List<String> _iosBuildArgs() {
    if (!ios) return [];

    final appleSysroot = this.appleSysroot;
    if (appleSysroot == null) {
      throw ArgumentError('apple_sysroot is null but ios is true');
    }
    final osxArch = this.osxArch;
    if (osxArch == null) {
      throw ArgumentError('osx_arch is null but ios is true');
    }
    final appleDeployTarget = this.appleDeployTarget;
    if (appleDeployTarget == null) {
      throw ArgumentError('apple_deploy_target is null but ios is true');
    }

    return [
      if (useXcode) '--use_xcode',
      '--ios',
      ...['--apple_sysroot', appleSysroot],
      ...['--osx_arch', osxArch],
      ...['--apple_deploy_target', appleDeployTarget],
      if (useCoreMl) '--use_coreml',
    ];
  }
}
