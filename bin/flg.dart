import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:flg/src/commands/generate_command.dart';
import 'package:flg/src/commands/init_command.dart';
import 'package:flg/src/commands/setup_command.dart';
import 'package:flg/src/commands/task_command.dart';
import 'package:flg/src/utils/console_utils.dart';

const String version = '1.2.0';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner<int>(
    'flg',
    'Flutter Generator - CLI for Clean Architecture projects.\n\n'
        'Version: $version',
  )
    ..addCommand(InitCommand())
    ..addCommand(GenerateCommand())
    ..addCommand(SetupCommand())
    ..addCommand(TaskCommand());

  // Add global flags
  runner.argParser
    ..addFlag(
      'version',
      negatable: false,
      help: 'Print the version number.',
    )
    ..addFlag(
      'no-color',
      negatable: false,
      help: 'Disable colored output.',
    );

  try {
    // Handle --version flag (only if it's the first/only argument)
    if (arguments.isNotEmpty &&
        (arguments.first == '--version' ||
            (arguments.first == '-v' && arguments.length == 1))) {
      print('flg version $version');
      exit(0);
    }

    // Handle --no-color flag
    if (arguments.contains('--no-color')) {
      ConsoleUtils.setColorsEnabled(false);
      arguments = arguments.where((arg) => arg != '--no-color').toList();
    }

    final exitCode = await runner.run(arguments) ?? 0;
    exit(exitCode);
  } on UsageException catch (e) {
    ConsoleUtils.error(e.message);
    print('');
    print(e.usage);
    exit(64);
  } catch (e, stackTrace) {
    ConsoleUtils.error('An unexpected error occurred:');
    ConsoleUtils.error(e.toString());
    if (arguments.contains('--verbose') || arguments.contains('-v')) {
      print('');
      print(stackTrace);
    }
    exit(1);
  }
}
