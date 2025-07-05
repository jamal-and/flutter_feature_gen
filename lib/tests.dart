// test_generator.dart

import 'package:flutter_feature_gen/utils/io_helper.dart';
import 'package:flutter_feature_gen/utils/test_templates.dart';

class TestGenerator {
  final String name;
  final String className;
  final String stateMgmt;
  final bool useFreezed;
  late final TestTemplateGenerator _templateGenerator;
  final String providerName;

  TestGenerator({
    required this.name,
    required this.className,
    required this.stateMgmt,
    required this.useFreezed,
    required this.providerName,
  }) {
    _templateGenerator = TestTemplateGenerator(
      className: className,
      featureName: name,
      useFreezed: useFreezed,
      providerName: providerName,
    );
  }

  void generate() {
    print('🧪 Generating test files...');
    _generateCoreTests();
    if (stateMgmt.isNotEmpty) _generateControllerTests();
    print('✅ Test files generated successfully!');
  }

  void _generateCoreTests() {
    // Get all core test templates from the generator
    final testTemplates = _templateGenerator.getAllTestTemplates('');

    // Generate each test file
    testTemplates.forEach((filePath, content) {
      // Extract the relative path for the writeTest function
      final relativePath = filePath.replaceFirst('test/features/', '');
      writeTest(relativePath, content);
    });
  }

  void _generateControllerTests() {
    switch (stateMgmt) {
      case 'riverpod':
        writeTest(
          '$name/presentation/controller/${name}_controller_test.dart',
          riverpodTestTemplate(name, className, providerName),
        );
        break;
      case 'bloc':
        final template = useFreezed
            ? blocFreezedTestTemplate(name, className)
            : blocPlainTestTemplate(name, className);
        writeTest(
          '$name/presentation/controller/${name}_bloc_test.dart',
          template,
        );
        break;
      case 'cubit':
        final template = useFreezed
            ? cubitFreezedTestTemplate(name, className)
            : cubitPlainTestTemplate(name, className);
        writeTest(
          '$name/presentation/controller/${name}_cubit_test.dart',
          template,
        );
        break;
    }
  }

  // Alternative approach: More explicit method calls for better control
  void generateExplicit() {
    print('🧪 Generating test files...');
    _generateDatasourceTests();
    _generateModelTests();
    _generateRepositoryTests();
    _generateEntityTests();
    _generateUsecaseTests();
    _generateWidgetTests();
    if (stateMgmt.isNotEmpty) _generateControllerTests();
    print('✅ Test files generated successfully!');
  }

  void _generateDatasourceTests() {
    writeTest(
      '$name/data/datasources/${name}_remote_datasource_test.dart',
      datasourceRemoteTestTemplate(name, className),
    );
    writeTest(
      '$name/data/datasources/${name}_local_datasource_test.dart',
      datasourceLocalTestTemplate(name, className),
    );
  }

  void _generateModelTests() {
    writeTest(
      '$name/data/models/${name}_model_test.dart',
      modelTestTemplate(name, className, useFreezed),
    );
  }

  void _generateRepositoryTests() {
    writeTest(
      '$name/data/repositories/${name}_repository_impl_test.dart',
      repositoryTestTemplate(name, className, useFreezed),
    );
  }

  void _generateEntityTests() {
    writeTest(
      '$name/domain/entities/${name}_entity_test.dart',
      entityTestTemplate(name, className, useFreezed),
    );
  }

  void _generateUsecaseTests() {
    writeTest(
      '$name/domain/usecases/get_${name}_usecase_test.dart',
      usecaseTestTemplate(name, className, useFreezed),
    );
  }

  void _generateWidgetTests() {
    writeTest(
      '$name/presentation/widgets/${name}_card_test.dart',
      widgetCardTestTemplate(name, className, useFreezed),
    );
    writeTest(
      '$name/presentation/screens/${name}_screen_test.dart',
      screenTestTemplate(name, className),
    );
  }
}
