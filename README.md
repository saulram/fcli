# flg

[![Pub Version](https://img.shields.io/pub/v/flg)](https://pub.dev/packages/flg)
[![Dart SDK](https://img.shields.io/badge/Dart-%5E3.0.0-blue)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-81%20passed-brightgreen)](https://github.com/saulram/flg)

**Flutter Generator** - A powerful CLI tool for generating Flutter projects with **Clean Architecture**, feature-first organization, and your choice of modern state management.

Inspired by Angular CLI, flg eliminates boilerplate and enforces architectural consistency across your Flutter projects.

## Features

| Feature | Description |
|---------|-------------|
| **Clean Architecture** | Domain, Data, and Presentation layers with clear separation of concerns |
| **Feature-First** | Each feature is self-contained with all its layers |
| **State Management** | Riverpod (default), Bloc, or Provider |
| **Routing** | GoRouter (default) or AutoRoute with code generation |
| **Freezed Integration** | Immutable data classes with `sealed class` syntax |
| **Code Generation** | Automatic `build_runner` execution |
| **Existing Projects** | Set up flg in any existing Flutter project |
| **AI Agent Workflows** | Git worktree management for parallel AI agents |

## Quick Start

### Installation

```bash
# From pub.dev (recommended)
dart pub global activate flg

# Or from source
git clone https://github.com/saulram/flg.git
cd flg
dart pub global activate --source path .
```

### Create a New Project

```bash
# Interactive mode (recommended for first-time users)
flg init my_app

# Non-interactive with defaults
flg init my_app -s

# With specific options
flg init my_app --state riverpod --router go_router --org com.mycompany
```

### Set Up an Existing Project

```bash
cd my_existing_flutter_app
flg setup
```

### Generate Components

```bash
# Generate a feature
flg g f auth

# Generate a screen
flg g s login -f auth

# Generate a widget
flg g w user_avatar -f auth

# Generate CRUD use cases
flg g u user -f user --crud

# Generate a repository
flg g r user -f user
```

## Commands

### `flg init <project_name>`

Creates a new Flutter project with Clean Architecture.

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--org` | `-o` | Organization identifier (reverse domain) | `com.example` |
| `--state` | | State management: `riverpod`, `bloc`, `provider` | `riverpod` |
| `--router` | | Router: `go_router`, `auto_route` | `go_router` |
| `--freezed` | | Use Freezed for data classes | `true` |
| `--dio` | | Use Dio HTTP client | `true` |
| `--platforms` | `-p` | Target platforms | `android,ios` |
| `--feature` | | Initial feature name | `home` |
| `--skip-prompts` | `-s` | Skip interactive prompts | `false` |
| `--dry-run` | | Preview without creating files | `false` |
| `--verbose` | `-v` | Show detailed output | `false` |

### `flg setup`

Configures flg in an existing Flutter project.

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--state` | | State management solution | `riverpod` |
| `--router` | | Router solution | `go_router` |
| `--freezed` | | Use Freezed | `true` |
| `--dio` | | Use Dio | `true` |
| `--feature` | | Initial feature name | (none) |
| `--skip-deps` | | Don't modify pubspec.yaml | `false` |
| `--skip-prompts` | `-s` | Skip interactive prompts | `false` |
| `--force` | `-f` | Reconfigure if flg.json exists | `false` |
| `--dry-run` | | Preview without making changes | `false` |

### `flg generate <component>` (alias: `g`)

Generates code components within a flg project.

| Subcommand | Alias | Description |
|------------|-------|-------------|
| `feature` | `f` | Complete feature module with all layers |
| `screen` | `s` | Screen widget with routing setup |
| `widget` | `w` | Widget (stateless, stateful, card, list_tile, form) |
| `provider` | `p` | Provider/Notifier/Bloc based on state management |
| `usecase` | `u` | Use case (single action or CRUD) |
| `repository` | `r` | Repository interface and implementation |

#### Examples

```bash
# Feature with custom entity
flg g f product --entity product_item

# Stateful widget
flg g w product_form -f product -t stateful

# Form widget
flg g w checkout_form -f checkout -t form

# Single use case
flg g u authenticate -f auth -a create

# All CRUD use cases at once
flg g u product -f product --crud
```

### `flg task` (alias: `t`)

Manage git worktrees for AI agent workflows. Perfect for running multiple Claude Code, Cursor, or other AI agents in parallel on separate tasks.

| Subcommand | Alias | Description |
|------------|-------|-------------|
| `add` | | Create a new task worktree with branch |
| `list` | `ls` | List all active task worktrees |
| `remove` | `rm` | Remove a task worktree |
| `status` | `st` | Show status of all task worktrees |

#### `flg task add <name>`

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--type` | `-t` | Branch prefix: `feat`, `fix`, `ref` | `feat` |
| `--agent` | `-a` | Setup for AI agent (pub get + .claude/TASK.md) | `false` |
| `--base` | `-b` | Base branch to create from | `main` |
| `--dry-run` | | Preview without creating | `false` |

#### Examples

```bash
# Create tasks for parallel AI agents
flg task add auth-feature --agent
flg task add fix-payment --type fix --agent
flg task add refactor-api --type ref --agent

# Check status of all tasks
flg task status

# List active worktrees
flg task list

# Remove when done
flg task remove auth-feature
```

#### Output Example

```
✓ Created task: feat-auth
  → Path: /Users/dev/my_app-tasks/feat-auth
  → Branch: feat/auth

✓ Running flutter pub get...
✓ Created .claude/TASK.md

Ready for AI Agent:
/Users/dev/my_app-tasks/feat-auth
```

Worktrees are created in `../[project-name]-tasks/` as sibling directories to your main project.

## Project Structure

After running `flg init my_app`, you get:

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
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   ├── network/
│   │   └── utils/
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
│                   ├── home_notifier.g.dart
│                   ├── home_state.dart
│                   └── home_state.freezed.dart
├── test/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
├── pubspec.yaml
└── flg.json
```

## State Management

### Riverpod (Default)

Uses modern `riverpod_annotation` with code generation:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_notifier.g.dart';

@riverpod
class HomeNotifier extends _$HomeNotifier {
  @override
  HomeState build() => const HomeState();

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.getAll();
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (items) => state = state.copyWith(
        isLoading: false,
        homes: items,
      ),
    );
  }
}
```

State classes use Freezed with `sealed class`:

```dart
@freezed
sealed class HomeState with _$HomeState {
  const factory HomeState({
    @Default([]) List<HomeEntity> homes,
    HomeEntity? selectedHome,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _HomeState;

  const HomeState._();

  bool get hasError => errorMessage != null;
  bool get isEmpty => homes.isEmpty;
}
```

### Bloc

Full Bloc pattern with events and states:

```dart
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._repository) : super(const HomeInitial()) {
    on<LoadHomesEvent>(_onLoadHomes);
  }

  final HomeRepository _repository;

  Future<void> _onLoadHomes(LoadHomesEvent event, Emitter<HomeState> emit) async {
    emit(const HomeLoading());
    final result = await _repository.getAll();
    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (homes) => emit(HomeLoaded(homes)),
    );
  }
}
```

### Provider

Simple ChangeNotifier pattern:

```dart
class HomeProvider extends ChangeNotifier {
  final HomeRepository _repository;

  List<HomeEntity> _homes = [];
  bool _isLoading = false;
  String? _error;

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    final result = await _repository.getAll();
    result.fold(
      (failure) => _error = failure.message,
      (homes) => _homes = homes,
    );

    _isLoading = false;
    notifyListeners();
  }
}
```

## Configuration

The `flg.json` file stores project configuration:

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

This file is automatically created during `init` or `setup` and is used by generate commands to maintain consistency.

## Architecture Overview

flg generates code following Clean Architecture principles:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌─────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │ Screens │  │   Widgets    │  │ Providers/Blocs   │  │
│  └─────────┘  └──────────────┘  └───────────────────┘  │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                      Domain Layer                        │
│  ┌──────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │ Entities │  │ Repository Intf. │  │   UseCases   │  │
│  └──────────┘  └──────────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                       Data Layer                         │
│  ┌────────┐  ┌───────────────────┐  ┌───────────────┐  │
│  │ Models │  │ Repository Impl.  │  │  DataSources  │  │
│  └────────┘  └───────────────────┘  └───────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Key Patterns

- **Entities**: Pure Dart classes representing business objects
- **Repositories**: Abstract interfaces in domain, implementations in data
- **Use Cases**: Single-responsibility classes for business logic
- **Models**: Data classes with JSON serialization (Freezed-based)
- **DataSources**: Handle external data (API, database, cache)

## Known Limitations

### Current Limitations

1. **No test file generation**: Test scaffolding is not yet implemented. The `test/` directory structure is created but test files are not generated.

2. **No migration support**: Upgrading configuration after `setup` or `init` requires manual intervention.

3. **Single datasource per feature**: Currently generates only remote datasources. Local caching datasources require manual implementation.

4. **No DI container setup**: Dependency injection setup (get_it, injectable) is not included. Repository injection in notifiers requires manual wiring.

### Planned Features

- [ ] Test file generation with mocking
- [ ] get_it / injectable integration
- [ ] Local datasource templates (Hive, SQLite)
- [ ] Migration command for config updates
- [ ] Custom template support

## Troubleshooting

### `build_runner` fails

If code generation fails after project creation:

```bash
# For Flutter projects
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for development
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Riverpod provider not found

Ensure you've run `build_runner` after adding new providers. The `.g.dart` files must be generated.

### Import errors

flg uses absolute package imports (`package:my_app/...`). If you rename your project, update the `name` field in `pubspec.yaml` and regenerate imports.

## Requirements

- Dart SDK: ^3.0.0
- Flutter (for generated projects): ^3.0.0

## Contributing

Contributions are welcome! Please see the [GitHub repository](https://github.com/saulram/flg) for:

- [Issue Tracker](https://github.com/saulram/flg/issues)
- [Pull Requests](https://github.com/saulram/flg/pulls)

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

Created by [Saul Ramirez](https://github.com/saulram)

Inspired by:
- [Angular CLI](https://angular.io/cli)
- [Very Good CLI](https://github.com/VeryGoodOpenSource/very_good_cli)
- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
