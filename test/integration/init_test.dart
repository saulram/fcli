import 'dart:io';

import 'package:fcli/src/config/config_loader.dart';
import 'package:fcli/src/config/fcli_config.dart';
import 'package:fcli/src/generators/project_generator.dart';
import 'package:fcli/src/utils/file_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Project Generation (Dry Run)', () {
    late Directory tempDir;
    late FcliConfig config;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fcli_init_test_');
      config = FcliConfig(
        projectName: 'test_app',
        org: 'com.example.test',
        stateManagement: StateManagement.riverpod,
        router: RouterOption.goRouter,
        useFreezed: true,
        useDioClient: true,
        platforms: [Platform.android, Platform.ios],
        features: ['home'],
        generateTests: true,
        l10n: false,
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('dry run shows expected output without creating files', () async {
      final generator = ProjectGenerator(
        config: config,
        targetPath: tempDir.path,
        verbose: false,
        dryRun: true,
      );

      final result = await generator.generate();

      expect(result, isTrue);

      // Verify no files were created
      final projectDir = Directory('${tempDir.path}/test_app');
      expect(projectDir.existsSync(), isFalse);
    });

    test('ProjectGenerator has correct paths', () {
      final generator = ProjectGenerator(
        config: config,
        targetPath: tempDir.path,
        verbose: false,
        dryRun: true,
      );

      expect(generator.projectPath, equals('${tempDir.path}/test_app'));
      expect(generator.libPath, equals('${tempDir.path}/test_app/lib'));
    });
  });

  group('Config Validation', () {
    test('validates project name format', () {
      final validNames = [
        'my_app',
        'myapp',
        'my_flutter_app',
        'app123',
        '_private_app',
      ];

      final invalidNames = [
        'MyApp',
        'my-app',
        'my app',
        '123app',
        'my.app',
        '',
      ];

      for (final name in validNames) {
        final config = FcliConfig(projectName: name);
        final errors = ConfigLoader.validate(config);
        expect(
          errors.any((e) => e.contains('valid Dart package name')),
          isFalse,
          reason: '$name should be valid',
        );
      }

      for (final name in invalidNames) {
        final config = FcliConfig(projectName: name);
        final errors = ConfigLoader.validate(config);
        expect(
          errors.isNotEmpty,
          isTrue,
          reason: '$name should be invalid',
        );
      }
    });

    test('validates platforms not empty', () {
      final config = FcliConfig(
        projectName: 'valid_app',
        platforms: [],
      );

      final errors = ConfigLoader.validate(config);
      expect(errors.any((e) => e.contains('platform')), isTrue);
    });

    test('validates org not empty', () {
      final config = FcliConfig(
        projectName: 'valid_app',
        org: '',
      );

      final errors = ConfigLoader.validate(config);
      expect(errors.any((e) => e.contains('Organization')), isTrue);
    });
  });

  group('File Utils Integration', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fcli_file_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('creates nested directories', () async {
      final nestedPath = '${tempDir.path}/a/b/c/d';
      await FileUtils.createDirectory(nestedPath);

      expect(Directory(nestedPath).existsSync(), isTrue);
    });

    test('writes and reads files', () async {
      final filePath = '${tempDir.path}/test.txt';
      const content = 'Hello, World!';

      await FileUtils.writeFile(filePath, content);

      expect(File(filePath).existsSync(), isTrue);
      expect(await FileUtils.readFile(filePath), equals(content));
    });

    test('creates parent directories when writing file', () async {
      final filePath = '${tempDir.path}/nested/dir/file.txt';
      const content = 'test content';

      await FileUtils.writeFile(filePath, content);

      expect(File(filePath).existsSync(), isTrue);
      expect(await FileUtils.readFile(filePath), equals(content));
    });

    test('lists files with extension filter', () async {
      await FileUtils.writeFile('${tempDir.path}/test.dart', 'dart');
      await FileUtils.writeFile('${tempDir.path}/test.txt', 'txt');
      await FileUtils.writeFile('${tempDir.path}/test.yaml', 'yaml');

      final dartFiles = await FileUtils.listFiles(
        tempDir.path,
        extensions: ['.dart'],
      );

      expect(dartFiles.length, equals(1));
      expect(dartFiles.first.path, contains('test.dart'));
    });

    test('checks file and directory existence', () async {
      final filePath = '${tempDir.path}/exists.txt';
      final dirPath = '${tempDir.path}/exists_dir';

      expect(await FileUtils.fileExists(filePath), isFalse);
      expect(await FileUtils.directoryExists(dirPath), isFalse);

      await FileUtils.writeFile(filePath, 'content');
      await FileUtils.createDirectory(dirPath);

      expect(await FileUtils.fileExists(filePath), isTrue);
      expect(await FileUtils.directoryExists(dirPath), isTrue);
    });

    test('deletes files and directories', () async {
      final filePath = '${tempDir.path}/to_delete.txt';
      final dirPath = '${tempDir.path}/to_delete_dir';

      await FileUtils.writeFile(filePath, 'content');
      await FileUtils.createDirectory(dirPath);
      await FileUtils.writeFile('$dirPath/nested.txt', 'nested');

      expect(await FileUtils.fileExists(filePath), isTrue);
      expect(await FileUtils.directoryExists(dirPath), isTrue);

      await FileUtils.deleteFile(filePath);
      await FileUtils.deleteDirectory(dirPath);

      expect(await FileUtils.fileExists(filePath), isFalse);
      expect(await FileUtils.directoryExists(dirPath), isFalse);
    });
  });
}
