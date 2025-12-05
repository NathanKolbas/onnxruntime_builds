import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:onnxruntime_builds/src/hook_helpers/environment.dart';

import 'artifacts_provider.dart';
import 'library_hash.dart';
import 'options.dart';
import 'precompile_binaries.dart';
import 'target.dart';

final log = Logger("verify_binaries");

class VerifyBinaries {
  Future<void> run() async {
    final precompiledBinaries = PrecompiledBinaries.load();

    final libraryHash = LibraryHash.compute();
    log.info('Library hash: $libraryHash');

    for (final target in Target.all) {
      final message = 'Checking ${target.name}...';
      log.info(message.padRight(40));

      final artifacts = getArtifactNames(
        target: target,
        libraryName: Environment.libraryName,
      );

      final prefix = precompiledBinaries.uriPrefix;

      bool ok = true;

      for (final artifact in artifacts) {
        final fileName = PrecompileBinaries.fileName(target, artifact);
        final signatureFileName = PrecompileBinaries.signatureFileName(target, artifact);

        final url = Uri.parse('$prefix$libraryHash/$fileName');
        final signatureUrl = Uri.parse('$prefix$libraryHash/$signatureFileName');

        final signature = await get(signatureUrl);
        if (signature.statusCode != 200) {
          log.info('MISSING');
          ok = false;
          break;
        }
        final asset = await get(url);
        if (asset.statusCode != 200) {
          log.info('MISSING');
          ok = false;
          break;
        }

        if (!verify(precompiledBinaries.publicKey, asset.bodyBytes, signature.bodyBytes)) {
          log.info('INVALID SIGNATURE');
          ok = false;
        }
      }

      if (ok) {
        log.info('OK');
      }
    }
  }
}
