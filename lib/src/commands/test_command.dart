import 'package:args/command_runner.dart';

import '../config/config_loader.dart';
import '../generators/test_generator.dart';
import '../utils/console_utils.dart';

/// Command for generating test scaffolds.
class TestCommand extends Command<int> {
  TestCommand() {
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Feature for screen, usecase, or repository tests.',
      )
      ..addFlag(
        'dry-run',
        help: 'Show what would be generated without creating files.',
        negatable: false,
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Show verbose output.',
        negatable: false,
      );
  }

  @override
  String get name => 'test';

  @override
  String get description => 'Generate test scaffolds for features and layers.';

  @override
  String get invocation =>
      'flg test [feature|screen|usecase|repository] <name>';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      ConsoleUtils.error('Please provide what to test.');
      ConsoleUtils.info('Usage: flg test feature auth');
      return 1;
    }

    final result = _parseTarget(argResults!.rest);
    final projectPath = ConfigLoader.ensureInProject();
    if (projectPath == null) return 1;

    final config = ConfigLoader.load(projectPath);
    if (config == null) {
      ConsoleUtils.error('Failed to load flg.json configuration.');
      return 1;
    }

    final generator = TestGenerator(
      config: config,
      projectPath: projectPath,
      dryRun: argResults!['dry-run'] as bool,
      verbose: argResults!['verbose'] as bool,
    );

    switch (result.component) {
      case TestComponent.feature:
        await generator.generateFeature(result.name);
      case TestComponent.screen:
        final feature = _requiredFeature();
        if (feature == null) return 1;
        await generator.generateScreen(result.name, feature);
      case TestComponent.usecase:
        final feature = _requiredFeature();
        if (feature == null) return 1;
        await generator.generateUseCase(result.name, feature);
      case TestComponent.repository:
        final feature = _requiredFeature();
        if (feature == null) return 1;
        await generator.generateRepository(result.name, feature);
    }

    return 0;
  }

  _TestTarget _parseTarget(List<String> rest) {
    final first = rest.first;
    if (rest.length == 1) {
      return _TestTarget(TestComponent.feature, first);
    }

    final component = switch (first) {
      'feature' || 'f' => TestComponent.feature,
      'screen' || 's' => TestComponent.screen,
      'usecase' || 'u' => TestComponent.usecase,
      'repository' || 'r' => TestComponent.repository,
      _ => TestComponent.feature,
    };

    return _TestTarget(component, rest[1]);
  }

  String? _requiredFeature() {
    final feature = argResults!['feature'] as String?;
    if (feature == null) {
      ConsoleUtils.error('Please specify a feature with -f <feature>.');
      return null;
    }
    return feature;
  }
}

class _TestTarget {
  const _TestTarget(this.component, this.name);

  final TestComponent component;
  final String name;
}
