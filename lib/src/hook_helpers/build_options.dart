import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'environment.dart';

// class BuildOptions {
//   static BuildOptions load() {
//     String fileName = "build_options.yaml";
//     var userProjectDir = Directory(Environment.projectRootDir);
//
//     while (userProjectDir.parent.path != userProjectDir.path) {
//       final configFile = File(path.join(userProjectDir.path, fileName));
//       if (configFile.existsSync()) {
//         final contents = loadYamlNode(
//           configFile.readAsStringSync(),
//           sourceUrl: configFile.uri,
//         );
//         final res = parse(contents);
//         if (res.verboseLogging) {
//           _log.info('Found user options file at ${configFile.path}');
//         }
//         return res;
//       }
//       userProjectDir = userProjectDir.parent;
//     }
//     return BuildOptions._();
//   }
// }
