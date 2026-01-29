import 'package:path/path.dart' as p;

import '../config/fcli_config.dart';
import '../templates/feature/notifier_template.dart';
import '../utils/console_utils.dart';
import '../utils/file_utils.dart';
import '../utils/string_utils.dart';

/// Generator for creating provider/notifier/bloc files.
class ProviderGenerator {
  const ProviderGenerator({
    required this.config,
    required this.projectPath,
    this.verbose = false,
    this.dryRun = false,
  });

  final FcliConfig config;
  final String projectPath;
  final bool verbose;
  final bool dryRun;

  /// Generates a provider/notifier/bloc for a feature.
  ///
  /// [providerName] - The name of the provider
  /// [featureName] - The feature this provider belongs to
  Future<void> generate(
    String providerName,
    String featureName,
  ) async {
    final snakeProvider = StringUtils.toSnakeCase(providerName);
    final snakeFeature = StringUtils.toSnakeCase(featureName);
    final pascalProvider = StringUtils.toPascalCase(providerName);

    final providersPath = p.join(
      projectPath,
      'lib',
      'features',
      snakeFeature,
      'presentation',
      'providers',
    );

    if (verbose) {
      ConsoleUtils.info('Generating provider: $pascalProvider in feature: $featureName');
    }

    if (dryRun) {
      _showDryRunOutput(providersPath, snakeProvider);
      return;
    }

    // Check if feature exists
    final featurePath = p.join(projectPath, 'lib', 'features', snakeFeature);
    if (!FileUtils.directoryExistsSync(featurePath)) {
      ConsoleUtils.error('Feature "$featureName" does not exist.');
      ConsoleUtils.info('Run "flg g feature $featureName" first.');
      return;
    }

    // Generate based on state management
    if (config.usesRiverpod) {
      await _generateRiverpod(providersPath, providerName);
    } else if (config.usesBloc) {
      await _generateBloc(providersPath, providerName);
    } else {
      await _generateProvider(providersPath, providerName);
    }
  }

  void _showDryRunOutput(String providersPath, String snakeProvider) {
    if (config.usesRiverpod) {
      ConsoleUtils.muted('Would create: $providersPath/${snakeProvider}_notifier.dart');
      ConsoleUtils.muted('Would create: $providersPath/${snakeProvider}_state.dart');
    } else if (config.usesBloc) {
      ConsoleUtils.muted('Would create: $providersPath/${snakeProvider}_bloc.dart');
      ConsoleUtils.muted('Would create: $providersPath/${snakeProvider}_event.dart');
      ConsoleUtils.muted('Would create: $providersPath/${snakeProvider}_state.dart');
    } else {
      ConsoleUtils.muted('Would create: $providersPath/${snakeProvider}_provider.dart');
    }
  }

  Future<void> _generateRiverpod(String providersPath, String providerName) async {
    final snakeProvider = StringUtils.toSnakeCase(providerName);

    // Notifier
    final notifierPath = p.join(providersPath, '${snakeProvider}_notifier.dart');
    await FileUtils.writeFile(
      notifierPath,
      NotifierTemplate.generate(providerName, config),
    );
    ConsoleUtils.success('Notifier created: $notifierPath');

    // State
    final statePath = p.join(providersPath, '${snakeProvider}_state.dart');
    await FileUtils.writeFile(
      statePath,
      NotifierTemplate.generateState(providerName, config),
    );
    ConsoleUtils.success('State created: $statePath');
  }

  Future<void> _generateBloc(String providersPath, String providerName) async {
    final snakeProvider = StringUtils.toSnakeCase(providerName);

    // Bloc
    final blocPath = p.join(providersPath, '${snakeProvider}_bloc.dart');
    await FileUtils.writeFile(
      blocPath,
      NotifierTemplate.generate(providerName, config),
    );
    ConsoleUtils.success('Bloc created: $blocPath');

    // Events
    final eventPath = p.join(providersPath, '${snakeProvider}_event.dart');
    await FileUtils.writeFile(
      eventPath,
      NotifierTemplate.generateBlocEvents(providerName),
    );
    ConsoleUtils.success('Events created: $eventPath');

    // States
    final statePath = p.join(providersPath, '${snakeProvider}_state.dart');
    await FileUtils.writeFile(
      statePath,
      NotifierTemplate.generateBlocStates(providerName),
    );
    ConsoleUtils.success('State created: $statePath');
  }

  Future<void> _generateProvider(String providersPath, String providerName) async {
    final snakeProvider = StringUtils.toSnakeCase(providerName);

    final providerPath = p.join(providersPath, '${snakeProvider}_provider.dart');
    await FileUtils.writeFile(
      providerPath,
      NotifierTemplate.generate(providerName, config),
    );
    ConsoleUtils.success('Provider created: $providerPath');
  }
}
