import 'package:path/path.dart' as p;

import '../config/fcli_config.dart';
import '../templates/feature/widget_template.dart';
import '../utils/console_utils.dart';
import '../utils/file_utils.dart';
import '../utils/string_utils.dart';

/// Type of widget to generate.
enum WidgetType {
  stateless,
  stateful,
  entityCard,
  entityListTile,
  entityForm,
}

/// Generator for creating widget files.
class WidgetGenerator {
  const WidgetGenerator({
    required this.config,
    required this.projectPath,
    this.verbose = false,
    this.dryRun = false,
  });

  final FcliConfig config;
  final String projectPath;
  final bool verbose;
  final bool dryRun;

  /// Generates a widget.
  ///
  /// [widgetName] - The name of the widget
  /// [featureName] - The feature this widget belongs to
  /// [type] - The type of widget to generate
  Future<void> generate(
    String widgetName,
    String featureName, {
    WidgetType type = WidgetType.stateless,
  }) async {
    final snakeWidget = StringUtils.toSnakeCase(widgetName);
    final snakeFeature = StringUtils.toSnakeCase(featureName);
    final pascalWidget = StringUtils.toPascalCase(widgetName);

    final fileName = _getFileName(snakeWidget, type);
    final widgetPath = p.join(
      projectPath,
      'lib',
      'features',
      snakeFeature,
      'presentation',
      'widgets',
      fileName,
    );

    if (verbose) {
      ConsoleUtils.info('Generating widget: $pascalWidget in feature: $featureName');
    }

    if (dryRun) {
      ConsoleUtils.muted('Would create: $widgetPath');
      return;
    }

    // Check if feature exists
    final featurePath = p.join(projectPath, 'lib', 'features', snakeFeature);
    if (!FileUtils.directoryExistsSync(featurePath)) {
      ConsoleUtils.error('Feature "$featureName" does not exist.');
      ConsoleUtils.info('Run "flg g feature $featureName" first.');
      return;
    }

    // Generate widget content
    final content = _generateContent(widgetName, featureName, type);

    await FileUtils.writeFile(widgetPath, content);

    ConsoleUtils.success('Widget created: $widgetPath');
  }

  String _getFileName(String snakeWidget, WidgetType type) {
    switch (type) {
      case WidgetType.entityCard:
        return '${snakeWidget}_card.dart';
      case WidgetType.entityListTile:
        return '${snakeWidget}_list_tile.dart';
      case WidgetType.entityForm:
        return '${snakeWidget}_form.dart';
      case WidgetType.stateless:
      case WidgetType.stateful:
        return '${snakeWidget}_widget.dart';
    }
  }

  String _generateContent(String widgetName, String featureName, WidgetType type) {
    switch (type) {
      case WidgetType.stateless:
        return WidgetTemplate.generateStateless(widgetName);
      case WidgetType.stateful:
        return WidgetTemplate.generateStateful(widgetName);
      case WidgetType.entityCard:
        return WidgetTemplate.generateEntityCard(featureName, config, entityName: widgetName);
      case WidgetType.entityListTile:
        return WidgetTemplate.generateEntityListTile(featureName, config, entityName: widgetName);
      case WidgetType.entityForm:
        return WidgetTemplate.generateEntityForm(featureName, config, entityName: widgetName);
    }
  }

  /// Generates multiple widgets for a feature.
  Future<void> generateMultiple(
    List<String> widgetNames,
    String featureName, {
    WidgetType type = WidgetType.stateless,
  }) async {
    for (final widgetName in widgetNames) {
      await generate(widgetName, featureName, type: type);
    }
  }
}
