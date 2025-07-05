import 'package:flutter_feature_gen/utils/string_utils.dart';
import 'package:test/test.dart';

void main() {
  test('toSnakeCase', () {
    expect(toSnakeCase('App Name'), 'app_name');
  });
  test('toPascalCase', () {
    expect(toPascalCase('app_name'), 'AppName');
  });
  test('toCamelCase', () {
    expect(toCamelCase('app_name'), 'appName');
  });

  test('toSnakeCase edge cases', () {
    expect(toSnakeCase('App Name'), 'app_name');
    expect(toSnakeCase('app name'), 'app_name');
    expect(toSnakeCase('App -Name'), 'app_name');
    expect(toSnakeCase('App--Name'), 'app_name');
    expect(toSnakeCase('App   Name'), 'app_name');
    expect(toSnakeCase('app_name'), 'app_name'); // already snake_case
    expect(toSnakeCase('app-Name'), 'app_name');
    expect(toSnakeCase('APP NAME'), 'app_name');
    expect(toSnakeCase('appName'), 'appname'); // camelCase is not processed as a snake_case
    expect(toSnakeCase('App123 Name456'), 'app123_name456');
    expect(toSnakeCase('   App Name   '), 'app_name');
    expect(toSnakeCase('--App--Name--'), 'app_name');
    expect(toSnakeCase('app-name with spaces'), 'app_name_with_spaces');
    expect(toSnakeCase('APP--NAME--EXTRA'), 'app_name_extra');
  });
}
