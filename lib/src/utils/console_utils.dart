import 'dart:io';

/// ANSI color codes for console output.
class ConsoleColor {
  ConsoleColor._();

  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  static const String italic = '\x1B[3m';
  static const String underline = '\x1B[4m';

  // Foreground colors
  static const String black = '\x1B[30m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';

  // Bright foreground colors
  static const String brightBlack = '\x1B[90m';
  static const String brightRed = '\x1B[91m';
  static const String brightGreen = '\x1B[92m';
  static const String brightYellow = '\x1B[93m';
  static const String brightBlue = '\x1B[94m';
  static const String brightMagenta = '\x1B[95m';
  static const String brightCyan = '\x1B[96m';
  static const String brightWhite = '\x1B[97m';

  /// Black background ANSI code.
  static const String bgBlack = '\x1B[40m';

  /// Red background ANSI code.
  static const String bgRed = '\x1B[41m';

  /// Green background ANSI code.
  static const String bgGreen = '\x1B[42m';

  /// Yellow background ANSI code.
  static const String bgYellow = '\x1B[43m';

  /// Blue background ANSI code.
  static const String bgBlue = '\x1B[44m';

  /// Magenta background ANSI code.
  static const String bgMagenta = '\x1B[45m';

  /// Cyan background ANSI code.
  static const String bgCyan = '\x1B[46m';

  /// White background ANSI code.
  static const String bgWhite = '\x1B[47m';
}

/// Utility class for console output with colors and formatting.
class ConsoleUtils {
  ConsoleUtils._();

  static bool _colorsEnabled = stdout.supportsAnsiEscapes;

  /// Enable or disable colors globally.
  static void setColorsEnabled(bool enabled) {
    _colorsEnabled = enabled;
  }

  /// Wraps text with ANSI color code.
  static String _colorize(String text, String color) {
    if (!_colorsEnabled) return text;
    return '$color$text${ConsoleColor.reset}';
  }

  // Color methods
  static String red(String text) => _colorize(text, ConsoleColor.red);
  static String green(String text) => _colorize(text, ConsoleColor.green);
  static String yellow(String text) => _colorize(text, ConsoleColor.yellow);
  static String blue(String text) => _colorize(text, ConsoleColor.blue);
  static String magenta(String text) => _colorize(text, ConsoleColor.magenta);
  static String cyan(String text) => _colorize(text, ConsoleColor.cyan);
  static String white(String text) => _colorize(text, ConsoleColor.white);
  static String dim(String text) => _colorize(text, ConsoleColor.dim);
  static String bold(String text) => _colorize(text, ConsoleColor.bold);

  /// Prints a success message (green checkmark).
  static void success(String message) {
    print('${green('✓')} $message');
  }

  /// Prints an error message (red X).
  static void error(String message) {
    print('${red('✗')} $message');
  }

  /// Prints a warning message (yellow warning sign).
  static void warning(String message) {
    print('${yellow('⚠')} $message');
  }

  /// Prints an info message (blue info sign).
  static void info(String message) {
    print('${blue('ℹ')} $message');
  }

  /// Prints a step message (cyan arrow).
  static void step(String message) {
    print('${cyan('→')} $message');
  }

  /// Prints a dimmed message.
  static void muted(String message) {
    print(dim(message));
  }

  /// Prints a newline.
  static void newLine() {
    print('');
  }

  /// Prints a horizontal line.
  static void line({int length = 40, String char = '─'}) {
    print(dim(char * length));
  }

  /// Prints a header with decoration.
  static void header(String text) {
    newLine();
    print(bold(cyan(text)));
    line(length: text.length);
  }

  /// Prompts the user for input.
  static String? prompt(String message, {String? defaultValue}) {
    if (defaultValue != null) {
      stdout.write('${cyan('?')} $message ${dim('($defaultValue)')}: ');
    } else {
      stdout.write('${cyan('?')} $message: ');
    }

    final input = stdin.readLineSync()?.trim();
    if (input == null || input.isEmpty) {
      return defaultValue;
    }
    return input;
  }

  /// Prompts the user for a yes/no confirmation.
  static bool confirm(String message, {bool defaultValue = false}) {
    final defaultStr = defaultValue ? 'Y/n' : 'y/N';
    stdout.write('${cyan('?')} $message ${dim('($defaultStr)')}: ');

    final input = stdin.readLineSync()?.trim().toLowerCase();
    if (input == null || input.isEmpty) {
      return defaultValue;
    }
    return input == 'y' || input == 'yes';
  }

  /// Prompts the user to select from a list of options.
  static int select(String message, List<String> options) {
    print('${cyan('?')} $message');
    for (var i = 0; i < options.length; i++) {
      print('  ${dim('${i + 1}.')} ${options[i]}');
    }

    while (true) {
      stdout.write('${cyan('→')} Enter selection (1-${options.length}): ');
      final input = stdin.readLineSync()?.trim();

      if (input != null && input.isNotEmpty) {
        final selection = int.tryParse(input);
        if (selection != null &&
            selection >= 1 &&
            selection <= options.length) {
          return selection - 1;
        }
      }
      error(
          'Invalid selection. Please enter a number between 1 and ${options.length}.');
    }
  }

  /// Prompts the user to select multiple options from a list.
  static List<int> multiSelect(
    String message,
    List<String> options, {
    List<int> defaultSelected = const [],
  }) {
    print('${cyan('?')} $message ${dim('(comma-separated, e.g., 1,3,4)')}');
    for (var i = 0; i < options.length; i++) {
      final isSelected = defaultSelected.contains(i);
      final marker = isSelected ? green('●') : dim('○');
      print('  $marker ${dim('${i + 1}.')} ${options[i]}');
    }

    while (true) {
      stdout.write('${cyan('→')} Enter selections: ');
      final input = stdin.readLineSync()?.trim();

      if (input == null || input.isEmpty) {
        return defaultSelected;
      }

      final selections = <int>[];
      var valid = true;

      for (final part in input.split(',')) {
        final selection = int.tryParse(part.trim());
        if (selection != null &&
            selection >= 1 &&
            selection <= options.length) {
          selections.add(selection - 1);
        } else {
          valid = false;
          break;
        }
      }

      if (valid && selections.isNotEmpty) {
        return selections;
      }
      error(
          'Invalid selection. Please enter comma-separated numbers between 1 and ${options.length}.');
    }
  }

  /// Clears the console.
  static void clear() {
    if (Platform.isWindows) {
      print('\x1B[2J\x1B[0;0H');
    } else {
      print('\x1B[2J\x1B[3J\x1B[H');
    }
  }

  /// Shows a spinner while executing an async operation.
  static Future<T> withSpinner<T>(
    String message,
    Future<T> Function() operation,
  ) async {
    const frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
    var frameIndex = 0;
    var running = true;

    // Start spinner in background
    Future<void> spin() async {
      while (running) {
        stdout.write('\r${cyan(frames[frameIndex])} $message');
        frameIndex = (frameIndex + 1) % frames.length;
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
    }

    final spinnerFuture = spin();

    try {
      final result = await operation();
      running = false;
      await spinnerFuture;
      stdout.write('\r${green('✓')} $message\n');
      return result;
    } catch (e) {
      running = false;
      await spinnerFuture;
      stdout.write('\r${red('✗')} $message\n');
      rethrow;
    }
  }

  /// Prints a progress bar.
  static void progressBar(int current, int total, {String? label}) {
    const barWidth = 30;
    final progress = current / total;
    final filled = (progress * barWidth).round();
    final empty = barWidth - filled;

    final bar = '${green('█' * filled)}${dim('░' * empty)}';
    final percentage = (progress * 100).toStringAsFixed(0).padLeft(3);

    if (label != null) {
      stdout.write('\r$bar $percentage% - $label');
    } else {
      stdout.write('\r$bar $percentage%');
    }

    if (current == total) {
      print('');
    }
  }
}
