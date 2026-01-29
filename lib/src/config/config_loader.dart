import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/console_utils.dart';
import '../utils/file_utils.dart';
import 'fcli_config.dart';

/// Utility class for loading and saving flg configuration.
class ConfigLoader {
  ConfigLoader._();

  static const String configFileName = 'flg.json';

  /// Gets the path to the config file in a directory.
  static String getConfigPath(String projectPath) =>
      p.join(projectPath, configFileName);

  /// Checks if a config file exists in the directory.
  static bool configExists(String projectPath) =>
      FileUtils.fileExistsSync(getConfigPath(projectPath));

  /// Loads configuration from the config file.
  /// Returns null if the file doesn't exist.
  static FcliConfig? load(String projectPath) {
    final configPath = getConfigPath(projectPath);
    if (!FileUtils.fileExistsSync(configPath)) {
      return null;
    }

    try {
      final content = FileUtils.readFileSync(configPath);
      final json = jsonDecode(content) as Map<String, dynamic>;
      return FcliConfig.fromJson(json);
    } catch (e) {
      ConsoleUtils.warning('Failed to parse config file: $e');
      return null;
    }
  }

  /// Saves configuration to the config file.
  static Future<void> save(String projectPath, FcliConfig config) async {
    final configPath = getConfigPath(projectPath);
    final content = const JsonEncoder.withIndent('  ').convert(config.toJson());
    await FileUtils.writeFile(configPath, content);
  }

  /// Saves configuration synchronously.
  static void saveSync(String projectPath, FcliConfig config) {
    final configPath = getConfigPath(projectPath);
    final content = const JsonEncoder.withIndent('  ').convert(config.toJson());
    FileUtils.writeFileSync(configPath, content);
  }

  /// Prompts user for configuration interactively.
  static FcliConfig promptForConfig(String projectName) {
    ConsoleUtils.header('Project Configuration');

    // Organization
    final org = ConsoleUtils.prompt(
      'Organization (reverse domain)',
      defaultValue: 'com.example',
    ) ?? 'com.example';

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

    // Platforms
    final platformIndices = ConsoleUtils.multiSelect(
      'Select platforms:',
      ['Android', 'iOS', 'Web', 'macOS', 'Windows', 'Linux'],
      defaultSelected: [0, 1],
    );
    final platforms = platformIndices.map((i) => Platform.values[i]).toList();

    // L10n
    final l10n = ConsoleUtils.confirm(
      'Enable localization (l10n)?',
      defaultValue: false,
    );

    // Generate tests
    final generateTests = ConsoleUtils.confirm(
      'Generate test files?',
      defaultValue: true,
    );

    // Initial feature
    final initialFeature = ConsoleUtils.prompt(
      'Initial feature name',
      defaultValue: 'home',
    ) ?? 'home';

    ConsoleUtils.newLine();

    return FcliConfig(
      projectName: projectName,
      org: org,
      stateManagement: stateManagement,
      router: router,
      useFreezed: useFreezed,
      useDioClient: useDioClient,
      platforms: platforms,
      features: [initialFeature],
      generateTests: generateTests,
      l10n: l10n,
    );
  }

  /// Loads or prompts for configuration.
  /// If force is true, always prompts even if config exists.
  static FcliConfig loadOrPrompt(
    String projectPath,
    String projectName, {
    bool force = false,
  }) {
    if (!force && configExists(projectPath)) {
      final config = load(projectPath);
      if (config != null) {
        ConsoleUtils.info('Loaded existing configuration from $configFileName');
        return config;
      }
    }

    return promptForConfig(projectName);
  }

  /// Validates the configuration.
  static List<String> validate(FcliConfig config) {
    final errors = <String>[];

    if (config.projectName.isEmpty) {
      errors.add('Project name is required');
    }

    if (!RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(config.projectName)) {
      errors.add('Project name must be valid Dart package name (lowercase, underscores)');
    }

    if (config.platforms.isEmpty) {
      errors.add('At least one platform must be selected');
    }

    if (config.org.isEmpty) {
      errors.add('Organization is required');
    }

    return errors;
  }

  /// Finds the nearest flg.json config file by traversing up the directory tree.
  static String? findConfigPath([String? startPath]) {
    var current = Directory(startPath ?? Directory.current.path);

    while (current.path != current.parent.path) {
      final configPath = p.join(current.path, configFileName);
      if (File(configPath).existsSync()) {
        return current.path;
      }
      current = current.parent;
    }

    return null;
  }

  /// Ensures we're in a valid flg project directory.
  /// Returns the project root path or null if not in a project.
  static String? ensureInProject([String? startPath]) {
    final projectPath = findConfigPath(startPath);
    if (projectPath == null) {
      ConsoleUtils.error('Not in a flg project directory.');
      ConsoleUtils.info('Run "flg init <project_name>" to create a new project.');
      return null;
    }
    return projectPath;
  }
}
