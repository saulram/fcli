import 'package:path/path.dart' as p;

import '../config/fcli_config.dart';
import '../templates/feature/datasource_template.dart';
import '../templates/feature/entity_template.dart';
import '../templates/feature/model_template.dart';
import '../templates/feature/notifier_template.dart';
import '../templates/feature/repository_abstract_template.dart';
import '../templates/feature/repository_impl_template.dart';
import '../templates/feature/screen_template.dart';
import '../templates/feature/widget_template.dart';
import '../utils/console_utils.dart';
import '../utils/file_utils.dart';
import '../utils/string_utils.dart';

/// Generator for creating a feature module with Clean Architecture layers.
class FeatureGenerator {
  const FeatureGenerator({
    required this.config,
    required this.projectPath,
    this.verbose = false,
    this.dryRun = false,
  });

  final FcliConfig config;
  final String projectPath;
  final bool verbose;
  final bool dryRun;

  /// Path to the lib directory.
  String get libPath => p.join(projectPath, 'lib');

  /// Path to the features directory.
  String get featuresPath => p.join(libPath, 'features');

  /// Generates a complete feature module.
  Future<void> generate(String featureName) async {
    final snakeName = StringUtils.toSnakeCase(featureName);
    final featurePath = p.join(featuresPath, snakeName);

    if (verbose) {
      ConsoleUtils.info('Generating feature: $featureName');
    }

    if (dryRun) {
      _showDryRunOutput(snakeName);
      return;
    }

    // Create directory structure
    await _createDirectoryStructure(featurePath);

    // Generate domain layer
    await _generateDomainLayer(featurePath, featureName);

    // Generate data layer
    await _generateDataLayer(featurePath, featureName);

    // Generate presentation layer
    await _generatePresentationLayer(featurePath, featureName);

    if (verbose) {
      ConsoleUtils.success('Feature $featureName generated');
    }
  }

  void _showDryRunOutput(String snakeName) {
    ConsoleUtils.muted('  lib/features/$snakeName/');
    ConsoleUtils.muted('  lib/features/$snakeName/domain/');
    ConsoleUtils.muted('  lib/features/$snakeName/domain/entities/');
    ConsoleUtils.muted('  lib/features/$snakeName/domain/repositories/');
    ConsoleUtils.muted('  lib/features/$snakeName/domain/usecases/');
    ConsoleUtils.muted('  lib/features/$snakeName/data/');
    ConsoleUtils.muted('  lib/features/$snakeName/data/models/');
    ConsoleUtils.muted('  lib/features/$snakeName/data/repositories/');
    ConsoleUtils.muted('  lib/features/$snakeName/data/datasources/');
    ConsoleUtils.muted('  lib/features/$snakeName/presentation/');
    ConsoleUtils.muted('  lib/features/$snakeName/presentation/screens/');
    ConsoleUtils.muted('  lib/features/$snakeName/presentation/widgets/');
    ConsoleUtils.muted('  lib/features/$snakeName/presentation/providers/');
  }

  Future<void> _createDirectoryStructure(String featurePath) async {
    final directories = [
      // Domain
      p.join(featurePath, 'domain', 'entities'),
      p.join(featurePath, 'domain', 'repositories'),
      p.join(featurePath, 'domain', 'usecases'),
      // Data
      p.join(featurePath, 'data', 'models'),
      p.join(featurePath, 'data', 'repositories'),
      p.join(featurePath, 'data', 'datasources'),
      // Presentation
      p.join(featurePath, 'presentation', 'screens'),
      p.join(featurePath, 'presentation', 'widgets'),
      p.join(featurePath, 'presentation', 'providers'),
    ];

    for (final dir in directories) {
      await FileUtils.createDirectory(dir);
    }
  }

  Future<void> _generateDomainLayer(
    String featurePath,
    String featureName,
  ) async {
    final snakeName = StringUtils.toSnakeCase(featureName);

    // Entity
    await FileUtils.writeFile(
      p.join(featurePath, 'domain', 'entities', '${snakeName}_entity.dart'),
      EntityTemplate.generate(featureName),
    );

    // Repository interface
    await FileUtils.writeFile(
      p.join(featurePath, 'domain', 'repositories',
          '${snakeName}_repository.dart'),
      RepositoryAbstractTemplate.generate(featureName, config),
    );
  }

  Future<void> _generateDataLayer(
    String featurePath,
    String featureName,
  ) async {
    final snakeName = StringUtils.toSnakeCase(featureName);

    // Model
    await FileUtils.writeFile(
      p.join(featurePath, 'data', 'models', '${snakeName}_model.dart'),
      ModelTemplate.generate(featureName, config),
    );

    // Repository implementation
    await FileUtils.writeFile(
      p.join(featurePath, 'data', 'repositories',
          '${snakeName}_repository_impl.dart'),
      RepositoryImplTemplate.generate(featureName, config),
    );

    // Remote data source
    await FileUtils.writeFile(
      p.join(featurePath, 'data', 'datasources',
          '${snakeName}_remote_datasource.dart'),
      DataSourceTemplate.generate(featureName, config),
    );
  }

  Future<void> _generatePresentationLayer(
    String featurePath,
    String featureName,
  ) async {
    final snakeName = StringUtils.toSnakeCase(featureName);

    // Screen
    await FileUtils.writeFile(
      p.join(
          featurePath, 'presentation', 'screens', '${snakeName}_screen.dart'),
      ScreenTemplate.generate(featureName, featureName, config),
    );

    // Provider/Notifier/Bloc
    final providerFileName = _getProviderFileName(snakeName);
    await FileUtils.writeFile(
      p.join(featurePath, 'presentation', 'providers', providerFileName),
      NotifierTemplate.generate(featureName, config),
    );

    // State file for Riverpod
    if (config.usesRiverpod) {
      await FileUtils.writeFile(
        p.join(featurePath, 'presentation', 'providers',
            '${snakeName}_state.dart'),
        NotifierTemplate.generateState(featureName, config),
      );
    }

    // Event and State files for Bloc
    if (config.usesBloc) {
      await FileUtils.writeFile(
        p.join(featurePath, 'presentation', 'providers',
            '${snakeName}_event.dart'),
        NotifierTemplate.generateBlocEvents(featureName),
      );
      await FileUtils.writeFile(
        p.join(featurePath, 'presentation', 'providers',
            '${snakeName}_state.dart'),
        NotifierTemplate.generateBlocStates(featureName),
      );
    }

    // Entity card widget
    await FileUtils.writeFile(
      p.join(featurePath, 'presentation', 'widgets', '${snakeName}_card.dart'),
      WidgetTemplate.generateEntityCard(featureName, config),
    );
  }

  String _getProviderFileName(String snakeName) {
    if (config.usesRiverpod) {
      return '${snakeName}_provider.dart';
    } else if (config.usesBloc) {
      return '${snakeName}_bloc.dart';
    } else {
      return '${snakeName}_provider.dart';
    }
  }
}
