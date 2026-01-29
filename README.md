# fcli - Flutter Clean Architecture CLI

A powerful CLI tool for generating Flutter projects with Clean Architecture, feature-first organization, and your choice of state management.

## Features

- **Clean Architecture**: Generates a well-organized project structure with domain, data, and presentation layers
- **Feature-First Organization**: Each feature is self-contained with all its layers
- **Multiple State Management Options**: Riverpod (default), Bloc, or Provider
- **Router Support**: GoRouter (default) or AutoRoute
- **Freezed Integration**: Optional Freezed for immutable data classes
- **Dio HTTP Client**: Built-in HTTP client setup
- **Code Generation**: Automatic generation of entities, models, repositories, use cases, screens, and widgets

## Installation

```bash
# Clone the repository
git clone https://github.com/your-username/fcli.git
cd fcli

# Install dependencies
dart pub get

# Activate globally
dart pub global activate --source path .
```

Or compile to an executable:

```bash
dart compile exe bin/fcli.dart -o fcli
./fcli --help
```

## Usage

### Initialize a New Project

```bash
# Interactive mode (recommended)
fcli init my_app

# With options
fcli init my_app --org com.mycompany --state riverpod --router go_router

# Skip prompts and use defaults
fcli init my_app -s
```

#### Init Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--org` | `-o` | Organization identifier | `com.example` |
| `--state` | | State management (riverpod, bloc, provider) | `riverpod` |
| `--router` | | Router (go_router, auto_route) | `go_router` |
| `--freezed` | | Use Freezed for data classes | `true` |
| `--dio` | | Use Dio HTTP client | `true` |
| `--platforms` | `-p` | Target platforms | `android,ios` |
| `--feature` | | Initial feature name | `home` |
| `--skip-prompts` | `-s` | Skip interactive prompts | `false` |
| `--dry-run` | | Preview without creating files | `false` |
| `--verbose` | `-v` | Show detailed output | `false` |

### Generate Components

All generate commands use the `generate` (or `g`) command:

```bash
# Generate a new feature
fcli g feature auth

# Generate a screen
fcli g screen login -f auth

# Generate a widget
fcli g widget user_avatar -f auth -t stateless

# Generate a provider/notifier/bloc
fcli g provider auth -f auth

# Generate a use case
fcli g usecase login -f auth -a create

# Generate all CRUD use cases
fcli g usecase user -f user --crud

# Generate a repository
fcli g repository user -f user
```

#### Generate Subcommands

| Command | Alias | Description |
|---------|-------|-------------|
| `feature` | `f` | Generate a complete feature module |
| `screen` | `s` | Generate a screen widget |
| `widget` | `w` | Generate a widget |
| `provider` | `p` | Generate a provider/notifier/bloc |
| `usecase` | `u` | Generate a use case |
| `repository` | `r` | Generate a repository |

### Examples

```bash
# Create a new project with Bloc
fcli init todo_app --state bloc --router go_router

# Add a task feature
cd todo_app
fcli g feature task

# Add a detail screen to task feature
fcli g screen task_detail -f task

# Add a form widget
fcli g widget task_form -f task -t form

# Generate CRUD use cases
fcli g usecase task -f task --crud
```

## Project Structure

After running `fcli init my_app`, you'll get:

```
my_app/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── error/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── usecases/
│   │   │   └── usecase.dart
│   │   └── router/
│   │       └── app_router.dart
│   └── features/
│       └── home/
│           ├── domain/
│           │   ├── entities/
│           │   │   └── home_entity.dart
│           │   ├── repositories/
│           │   │   └── home_repository.dart
│           │   └── usecases/
│           ├── data/
│           │   ├── models/
│           │   │   └── home_model.dart
│           │   ├── repositories/
│           │   │   └── home_repository_impl.dart
│           │   └── datasources/
│           │       └── home_remote_datasource.dart
│           └── presentation/
│               ├── screens/
│               │   └── home_screen.dart
│               ├── widgets/
│               │   └── home_card.dart
│               └── providers/
│                   ├── home_notifier.dart
│                   └── home_state.dart
├── test/
├── pubspec.yaml
└── fcli.json
```

## Configuration

The `fcli.json` file stores your project configuration:

```json
{
  "projectName": "my_app",
  "org": "com.example",
  "stateManagement": "riverpod",
  "router": "go_router",
  "useFreezed": true,
  "useDioClient": true,
  "platforms": ["android", "ios"],
  "features": ["home"],
  "generateTests": true,
  "l10n": false
}
```

## State Management

### Riverpod (Default)

Generates `StateNotifier` with `StateNotifierProvider`:

```dart
final homeNotifierProvider =
    StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  // ...
});

class HomeNotifier extends StateNotifier<HomeState> {
  // ...
}
```

### Bloc

Generates full Bloc pattern with events and states:

```dart
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  // ...
}
```

### Provider

Generates `ChangeNotifier`:

```dart
class HomeProvider extends ChangeNotifier {
  // ...
}
```

## After Project Creation

1. Navigate to your project:
   ```bash
   cd my_app
   ```

2. Run build_runner (if using Freezed):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details.
