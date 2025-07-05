// This is a minimal usage example for flutter_feature_gen
// Note: This is a CLI tool. You normally run it via terminal, not inside Dart code.
import 'dart:io';

void main() async {

  // Equivalent to: `dart run ../lib/flutter_feature_gen.dart meal-plan`
  //
  // ✅ In a real project, use: `flutter_feature_gen <feature_name> [state_management] [options]`
  // Example: flutter_feature_gen meal-plan --riverpod --freezed --test
  final result = await Process.run('dart', [
    'run',
    '../lib/flutter_feature_gen.dart',
    'meal-plan',
  ], workingDirectory: './example');

  if (result.exitCode == 0) {
    print('✅ Feature generated successfully!');
  } else {
    print('❌ Failed to generate feature:\n${result.stderr}');
  }
}
