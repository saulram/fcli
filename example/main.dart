import 'package:flg/flg.dart';

void main() {
  final config = FcliConfig.defaults('todo_app').copyWith(
    features: const ['auth', 'todos'],
  );

  final entityName = StringUtils.toSnakeCase('TodoItem');
  final routerCode = AppRouterTemplate.generate(config);

  print('Project: ${config.projectName}');
  print(
      'Entity file: lib/features/todos/domain/entities/${entityName}_entity.dart');
  print('Router preview:');
  print(routerCode);
}
