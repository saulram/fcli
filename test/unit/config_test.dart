import 'dart:io';

import 'package:flg/src/config/config_loader.dart';
import 'package:flg/src/config/fcli_config.dart';
import 'package:test/test.dart';

void main() {
  group('FcliConfig', () {
    test('creates with default values', () {
      final config = FcliConfig.defaults('my_app');

      expect(config.projectName, equals('my_app'));
      expect(config.org, equals('com.example'));
      expect(config.stateManagement, equals(StateManagement.riverpod));
      expect(config.router, equals(RouterOption.goRouter));
      expect(config.useFreezed, isTrue);
      expect(config.useDioClient, isTrue);
      expect(config.platforms, contains(Platform.android));
      expect(config.platforms, contains(Platform.ios));
      expect(config.features, equals(['home']));
      expect(config.generateTests, isTrue);
      expect(config.l10n, isFalse);
    });

    test('serializes to JSON and back', () {
      final config = FcliConfig(
        projectName: 'test_app',
        org: 'com.test',
        stateManagement: StateManagement.bloc,
        router: RouterOption.autoRoute,
        useFreezed: false,
        useDioClient: false,
        platforms: [Platform.android, Platform.ios, Platform.web],
        features: ['home', 'auth', 'profile'],
        generateTests: false,
        l10n: true,
      );

      final json = config.toJson();
      final restored = FcliConfig.fromJson(json);

      expect(restored.projectName, equals(config.projectName));
      expect(restored.org, equals(config.org));
      expect(restored.stateManagement, equals(config.stateManagement));
      expect(restored.router, equals(config.router));
      expect(restored.useFreezed, equals(config.useFreezed));
      expect(restored.useDioClient, equals(config.useDioClient));
      expect(restored.platforms.length, equals(config.platforms.length));
      expect(restored.features, equals(config.features));
      expect(restored.generateTests, equals(config.generateTests));
      expect(restored.l10n, equals(config.l10n));
    });

    test('copyWith creates new instance with updated values', () {
      final config = FcliConfig.defaults('my_app');
      final updated = config.copyWith(
        projectName: 'new_app',
        stateManagement: StateManagement.bloc,
      );

      expect(updated.projectName, equals('new_app'));
      expect(updated.stateManagement, equals(StateManagement.bloc));
      // Original should be unchanged
      expect(config.projectName, equals('my_app'));
      expect(config.stateManagement, equals(StateManagement.riverpod));
    });

    test('convenience getters work correctly', () {
      final riverpodConfig = FcliConfig(
        projectName: 'app',
        stateManagement: StateManagement.riverpod,
        router: RouterOption.goRouter,
      );

      expect(riverpodConfig.usesRiverpod, isTrue);
      expect(riverpodConfig.usesBloc, isFalse);
      expect(riverpodConfig.usesProvider, isFalse);
      expect(riverpodConfig.usesGoRouter, isTrue);
      expect(riverpodConfig.usesAutoRoute, isFalse);

      final blocConfig = FcliConfig(
        projectName: 'app',
        stateManagement: StateManagement.bloc,
        router: RouterOption.autoRoute,
      );

      expect(blocConfig.usesRiverpod, isFalse);
      expect(blocConfig.usesBloc, isTrue);
      expect(blocConfig.usesProvider, isFalse);
      expect(blocConfig.usesGoRouter, isFalse);
      expect(blocConfig.usesAutoRoute, isTrue);
    });

    test('platformStrings returns correct values', () {
      final config = FcliConfig(
        projectName: 'app',
        platforms: [Platform.android, Platform.ios, Platform.web],
      );

      expect(config.platformStrings, equals(['android', 'ios', 'web']));
    });
  });

  group('StateManagement', () {
    test('fromString parses correctly', () {
      expect(StateManagement.fromString('riverpod'),
          equals(StateManagement.riverpod));
      expect(StateManagement.fromString('bloc'), equals(StateManagement.bloc));
      expect(StateManagement.fromString('provider'),
          equals(StateManagement.provider));
      expect(StateManagement.fromString('RIVERPOD'),
          equals(StateManagement.riverpod));
    });

    test('fromString returns default for unknown', () {
      expect(
          StateManagement.fromString('unknown'), equals(StateManagement.riverpod));
    });
  });

  group('RouterOption', () {
    test('fromString parses correctly', () {
      expect(RouterOption.fromString('go_router'), equals(RouterOption.goRouter));
      expect(
          RouterOption.fromString('auto_route'), equals(RouterOption.autoRoute));
    });

    test('fromString returns default for unknown', () {
      expect(RouterOption.fromString('unknown'), equals(RouterOption.goRouter));
    });
  });

  group('Platform', () {
    test('fromString parses correctly', () {
      expect(Platform.fromString('android'), equals(Platform.android));
      expect(Platform.fromString('ios'), equals(Platform.ios));
      expect(Platform.fromString('web'), equals(Platform.web));
      expect(Platform.fromString('macos'), equals(Platform.macos));
      expect(Platform.fromString('windows'), equals(Platform.windows));
      expect(Platform.fromString('linux'), equals(Platform.linux));
    });

    test('fromStringList parses list correctly', () {
      final platforms = Platform.fromStringList(['android', 'ios', 'web']);
      expect(platforms.length, equals(3));
      expect(platforms, contains(Platform.android));
      expect(platforms, contains(Platform.ios));
      expect(platforms, contains(Platform.web));
    });
  });

  group('ConfigLoader', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fcli_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('configExists returns false for non-existent file', () {
      expect(ConfigLoader.configExists(tempDir.path), isFalse);
    });

    test('save and load work correctly', () async {
      final config = FcliConfig(
        projectName: 'test_project',
        org: 'com.test',
        stateManagement: StateManagement.bloc,
      );

      await ConfigLoader.save(tempDir.path, config);

      expect(ConfigLoader.configExists(tempDir.path), isTrue);

      final loaded = ConfigLoader.load(tempDir.path);
      expect(loaded, isNotNull);
      expect(loaded!.projectName, equals('test_project'));
      expect(loaded.org, equals('com.test'));
      expect(loaded.stateManagement, equals(StateManagement.bloc));
    });

    test('validate returns errors for invalid config', () {
      final invalidConfig = FcliConfig(
        projectName: '',
        platforms: [],
        org: '',
      );

      final errors = ConfigLoader.validate(invalidConfig);

      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.contains('Project name')), isTrue);
      expect(errors.any((e) => e.contains('platform')), isTrue);
      expect(errors.any((e) => e.contains('Organization')), isTrue);
    });

    test('validate returns errors for invalid project name', () {
      final invalidConfig = FcliConfig(
        projectName: 'Invalid-Name',
      );

      final errors = ConfigLoader.validate(invalidConfig);

      expect(errors.any((e) => e.contains('valid Dart package name')), isTrue);
    });

    test('validate returns empty for valid config', () {
      final validConfig = FcliConfig(
        projectName: 'valid_name',
        org: 'com.example',
        platforms: [Platform.android],
      );

      final errors = ConfigLoader.validate(validConfig);

      expect(errors, isEmpty);
    });
  });
}
