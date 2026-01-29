# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-28

### Added

- Initial release of fcli
- `init` command for creating new Flutter projects with Clean Architecture
  - Interactive configuration prompts
  - Support for Riverpod, Bloc, and Provider state management
  - Support for GoRouter and AutoRoute
  - Optional Freezed integration
  - Optional Dio HTTP client
  - Multi-platform support (Android, iOS, Web, macOS, Windows, Linux)
  - Localization (l10n) support
- `generate` command with subcommands:
  - `feature` (alias: `f`) - Generate complete feature modules
  - `screen` (alias: `s`) - Generate screen widgets
  - `widget` (alias: `w`) - Generate widgets (stateless, stateful, card, list_tile, form)
  - `provider` (alias: `p`) - Generate providers/notifiers/blocs
  - `usecase` (alias: `u`) - Generate use cases (single or CRUD)
  - `repository` (alias: `r`) - Generate repositories with data sources
- Core templates:
  - Exceptions and Failures
  - Base UseCase classes
  - App Router configuration
  - Main.dart with state management setup
- Feature templates:
  - Entity classes with Equatable
  - Repository interfaces
  - Model classes (with optional Freezed)
  - Repository implementations
  - Remote data sources (Dio or http)
  - Notifiers/Blocs/Providers based on state management choice
  - Screen widgets with state management integration
  - Widget templates (card, list tile, form)
- Global options:
  - `--dry-run` - Preview changes without creating files
  - `--verbose` - Show detailed output
  - `--no-color` - Disable colored console output
- Configuration file (`fcli.json`) for project settings
- Comprehensive test suite

### Technical Details

- Written in Dart
- Uses `args` package for CLI argument parsing
- Uses `recase` package for string case transformations
- Uses `yaml` package for YAML parsing
- Uses `path` package for cross-platform path handling
