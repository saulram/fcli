import '../../config/fcli_config.dart';
import '../../utils/string_utils.dart';

/// Template for generating presentation/screens/<screen>_screen.dart
class ScreenTemplate {
  ScreenTemplate._();

  /// Generates a screen widget.
  ///
  /// [screenName] - The screen name (e.g., 'home', 'user_list')
  /// [featureName] - The feature name for the screen
  /// [config] - The fcli configuration
  static String generate(
    String screenName,
    String featureName,
    FcliConfig config,
  ) {
    final pascalScreen = StringUtils.toPascalCase(screenName);
    final pascalFeature = StringUtils.toPascalCase(featureName);
    final snakeFeature = StringUtils.toSnakeCase(featureName);
    final titleScreen = StringUtils.toTitleCase(screenName);
    final projectName = config.projectName;

    if (config.usesRiverpod) {
      return _generateRiverpodScreen(
        pascalScreen,
        pascalFeature,
        snakeFeature,
        titleScreen,
        projectName,
      );
    } else if (config.usesBloc) {
      return _generateBlocScreen(
        pascalScreen,
        pascalFeature,
        snakeFeature,
        titleScreen,
        projectName,
      );
    } else {
      return _generateProviderScreen(
        pascalScreen,
        pascalFeature,
        snakeFeature,
        titleScreen,
        projectName,
      );
    }
  }

  static String _generateRiverpodScreen(
    String pascalScreen,
    String pascalFeature,
    String snakeFeature,
    String titleScreen,
    String projectName,
  ) =>
      '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:$projectName/features/$snakeFeature/presentation/providers/${snakeFeature}_notifier.dart';
import 'package:$projectName/features/$snakeFeature/presentation/providers/${snakeFeature}_state.dart';

/// Screen for $titleScreen.
class ${pascalScreen}Screen extends ConsumerStatefulWidget {
  const ${pascalScreen}Screen({super.key});

  @override
  ConsumerState<${pascalScreen}Screen> createState() => _${pascalScreen}ScreenState();
}

class _${pascalScreen}ScreenState extends ConsumerState<${pascalScreen}Screen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(${StringUtils.toCamelCase(pascalFeature)}NotifierProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(${StringUtils.toCamelCase(pascalFeature)}NotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('$titleScreen'),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(${pascalFeature}State state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.errorMessage ?? 'An error occurred',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(${StringUtils.toCamelCase(pascalFeature)}NotifierProvider.notifier).loadAll();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.${StringUtils.toPlural(StringUtils.toCamelCase(pascalFeature))}.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.${StringUtils.toPlural(StringUtils.toCamelCase(pascalFeature))}.length,
      itemBuilder: (context, index) {
        final item = state.${StringUtils.toPlural(StringUtils.toCamelCase(pascalFeature))}[index];
        return Card(
          child: ListTile(
            title: Text(item.name),
            subtitle: Text(item.id),
            onTap: () {
              // Handle item tap
            },
          ),
        );
      },
    );
  }
}
''';

  static String _generateBlocScreen(
    String pascalScreen,
    String pascalFeature,
    String snakeFeature,
    String titleScreen,
    String projectName,
  ) =>
      '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:$projectName/features/$snakeFeature/presentation/providers/${snakeFeature}_bloc.dart';

/// Screen for $titleScreen.
class ${pascalScreen}Screen extends StatefulWidget {
  const ${pascalScreen}Screen({super.key});

  @override
  State<${pascalScreen}Screen> createState() => _${pascalScreen}ScreenState();
}

class _${pascalScreen}ScreenState extends State<${pascalScreen}Screen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    context.read<${pascalFeature}Bloc>().add(const Load${pascalFeature}s());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$titleScreen'),
      ),
      body: BlocBuilder<${pascalFeature}Bloc, ${pascalFeature}State>(
        builder: (context, state) {
          return switch (state) {
            ${pascalFeature}Initial() => const Center(
                child: Text('Welcome'),
              ),
            ${pascalFeature}Loading() => const Center(
                child: CircularProgressIndicator(),
              ),
            ${pascalFeature}Error(:final message) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<${pascalFeature}Bloc>().add(const Load${pascalFeature}s());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ${pascalFeature}Loaded(:final ${StringUtils.toCamelCase(pascalFeature)}s) => ${StringUtils.toCamelCase(pascalFeature)}s.isEmpty
                ? const Center(child: Text('No data available'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ${StringUtils.toCamelCase(pascalFeature)}s.length,
                    itemBuilder: (context, index) {
                      final item = ${StringUtils.toCamelCase(pascalFeature)}s[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Text(item.id),
                          onTap: () {
                            // Handle item tap
                          },
                        ),
                      );
                    },
                  ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}
''';

  static String _generateProviderScreen(
    String pascalScreen,
    String pascalFeature,
    String snakeFeature,
    String titleScreen,
    String projectName,
  ) =>
      '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:$projectName/features/$snakeFeature/presentation/providers/${snakeFeature}_provider.dart';

/// Screen for $titleScreen.
class ${pascalScreen}Screen extends StatefulWidget {
  const ${pascalScreen}Screen({super.key});

  @override
  State<${pascalScreen}Screen> createState() => _${pascalScreen}ScreenState();
}

class _${pascalScreen}ScreenState extends State<${pascalScreen}Screen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<${pascalFeature}Provider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$titleScreen'),
      ),
      body: Consumer<${pascalFeature}Provider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.errorMessage!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadAll();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.${StringUtils.toPlural(StringUtils.toCamelCase(pascalFeature))}.isEmpty) {
            return const Center(
              child: Text('No data available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.${StringUtils.toPlural(StringUtils.toCamelCase(pascalFeature))}.length,
            itemBuilder: (context, index) {
              final item = provider.${StringUtils.toPlural(StringUtils.toCamelCase(pascalFeature))}[index];
              return Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(item.id),
                  onTap: () {
                    // Handle item tap
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
''';

  /// Generates a simple screen without state management integration.
  static String generateSimple(String screenName) {
    final pascalScreen = StringUtils.toPascalCase(screenName);
    final titleScreen = StringUtils.toTitleCase(screenName);

    return '''
import 'package:flutter/material.dart';

/// Screen for $titleScreen.
class ${pascalScreen}Screen extends StatelessWidget {
  const ${pascalScreen}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$titleScreen'),
      ),
      body: const Center(
        child: Text('$titleScreen Screen'),
      ),
    );
  }
}
''';
  }
}
