import 'dart:io';

import 'package:fcli/src/config/fcli_config.dart';
import 'package:fcli/src/generators/feature_generator.dart';
import 'package:fcli/src/utils/file_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Feature Generation', () {
    late Directory tempDir;
    late FcliConfig config;
    late String projectPath;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('fcli_feature_test_');
      projectPath = '${tempDir.path}/test_app';

      config = FcliConfig(
        projectName: 'test_app',
        stateManagement: StateManagement.riverpod,
        router: RouterOption.goRouter,
        useFreezed: true,
        useDioClient: true,
      );

      // Create basic project structure
      await FileUtils.createDirectory('$projectPath/lib/features');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('generates complete feature structure', () async {
      final generator = FeatureGenerator(
        config: config,
        projectPath: projectPath,
        verbose: false,
        dryRun: false,
      );

      await generator.generate('auth');

      // Check domain layer
      expect(
        FileUtils.fileExistsSync(
          '$projectPath/lib/features/auth/domain/entities/auth_entity.dart',
        ),
        isTrue,
      );
      expect(
        FileUtils.fileExistsSync(
          '$projectPath/lib/features/auth/domain/repositories/auth_repository.dart',
        ),
        isTrue,
      );

      // Check data layer
      expect(
        FileUtils.fileExistsSync(
          '$projectPath/lib/features/auth/data/models/auth_model.dart',
        ),
        isTrue,
      );
      expect(
        FileUtils.fileExistsSync(
          '$projectPath/lib/features/auth/data/repositories/auth_repository_impl.dart',
        ),
        isTrue,
      );
      expect(
        FileUtils.fileExistsSync(
          '$projectPath/lib/features/auth/data/datasources/auth_remote_datasource.dart',
        ),
        isTrue,
      );

      // Check presentation layer
      expect(
        FileUtils.fileExistsSync(
          '$projectPath/lib/features/auth/presentation/screens/auth_screen.dart',
        ),
        isTrue,
      );
      expect(
        FileUtils.fileExistsSync(
          '$projectPath/lib/features/auth/presentation/providers/auth_notifier.dart',
        ),
        isTrue,
      );
      expect(
        FileUtils.fileExistsSync(
          '$projectPath/lib/features/auth/presentation/providers/auth_state.dart',
        ),
        isTrue,
      );
      expect(
        FileUtils.fileExistsSync(
          '$projectPath/lib/features/auth/presentation/widgets/auth_card.dart',
        ),
        isTrue,
      );
    });

    test('generates Bloc files when using Bloc', () async {
      final blocConfig = config.copyWith(
        stateManagement: StateManagement.bloc,
      );

      final generator = FeatureGenerator(
        config: blocConfig,
        projectPath: projectPath,
        verbose: false,
        dryRun: false,
      );

      await generator.generate('user');

      expect(
        FileUtils.fileExistsSync(
          '$projectPath/lib/features/user/presentation/providers/user_bloc.dart',
        ),
        isTrue,
      );
      expect(
        FileUtils.fileExistsSync(
          '$projectPath/lib/features/user/presentation/providers/user_event.dart',
        ),
        isTrue,
      );
      expect(
        FileUtils.fileExistsSync(
          '$projectPath/lib/features/user/presentation/providers/user_state.dart',
        ),
        isTrue,
      );
    });

    test('generates Provider files when using Provider', () async {
      final providerConfig = config.copyWith(
        stateManagement: StateManagement.provider,
      );

      final generator = FeatureGenerator(
        config: providerConfig,
        projectPath: projectPath,
        verbose: false,
        dryRun: false,
      );

      await generator.generate('product');

      expect(
        FileUtils.fileExistsSync(
          '$projectPath/lib/features/product/presentation/providers/product_provider.dart',
        ),
        isTrue,
      );
    });

    test('generates non-Freezed model when useFreezed is false', () async {
      final noFreezedConfig = config.copyWith(useFreezed: false);

      final generator = FeatureGenerator(
        config: noFreezedConfig,
        projectPath: projectPath,
        verbose: false,
        dryRun: false,
      );

      await generator.generate('order');

      final modelContent = FileUtils.readFileSync(
        '$projectPath/lib/features/order/data/models/order_model.dart',
      );

      expect(modelContent, isNot(contains('@freezed')));
      expect(modelContent, contains('class OrderModel'));
      expect(modelContent, contains('factory OrderModel.fromJson'));
    });

    test('dry run does not create files', () async {
      final generator = FeatureGenerator(
        config: config,
        projectPath: projectPath,
        verbose: false,
        dryRun: true,
      );

      await generator.generate('settings');

      expect(
        FileUtils.directoryExistsSync(
          '$projectPath/lib/features/settings',
        ),
        isFalse,
      );
    });

    test('handles PascalCase feature names', () async {
      final generator = FeatureGenerator(
        config: config,
        projectPath: projectPath,
        verbose: false,
        dryRun: false,
      );

      await generator.generate('UserProfile');

      expect(
        FileUtils.fileExistsSync(
          '$projectPath/lib/features/user_profile/domain/entities/user_profile_entity.dart',
        ),
        isTrue,
      );
    });

    test('generated entity file contains correct content', () async {
      final generator = FeatureGenerator(
        config: config,
        projectPath: projectPath,
        verbose: false,
        dryRun: false,
      );

      await generator.generate('cart');

      final entityContent = FileUtils.readFileSync(
        '$projectPath/lib/features/cart/domain/entities/cart_entity.dart',
      );

      expect(entityContent, contains('class CartEntity extends Equatable'));
      expect(entityContent, contains('final String id'));
      expect(entityContent, contains('final String name'));
      expect(entityContent, contains('required this.id'));
      expect(entityContent, contains('@override'));
      expect(entityContent, contains('List<Object?> get props'));
    });

    test('generated repository interface contains correct methods', () async {
      final generator = FeatureGenerator(
        config: config,
        projectPath: projectPath,
        verbose: false,
        dryRun: false,
      );

      await generator.generate('notification');

      final repoContent = FileUtils.readFileSync(
        '$projectPath/lib/features/notification/domain/repositories/notification_repository.dart',
      );

      expect(repoContent, contains('abstract class NotificationRepository'));
      expect(repoContent, contains('Future<Either<Failure, List<NotificationEntity>>> getAll()'));
      expect(repoContent, contains('Future<Either<Failure, NotificationEntity>> getById(String id)'));
      expect(repoContent, contains('Future<Either<Failure, NotificationEntity>> create'));
      expect(repoContent, contains('Future<Either<Failure, NotificationEntity>> update'));
      expect(repoContent, contains('Future<Either<Failure, void>> delete'));
    });
  });
}
