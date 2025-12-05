import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  await build(args, (input, output) async {
    final localBuild = input.userDefines['local_build'] as bool? ?? false;

    if (localBuild) {
      // await runBuild(input, output);
    } else {
      // final targetOS = input.config.code.targetOS;
      // final targetArchitecture = input.config.code.targetArchitecture;
      // final iOSSdk = targetOS == OS.iOS
      //     ? input.config.code.iOS.targetSdk
      //     : null;
      // final outputDirectory = Directory.fromUri(input.outputDirectory);
      // final file = await downloadAsset(
      //   targetOS,
      //   targetArchitecture,
      //   iOSSdk,
      //   outputDirectory,
      // );
      // final fileHash = await hashAsset(file);
      // final expectedHash = assetHashes[input.config.code.targetOS.dylibFileName(
      //   createTargetName(
      //     targetOS.name,
      //     targetArchitecture.name,
      //     iOSSdk?.type,
      //   ),
      // )];
      // if (fileHash != expectedHash) {
      //   throw Exception(
      //     'File $file was not downloaded correctly. '
      //         'Found hash $fileHash, expected $expectedHash.',
      //   );
      // }

      final objectName = 'libonnxruntime.so';
      // final objectName = 'onnxruntime.dll';
      final outputDirectory = Directory.fromUri(input.outputDirectory);
      final outputObject = path.join(outputDirectory.path, objectName);
      final so = File(path.join(Directory.current.resolveSymbolicLinksSync(), 'hook', objectName));
      await so.copy(outputObject);

      // output.assets.code.add(
      //   CodeAsset(
      //     package: input.packageName,
      //     name: objectName,
      //     linkMode: LookupInProcess(),
      //     file: File(outputObject).uri,
      //   ),
      // );

      output.assets.code.add(
        CodeAsset(
          package: input.packageName,
          name: objectName,
          linkMode: DynamicLoadingBundled(),
          file: File(outputObject).uri,
        ),
      );
    }
  });
}
