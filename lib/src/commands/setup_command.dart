import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../config/config_loader.dart';
import '../config/fcli_config.dart';
import '../generators/feature_generator.dart';
import '../templates/config/fcli_json_template.dart';
import '../templates/core/app_router_template.dart';
import '../templates/core/exceptions_template.dart';
import '../templates/core/failures_template.dart';
import '../templates/core/usecase_template.dart';
import '../utils/console_utils.dart';
import '../utils/file_utils.dart';
import '../utils/process_utils.dart';

/// Command for setting up flg in an existing Flutter project.
class SetupCommand extends Command<int> {
  SetupCommand() {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Force re-prompt for configuration even if flg.json exists.',
        negatable: false,
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
      )
      ..addFlag(
        'skip-prompts',
        abbr: 's',
        help: 'Skip interactive prompts and use defaults.',
        negatable: false,
      )
      ..addFlag(
        'skip-deps',
        help: 'Skip adding dependencies to pubspec.yaml.',
        negatable: false,
      )
      ..addOption(
        'state',
        help: 'State management solution (riverpod, bloc, provider).',
        allowed: ['riverpod', 'bloc', 'provider'],
        defaultsTo: 'riverpod',
      )
      ..addOption(
        'router',
        help: 'Router solution (go_router, auto_route).',
        allowed: ['go_router', 'auto_route'],
        defaultsTo: 'go_router',
      )
      ..addFlag(
        'freezed',
        help: 'Use Freezed for data classes.',
        defaultsTo: true,
      )
      ..addFlag(
        'dio',
        help: 'Use Dio HTTP client.',
        defaultsTo: true,
      )
      ..addOption(
        'feature',
        help: 'Initial feature name (leave empty to skip).',
      );
  }

  @override
  String get name => 'setup';

  @override
  String get description =>
      'Set up fcli in an existing Flutter project with Clean Architecture.';

  @override
  String get invocation => 'flg setup [options]';

  @override
  Future<int> run() async {
    final force = argResults!['force'] as bool;
    final dryRun = argResults!['dry-run'] as bool;
    final verbose = argResults!['verbose'] as bool;
    final skipPrompts = argResults!['skip-prompts'] as bool;
    final skipDeps = argResults!['skip-deps'] as bool;

    final projectPath = Directory.current.path;
    final pubspecPath = p.join(projectPath, 'pubspec.yaml');
    final libPath = p.join(projectPath, 'lib');

    // Check if this is a Flutter project
    if (!FileUtils.fileExistsSync(pubspecPath)) {
      ConsoleUtils.error('No pubspec.yaml found in current directory.');
      ConsoleUtils.info('Please run this command from a Flutter project root.');
      ConsoleUtils.info('Or use "flg init <project_name>" to create a new project.');
      return 1;
    }

    // Check if flg.json already exists
    if (ConfigLoader.configExists(projectPath) && !force) {
      ConsoleUtils.warning('flg.json already exists.');
      if (!ConsoleUtils.confirm('Do you want to reconfigure?')) {
        ConsoleUtils.info('Use "flg g f <feature_name>" to generate features.');
        return 0;
      }
    }

    // Parse existing pubspec.yaml to get project name
    final projectName = _getProjectNameFromPubspec(pubspecPath);
    if (projectName == null) {
      ConsoleUtils.error('Could not parse project name from pubspec.yaml');
      return 1;
    }

    ConsoleUtils.header('Setting up fcli for: $projectName');

    if (dryRun) {
      ConsoleUtils.info('Dry run mode - no files will be modified');
    }

    // Get or prompt for configuration
    FcliConfig config;

    if (skipPrompts) {
      config = _buildConfigFromArgs(projectName);
    } else {
      config = _promptForExistingProjectConfig(projectName);
    }

    // Validate configuration
    final errors = ConfigLoader.validate(config);
    if (errors.isNotEmpty) {
      ConsoleUtils.error('Configuration validation failed:');
      for (final error in errors) {
        ConsoleUtils.error('  - $error');
      }
      return 1;
    }

    if (dryRun) {
      _showDryRunOutput(config);
      return 0;
    }

    // Step 1: Add dependencies to pubspec.yaml
    if (!skipDeps) {
      await _updatePubspec(pubspecPath, config, verbose);
    }

    // Step 2: Create directory structure
    await _createDirectoryStructure(libPath, projectPath);

    // Step 3: Generate core files
    await _generateCoreFiles(libPath, config);

    // Step 4: Save flg.json
    await _saveFcliConfig(projectPath, config);

    // Step 5: Generate initial feature if specified
    if (config.features.isNotEmpty && config.features.first.isNotEmpty) {
      await _generateFeatures(config, projectPath, verbose, dryRun);
    }

    // Step 6: Run flutter pub get
    await _runPubGet(projectPath, verbose);

    // Step 7: Run build_runner if needed
    if (config.useFreezed || config.usesRiverpod || config.usesAutoRoute) {
      await _runBuildRunner(projectPath, verbose);
    }

    ConsoleUtils.newLine();
    ConsoleUtils.success('flg setup completed!');
    ConsoleUtils.newLine();
    ConsoleUtils.info('Next steps:');
    ConsoleUtils.step('flg g f <feature_name>  - Generate a new feature');
    ConsoleUtils.step('flg g s <screen_name> --feature=<feature>  - Generate a screen');
    ConsoleUtils.step('flutter run');

    return 0;
  }

  String? _getProjectNameFromPubspec(String pubspecPath) {
    try {
      final content = FileUtils.readFileSync(pubspecPath);
      final yaml = loadYaml(content) as YamlMap;
      return yaml['name'] as String?;
    } catch (e) {
      return null;
    }
  }

  FcliConfig _promptForExistingProjectConfig(String projectName) {
    ConsoleUtils.header('Project Configuration');

    // State management
    final stateIndex = ConsoleUtils.select(
      'Select state management:',
      ['Riverpod (Recommended)', 'Bloc', 'Provider'],
    );
    final stateManagement = StateManagement.values[stateIndex];

    // Router
    final routerIndex = ConsoleUtils.select(
      'Select router:',
      ['GoRouter (Recommended)', 'AutoRoute'],
    );
    final router = RouterOption.values[routerIndex];

    // Freezed
    final useFreezed = ConsoleUtils.confirm(
      'Use Freezed for data classes?',
      defaultValue: true,
    );

    // Dio client
    final useDioClient = ConsoleUtils.confirm(
      'Include Dio HTTP client?',
      defaultValue: true,
    );

    // Generate tests
    final generateTests = ConsoleUtils.confirm(
      'Generate test files?',
      defaultValue: true,
    );

    // Initial feature
    final initialFeature = ConsoleUtils.prompt(
      'Initial feature name (leave empty to skip)',
      defaultValue: '',
    ) ?? '';

    ConsoleUtils.newLine();

    return FcliConfig(
      projectName: projectName,
      org: 'com.example', // Not needed for existing projects
      stateManagement: stateManagement,
      router: router,
      useFreezed: useFreezed,
      useDioClient: useDioClient,
      platforms: [Platform.android, Platform.ios], // Default, not used
      features: initialFeature.isNotEmpty ? [initialFeature] : [],
      generateTests: generateTests,
      l10n: false,
    );
  }

  FcliConfig _buildConfigFromArgs(String projectName) {
    final state = argResults!['state'] as String;
    final router = argResults!['router'] as String;
    final useFreezed = argResults!['freezed'] as bool;
    final useDio = argResults!['dio'] as bool;
    final feature = argResults!['feature'] as String?;

    return FcliConfig(
      projectName: projectName,
      org: 'com.example',
      stateManagement: StateManagement.fromString(state),
      router: RouterOption.fromString(router),
      useFreezed: useFreezed,
      useDioClient: useDio,
      platforms: [Platform.android, Platform.ios],
      features: feature != null && feature.isNotEmpty ? [feature] : [],
    );
  }

  void _showDryRunOutput(FcliConfig config) {
    ConsoleUtils.newLine();
    ConsoleUtils.info('Would create/modify the following:');
    ConsoleUtils.newLine();

    final paths = [
      'pubspec.yaml (add dependencies)',
      'flg.json',
      'lib/core/',
      'lib/core/error/exceptions.dart',
      'lib/core/error/failures.dart',
      'lib/core/usecases/usecase.dart',
      'lib/core/router/app_router.dart',
      'lib/core/network/',
      'lib/core/utils/',
      'lib/features/',
    ];

    if (config.features.isNotEmpty && config.features.first.isNotEmpty) {
      final feature = config.features.first;
      paths.addAll([
        'lib/features/$feature/',
        'lib/features/$feature/domain/entities/',
        'lib/features/$feature/domain/repositories/',
        'lib/features/$feature/domain/usecases/',
        'lib/features/$feature/data/models/',
        'lib/features/$feature/data/repositories/',
        'lib/features/$feature/data/datasources/',
        'lib/features/$feature/presentation/screens/',
        'lib/features/$feature/presentation/widgets/',
        'lib/features/$feature/presentation/providers/',
      ]);
    }

    paths.addAll([
      'test/unit/',
      'test/integration/',
      'test/fixtures/',
    ]);

    for (final path in paths) {
      ConsoleUtils.muted('  $path');
    }
  }

  Future<void> _updatePubspec(String pubspecPath, FcliConfig config, bool verbose) async {
    ConsoleUtils.step('Adding dependencies to pubspec.yaml...');

    final content = FileUtils.readFileSync(pubspecPath);
    final deps = _getDependenciesToAdd(config);
    final devDeps = _getDevDependenciesToAdd(config);

    // Parse existing pubspec
    final yaml = loadYaml(content) as YamlMap;
    final existingDeps = (yaml['dependencies'] as YamlMap?)?.keys.toList() ?? [];
    final existingDevDeps = (yaml['dev_dependencies'] as YamlMap?)?.keys.toList() ?? [];

    // Filter out already existing dependencies
    final newDeps = deps.entries
        .where((e) => !existingDeps.contains(e.key))
        .toList();
    final newDevDeps = devDeps.entries
        .where((e) => !existingDevDeps.contains(e.key))
        .toList();

    if (newDeps.isEmpty && newDevDeps.isEmpty) {
      ConsoleUtils.success('All dependencies already present');
      return;
    }

    // Append dependencies to pubspec.yaml
    var updatedContent = content;

    if (newDeps.isNotEmpty) {
      final depsSection = newDeps.map((e) => '  ${e.key}: ${e.value}').join('\n');
      // Find dependencies: section and append
      final depsPattern = RegExp(r'dependencies:\s*\n');
      final match = depsPattern.firstMatch(updatedContent);
      if (match != null) {
        final insertPos = match.end;
        updatedContent = updatedContent.substring(0, insertPos) +
            depsSection +
            '\n' +
            updatedContent.substring(insertPos);
      }
    }

    if (newDevDeps.isNotEmpty) {
      final devDepsSection = newDevDeps.map((e) => '  ${e.key}: ${e.value}').join('\n');
      // Find dev_dependencies: section and append
      final devDepsPattern = RegExp(r'dev_dependencies:\s*\n');
      final match = devDepsPattern.firstMatch(updatedContent);
      if (match != null) {
        final insertPos = match.end;
        updatedContent = updatedContent.substring(0, insertPos) +
            devDepsSection +
            '\n' +
            updatedContent.substring(insertPos);
      } else {
        // dev_dependencies section doesn't exist, add it
        updatedContent += '\ndev_dependencies:\n$devDepsSection\n';
      }
    }

    await FileUtils.writeFile(pubspecPath, updatedContent);

    if (verbose) {
      if (newDeps.isNotEmpty) {
        ConsoleUtils.muted('  Added: ${newDeps.map((e) => e.key).join(', ')}');
      }
      if (newDevDeps.isNotEmpty) {
        ConsoleUtils.muted('  Added dev: ${newDevDeps.map((e) => e.key).join(', ')}');
      }
    }

    ConsoleUtils.success('Dependencies added to pubspec.yaml');
  }

  Map<String, String> _getDependenciesToAdd(FcliConfig config) {
    final deps = <String, String>{
      'equatable': '^2.0.5',
      'dartz': '^0.10.1',
    };

    switch (config.stateManagement) {
      case StateManagement.riverpod:
        deps['flutter_riverpod'] = '^2.4.9';
        deps['riverpod_annotation'] = '^2.3.3';
      case StateManagement.bloc:
        deps['flutter_bloc'] = '^8.1.3';
      case StateManagement.provider:
        deps['provider'] = '^6.1.1';
    }

    switch (config.router) {
      case RouterOption.goRouter:
        deps['go_router'] = '^13.0.1';
      case RouterOption.autoRoute:
        deps['auto_route'] = '^7.8.4';
    }

    if (config.useFreezed) {
      deps['freezed_annotation'] = '^2.4.1';
    }

    if (config.useDioClient) {
      deps['dio'] = '^5.4.0';
    }

    return deps;
  }

  Map<String, String> _getDevDependenciesToAdd(FcliConfig config) {
    final devDeps = <String, String>{
      'build_runner': '^2.4.8',
      'mocktail': '^1.0.1',
    };

    if (config.stateManagement == StateManagement.riverpod) {
      devDeps['riverpod_generator'] = '^2.3.9';
    }

    if (config.router == RouterOption.autoRoute) {
      devDeps['auto_route_generator'] = '^7.3.2';
    }

    if (config.useFreezed) {
      devDeps['freezed'] = '^2.4.6';
      devDeps['json_serializable'] = '^6.7.1';
    }

    return devDeps;
  }

  Future<void> _createDirectoryStructure(String libPath, String projectPath) async {
    ConsoleUtils.step('Creating directory structure...');

    final directories = [
      // Core
      p.join(libPath, 'core', 'error'),
      p.join(libPath, 'core', 'usecases'),
      p.join(libPath, 'core', 'router'),
      p.join(libPath, 'core', 'network'),
      p.join(libPath, 'core', 'utils'),
      // Features directory
      p.join(libPath, 'features'),
      // Test directories
      p.join(projectPath, 'test', 'unit'),
      p.join(projectPath, 'test', 'integration'),
      p.join(projectPath, 'test', 'fixtures'),
    ];

    for (final dir in directories) {
      await FileUtils.createDirectory(dir);
    }

    ConsoleUtils.success('Directory structure created');
  }

  Future<void> _generateCoreFiles(String libPath, FcliConfig config) async {
    ConsoleUtils.step('Generating core files...');

    // Exceptions
    await FileUtils.writeFile(
      p.join(libPath, 'core', 'error', 'exceptions.dart'),
      ExceptionsTemplate.generate(),
    );

    // Failures
    await FileUtils.writeFile(
      p.join(libPath, 'core', 'error', 'failures.dart'),
      FailuresTemplate.generate(),
    );

    // UseCase base
    await FileUtils.writeFile(
      p.join(libPath, 'core', 'usecases', 'usecase.dart'),
      UseCaseBaseTemplate.generate(),
    );

    // App Router
    await FileUtils.writeFile(
      p.join(libPath, 'core', 'router', 'app_router.dart'),
      AppRouterTemplate.generate(config),
    );

    ConsoleUtils.success('Core files generated');
  }

  Future<void> _saveFcliConfig(String projectPath, FcliConfig config) async {
    ConsoleUtils.step('Saving flg.json...');

    await FileUtils.writeFile(
      p.join(projectPath, 'flg.json'),
      FcliJsonTemplate.generate(config),
    );

    ConsoleUtils.success('flg.json saved');
  }

  Future<void> _generateFeatures(
    FcliConfig config,
    String projectPath,
    bool verbose,
    bool dryRun,
  ) async {
    ConsoleUtils.step('Generating features...');

    final featureGenerator = FeatureGenerator(
      config: config,
      projectPath: projectPath,
      verbose: verbose,
      dryRun: dryRun,
    );

    for (final feature in config.features) {
      await featureGenerator.generate(feature);
    }

    ConsoleUtils.success('Features generated');
  }

  Future<void> _runPubGet(String projectPath, bool verbose) async {
    ConsoleUtils.step('Running flutter pub get...');

    final result = await ProcessUtils.flutterPubGet(
      workingDirectory: projectPath,
      verbose: verbose,
    );

    if (result.failed) {
      ConsoleUtils.warning('flutter pub get failed - you may need to run it manually');
      if (verbose) {
        ConsoleUtils.muted(result.stderr);
      }
    } else {
      ConsoleUtils.success('Dependencies installed');
    }
  }

  Future<void> _runBuildRunner(String projectPath, bool verbose) async {
    ConsoleUtils.step('Running build_runner...');

    final result = await ProcessUtils.buildRunner(
      workingDirectory: projectPath,
      deleteConflicting: true,
      verbose: verbose,
      useFlutter: true,
    );

    if (result.failed) {
      ConsoleUtils.warning('build_runner failed - you may need to run it manually');
      ConsoleUtils.muted('Run: flutter pub run build_runner build --delete-conflicting-outputs');
      if (verbose) {
        ConsoleUtils.muted(result.stderr);
      }
    } else {
      ConsoleUtils.success('Code generation completed');
    }
  }
}
