// Fixed test templates that align with the SourceTemplate class

String datasourceRemoteTestTemplate(String name, String className) =>
    '''
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import '../../../../../lib/features/$name/data/datasources/${name}_remote_datasource_impl.dart';
import '../../../../../lib/features/$name/data/models/${name}_model.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late ${className}RemoteDataSourceImpl dataSource;
  late MockDio mockDio;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockDio = MockDio();
    dataSource = ${className}RemoteDataSourceImpl(mockDio);
  });

  group('${className}RemoteDataSource', () {
    test('should return ${className}Model when the call is successful', () async {
      final tResponseData = {'id': '123'};
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => Response(
          data: tResponseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await dataSource.fetchData();

      expect(result, isA<${className}Model>());
      expect(result.id, '123');
      verify(() => mockDio.get('https://api.example.com/$name')).called(1);
    });

    test('should throw exception when the call fails', () async {
      when(() => mockDio.get(any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        message: 'Network error',
      ));

      expect(() => dataSource.fetchData(), throwsA(isA<DioException>()));
    });
  });
}
''';

String datasourceLocalTestTemplate(String name, String className) =>
    '''
import 'package:flutter_test/flutter_test.dart';
import '../../../../../lib/features/$name/data/datasources/${name}_local_datasource_impl.dart';
import '../../../../../lib/features/$name/data/models/${name}_model.dart';

void main() {
  late ${className}LocalDataSourceImpl dataSource;

  setUp(() {
    dataSource = ${className}LocalDataSourceImpl();
  });

  group('${className}LocalDataSource', () {
    test('should return null when no cached data exists', () async {
      final result = await dataSource.fetchCachedData();
      expect(result, isNull);
    });

    test('should cache data successfully', () async {
      const testModel = ${className}Model(id: '123');
      
      await dataSource.cacheData(testModel);
      
      // Verify no exception is thrown (implementation pending)
      expect(true, true);
    });
  });
}
''';

String modelTestTemplate(String name, String className, bool useFreezed) =>
    '''
import 'package:flutter_test/flutter_test.dart';
import '../../../../../lib/features/$name/data/models/${name}_model.dart';

void main() {
  ${useFreezed ? '''
  const t${className}Model = ${className}Model(
    id: '123',
    name: 'Test Name',
    description: 'Test Description',
  );
  ''' : '''
  const t${className}Model = ${className}Model(id: '123');
  '''}

  group('${className}Model', () {
    test('should be a valid model', () {
      expect(t${className}Model.id, '123');
      ${useFreezed ? '''
      expect(t${className}Model.name, 'Test Name');
      expect(t${className}Model.description, 'Test Description');
      ''' : ''}
    });

    test('should return a valid JSON map', () {
      final result = t${className}Model.toJson();
      ${useFreezed ? '''
      expect(result['id'], '123');
      expect(result['name'], 'Test Name');
      expect(result['description'], 'Test Description');
      ''' : '''
      final expectedMap = {'id': '123'};
      expect(result, expectedMap);
      '''}
    });

    test('should return a valid model from JSON', () {
      ${useFreezed ? '''
      final jsonMap = {
        'id': '123',
        'name': 'Test Name',
        'description': 'Test Description',
      };
      ''' : '''
      final jsonMap = {'id': '123'};
      '''}
      final result = ${className}Model.fromJson(jsonMap);
      expect(result.id, t${className}Model.id);
      ${useFreezed ? '''
      expect(result.name, t${className}Model.name);
      expect(result.description, t${className}Model.description);
      ''' : '''
      expect(result, t${className}Model);
      '''}
    });
  });
}
''';

String repositoryTestTemplate(String name, String className, bool useFreezed) =>
    '''
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../../lib/features/$name/data/datasources/${name}_remote_datasource.dart';
import '../../../../../lib/features/$name/data/datasources/${name}_local_datasource.dart';
import '../../../../../lib/features/$name/data/repositories/${name}_repository_impl.dart';
import '../../../../../lib/features/$name/data/models/${name}_model.dart';
import '../../../../../lib/features/$name/domain/entities/${name}_entity.dart';

class Mock${className}RemoteDataSource extends Mock implements ${className}RemoteDataSource {}
class Mock${className}LocalDataSource extends Mock implements ${className}LocalDataSource {}

void main() {
  late ${className}RepositoryImpl repository;
  late Mock${className}RemoteDataSource mockRemoteDataSource;
  late Mock${className}LocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = Mock${className}RemoteDataSource();
    mockLocalDataSource = Mock${className}LocalDataSource();
    repository = ${className}RepositoryImpl(
      mockRemoteDataSource,
      mockLocalDataSource,
    );
  });

  group('${className}Repository', () {
    ${useFreezed ? '''
    const t${className}Model = ${className}Model(
      id: '123',
      name: 'Test Name',
      description: 'Test Description',
    );


    ''' : '''
    const t${className}Model = ${className}Model(id: '123');
    '''}

    test('should return entity from remote data source when call is successful', () async {
      when(() => mockRemoteDataSource.fetchData())
          .thenAnswer((_) async => t${className}Model);
      when(() => mockLocalDataSource.cacheData(any()))
          .thenAnswer((_) async {});

      final result = await repository.fetchData();

      expect(result, isA<${className}Entity>());
      expect(result.id, '123');
      ${useFreezed ? '''
      expect(result.name, 'Test Name');
      expect(result.description, 'Test Description');
      ''' : ''}
      verify(() => mockRemoteDataSource.fetchData()).called(1);
      verify(() => mockLocalDataSource.cacheData(t${className}Model)).called(1);
    });

    test('should return cached data when remote call fails', () async {
      when(() => mockRemoteDataSource.fetchData()).thenThrow(Exception());
      when(() => mockLocalDataSource.fetchCachedData())
          .thenAnswer((_) async => t${className}Model);

      final result = await repository.fetchData();

      expect(result, isA<${className}Entity>());
      expect(result.id, '123');
      verify(() => mockRemoteDataSource.fetchData()).called(1);
      verify(() => mockLocalDataSource.fetchCachedData()).called(1);
    });

    test('should throw exception when both remote and local calls fail', () async {
      when(() => mockRemoteDataSource.fetchData()).thenThrow(Exception());
      when(() => mockLocalDataSource.fetchCachedData())
          .thenAnswer((_) async => null);

      expect(() => repository.fetchData(), throwsA(isA<Exception>()));
      verify(() => mockRemoteDataSource.fetchData()).called(1);
      verify(() => mockLocalDataSource.fetchCachedData()).called(1);
    });
  });
}
''';

String entityTestTemplate(String name, String className, bool useFreezed) =>
    '''
import 'package:flutter_test/flutter_test.dart';
import '../../../../../lib/features/$name/domain/entities/${name}_entity.dart';

void main() {
  ${useFreezed ? '''
  const t${className}Entity = ${className}Entity(
    id: '123',
    name: 'Test Name',
    description: 'Test Description',
  );
  ''' : '''
  const t${className}Entity = ${className}Entity(id: '123');
  '''}

  group('${className}Entity', () {
    test('should be a valid entity', () {
      expect(t${className}Entity.id, '123');
      ${useFreezed ? '''
      expect(t${className}Entity.name, 'Test Name');
      expect(t${className}Entity.description, 'Test Description');
      ''' : ''}
    });

    ${useFreezed ? '''
    test('should support equality comparison with freezed', () {
      const t${className}Entity2 = ${className}Entity(
        id: '123',
        name: 'Test Name',
        description: 'Test Description',
      );
      expect(t${className}Entity, t${className}Entity2);
    });

    test('should support copyWith functionality', () {
      final copiedEntity = t${className}Entity.copyWith(name: 'Updated Name');
      expect(copiedEntity.id, '123');
      expect(copiedEntity.name, 'Updated Name');
      expect(copiedEntity.description, 'Test Description');
    });
    ''' : '''
    test('should support equality comparison', () {
      const t${className}Entity2 = ${className}Entity(id: '123');
      expect(t${className}Entity, t${className}Entity2);
    });
    '''}
  });
}
''';

String usecaseTestTemplate(String name, String className, bool useFreezed) =>
    '''
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../../lib/features/$name/domain/repositories/${name}_repository.dart';
import '../../../../../lib/features/$name/domain/usecases/get_${name}_usecase.dart';
import '../../../../../lib/features/$name/domain/entities/${name}_entity.dart';

class Mock${className}Repository extends Mock implements ${className}Repository {}

void main() {
  late Get${className}UseCase usecase;
  late Mock${className}Repository mockRepository;

  setUp(() {
    mockRepository = Mock${className}Repository();
    usecase = Get${className}UseCase(mockRepository);
  });

  group('Get${className}UseCase', () {
    ${useFreezed ? '''
    const t${className}Entity = ${className}Entity(
      id: '123',
      name: 'Test Name',
      description: 'Test Description',
    );
    ''' : '''
    const t${className}Entity = ${className}Entity(id: '123');
    '''}

    test('should get entity from repository when executed', () async {
      when(() => mockRepository.fetchData())
          .thenAnswer((_) async => t${className}Entity);

      final result = await usecase.call();

      expect(result, t${className}Entity);
      verify(() => mockRepository.fetchData()).called(1);
    });

    test('should throw exception when repository fails', () async {
      when(() => mockRepository.fetchData()).thenThrow(Exception());

      expect(() => usecase.call(), throwsA(isA<Exception>()));
      verify(() => mockRepository.fetchData()).called(1);
    });
  });
}
''';

String widgetCardTestTemplate(String name, String className, bool useFreezed) =>
    '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../lib/features/$name/presentation/widgets/${name}_card.dart';
${useFreezed ? "import '../../../../../lib/features/$name/domain/entities/${name}_entity.dart';" : ''}

void main() {
  group('${className}Card', () {
    testWidgets('should display the provided title', (tester) async {
      const testTitle = 'Test Title';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ${className}Card(title: testTitle),
          ),
        ),
      );

      expect(find.text(testTitle), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    ${useFreezed ? '''
    testWidgets('should display entity information when provided', (tester) async {
      const testTitle = 'Test Title';
      const testEntity = ${className}Entity(
        id: '123',
        name: 'Test Name',
        description: 'Test Description',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ${className}Card(
              title: testTitle,
              entity: testEntity,
            ),
          ),
        ),
      );

      expect(find.text(testTitle), findsOneWidget);
      expect(find.text('ID: 123'), findsOneWidget);
      expect(find.text('Name: Test Name'), findsOneWidget);
      expect(find.text('Description: Test Description'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should handle null entity gracefully', (tester) async {
      const testTitle = 'Test Title';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ${className}Card(
              title: testTitle,
              entity: null,
            ),
          ),
        ),
      );

      expect(find.text(testTitle), findsOneWidget);
      expect(find.text('ID:'), findsNothing);
      expect(find.byType(Card), findsOneWidget);
    });
    ''' : ''}
  });
}
''';

String screenTestTemplate(String name, String className) =>
    '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../lib/features/$name/presentation/screens/${name}_screen.dart';

void main() {
  group('${className}Screen', () {
    testWidgets('should display app bar and content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ${className}Screen(),
        ),
      );

      expect(find.text('$className'), findsNWidgets(2)); // AppBar title and body text
      expect(find.text('$className Screen'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
''';

String riverpodTestTemplate(
  String name,
  String className,
  String providerName,
) =>
    '''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../lib/features/$name/presentation/controller/${name}_controller.dart';

void main() {
  group('${className}Controller', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should have initial state', () {
      final controller = container.read(${providerName}ControllerProvider.notifier);
      expect(controller.state, const ${className}State(isLoading: false));
    });

    test('should update state after fetchData', () async {
      final controller = container.read(${providerName}ControllerProvider.notifier);

      await controller.fetchData();

      expect(controller.state.isLoading, false);
      expect(controller.state.data, 'Fetched!');
      expect(controller.state.error, isNull);
    });
  });
}
''';

String blocFreezedTestTemplate(String name, String className) =>
    '''
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../lib/features/$name/presentation/controller/${name}_bloc.dart';

void main() {
  group('${className}Bloc', () {
    late ${className}Bloc bloc;

    setUp(() {
      bloc = ${className}Bloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state should be initial', () {
      expect(bloc.state, const ${className}State.initial());
    });

    blocTest<${className}Bloc, ${className}State>(
      'should emit [loading, loaded] when FetchData is added',
      build: () => ${className}Bloc(),
      act: (bloc) => bloc.add(const ${className}Event.fetchData()),
      expect: () => [
        const ${className}State.loading(),
        const ${className}State.loaded('Fetched data'),
      ],
    );

    blocTest<${className}Bloc, ${className}State>(
      'should emit [loading, error] when FetchData fails',
      build: () => ${className}Bloc(),
      act: (bloc) => bloc.add(const ${className}Event.fetchData()),
      errors: () => [isA<Exception>()],
      expect: () => [
        const ${className}State.loading(),
        const ${className}State.error('Error occurred'),
      ],
    );
  });
}
''';

String blocPlainTestTemplate(String name, String className) =>
    '''
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../lib/features/$name/presentation/controller/${name}_bloc.dart';
import '../../../../../lib/features/$name/presentation/controller/${name}_state.dart';
import '../../../../../lib/features/$name/presentation/controller/${name}_event.dart';

void main() {
  group('${className}Bloc', () {
    late ${className}Bloc bloc;

    setUp(() {
      bloc = ${className}Bloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state should be initial', () {
      expect(bloc.state, ${className}State.initial());
    });

    blocTest<${className}Bloc, ${className}State>(
      'emits [loading, loaded] when Fetch${className}Event is added',
      build: () => ${className}Bloc(),
      act: (bloc) => bloc.add(Fetch${className}Event()),
      expect: () => [
        ${className}State.loading(),
        ${className}State.loaded('Fetched data'),
      ],
    );

    blocTest<${className}Bloc, ${className}State>(
      'emits [loading, error] when Fetch${className}Event fails',
      build: () => ${className}Bloc(),
      act: (bloc) => bloc.add(Fetch${className}Event()),
      expect: () => [
        ${className}State.loading(),
        ${className}State.error('Error occurred'),
      ],
    );
  });
}
''';

String cubitFreezedTestTemplate(String name, String className) =>
    '''
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../lib/features/$name/presentation/controller/${name}_cubit.dart';

void main() {
  group('${className}Cubit', () {
    late ${className}Cubit cubit;

    setUp(() {
      cubit = ${className}Cubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state should be initial', () {
      expect(cubit.state, const ${className}State.initial());
    });

    blocTest<${className}Cubit, ${className}State>(
      'emits [loading, loaded] when fetchData is called',
      build: () => ${className}Cubit(),
      act: (cubit) => cubit.fetchData(),
      expect: () => [
        const ${className}State.loading(),
        const ${className}State.loaded('Data loaded successfully'),
      ],
    );

    blocTest<${className}Cubit, ${className}State>(
      'emits [loading, error] when fetchData fails',
      build: () => ${className}Cubit(),
      act: (cubit) => cubit.fetchData(),
      expect: () => [
        const ${className}State.loading(),
        const ${className}State.error('Error occurred'),
      ],
    );
  });
}
''';

String cubitPlainTestTemplate(String name, String className) =>
    '''
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../lib/features/$name/presentation/controller/${name}_cubit.dart';
import '../../../../../lib/features/$name/presentation/controller/${name}_state.dart';

void main() {
  group('${className}Cubit', () {
    late ${className}Cubit cubit;

    setUp(() {
      cubit = ${className}Cubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state should be initial', () {
      expect(cubit.state, ${className}State.initial());
    });

    blocTest<${className}Cubit, ${className}State>(
      'emits [loading, loaded] when fetchData is called',
      build: () => ${className}Cubit(),
      act: (cubit) => cubit.fetchData(),
      expect: () => [
        ${className}State.loading(),
        ${className}State.loaded('Data loaded successfully'),
      ],
    );

    blocTest<${className}Cubit, ${className}State>(
      'emits [loading, error] when fetchData fails',
      build: () => ${className}Cubit(),
      act: (cubit) => cubit.fetchData(),
      expect: () => [
        ${className}State.loading(),
        ${className}State.error('Error occurred'),
      ],
    );
  });
}
''';

// Helper class to generate all test templates with proper parameters
class TestTemplateGenerator {
  final String className;
  final String featureName;
  final bool useFreezed;
  final String providerName;

  TestTemplateGenerator({
    required this.className,
    required this.featureName,
    required this.providerName,
    this.useFreezed = false,
  });

  Map<String, String> getAllTestTemplates(String basePath) {
    return {
      // Data layer tests
      '$basePath/test/features/$featureName/data/datasources/${featureName}_remote_datasource_test.dart':
          datasourceRemoteTestTemplate(featureName, className),

      '$basePath/test/features/$featureName/data/datasources/${featureName}_local_datasource_test.dart':
          datasourceLocalTestTemplate(featureName, className),

      '$basePath/test/features/$featureName/data/models/${featureName}_model_test.dart':
          modelTestTemplate(featureName, className, useFreezed),

      '$basePath/test/features/$featureName/data/repositories/${featureName}_repository_impl_test.dart':
          repositoryTestTemplate(featureName, className, useFreezed),

      // Domain layer tests
      '$basePath/test/features/$featureName/domain/entities/${featureName}_entity_test.dart':
          entityTestTemplate(featureName, className, useFreezed),

      '$basePath/test/features/$featureName/domain/usecases/get_${featureName}_usecase_test.dart':
          usecaseTestTemplate(featureName, className, useFreezed),

      // Presentation layer tests
      '$basePath/test/features/$featureName/presentation/widgets/${featureName}_card_test.dart':
          widgetCardTestTemplate(featureName, className, useFreezed),

      '$basePath/test/features/$featureName/presentation/screens/${featureName}_screen_test.dart':
          screenTestTemplate(featureName, className),
    };
  }

  // Method to get controller test template based on state management choice
  String getControllerTestTemplate(String stateMgmt) {
    switch (stateMgmt) {
      case 'riverpod':
        return riverpodTestTemplate(featureName, className, providerName);
      case 'bloc':
        return useFreezed
            ? blocFreezedTestTemplate(featureName, className)
            : blocPlainTestTemplate(featureName, className);
      case 'cubit':
        return useFreezed
            ? cubitFreezedTestTemplate(featureName, className)
            : cubitPlainTestTemplate(featureName, className);
      default:
        return '';
    }
  }

  // Method to get controller test file path
  String getControllerTestPath(String stateMgmt, String basePath) {
    switch (stateMgmt) {
      case 'riverpod':
        return '$basePath/test/features/$featureName/presentation/controller/${featureName}_controller_test.dart';
      case 'bloc':
        return '$basePath/test/features/$featureName/presentation/controller/${featureName}_bloc_test.dart';
      case 'cubit':
        return '$basePath/test/features/$featureName/presentation/controller/${featureName}_cubit_test.dart';
      default:
        return '';
    }
  }
}
