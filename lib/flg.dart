/// Flutter Generator - CLI for Clean Architecture projects.
///
/// This library provides tools for creating and managing Flutter projects
/// using Clean Architecture patterns with feature-first organization.
library flg;

// Config
export 'src/config/config_loader.dart';
export 'src/config/fcli_config.dart';

// Commands
export 'src/commands/generate_command.dart';
export 'src/commands/init_command.dart';
export 'src/commands/setup_command.dart';

// Generators
export 'src/generators/feature_generator.dart';
export 'src/generators/project_generator.dart';
export 'src/generators/provider_generator.dart';
export 'src/generators/repository_generator.dart';
export 'src/generators/screen_generator.dart';
export 'src/generators/usecase_generator.dart';
export 'src/generators/widget_generator.dart';

// Templates - Core
export 'src/templates/core/app_router_template.dart';
export 'src/templates/core/exceptions_template.dart';
export 'src/templates/core/failures_template.dart';
export 'src/templates/core/main_template.dart';
export 'src/templates/core/usecase_template.dart';

// Templates - Feature
export 'src/templates/feature/datasource_template.dart';
export 'src/templates/feature/entity_template.dart';
export 'src/templates/feature/model_template.dart';
export 'src/templates/feature/notifier_template.dart';
export 'src/templates/feature/repository_abstract_template.dart';
export 'src/templates/feature/repository_impl_template.dart';
export 'src/templates/feature/screen_template.dart';
export 'src/templates/feature/widget_template.dart';

// Templates - Config
export 'src/templates/config/fcli_json_template.dart';
export 'src/templates/config/pubspec_template.dart';

// Utils
export 'src/utils/console_utils.dart';
export 'src/utils/file_utils.dart';
export 'src/utils/process_utils.dart';
export 'src/utils/string_utils.dart';
