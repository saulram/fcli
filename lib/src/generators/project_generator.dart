import 'package:path/path.dart' as p;

import '../config/fcli_config.dart';
import '../templates/config/fcli_json_template.dart';
import '../templates/config/pubspec_template.dart';
import '../templates/core/app_router_template.dart';
import '../templates/core/exceptions_template.dart';
import '../templates/core/failures_template.dart';
import '../templates/core/main_template.dart';
import '../templates/core/usecase_template.dart';
import '../utils/console_utils.dart';
import '../utils/file_utils.dart';
import '../utils/process_utils.dart';
import 'feature_generator.dart';

/// Generator for creating a new Flutter project with Clean Architecture.
class ProjectGenerator {
  const ProjectGenerator({
    required this.config,
    required this.targetPath,
    this.verbose = false,
    this.dryRun = false,
  });

  final FcliConfig config;
  final String targetPath;
  final bool verbose;
  final bool dryRun;

  /// Full path to the project directory.
  String get projectPath => p.join(targetPath, config.projectName);

  /// Full path to the lib directory.
  String get libPath => p.join(projectPath, 'lib');

  /// Generates the complete project.
  Future<bool> generate() async {
    ConsoleUtils.header('Creating project: ${config.projectName}');

    if (dryRun) {
      ConsoleUtils.info('Dry run mode - no files will be created');
      _showDryRunOutput();
      return true;
    }

    // Step 1: Run flutter create
    if (!await _runFlutterCreate()) {
      return false;
    }

    // Step 2: Generate pubspec.yaml
    await _generatePubspec();

    // Step 3: Create directory structure
    await _createDirectoryStructure();

    // Step 4: Generate core files
    await _generateCoreFiles();

    // Step 5: Generate initial feature(s)
    await _generateFeatures();

    // Step 6: Generate main.dart
    await _generateMain();

    // Step 7: Save flg.json
    await _saveFcliConfig();

    // Step 8: Run flutter pub get
    await _runPubGet();

    // Step 9: Run build_runner if needed
    if (config.useFreezed || config.usesRiverpod || config.usesAutoRoute) {
      await _runBuildRunner();
    }

    ConsoleUtils.newLine();
    ConsoleUtils.success('Project created successfully!');
    ConsoleUtils.newLine();
    ConsoleUtils.info('Next steps:');
    ConsoleUtils.step('cd ${config.projectName}');
    ConsoleUtils.step('flutter run');

    return true;
  }

  void _showDryRunOutput() {
    ConsoleUtils.newLine();
    ConsoleUtils.info('Would create the following structure:');
    ConsoleUtils.newLine();

    final paths = [
      'lib/',
      'lib/main.dart',
      'lib/core/',
      'lib/core/error/exceptions.dart',
      'lib/core/error/failures.dart',
      'lib/core/usecases/usecase.dart',
      'lib/core/router/app_router.dart',
    ];

    for (final feature in config.features) {
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
      'test/',
      'pubspec.yaml',
      'flg.json',
    ]);

    for (final path in paths) {
      ConsoleUtils.muted('  $path');
    }
  }

  Future<bool> _runFlutterCreate() async {
    ConsoleUtils.step('Running flutter create...');

    final result = await ProcessUtils.flutterCreate(
      config.projectName,
      workingDirectory: targetPath,
      platforms: config.platformStrings,
      org: config.org,
      verbose: verbose,
    );

    if (result.failed) {
      ConsoleUtils.error('Failed to create Flutter project');
      if (verbose) {
        ConsoleUtils.muted(result.stderr);
      }
      return false;
    }

    ConsoleUtils.success('Flutter project created');
    return true;
  }

  Future<void> _generatePubspec() async {
    ConsoleUtils.step('Generating pubspec.yaml...');

    final content = PubspecTemplate.generate(config);
    await FileUtils.writeFile(p.join(projectPath, 'pubspec.yaml'), content);

    // Generate l10n files if enabled
    if (config.l10n) {
      await FileUtils.writeFile(
        p.join(projectPath, 'l10n.yaml'),
        PubspecTemplate.generateL10nYaml(),
      );
      await FileUtils.writeFile(
        p.join(libPath, 'l10n', 'app_en.arb'),
        PubspecTemplate.generateDefaultArb(config.projectName),
      );
    }

    ConsoleUtils.success('pubspec.yaml generated');
  }

  Future<void> _createDirectoryStructure() async {
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

  Future<void> _generateCoreFiles() async {
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

  Future<void> _generateFeatures() async {
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

  Future<void> _generateMain() async {
    ConsoleUtils.step('Generating main.dart...');

    await FileUtils.writeFile(
      p.join(libPath, 'main.dart'),
      MainTemplate.generate(config),
    );

    ConsoleUtils.success('main.dart generated');
  }

  Future<void> _saveFcliConfig() async {
    ConsoleUtils.step('Saving flg.json...');

    await FileUtils.writeFile(
      p.join(projectPath, 'flg.json'),
      FcliJsonTemplate.generate(config),
    );

    ConsoleUtils.success('flg.json saved');
  }

  Future<void> _runPubGet() async {
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

  Future<void> _runBuildRunner() async {
    ConsoleUtils.step('Running build_runner...');

    final result = await ProcessUtils.buildRunner(
      workingDirectory: projectPath,
      deleteConflicting: true,
      verbose: verbose,
      useFlutter: true,
    );

    if (result.failed) {
      ConsoleUtils.warning('build_runner failed - you may need to run it manually');
      ConsoleUtils.muted('Run: dart run build_runner build --delete-conflicting-outputs');
      if (verbose) {
        ConsoleUtils.muted(result.stderr);
      }
    } else {
      ConsoleUtils.success('Code generation completed');
    }
  }
}
