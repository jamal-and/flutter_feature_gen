import 'dart:io';

class FeatureOptions {
  String? stateMgmt; // 'riverpod', 'bloc', or 'cubit'
  bool useFreezed = false;
  bool generateTests = false;
  String? featureName;
}

FeatureOptions parseArguments(List<String> args) {
  final options = FeatureOptions();
  final featureParts = <String>[];

  for (final arg in args) {
    switch (arg) {
      case '--riverpod':
      case '--bloc':
      case '--cubit':
        if (options.stateMgmt != null) {
          _exitWithError(
            'Multiple state management flags provided: '
            "'--${options.stateMgmt}' and '$arg'",
          );
        }
        options.stateMgmt = arg.replaceFirst('--', '');
        break;
      case '--freezed':
        options.useFreezed = true;
        break;
      case '--test':
        options.generateTests = true;
        break;
      default:
        if (arg.startsWith('--')) {
          _exitWithError("Unknown flag: '$arg'");
        } else if (arg.startsWith('-')) {
          _exitWithError(
            "Invalid flag: '$arg'\n"
            '💡 Did you mean one of these?\n'
            '   State management: --riverpod, --bloc, --cubit\n'
            '   Feature flags: --freezed, --test',
          );
        } else {
          featureParts.add(arg);
        }
    }
  }

  if (featureParts.isEmpty) {
    _exitWithError(
      'Missing feature name.\nUsage: flutter_feature_gen feature_name [flags]',
    );
  }

  options.featureName = featureParts.join('_');
  return options;
}

Never _exitWithError(String message) {
  print('❌ $message');
  exit(1);
}

class PackageManager {
  static const Map<String, PackageInfo> _packages = {
    'riverpod': PackageInfo(
      dependencies: ['flutter_riverpod'],
      devDependencies: [],
    ),
    'bloc': PackageInfo(dependencies: ['flutter_bloc'], devDependencies: []),
    'cubit': PackageInfo(
      dependencies: ['flutter_bloc'], // Cubit is part of flutter_bloc
      devDependencies: [],
    ),
    'freezed': PackageInfo(
      dependencies: ['freezed_annotation', 'json_annotation'],
      devDependencies: ['freezed', 'build_runner', 'json_serializable'],
    ),
    'test': PackageInfo(
      dependencies: [],
      devDependencies: ['mocktail', 'build_runner'],
    ),
  };

  static Future<void> ensurePackages(FeatureOptions options) async {
    print('🔍 Checking required packages...');

    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      _exitWithError('pubspec.yaml not found. Are you in a Flutter project?');
    }

    final requiredPackages = _getRequiredPackages(options);
    final pubspecContent = await pubspecFile.readAsString();

    if (_arePackagesPresent(pubspecContent, requiredPackages)) {
      print('✅ All required packages are already present');
      return;
    }

    print('📦 Adding missing packages...');
    await _addPackages(requiredPackages);

    print('🔄 Running flutter pub get...');
    await _runPubGet();

    print('✅ Packages installed successfully');
  }

  static PackageRequirements _getRequiredPackages(FeatureOptions options) {
    final deps = <String>['dio'];
    final devDeps = <String>[];

    // Add state management packages
    if (options.stateMgmt != null) {
      final statePackage = _packages[options.stateMgmt!]!;
      deps.addAll(statePackage.dependencies);
      if (options.stateMgmt == 'bloc' && options.generateTests) {
        // Add bloc_test only for bloc state management
        devDeps.add('bloc_test');
      }
      devDeps.addAll(statePackage.devDependencies);
    }

    // Add freezed packages
    if (options.useFreezed) {
      final freezedPackage = _packages['freezed']!;
      deps.addAll(freezedPackage.dependencies);
      devDeps.addAll(freezedPackage.devDependencies);
    }

    // Add test packages
    if (options.generateTests) {
      final testPackage = _packages['test']!;
      deps.addAll(testPackage.dependencies);
      devDeps.addAll(testPackage.devDependencies);
    }

    return PackageRequirements(
      dependencies: deps.toSet().toList(),
      devDependencies: devDeps.toSet().toList(),
    );
  }

  static bool _arePackagesPresent(
    String pubspecContent,
    PackageRequirements required,
  ) {
    // Simple check - in a real implementation, you'd want to parse YAML properly
    for (final dep in required.dependencies) {
      if (!pubspecContent.contains('$dep:')) return false;
    }
    for (final devDep in required.devDependencies) {
      if (!pubspecContent.contains('$devDep:')) return false;
    }
    return true;
  }

  static Future<void> _addPackages(PackageRequirements packages) async {
    final commands = <String>[];

    if (packages.dependencies.isNotEmpty) {
      commands.add('flutter pub add ${packages.dependencies.join(' ')}');
    }

    if (packages.devDependencies.isNotEmpty) {
      commands.add(
        'flutter pub add dev:${packages.devDependencies.join(' dev:')}',
      );
    }

    for (final command in commands) {
      print('Running: $command');
      final result = await Process.run(
        'flutter',
        command.split(' ').skip(1).toList(),
      );

      if (result.exitCode != 0) {
        _exitWithError('Failed to add packages: ${result.stderr}');
      }
    }
  }

  static Future<void> _runPubGet() async {
    final result = await Process.run('flutter', ['pub', 'get']);

    if (result.exitCode != 0) {
      _exitWithError('Failed to run pub get: ${result.stderr}');
    }
  }
}

class PackageInfo {
  final List<String> dependencies;
  final List<String> devDependencies;

  const PackageInfo({
    required this.dependencies,
    required this.devDependencies,
  });
}

class PackageRequirements {
  final List<String> dependencies;
  final List<String> devDependencies;

  const PackageRequirements({
    required this.dependencies,
    required this.devDependencies,
  });
}
