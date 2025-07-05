import 'dart:io';

import 'package:flutter_feature_gen/options.dart';
import 'package:flutter_feature_gen/stmngt.dart';
import 'package:flutter_feature_gen/tests.dart';
import 'package:flutter_feature_gen/utils/io_helper.dart';
import 'package:flutter_feature_gen/utils/source_template.dart';
import 'package:flutter_feature_gen/utils/string_utils.dart';

/// Entry point of the CLI tool.
/// Accepts a single argument: the feature name.
/// Example: `flutter_feature_gen meal-plan`
void main(List<String> args) {
  final options = parseArguments(args);
  final generator = FeatureGenerator(options);
  generator.generate();
}

/// Prints usage information and exits with error code

/// Main feature generator class that orchestrates the generation process
class FeatureGenerator {
  final FeatureOptions options;
  late final String featureName;
  late final String className;
  late final String providerName;
  late final String basePath;

  final bool _log = false;
  FeatureGenerator(this.options) {
    featureName = toSnakeCase(options.featureName!);
    className = toPascalCase(featureName);
    providerName = toCamelCase(featureName);
    basePath = 'lib/features/$featureName';
  }

  /// Generates the complete feature structure
  void generate() {
    _printConfiguration();
    _createFolderStructure();
    _generateFiles();
    _generateStateManagement();
    _generateTests();
    _printSuccess();
    if (options.useFreezed) {
      runBuildRunner();
    }
  }

  /// Prints the current configuration
  void _printConfiguration() {
    print('  🧠 State Management: ${options.stateMgmt ?? "none"}');
    print('  ❄️  Use Freezed: ${options.useFreezed}');
    print('  🧪 Generate Tests: ${options.generateTests}\n');
  }

  /// Creates the folder structure for the feature
  void _createFolderStructure() {
    final folders = _getFolderStructure();

    for (final folder in folders) {
      Directory(folder).createSync(recursive: true);
      if (_log) print('📁 Created $folder');
    }
    print('✅ Folder structure created successfully!');
  }

  /// Returns the list of folders to create
  List<String> _getFolderStructure() {
    return [
      '$basePath/data/datasources',
      '$basePath/data/models',
      '$basePath/data/repositories',
      '$basePath/domain/entities',
      '$basePath/domain/repositories',
      '$basePath/domain/usecases',
      '$basePath/presentation/screens',
      '$basePath/presentation/widgets',
      '$basePath/presentation/controller',
    ];
  }

  /// Generates all the feature files
  void _generateFiles() {
    final fileTemplates = _getFileTemplates();

    for (final entry in fileTemplates.entries) {
      File(entry.key).writeAsStringSync(entry.value);
      if (_log) print('✅ Created ${entry.key}');
    }
    print('✅ Feature files generated successfully!');
  }

  /// Returns a map of file paths to their content templates
  Map<String, String> _getFileTemplates() {
    final sourceTemplate = SourceTemplate(
      className: className,
      featureName: featureName,
      useFreezed: options.useFreezed,
    );
    return sourceTemplate.getFileTemplates(basePath);
  }

  /// Generates state management files if specified
  void _generateStateManagement() {
    if (options.stateMgmt?.isNotEmpty == true) {
      StateManagementGenerator(
        name: featureName,
        className: className,
        providerName: providerName,
        stateMgmt: options.stateMgmt,
        useFreezed: options.useFreezed,
      ).generate();
    }
  }

  /// Generates test files if specified
  void _generateTests() {
    if (options.generateTests) {
      TestGenerator(
        className: className,
        name: featureName,
        stateMgmt: options.stateMgmt ?? '',
        useFreezed: options.useFreezed,
      ).generate();
    }
  }

  /// Prints success message
  void _printSuccess() {
    print('\n🚀 Feature "$featureName" generated successfully!');
  }

  // Template methods are now handled by SourceTemplate class
}
