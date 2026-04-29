import 'dart:io';

import 'package:flg/src/config/fcli_config.dart';
import 'package:flg/src/generators/test_generator.dart';
import 'package:flg/src/utils/file_utils.dart';
import 'package:test/test.dart';

void main() {
  group('TestGenerator', () {
    late Directory tempDir;
    late String projectPath;
    late TestGenerator generator;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('flg_test_generator_');
      projectPath = '${tempDir.path}/test_app';
      generator = TestGenerator(
        config: const FcliConfig(projectName: 'test_app'),
        projectPath: projectPath,
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('generates feature test file', () async {
      await generator.generateFeature('auth');

      final path = '$projectPath/test/features/auth/auth_feature_test.dart';
      expect(FileUtils.fileExistsSync(path), isTrue);
      expect(
        FileUtils.readFileSync(path),
        contains("group('Auth feature'"),
      );
    });

    test('generates screen test file', () async {
      await generator.generateScreen('login', 'auth');

      expect(
        FileUtils.fileExistsSync(
          '$projectPath/test/features/auth/presentation/screens/login_screen_test.dart',
        ),
        isTrue,
      );
    });

    test('dry run does not create files', () async {
      final dryRunGenerator = TestGenerator(
        config: const FcliConfig(projectName: 'test_app'),
        projectPath: projectPath,
        dryRun: true,
      );

      await dryRunGenerator.generateFeature('settings');

      expect(
        FileUtils.fileExistsSync(
          '$projectPath/test/features/settings/settings_feature_test.dart',
        ),
        isFalse,
      );
    });
  });
}
