import 'dart:io';

import 'package:logging/logging.dart';
import 'package:onnxruntime_builds/src/hook_helpers/builds/build.dart';
import 'package:onnxruntime_builds/src/hook_helpers/environment.dart';
import 'package:onnxruntime_builds/src/hook_helpers/target.dart';
import 'package:onnxruntime_builds/src/hook_helpers/util.dart';
import 'package:path/path.dart' as path;

final log = Logger("build_target");

/// Builds onnxruntime for a [Target].
class BuildTarget extends Build {
  final Target target;

  BuildTarget._({
    required this.target,

    super.cmakeExtraDefines,

    super.android,
    super.androidAbi,
    super.androidApi,

    super.ios,
    super.appleSysroot,
    super.osxArch,
    super.appleDeployTarget,
  });

  static BuildTarget fromTarget({required Target target, String? cmakeExtraDefines}) {
    cmakeExtraDefines ??= '';

    if (target.isMacOS) {
      cmakeExtraDefines = 'CMAKE_OSX_ARCHITECTURES=${target.darwinArch} $cmakeExtraDefines'.trim();
    }

    return BuildTarget._(
      target: target,

      cmakeExtraDefines: cmakeExtraDefines,

      android: target.isAndroid,
      androidAbi: target.android,
      androidApi: '${target.androidMinSdkVersion}',

      ios: target.isIOS,
      appleSysroot: target.darwinPlatform,
      osxArch: target.darwinArch,
      appleDeployTarget: '${target.iosMinSdkVersion}',
    );
  }
}
