import 'package:path/path.dart' as p;

import '../config/fcli_config.dart';
import '../templates/feature/datasource_template.dart';
import '../templates/feature/repository_abstract_template.dart';
import '../templates/feature/repository_impl_template.dart';
import '../utils/console_utils.dart';
import '../utils/file_utils.dart';
import '../utils/string_utils.dart';

/// Generator for creating repository files.
class RepositoryGenerator {
  const RepositoryGenerator({
    required this.config,
    required this.projectPath,
    this.verbose = false,
    this.dryRun = false,
  });

  final FcliConfig config;
  final String projectPath;
  final bool verbose;
  final bool dryRun;

  /// Generates a repository (abstract + implementation).
  ///
  /// [repositoryName] - The name of the repository (e.g., 'user', 'product')
  /// [featureName] - The feature this repository belongs to
  /// [withDataSource] - Whether to also generate a data source
  Future<void> generate(
    String repositoryName,
    String featureName, {
    bool withDataSource = true,
  }) async {
    final snakeRepo = StringUtils.toSnakeCase(repositoryName);
    final snakeFeature = StringUtils.toSnakeCase(featureName);
    final pascalRepo = StringUtils.toPascalCase(repositoryName);

    final domainPath = p.join(
      projectPath,
      'lib',
      'features',
      snakeFeature,
      'domain',
      'repositories',
    );

    final dataPath = p.join(
      projectPath,
      'lib',
      'features',
      snakeFeature,
      'data',
      'repositories',
    );

    final datasourcePath = p.join(
      projectPath,
      'lib',
      'features',
      snakeFeature,
      'data',
      'datasources',
    );

    if (verbose) {
      ConsoleUtils.info('Generating repository: $pascalRepo in feature: $featureName');
    }

    if (dryRun) {
      ConsoleUtils.muted('Would create: $domainPath/${snakeRepo}_repository.dart');
      ConsoleUtils.muted('Would create: $dataPath/${snakeRepo}_repository_impl.dart');
      if (withDataSource) {
        ConsoleUtils.muted('Would create: $datasourcePath/${snakeRepo}_remote_datasource.dart');
      }
      return;
    }

    // Check if feature exists
    final featurePath = p.join(projectPath, 'lib', 'features', snakeFeature);
    if (!FileUtils.directoryExistsSync(featurePath)) {
      ConsoleUtils.error('Feature "$featureName" does not exist.');
      ConsoleUtils.info('Run "flg g feature $featureName" first.');
      return;
    }

    // Generate abstract repository
    final abstractPath = p.join(domainPath, '${snakeRepo}_repository.dart');
    await FileUtils.writeFile(
      abstractPath,
      RepositoryAbstractTemplate.generate(repositoryName, config),
    );
    ConsoleUtils.success('Repository interface created: $abstractPath');

    // Generate repository implementation
    final implPath = p.join(dataPath, '${snakeRepo}_repository_impl.dart');
    await FileUtils.writeFile(
      implPath,
      RepositoryImplTemplate.generate(repositoryName, config),
    );
    ConsoleUtils.success('Repository implementation created: $implPath');

    // Generate data source
    if (withDataSource) {
      final remoteDsPath = p.join(datasourcePath, '${snakeRepo}_remote_datasource.dart');
      await FileUtils.writeFile(
        remoteDsPath,
        DataSourceTemplate.generate(repositoryName, config),
      );
      ConsoleUtils.success('Remote data source created: $remoteDsPath');
    }
  }

  /// Generates a local data source for caching.
  Future<void> generateLocalDataSource(
    String name,
    String featureName,
  ) async {
    final snakeName = StringUtils.toSnakeCase(name);
    final snakeFeature = StringUtils.toSnakeCase(featureName);
    final pascalName = StringUtils.toPascalCase(name);

    final datasourcePath = p.join(
      projectPath,
      'lib',
      'features',
      snakeFeature,
      'data',
      'datasources',
      '${snakeName}_local_datasource.dart',
    );

    if (verbose) {
      ConsoleUtils.info('Generating local data source: $pascalName');
    }

    if (dryRun) {
      ConsoleUtils.muted('Would create: $datasourcePath');
      return;
    }

    // Check if feature exists
    final featurePath = p.join(projectPath, 'lib', 'features', snakeFeature);
    if (!FileUtils.directoryExistsSync(featurePath)) {
      ConsoleUtils.error('Feature "$featureName" does not exist.');
      ConsoleUtils.info('Run "flg g feature $featureName" first.');
      return;
    }

    await FileUtils.writeFile(
      datasourcePath,
      DataSourceTemplate.generateLocal(featureName, config, entityName: name),
    );

    ConsoleUtils.success('Local data source created: $datasourcePath');
  }
}
