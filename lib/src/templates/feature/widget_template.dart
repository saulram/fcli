import '../../config/fcli_config.dart';
import '../../utils/string_utils.dart';

/// Template for generating presentation/widgets/<widget>_widget.dart
class WidgetTemplate {
  WidgetTemplate._();

  /// Generates a stateless widget.
  ///
  /// [widgetName] - The widget name (e.g., 'user_card', 'profile_avatar')
  static String generateStateless(String widgetName) {
    final pascalName = StringUtils.toPascalCase(widgetName);
    final titleName = StringUtils.toTitleCase(widgetName);

    return '''
import 'package:flutter/material.dart';

/// Widget for $titleName.
class ${pascalName}Widget extends StatelessWidget {
  const ${pascalName}Widget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
''';
  }

  /// Generates a stateful widget.
  ///
  /// [widgetName] - The widget name (e.g., 'animated_button', 'counter_display')
  static String generateStateful(String widgetName) {
    final pascalName = StringUtils.toPascalCase(widgetName);
    final titleName = StringUtils.toTitleCase(widgetName);

    return '''
import 'package:flutter/material.dart';

/// Widget for $titleName.
class ${pascalName}Widget extends StatefulWidget {
  const ${pascalName}Widget({
    super.key,
  });

  @override
  State<${pascalName}Widget> createState() => _${pascalName}WidgetState();
}

class _${pascalName}WidgetState extends State<${pascalName}Widget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
''';
  }

  /// Generates a card widget for displaying an entity.
  ///
  /// [featureName] - The feature name (e.g., 'user', 'product')
  /// [config] - The fcli configuration
  /// [entityName] - Optional custom entity name, defaults to feature name
  static String generateEntityCard(
    String featureName,
    FcliConfig config, {
    String? entityName,
  }) {
    final name = entityName ?? featureName;
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final camelName = StringUtils.toCamelCase(name);
    final titleName = StringUtils.toTitleCase(name);
    final featureSnake = StringUtils.toSnakeCase(featureName);
    final projectName = config.projectName;

    return '''
import 'package:flutter/material.dart';

import 'package:$projectName/features/$featureSnake/domain/entities/${snakeName}_entity.dart';

/// Card widget for displaying a $titleName.
class ${pascalName}Card extends StatelessWidget {
  const ${pascalName}Card({
    super.key,
    required this.$camelName,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final ${pascalName}Entity $camelName;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      $camelName.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      $camelName.id,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
''';
  }

  /// Generates a list tile widget for displaying an entity.
  ///
  /// [featureName] - The feature name (e.g., 'user', 'product')
  /// [config] - The fcli configuration
  /// [entityName] - Optional custom entity name, defaults to feature name
  static String generateEntityListTile(
    String featureName,
    FcliConfig config, {
    String? entityName,
  }) {
    final name = entityName ?? featureName;
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final camelName = StringUtils.toCamelCase(name);
    final titleName = StringUtils.toTitleCase(name);
    final featureSnake = StringUtils.toSnakeCase(featureName);
    final projectName = config.projectName;

    return '''
import 'package:flutter/material.dart';

import 'package:$projectName/features/$featureSnake/domain/entities/${snakeName}_entity.dart';

/// List tile widget for displaying a $titleName.
class ${pascalName}ListTile extends StatelessWidget {
  const ${pascalName}ListTile({
    super.key,
    required this.$camelName,
    this.onTap,
    this.trailing,
  });

  final ${pascalName}Entity $camelName;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text($camelName.name),
      subtitle: Text($camelName.id),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
''';
  }

  /// Generates a form widget for an entity.
  ///
  /// [featureName] - The feature name (e.g., 'user', 'product')
  /// [config] - The fcli configuration
  /// [entityName] - Optional custom entity name, defaults to feature name
  static String generateEntityForm(
    String featureName,
    FcliConfig config, {
    String? entityName,
  }) {
    final name = entityName ?? featureName;
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final camelName = StringUtils.toCamelCase(name);
    final titleName = StringUtils.toTitleCase(name);
    final featureSnake = StringUtils.toSnakeCase(featureName);
    final projectName = config.projectName;

    return '''
import 'package:flutter/material.dart';

import 'package:$projectName/features/$featureSnake/domain/entities/${snakeName}_entity.dart';

/// Form widget for creating/editing a $titleName.
class ${pascalName}Form extends StatefulWidget {
  const ${pascalName}Form({
    super.key,
    this.$camelName,
    required this.onSubmit,
  });

  final ${pascalName}Entity? $camelName;
  final void Function(${pascalName}Entity $camelName) onSubmit;

  @override
  State<${pascalName}Form> createState() => _${pascalName}FormState();
}

class _${pascalName}FormState extends State<${pascalName}Form> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  bool get isEditing => widget.$camelName != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.$camelName?.name ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final entity = ${pascalName}Entity(
        id: widget.$camelName?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        createdAt: widget.$camelName?.createdAt ?? DateTime.now(),
        updatedAt: isEditing ? DateTime.now() : null,
      );
      widget.onSubmit(entity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter name',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submit,
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}
''';
  }
}
