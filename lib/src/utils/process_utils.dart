import 'dart:io';

import 'console_utils.dart';

/// Result of a process execution.
class ProcessResult {
  const ProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get success => exitCode == 0;
  bool get failed => exitCode != 0;
}

/// Utility class for running external processes.
class ProcessUtils {
  ProcessUtils._();

  /// Runs a command and returns the result.
  static Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool verbose = false,
  }) async {
    if (verbose) {
      ConsoleUtils.muted('Running: $executable ${arguments.join(' ')}');
    }

    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: Platform.isWindows,
    );

    return ProcessResult(
      exitCode: result.exitCode,
      stdout: result.stdout.toString().trim(),
      stderr: result.stderr.toString().trim(),
    );
  }

  /// Runs a command with output streaming.
  static Future<int> runWithOutput(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: Platform.isWindows,
    );

    // Stream output
    process.stdout.transform(const SystemEncoding().decoder).listen(stdout.write);
    process.stderr.transform(const SystemEncoding().decoder).listen(stderr.write);

    return process.exitCode;
  }

  /// Runs `flutter create` to create a new Flutter project.
  static Future<ProcessResult> flutterCreate(
    String projectName, {
    String? workingDirectory,
    List<String> platforms = const ['ios', 'android'],
    String? org,
    bool verbose = false,
  }) async {
    final args = [
      'create',
      '--no-pub',
      '--platforms=${platforms.join(',')}',
      if (org != null) '--org=$org',
      projectName,
    ];

    return run(
      'flutter',
      args,
      workingDirectory: workingDirectory,
      verbose: verbose,
    );
  }

  /// Runs `flutter pub get` in the project directory.
  static Future<ProcessResult> flutterPubGet({
    String? workingDirectory,
    bool verbose = false,
  }) async =>
      run(
        'flutter',
        ['pub', 'get'],
        workingDirectory: workingDirectory,
        verbose: verbose,
      );

  /// Runs `dart pub get` in the project directory.
  static Future<ProcessResult> dartPubGet({
    String? workingDirectory,
    bool verbose = false,
  }) async =>
      run(
        'dart',
        ['pub', 'get'],
        workingDirectory: workingDirectory,
        verbose: verbose,
      );

  /// Runs `dart run build_runner build` in the project directory.
  static Future<ProcessResult> buildRunner({
    String? workingDirectory,
    bool deleteConflicting = true,
    bool verbose = false,
    bool useFlutter = false,
  }) async {
    final executable = useFlutter ? 'flutter' : 'dart';
    final args = useFlutter
        ? [
            'pub',
            'run',
            'build_runner',
            'build',
            if (deleteConflicting) '--delete-conflicting-outputs',
          ]
        : [
            'run',
            'build_runner',
            'build',
            if (deleteConflicting) '--delete-conflicting-outputs',
          ];

    return run(
      executable,
      args,
      workingDirectory: workingDirectory,
      verbose: verbose,
    );
  }

  /// Runs `dart run build_runner watch` in the project directory.
  static Future<Process> buildRunnerWatch({
    String? workingDirectory,
    bool deleteConflicting = true,
  }) async {
    final args = [
      'run',
      'build_runner',
      'watch',
      if (deleteConflicting) '--delete-conflicting-outputs',
    ];

    return Process.start(
      'dart',
      args,
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
    );
  }

  /// Runs `flutter format` on the project.
  static Future<ProcessResult> flutterFormat({
    String? workingDirectory,
    String path = '.',
    bool verbose = false,
  }) async =>
      run(
        'dart',
        ['format', path],
        workingDirectory: workingDirectory,
        verbose: verbose,
      );

  /// Runs `flutter analyze` on the project.
  static Future<ProcessResult> flutterAnalyze({
    String? workingDirectory,
    bool verbose = false,
  }) async =>
      run(
        'flutter',
        ['analyze'],
        workingDirectory: workingDirectory,
        verbose: verbose,
      );

  /// Runs `flutter test` on the project.
  static Future<ProcessResult> flutterTest({
    String? workingDirectory,
    bool verbose = false,
    String? testPath,
  }) async =>
      run(
        'flutter',
        ['test', if (testPath != null) testPath],
        workingDirectory: workingDirectory,
        verbose: verbose,
      );

  /// Checks if Flutter is installed and available.
  static Future<bool> isFlutterInstalled() async {
    try {
      final result = await run('flutter', ['--version']);
      return result.success;
    } catch (_) {
      return false;
    }
  }

  /// Checks if Dart is installed and available.
  static Future<bool> isDartInstalled() async {
    try {
      final result = await run('dart', ['--version']);
      return result.success;
    } catch (_) {
      return false;
    }
  }

  /// Gets the Flutter version.
  static Future<String?> getFlutterVersion() async {
    try {
      final result = await run('flutter', ['--version']);
      if (result.success) {
        // Parse first line: "Flutter 3.x.x • channel stable • ..."
        final match = RegExp(r'Flutter (\d+\.\d+\.\d+)').firstMatch(result.stdout);
        return match?.group(1);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Gets the Dart version.
  static Future<String?> getDartVersion() async {
    try {
      final result = await run('dart', ['--version']);
      if (result.success) {
        // Parse: "Dart SDK version: 3.x.x ..."
        final output = result.stdout.isNotEmpty ? result.stdout : result.stderr;
        final match = RegExp(r'Dart SDK version: (\d+\.\d+\.\d+)').firstMatch(output);
        return match?.group(1);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
