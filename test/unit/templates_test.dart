import 'package:fcli/src/config/fcli_config.dart';
import 'package:fcli/src/templates/core/exceptions_template.dart';
import 'package:fcli/src/templates/core/failures_template.dart';
import 'package:fcli/src/templates/core/usecase_template.dart';
import 'package:fcli/src/templates/feature/entity_template.dart';
import 'package:fcli/src/templates/feature/model_template.dart';
import 'package:fcli/src/templates/feature/notifier_template.dart';
import 'package:fcli/src/templates/feature/repository_abstract_template.dart';
import 'package:fcli/src/templates/feature/screen_template.dart';
import 'package:test/test.dart';

void main() {
  group('Core Templates', () {
    test('ExceptionsTemplate generates valid Dart code', () {
      final code = ExceptionsTemplate.generate();

      expect(code, contains('abstract class AppException'));
      expect(code, contains('class ServerException'));
      expect(code, contains('class NetworkException'));
      expect(code, contains('class CacheException'));
      expect(code, contains('class AuthException'));
      expect(code, contains('class NotFoundException'));
      expect(code, contains('class ValidationException'));
      expect(code, contains('class UnauthorizedException'));
      expect(code, contains('class TimeoutException'));
    });

    test('FailuresTemplate generates valid Dart code', () {
      final code = FailuresTemplate.generate();

      expect(code, contains("import 'package:equatable/equatable.dart'"));
      expect(code, contains('abstract class Failure extends Equatable'));
      expect(code, contains('class ServerFailure extends Failure'));
      expect(code, contains('class NetworkFailure extends Failure'));
      expect(code, contains('class CacheFailure extends Failure'));
      expect(code, contains('class AuthFailure extends Failure'));
      expect(code, contains('class NotFoundFailure extends Failure'));
      expect(code, contains('class ValidationFailure extends Failure'));
    });

    test('UseCaseBaseTemplate generates valid Dart code', () {
      final code = UseCaseBaseTemplate.generate();

      expect(code, contains("import 'package:dartz/dartz.dart'"));
      expect(code, contains('abstract class UseCase<Type, Params>'));
      expect(code, contains('abstract class UseCaseNoParams<Type>'));
      expect(code, contains('abstract class StreamUseCase<Type, Params>'));
      expect(code, contains('class NoParams'));
    });
  });

  group('Feature Templates', () {
    group('EntityTemplate', () {
      test('generates valid entity class', () {
        final code = EntityTemplate.generate('user');

        expect(code, contains("import 'package:equatable/equatable.dart'"));
        expect(code, contains('class UserEntity extends Equatable'));
        expect(code, contains('required this.id'));
        expect(code, contains('required this.name'));
        expect(code, contains('required this.createdAt'));
        expect(code, contains('this.updatedAt'));
        expect(code, contains('@override'));
        expect(code, contains('List<Object?> get props'));
      });

      test('generates entity with custom properties', () {
        final code = EntityTemplate.generate(
          'product',
          properties: [
            ('String', 'id'),
            ('String', 'title'),
            ('double', 'price'),
            ('int?', 'stock'),
          ],
        );

        expect(code, contains('class ProductEntity'));
        expect(code, contains('final String id'));
        expect(code, contains('final String title'));
        expect(code, contains('final double price'));
        expect(code, contains('final int? stock'));
      });
    });

    group('RepositoryAbstractTemplate', () {
      test('generates valid repository interface', () {
        final code = RepositoryAbstractTemplate.generate('user');

        expect(code, contains("import 'package:dartz/dartz.dart'"));
        expect(code, contains('abstract class UserRepository'));
        expect(code,
            contains('Future<Either<Failure, List<UserEntity>>> getAll()'));
        expect(code,
            contains('Future<Either<Failure, UserEntity>> getById(String id)'));
        expect(code, contains(
            'Future<Either<Failure, UserEntity>> create(UserEntity entity)'));
        expect(code, contains(
            'Future<Either<Failure, UserEntity>> update(UserEntity entity)'));
        expect(
            code, contains('Future<Either<Failure, void>> delete(String id)'));
      });
    });

    group('ModelTemplate', () {
      test('generates Freezed model when useFreezed is true', () {
        final config = FcliConfig(projectName: 'app', useFreezed: true);
        final code = ModelTemplate.generate('user', config);

        expect(code, contains("import 'package:freezed_annotation/freezed_annotation.dart'"));
        expect(code, contains("part 'user_model.freezed.dart'"));
        expect(code, contains("part 'user_model.g.dart'"));
        expect(code, contains('@freezed'));
        expect(code, contains('class UserModel with _\$UserModel'));
        expect(code, contains('factory UserModel.fromJson'));
        expect(code, contains('UserEntity toEntity()'));
      });

      test('generates manual model when useFreezed is false', () {
        final config = FcliConfig(projectName: 'app', useFreezed: false);
        final code = ModelTemplate.generate('user', config);

        expect(code, isNot(contains('@freezed')));
        expect(code, contains('class UserModel'));
        expect(code, contains('factory UserModel.fromJson'));
        expect(code, contains('Map<String, dynamic> toJson()'));
        expect(code, contains('UserEntity toEntity()'));
      });
    });

    group('NotifierTemplate', () {
      test('generates Riverpod notifier', () {
        final config = FcliConfig(
          projectName: 'app',
          stateManagement: StateManagement.riverpod,
        );
        final code = NotifierTemplate.generate('user', config);

        expect(code, contains("import 'package:flutter_riverpod/flutter_riverpod.dart'"));
        expect(code, contains('StateNotifierProvider<UserNotifier, UserState>'));
        expect(code, contains('class UserNotifier extends StateNotifier<UserState>'));
        expect(code, contains('Future<void> loadAll()'));
        expect(code, contains('Future<void> loadById(String id)'));
        expect(code, contains('Future<void> create(UserEntity entity)'));
        expect(code, contains('Future<void> update(UserEntity entity)'));
        expect(code, contains('Future<void> delete(String id)'));
      });

      test('generates Bloc', () {
        final config = FcliConfig(
          projectName: 'app',
          stateManagement: StateManagement.bloc,
        );
        final code = NotifierTemplate.generate('user', config);

        expect(code, contains("import 'package:flutter_bloc/flutter_bloc.dart'"));
        expect(code, contains('class UserBloc extends Bloc<UserEvent, UserState>'));
        expect(code, contains('on<LoadUsers>'));
        expect(code, contains('on<LoadUser>'));
        expect(code, contains('on<CreateUser>'));
        expect(code, contains('on<UpdateUser>'));
        expect(code, contains('on<DeleteUser>'));
      });

      test('generates Provider (ChangeNotifier)', () {
        final config = FcliConfig(
          projectName: 'app',
          stateManagement: StateManagement.provider,
        );
        final code = NotifierTemplate.generate('user', config);

        expect(code, contains("import 'package:flutter/foundation.dart'"));
        expect(code, contains('class UserProvider extends ChangeNotifier'));
        expect(code, contains('List<UserEntity> get users'));
        expect(code, contains('bool get isLoading'));
        expect(code, contains('notifyListeners()'));
      });

      test('generateState creates valid state class', () {
        final code = NotifierTemplate.generateState('user');

        expect(code, contains("import 'package:equatable/equatable.dart'"));
        expect(code, contains('enum UserStatus { initial, loading, loaded, error }'));
        expect(code, contains('class UserState extends Equatable'));
        expect(code, contains('bool get isLoading'));
        expect(code, contains('bool get hasError'));
        expect(code, contains('UserState copyWith'));
      });
    });

    group('ScreenTemplate', () {
      test('generates Riverpod screen', () {
        final config = FcliConfig(
          projectName: 'app',
          stateManagement: StateManagement.riverpod,
        );
        final code = ScreenTemplate.generate('home', 'home', config);

        expect(code, contains("import 'package:flutter_riverpod/flutter_riverpod.dart'"));
        expect(code, contains('class HomeScreen extends ConsumerStatefulWidget'));
        expect(code, contains('ConsumerState<HomeScreen>'));
        expect(code, contains('ref.watch'));
        expect(code, contains('ref.read'));
      });

      test('generates Bloc screen', () {
        final config = FcliConfig(
          projectName: 'app',
          stateManagement: StateManagement.bloc,
        );
        final code = ScreenTemplate.generate('home', 'home', config);

        expect(code, contains("import 'package:flutter_bloc/flutter_bloc.dart'"));
        expect(code, contains('class HomeScreen extends StatefulWidget'));
        expect(code, contains('BlocBuilder<HomeBloc, HomeState>'));
        expect(code, contains("context.read<HomeBloc>()"));
      });

      test('generates Provider screen', () {
        final config = FcliConfig(
          projectName: 'app',
          stateManagement: StateManagement.provider,
        );
        final code = ScreenTemplate.generate('home', 'home', config);

        expect(code, contains("import 'package:provider/provider.dart'"));
        expect(code, contains('class HomeScreen extends StatefulWidget'));
        expect(code, contains('Consumer<HomeProvider>'));
        expect(code, contains("context.read<HomeProvider>()"));
      });

      test('generateSimple creates basic screen', () {
        final code = ScreenTemplate.generateSimple('settings');

        expect(code, contains('class SettingsScreen extends StatelessWidget'));
        expect(code, contains('Settings Screen'));
        expect(code, isNot(contains('riverpod')));
        expect(code, isNot(contains('bloc')));
        expect(code, isNot(contains('provider')));
      });
    });
  });
}
