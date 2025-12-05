import 'dart:io';

import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:github/github.dart';
import 'package:logging/logging.dart';
import 'package:onnxruntime_builds/src/hook_helpers/builds/build_target.dart';
import 'package:onnxruntime_builds/src/hook_helpers/environment.dart';
import 'package:path/path.dart' as path;

import 'artifacts_provider.dart';
import 'library_hash.dart';
import 'target.dart';

final log = Logger('precompile_binaries');

class PrecompileBinaries {
  PrecompileBinaries({
    required this.privateKey,
    required this.githubToken,
    required this.repositorySlug,
    required this.targets,
    bool? includeAndroid,
    this.cmakeExtraDefines,
    this.tempDir,
  }) : includeAndroid = includeAndroid ?? false;

  final PrivateKey privateKey;
  final String githubToken;
  final RepositorySlug repositorySlug;
  final List<Target> targets;
  final bool includeAndroid;
  final List<String>? cmakeExtraDefines;
  final String? tempDir;

  static String fileName(Target target, String name) {
    return '${target.name}_$name';
  }

  static String signatureFileName(Target target, String name) {
    return '${target.name}_$name.sig';
  }

  Future<void> run() async {
    final onnxVersion = File(Environment.onnxruntimeVersionFile).readAsStringSync().trim();

    final targets = List.of(this.targets);
    if (targets.isEmpty) {
      targets.addAll([
        ...Target.buildableTargets(),
        if (includeAndroid) ...Target.androidTargets(),
      ]);
    }

    log.info('Precompiling binaries for $targets');

    final hash = LibraryHash.compute();
    log.info('Computed library hash: $hash');

    final String tagName = 'precompiled_$hash';

    final github = GitHub(auth: Authentication.withToken(githubToken));
    final repo = github.repositories;
    final release = await _getOrCreateRelease(
      repo: repo,
      tagName: tagName,
      version: onnxVersion,
      hash: hash,
    );

    final tempDir = this.tempDir != null
        ? Directory(this.tempDir!)
        : Directory.systemTemp.createTempSync('precompiled_');

    tempDir.createSync(recursive: true);

    for (final target in targets) {
      final artifactNames = getArtifactNames(
        target: target,
        libraryName: Environment.libraryName,
      );

      if (artifactNames.every((name) {
        final fileName = PrecompileBinaries.fileName(target, name);
        return (release.assets ?? []).any((e) => e.name == fileName);
      })) {
        log.info("All artifacts for $target already exist - skipping");
        continue;
      }

      log.info('Building for $target');

      final builder = BuildTarget.fromTarget(target: target, cmakeExtraDefines: cmakeExtraDefines);
      final res = await builder.compile();

      final assets = <CreateReleaseAsset>[];
      for (final name in artifactNames) {
        final file = File(path.join(res, name));
        if (!file.existsSync()) {
          throw Exception('Missing artifact: ${file.path}');
        }

        final data = file.readAsBytesSync();
        final create = CreateReleaseAsset(
          name: PrecompileBinaries.fileName(target, name),
          contentType: "application/octet-stream",
          assetData: data,
        );
        final signature = sign(privateKey, data);
        final signatureCreate = CreateReleaseAsset(
          name: signatureFileName(target, name),
          contentType: "application/octet-stream",
          assetData: signature,
        );
        bool verified = verify(public(privateKey), data, signature);
        if (!verified) {
          throw Exception('Signature verification failed');
        }
        assets.add(create);
        assets.add(signatureCreate);
      }
      log.info('Uploading assets: ${assets.map((e) => e.name)}');
      for (final asset in assets) {
        // This seems to be failing on CI so do it one by one
        int retryCount = 0;
        while (true) {
          try {
            await repo.uploadReleaseAssets(release, [asset]);
            break;
          } on Exception catch (e) {
            if (retryCount == 10) {
              rethrow;
            }
            ++retryCount;
            log.shout('Upload failed (attempt $retryCount, will retry): ${e.toString()}');
            await Future.delayed(Duration(seconds: 2));
          }
        }
      }
    }

    log.info('Cleaning up');
    tempDir.deleteSync(recursive: true);
  }

  Future<Release> _getOrCreateRelease({
    required RepositoriesService repo,
    required String tagName,
    required String version,
    required String hash,
  }) async {
    Release release;
    try {
      log.info('Fetching release $tagName');
      release = await repo.getReleaseByTagName(repositorySlug, tagName);
    } on ReleaseNotFound {
      log.info('Release not found - creating release $tagName');
      release = await repo.createRelease(
        repositorySlug,
        CreateRelease.from(
          tagName: tagName,
          name: 'ONNX Runtime $version - Precompiled binaries ${hash.substring(0, 8)}',
          targetCommitish: null,
          isDraft: false,
          isPrerelease: false,
          body: 'Precompiled binaries for ONNX Runtime $version, hash $hash.',
        ),
      );
    }
    return release;
  }
}
