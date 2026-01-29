import 'dart:io';

import 'package:args/command_runner.dart';

import '../config/config_loader.dart';
import '../config/fcli_config.dart';
import '../generators/project_generator.dart';
import '../utils/console_utils.dart';
import '../utils/file_utils.dart';
import '../utils/process_utils.dart';

/// Command for initializing a new Flutter project with Clean Architecture.
class InitCommand extends Command<int> {
  InitCommand() {
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
      ..addOption(
        'org',
        abbr: 'o',
        help: 'Organization identifier (reverse domain).',
        defaultsTo: 'com.example',
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
      ..addMultiOption(
        'platforms',
        abbr: 'p',
        help: 'Target platforms (android, ios, web, macos, windows, linux).',
        allowed: ['android', 'ios', 'web', 'macos', 'windows', 'linux'],
        defaultsTo: ['android', 'ios'],
      )
      ..addOption(
        'feature',
        help: 'Initial feature name.',
        defaultsTo: 'home',
      );
  }

  @override
  String get name => 'init';

  @override
  String get description =>
      'Initialize a new Flutter project with Clean Architecture.';

  @override
  String get invocation => 'flg init <project_name>';

  @override
  Future<int> run() async {
    // Check for project name
    if (argResults!.rest.isEmpty) {
      ConsoleUtils.error('Please provide a project name.');
      ConsoleUtils.info('Usage: flg init <project_name>');
      return 1;
    }

    final projectName = argResults!.rest.first;
    final dryRun = argResults!['dry-run'] as bool;
    final verbose = argResults!['verbose'] as bool;
    final skipPrompts = argResults!['skip-prompts'] as bool;

    // Validate project name
    if (!_isValidProjectName(projectName)) {
      ConsoleUtils.error('Invalid project name: $projectName');
      ConsoleUtils.info(
        'Project name must be a valid Dart package name '
        '(lowercase, underscores allowed).',
      );
      return 1;
    }

    // Check if directory already exists
    final targetPath = Directory.current.path;
    final projectPath = FileUtils.joinPath([targetPath, projectName]);

    if (FileUtils.directoryExistsSync(projectPath) && !dryRun) {
      ConsoleUtils.error('Directory "$projectName" already exists.');
      if (!ConsoleUtils.confirm('Do you want to overwrite it?')) {
        return 1;
      }
      FileUtils.deleteDirectorySync(projectPath);
    }

    // Check Flutter installation
    if (!dryRun) {
      final flutterInstalled = await ProcessUtils.isFlutterInstalled();
      if (!flutterInstalled) {
        ConsoleUtils.error('Flutter is not installed or not in PATH.');
        ConsoleUtils.info('Please install Flutter: https://flutter.dev/docs/get-started/install');
        return 1;
      }
    }

    // Get or prompt for configuration
    FcliConfig config;

    if (skipPrompts) {
      config = _buildConfigFromArgs(projectName);
    } else {
      config = ConfigLoader.promptForConfig(projectName);
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

    // Generate project
    final generator = ProjectGenerator(
      config: config,
      targetPath: targetPath,
      verbose: verbose,
      dryRun: dryRun,
    );

    final success = await generator.generate();

    return success ? 0 : 1;
  }

  bool _isValidProjectName(String name) =>
      RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(name);

  FcliConfig _buildConfigFromArgs(String projectName) {
    final org = argResults!['org'] as String;
    final state = argResults!['state'] as String;
    final router = argResults!['router'] as String;
    final useFreezed = argResults!['freezed'] as bool;
    final useDio = argResults!['dio'] as bool;
    final platforms = argResults!['platforms'] as List<String>;
    final feature = argResults!['feature'] as String;

    return FcliConfig(
      projectName: projectName,
      org: org,
      stateManagement: StateManagement.fromString(state),
      router: RouterOption.fromString(router),
      useFreezed: useFreezed,
      useDioClient: useDio,
      platforms: platforms.map(Platform.fromString).toList(),
      features: [feature],
    );
  }
}
