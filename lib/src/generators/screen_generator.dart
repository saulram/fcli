import 'package:path/path.dart' as p;

import '../config/fcli_config.dart';
import '../templates/core/app_router_template.dart';
import '../templates/feature/screen_template.dart';
import '../utils/console_utils.dart';
import '../utils/file_utils.dart';
import '../utils/string_utils.dart';

/// Generator for creating screen widgets.
class ScreenGenerator {
  const ScreenGenerator({
    required this.config,
    required this.projectPath,
    this.verbose = false,
    this.dryRun = false,
  });

  final FcliConfig config;
  final String projectPath;
  final bool verbose;
  final bool dryRun;

  /// Generates a screen widget.
  ///
  /// [screenName] - The name of the screen (e.g., 'user_detail', 'settings')
  /// [featureName] - The feature this screen belongs to
  /// [simple] - If true, generates a simple screen without state management
  Future<void> generate(
    String screenName,
    String featureName, {
    bool simple = false,
  }) async {
    final snakeScreen = StringUtils.toSnakeCase(screenName);
    final snakeFeature = StringUtils.toSnakeCase(featureName);
    final pascalScreen = StringUtils.toPascalCase(screenName);

    final screenPath = p.join(
      projectPath,
      'lib',
      'features',
      snakeFeature,
      'presentation',
      'screens',
      '${snakeScreen}_screen.dart',
    );

    if (verbose) {
      ConsoleUtils.info('Generating screen: $pascalScreen in feature: $featureName');
    }

    if (dryRun) {
      ConsoleUtils.muted('Would create: $screenPath');
      ConsoleUtils.muted('Would add route to app_router.dart');
      return;
    }

    // Check if feature exists
    final featurePath = p.join(projectPath, 'lib', 'features', snakeFeature);
    if (!FileUtils.directoryExistsSync(featurePath)) {
      ConsoleUtils.error('Feature "$featureName" does not exist.');
      ConsoleUtils.info('Run "flg g feature $featureName" first.');
      return;
    }

    // Generate screen
    final content = simple
        ? ScreenTemplate.generateSimple(screenName)
        : ScreenTemplate.generate(screenName, featureName, config);

    await FileUtils.writeFile(screenPath, content);

    ConsoleUtils.success('Screen created: $screenPath');

    // Show route snippet
    ConsoleUtils.newLine();
    ConsoleUtils.info('Add this route to your app_router.dart:');
    ConsoleUtils.newLine();
    ConsoleUtils.muted(
      AppRouterTemplate.generateRouteSnippet(featureName, screenName, config),
    );
  }

  /// Generates multiple screens for a feature.
  Future<void> generateMultiple(
    List<String> screenNames,
    String featureName, {
    bool simple = false,
  }) async {
    for (final screenName in screenNames) {
      await generate(screenName, featureName, simple: simple);
    }
  }
}
