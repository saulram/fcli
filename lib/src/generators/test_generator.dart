import 'package:path/path.dart' as p;

import '../config/fcli_config.dart';
import '../templates/feature/test_template.dart';
import '../utils/console_utils.dart';
import '../utils/file_utils.dart';
import '../utils/string_utils.dart';

/// Test components supported by the test generator.
enum TestComponent {
  feature,
  screen,
  usecase,
  repository;
}

/// Generator for creating test scaffolds.
class TestGenerator {
  const TestGenerator({
    required this.config,
    required this.projectPath,
    this.verbose = false,
    this.dryRun = false,
  });

  final FcliConfig config;
  final String projectPath;
  final bool verbose;
  final bool dryRun;

  /// Generates a feature-level test scaffold.
  Future<void> generateFeature(String featureName) async {
    final snakeFeature = StringUtils.toSnakeCase(featureName);
    final path = p.join(
      projectPath,
      'test',
      'features',
      snakeFeature,
      '${snakeFeature}_feature_test.dart',
    );

    await _write(path, TestTemplate.generateFeature(featureName));
  }

  /// Generates a screen test scaffold.
  Future<void> generateScreen(String screenName, String featureName) async {
    final snakeFeature = StringUtils.toSnakeCase(featureName);
    final snakeScreen = StringUtils.toSnakeCase(screenName);
    final path = p.join(
      projectPath,
      'test',
      'features',
      snakeFeature,
      'presentation',
      'screens',
      '${snakeScreen}_screen_test.dart',
    );

    await _write(path, TestTemplate.generateScreen(screenName, featureName));
  }

  /// Generates a use case test scaffold.
  Future<void> generateUseCase(String useCaseName, String featureName) async {
    final snakeFeature = StringUtils.toSnakeCase(featureName);
    final snakeUseCase = StringUtils.toSnakeCase(useCaseName);
    final path = p.join(
      projectPath,
      'test',
      'features',
      snakeFeature,
      'domain',
      'usecases',
      '${snakeUseCase}_usecase_test.dart',
    );

    await _write(path, TestTemplate.generateUseCase(useCaseName, featureName));
  }

  /// Generates a repository test scaffold.
  Future<void> generateRepository(
    String repositoryName,
    String featureName,
  ) async {
    final snakeFeature = StringUtils.toSnakeCase(featureName);
    final snakeRepository = StringUtils.toSnakeCase(repositoryName);
    final path = p.join(
      projectPath,
      'test',
      'features',
      snakeFeature,
      'domain',
      'repositories',
      '${snakeRepository}_repository_test.dart',
    );

    await _write(
      path,
      TestTemplate.generateRepository(repositoryName, featureName),
    );
  }

  Future<void> _write(String path, String content) async {
    if (verbose || dryRun) {
      ConsoleUtils.muted(dryRun ? 'Would create: $path' : 'Creating: $path');
    }

    if (dryRun) {
      return;
    }

    await FileUtils.writeFile(path, content);
    ConsoleUtils.success('Test created: $path');
  }
}
