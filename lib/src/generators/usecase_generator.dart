import 'package:path/path.dart' as p;

import '../config/fcli_config.dart';
import '../templates/feature/usecase_feature_template.dart';
import '../utils/console_utils.dart';
import '../utils/file_utils.dart';
import '../utils/string_utils.dart';

/// Generator for creating use case files.
class UseCaseGenerator {
  const UseCaseGenerator({
    required this.config,
    required this.projectPath,
    this.verbose = false,
    this.dryRun = false,
  });

  final FcliConfig config;
  final String projectPath;
  final bool verbose;
  final bool dryRun;

  /// Generates a use case.
  ///
  /// [action] - The action (e.g., 'get', 'create', 'update', 'delete')
  /// [entityName] - The entity name (e.g., 'user', 'product')
  /// [featureName] - The feature this use case belongs to
  Future<void> generate(
    String action,
    String entityName,
    String featureName,
  ) async {
    final snakeAction = StringUtils.toSnakeCase(action);
    final snakeEntity = StringUtils.toSnakeCase(entityName);
    final snakeFeature = StringUtils.toSnakeCase(featureName);
    final pascalAction = StringUtils.toPascalCase(action);
    final pascalEntity = StringUtils.toPascalCase(entityName);

    final usecasePath = p.join(
      projectPath,
      'lib',
      'features',
      snakeFeature,
      'domain',
      'usecases',
      '${snakeAction}_${snakeEntity}_usecase.dart',
    );

    if (verbose) {
      ConsoleUtils.info('Generating use case: $pascalAction$pascalEntity');
    }

    if (dryRun) {
      ConsoleUtils.muted('Would create: $usecasePath');
      return;
    }

    // Check if feature exists
    final featurePath = p.join(projectPath, 'lib', 'features', snakeFeature);
    if (!FileUtils.directoryExistsSync(featurePath)) {
      ConsoleUtils.error('Feature "$featureName" does not exist.');
      ConsoleUtils.info('Run "flg g feature $featureName" first.');
      return;
    }

    // Determine params based on action
    String? paramsType;
    String? paramsFields;
    String? returnType;

    switch (action.toLowerCase()) {
      case 'get':
        paramsType = 'Get${pascalEntity}Params';
        paramsFields = '{required this.id}';
      case 'getall' || 'get_all' || 'list':
        returnType = 'List<${pascalEntity}Entity>';
      case 'create':
        paramsType = 'Create${pascalEntity}Params';
        paramsFields = '{required this.entity}';
      case 'update':
        paramsType = 'Update${pascalEntity}Params';
        paramsFields = '{required this.entity}';
      case 'delete':
        paramsType = 'Delete${pascalEntity}Params';
        paramsFields = '{required this.id}';
        returnType = 'void';
    }

    final content = UseCaseFeatureTemplate.generate(
      featureName,
      action,
      config,
      entityName: entityName,
      paramsType: paramsType,
      paramsFields: paramsFields,
      returnType: returnType,
    );

    await FileUtils.writeFile(usecasePath, content);

    ConsoleUtils.success('Use case created: $usecasePath');
  }

  /// Generates all common use cases for a feature.
  Future<void> generateCommon(
    String featureName, {
    String? entityName,
  }) async {
    final snakeFeature = StringUtils.toSnakeCase(featureName);
    final usecasesPath = p.join(
      projectPath,
      'lib',
      'features',
      snakeFeature,
      'domain',
      'usecases',
    );

    if (verbose) {
      ConsoleUtils.info('Generating common use cases for: $featureName');
    }

    if (dryRun) {
      ConsoleUtils.muted('Would create CRUD use cases in: $usecasesPath');
      return;
    }

    // Check if feature exists
    final featurePath = p.join(projectPath, 'lib', 'features', snakeFeature);
    if (!FileUtils.directoryExistsSync(featurePath)) {
      ConsoleUtils.error('Feature "$featureName" does not exist.');
      ConsoleUtils.info('Run "flg g feature $featureName" first.');
      return;
    }

    final usecases = UseCaseFeatureTemplate.generateCommonUseCases(
      featureName,
      config,
      entityName: entityName,
    );

    for (final entry in usecases.entries) {
      final path = p.join(usecasesPath, entry.key);
      await FileUtils.writeFile(path, entry.value);
      ConsoleUtils.success('Use case created: $path');
    }
  }
}
