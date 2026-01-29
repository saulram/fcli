---
name: flg
description: |
  Flutter Generator CLI for Clean Architecture. **USE PROACTIVELY** when user asks to:
  - Create a new Flutter project/app (use `flg init` instead of `flutter create`)
  - Generate features, screens, widgets, providers
  - Setup Clean Architecture in existing project
user-invocable: true
allowed-tools: Bash, Read, Glob
---

# FLG - Flutter Generator

A CLI tool for generating Flutter projects with Clean Architecture, feature-first organization, and modern state management.

## Commands

### Initialize New Project
```bash
# Interactive mode
flg init <project_name>

# Non-interactive with defaults
flg init <project_name> -s

# With options
flg init <project_name> --state riverpod --router go_router --org com.mycompany
```

### Setup Existing Project
```bash
cd my_existing_flutter_app
flg setup
```

### Generate Feature (Complete Clean Architecture module)
```bash
flg generate feature <name>
flg g f <name>

# Example
flg g f auth
flg g f user_profile
```

Generates:
- `domain/entities/<name>_entity.dart`
- `domain/repositories/<name>_repository.dart`
- `data/models/<name>_model.dart`
- `data/repositories/<name>_repository_impl.dart`
- `data/datasources/<name>_remote_datasource.dart`
- `presentation/screens/<name>_screen.dart`
- `presentation/providers/<name>_provider.dart` (Riverpod)
- `presentation/providers/<name>_state.dart`
- `presentation/widgets/<name>_card.dart`

### Generate Screen
```bash
flg generate screen <name> --feature <feature>
flg g s <name> -f <feature>

# Example
flg g s login -f auth
flg g s profile_detail -f user
```

### Generate Widget
```bash
flg generate widget <name> --feature <feature> [--type <type>]
flg g w <name> -f <feature> [-t <type>]

# Types: stateless (default), stateful, card, list_tile, form

# Examples
flg g w user_avatar -f auth
flg g w checkout_form -f checkout -t form
flg g w product_item -f product -t list_tile
```

### Generate Provider/Notifier/Bloc
```bash
flg generate provider <name> --feature <feature>
flg g p <name> -f <feature>

# Example
flg g p cart -f shopping
```

### Generate Use Case
```bash
flg generate usecase <name> --feature <feature> [--action <action>] [--crud]
flg g u <name> -f <feature> [-a <action>]

# Actions: get, create, update, delete

# Examples
flg g u authenticate -f auth -a create
flg g u user -f user --crud  # Generates all CRUD use cases
```

### Generate Repository
```bash
flg generate repository <name> --feature <feature>
flg g r <name> -f <feature>

# Example
flg g r payment -f checkout
```

### Task Management (Git Worktrees for AI Agents)
```bash
# Create a new task worktree
flg task add <name> [--type <type>] [--agent] [--base <branch>]
flg t add <name>

# Types: feat (default), fix, ref

# Examples
flg task add auth-feature --agent
flg task add fix-payment --type fix --agent

# List active worktrees
flg task list
flg t ls

# Show status
flg task status
flg t st

# Remove worktree
flg task remove <name>
flg t rm <name>
```

## Configuration

flg stores configuration in `flg.json`:

```json
{
  "projectName": "my_app",
  "org": "com.example",
  "stateManagement": "riverpod",
  "router": "go_router",
  "useFreezed": true,
  "useDioClient": true,
  "features": ["home", "auth"]
}
```

## State Management Options

- **riverpod** (default): Uses `@riverpod` annotation with code generation
- **bloc**: Full Bloc pattern with events and states
- **provider**: ChangeNotifier pattern

## Naming Conventions

- Feature names: `snake_case` or `camelCase` (converted to snake_case)
- Generated classes: `PascalCase`
- Generated files: `snake_case.dart`
- Provider names (Riverpod): `featureNameProvider` (not `featureNameNotifierProvider`)

## After Generation

Run build_runner to generate required files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs

# Or watch mode
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Common Flags

- `--dry-run`: Preview without creating files
- `--verbose` / `-v`: Show detailed output
- `--force` / `-f`: Overwrite existing files
