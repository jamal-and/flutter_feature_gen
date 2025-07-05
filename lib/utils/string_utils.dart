/// String utility functions
extension StringUtils on String {
  /// Converts input like "meal-plan" or "meal plan" into snake_case.
  String toSnakeCase() {
    return trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-]+'), '_') // Replace spaces and hyphens with underscores
        .replaceAll(RegExp(r'_+'), '_') // Merge multiple consecutive underscores
        .replaceAll(RegExp(r'^_+|_+$'), ''); // Remove leading and trailing underscores
  }

  /// Converts snake_case into PascalCase (e.g., "meal_plan" → "MealPlan").
  String toPascalCase() {
    return split('_').map((part) => part[0].toUpperCase() + part.substring(1)).join();
  }

  /// Converts snake_case into camelCase (e.g., "meal_plan" → "mealPlan").
  String toCamelCase() {
    final pascal = toPascalCase();
    return pascal[0].toLowerCase() + pascal.substring(1);
  }
}

/// Converts input like "meal-plan" or "meal plan" into snake_case.
String toSnakeCase(String input) => input.toSnakeCase();

/// Converts snake_case into PascalCase (e.g., "meal_plan" → "MealPlan").
String toPascalCase(String input) => input.toPascalCase();

/// Converts snake_case into camelCase (e.g., "meal_plan" → "mealPlan").
String toCamelCase(String input) => input.toCamelCase();
