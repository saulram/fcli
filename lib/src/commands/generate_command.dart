import 'package:args/command_runner.dart';

import '../config/config_loader.dart';
import '../config/fcli_config.dart';
import '../generators/feature_generator.dart';
import '../generators/provider_generator.dart';
import '../generators/repository_generator.dart';
import '../generators/screen_generator.dart';
import '../generators/usecase_generator.dart';
import '../generators/widget_generator.dart';
import '../utils/console_utils.dart';

/// Command for generating code components.
class GenerateCommand extends Command<int> {
  GenerateCommand() {
    addSubcommand(GenerateFeatureCommand());
    addSubcommand(GenerateScreenCommand());
    addSubcommand(GenerateWidgetCommand());
    addSubcommand(GenerateProviderCommand());
    addSubcommand(GenerateUseCaseCommand());
    addSubcommand(GenerateRepositoryCommand());
  }

  @override
  String get name => 'generate';

  @override
  List<String> get aliases => ['g'];

  @override
  String get description => 'Generate code components (feature, screen, widget, etc.).';
}

/// Base class for generate subcommands.
abstract class GenerateSubcommand extends Command<int> {
  GenerateSubcommand() {
    argParser
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

  bool get dryRun => argResults!['dry-run'] as bool;
  bool get verbose => argResults!['verbose'] as bool;

  /// Gets the config and project path, returning null if not in a project.
  (FcliConfig, String)? getConfigAndPath() {
    final projectPath = ConfigLoader.ensureInProject();
    if (projectPath == null) {
      return null;
    }

    final config = ConfigLoader.load(projectPath);
    if (config == null) {
      ConsoleUtils.error('Failed to load flg.json configuration.');
      return null;
    }

    return (config, projectPath);
  }
}

/// Subcommand for generating a feature.
class GenerateFeatureCommand extends GenerateSubcommand {
  @override
  String get name => 'feature';

  @override
  List<String> get aliases => ['f'];

  @override
  String get description => 'Generate a new feature module with all layers.';

  @override
  String get invocation => 'flg generate feature <feature_name>';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      ConsoleUtils.error('Please provide a feature name.');
      ConsoleUtils.info('Usage: flg g feature <feature_name>');
      return 1;
    }

    final featureName = argResults!.rest.first;
    final result = getConfigAndPath();
    if (result == null) return 1;

    final (config, projectPath) = result;

    final generator = FeatureGenerator(
      config: config,
      projectPath: projectPath,
      verbose: verbose,
      dryRun: dryRun,
    );

    await generator.generate(featureName);

    if (!dryRun) {
      // Update flg.json with new feature
      final updatedConfig = config.copyWith(
        features: [...config.features, featureName],
      );
      ConfigLoader.saveSync(projectPath, updatedConfig);
    }

    return 0;
  }
}

/// Subcommand for generating a screen.
class GenerateScreenCommand extends GenerateSubcommand {
  GenerateScreenCommand() {
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'The feature this screen belongs to.',
      )
      ..addFlag(
        'simple',
        abbr: 's',
        help: 'Generate a simple screen without state management.',
        negatable: false,
      );
  }

  @override
  String get name => 'screen';

  @override
  List<String> get aliases => ['s'];

  @override
  String get description => 'Generate a new screen widget.';

  @override
  String get invocation => 'flg generate screen <screen_name> -f <feature>';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      ConsoleUtils.error('Please provide a screen name.');
      ConsoleUtils.info('Usage: flg g screen <screen_name> -f <feature>');
      return 1;
    }

    final screenName = argResults!.rest.first;
    final featureName = argResults!['feature'] as String?;
    final simple = argResults!['simple'] as bool;

    if (featureName == null) {
      ConsoleUtils.error('Please specify a feature with -f <feature>.');
      return 1;
    }

    final result = getConfigAndPath();
    if (result == null) return 1;

    final (config, projectPath) = result;

    final generator = ScreenGenerator(
      config: config,
      projectPath: projectPath,
      verbose: verbose,
      dryRun: dryRun,
    );

    await generator.generate(screenName, featureName, simple: simple);

    return 0;
  }
}

/// Subcommand for generating a widget.
class GenerateWidgetCommand extends GenerateSubcommand {
  GenerateWidgetCommand() {
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'The feature this widget belongs to.',
      )
      ..addOption(
        'type',
        abbr: 't',
        help: 'Widget type (stateless, stateful, card, list_tile, form).',
        allowed: ['stateless', 'stateful', 'card', 'list_tile', 'form'],
        defaultsTo: 'stateless',
      );
  }

  @override
  String get name => 'widget';

  @override
  List<String> get aliases => ['w'];

  @override
  String get description => 'Generate a new widget.';

  @override
  String get invocation => 'flg generate widget <widget_name> -f <feature>';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      ConsoleUtils.error('Please provide a widget name.');
      ConsoleUtils.info('Usage: flg g widget <widget_name> -f <feature>');
      return 1;
    }

    final widgetName = argResults!.rest.first;
    final featureName = argResults!['feature'] as String?;
    final typeStr = argResults!['type'] as String;

    if (featureName == null) {
      ConsoleUtils.error('Please specify a feature with -f <feature>.');
      return 1;
    }

    final result = getConfigAndPath();
    if (result == null) return 1;

    final (config, projectPath) = result;

    final type = switch (typeStr) {
      'stateless' => WidgetType.stateless,
      'stateful' => WidgetType.stateful,
      'card' => WidgetType.entityCard,
      'list_tile' => WidgetType.entityListTile,
      'form' => WidgetType.entityForm,
      _ => WidgetType.stateless,
    };

    final generator = WidgetGenerator(
      config: config,
      projectPath: projectPath,
      verbose: verbose,
      dryRun: dryRun,
    );

    await generator.generate(widgetName, featureName, type: type);

    return 0;
  }
}

/// Subcommand for generating a provider/notifier/bloc.
class GenerateProviderCommand extends GenerateSubcommand {
  GenerateProviderCommand() {
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'The feature this provider belongs to.',
    );
  }

  @override
  String get name => 'provider';

  @override
  List<String> get aliases => ['p'];

  @override
  String get description => 'Generate a new provider/notifier/bloc.';

  @override
  String get invocation => 'flg generate provider <provider_name> -f <feature>';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      ConsoleUtils.error('Please provide a provider name.');
      ConsoleUtils.info('Usage: flg g provider <provider_name> -f <feature>');
      return 1;
    }

    final providerName = argResults!.rest.first;
    final featureName = argResults!['feature'] as String?;

    if (featureName == null) {
      ConsoleUtils.error('Please specify a feature with -f <feature>.');
      return 1;
    }

    final result = getConfigAndPath();
    if (result == null) return 1;

    final (config, projectPath) = result;

    final generator = ProviderGenerator(
      config: config,
      projectPath: projectPath,
      verbose: verbose,
      dryRun: dryRun,
    );

    await generator.generate(providerName, featureName);

    return 0;
  }
}

/// Subcommand for generating a use case.
class GenerateUseCaseCommand extends GenerateSubcommand {
  GenerateUseCaseCommand() {
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'The feature this use case belongs to.',
      )
      ..addOption(
        'action',
        abbr: 'a',
        help: 'The action (get, create, update, delete, getAll).',
        allowed: ['get', 'create', 'update', 'delete', 'getAll'],
      )
      ..addFlag(
        'crud',
        help: 'Generate all CRUD use cases.',
        negatable: false,
      );
  }

  @override
  String get name => 'usecase';

  @override
  List<String> get aliases => ['u'];

  @override
  String get description => 'Generate a new use case.';

  @override
  String get invocation =>
      'flg generate usecase <entity_name> -f <feature> -a <action>';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      ConsoleUtils.error('Please provide an entity name.');
      ConsoleUtils.info('Usage: flg g usecase <entity_name> -f <feature> -a <action>');
      return 1;
    }

    final entityName = argResults!.rest.first;
    final featureName = argResults!['feature'] as String?;
    final action = argResults!['action'] as String?;
    final crud = argResults!['crud'] as bool;

    if (featureName == null) {
      ConsoleUtils.error('Please specify a feature with -f <feature>.');
      return 1;
    }

    final result = getConfigAndPath();
    if (result == null) return 1;

    final (config, projectPath) = result;

    final generator = UseCaseGenerator(
      config: config,
      projectPath: projectPath,
      verbose: verbose,
      dryRun: dryRun,
    );

    if (crud) {
      await generator.generateCommon(featureName, entityName: entityName);
    } else {
      if (action == null) {
        ConsoleUtils.error('Please specify an action with -a <action> or use --crud.');
        return 1;
      }
      await generator.generate(action, entityName, featureName);
    }

    return 0;
  }
}

/// Subcommand for generating a repository.
class GenerateRepositoryCommand extends GenerateSubcommand {
  GenerateRepositoryCommand() {
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'The feature this repository belongs to.',
      )
      ..addFlag(
        'no-datasource',
        help: 'Skip generating the data source.',
        negatable: false,
      )
      ..addFlag(
        'local',
        abbr: 'l',
        help: 'Generate a local data source for caching.',
        negatable: false,
      );
  }

  @override
  String get name => 'repository';

  @override
  List<String> get aliases => ['r'];

  @override
  String get description => 'Generate a new repository (abstract + implementation).';

  @override
  String get invocation => 'flg generate repository <name> -f <feature>';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      ConsoleUtils.error('Please provide a repository name.');
      ConsoleUtils.info('Usage: flg g repository <name> -f <feature>');
      return 1;
    }

    final repositoryName = argResults!.rest.first;
    final featureName = argResults!['feature'] as String?;
    final noDataSource = argResults!['no-datasource'] as bool;
    final local = argResults!['local'] as bool;

    if (featureName == null) {
      ConsoleUtils.error('Please specify a feature with -f <feature>.');
      return 1;
    }

    final result = getConfigAndPath();
    if (result == null) return 1;

    final (config, projectPath) = result;

    final generator = RepositoryGenerator(
      config: config,
      projectPath: projectPath,
      verbose: verbose,
      dryRun: dryRun,
    );

    await generator.generate(
      repositoryName,
      featureName,
      withDataSource: !noDataSource,
    );

    if (local) {
      await generator.generateLocalDataSource(repositoryName, featureName);
    }

    return 0;
  }
}
