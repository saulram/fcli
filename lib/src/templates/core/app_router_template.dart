import '../../config/fcli_config.dart';
import '../../utils/string_utils.dart';

/// Template for generating core/router/app_router.dart
class AppRouterTemplate {
  AppRouterTemplate._();

  static String generate(FcliConfig config) {
    if (config.usesGoRouter) {
      return _generateGoRouter(config);
    } else {
      return _generateAutoRoute(config);
    }
  }

  static String _generateGoRouter(FcliConfig config) {
    final features = config.features;
    final projectName = config.projectName;
    final imports = StringBuffer();
    final routes = StringBuffer();

    for (final feature in features) {
      final pascal = StringUtils.toPascalCase(feature);
      final snake = StringUtils.toSnakeCase(feature);
      imports.writeln(
          "import 'package:$projectName/features/$snake/presentation/screens/${snake}_screen.dart';");
    }

    for (var i = 0; i < features.length; i++) {
      final feature = features[i];
      final pascal = StringUtils.toPascalCase(feature);
      final snake = StringUtils.toSnakeCase(feature);
      final isFirst = i == 0;

      routes.writeln('''
      GoRoute(
        path: ${isFirst ? "'/'" : "'/$snake'"},
        name: '${pascal}Screen',
        builder: (context, state) => const ${pascal}Screen(),
      ),''');
    }

    return '''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

$imports

/// Application router configuration using GoRouter.
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
$routes
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: \${state.uri}'),
      ),
    ),
  );
}
''';
  }

  static String _generateAutoRoute(FcliConfig config) {
    final features = config.features;
    final projectName = config.projectName;
    final imports = StringBuffer();
    final routes = StringBuffer();

    for (final feature in features) {
      final pascal = StringUtils.toPascalCase(feature);
      final snake = StringUtils.toSnakeCase(feature);
      imports.writeln(
          "import 'package:$projectName/features/$snake/presentation/screens/${snake}_screen.dart';");
    }

    for (var i = 0; i < features.length; i++) {
      final feature = features[i];
      final pascal = StringUtils.toPascalCase(feature);
      final isFirst = i == 0;

      routes.writeln('''
    AutoRoute(
      path: ${isFirst ? "'/'" : "'/${StringUtils.toSnakeCase(feature)}'"},
      page: ${pascal}Route.page,
      ${isFirst ? 'initial: true,' : ''}
    ),''');
    }

    return '''
import 'package:auto_route/auto_route.dart';

$imports

part 'app_router.gr.dart';

/// Application router configuration using AutoRoute.
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
$routes
  ];
}
''';
  }

  /// Generates the route addition snippet for a new screen.
  static String generateRouteSnippet(
    String featureName,
    String screenName,
    FcliConfig config,
  ) {
    final featureSnake = StringUtils.toSnakeCase(featureName);
    final screenSnake = StringUtils.toSnakeCase(screenName);
    final screenPascal = StringUtils.toPascalCase(screenName);

    if (config.usesGoRouter) {
      return '''
GoRoute(
  path: '/$featureSnake/$screenSnake',
  name: '${screenPascal}Screen',
  builder: (context, state) => const ${screenPascal}Screen(),
),''';
    } else {
      return '''
AutoRoute(
  path: '/$featureSnake/$screenSnake',
  page: ${screenPascal}Route.page,
),''';
    }
  }
}
