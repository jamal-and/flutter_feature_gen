import 'package:flutter_feature_gen/flutter_feature_gen.dart';
import 'package:flutter_feature_gen/options.dart';

/// Entry point of the CLI tool.
/// Accepts a single argument: the feature name.
/// Example: `flutter_feature_gen meal-plan`
void main(List<String> args) async {
  final options = parseArguments(args);
  await PackageManager.ensurePackages(options);
  final generator = FeatureGenerator(options);
  generator.generate();
}

/// Prints usage information and exits with error code

/// Main feature generator class that orchestrates the generation process
