import 'dart:io';

class StateManagementGenerator {
  final String name;
  final String className;
  final String providerName;
  final String? stateMgmt;
  final bool useFreezed;

  StateManagementGenerator({
    required this.name,
    required this.className,
    required this.providerName,
    required this.stateMgmt,
    required this.useFreezed,
  });

  void generate() {
    if (stateMgmt == null) return;

    final path = 'lib/features/$name/presentation/controller';
    Directory(path).createSync(recursive: true);

    switch (stateMgmt) {
      case 'riverpod':
        _generateRiverpod(path);
        break;
      case 'bloc':
        _generateBloc(path);
        break;
      case 'cubit':
        _generateCubit(path);
        break;
      default:
        print('⚠️ Unknown state management: $stateMgmt');
    }

    // if (useFreezed) {
    //   runBuildRunner();
    // }
  }

  void _generateRiverpod(String path) {
    final controllerFile = File('$path/${name}_controller.dart');
    final stateFile = File('$path/${name}_state.dart');

    if (useFreezed) {
      controllerFile.writeAsStringSync('''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '${name}_controller.freezed.dart';
part '${name}_state.dart';

class ${className}Controller extends Notifier<${className}State> {
  @override
  ${className}State build() => const ${className}State();

  Future<void> fetchData() async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(isLoading: false, data: 'Fetched!');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final ${providerName}ControllerProvider = NotifierProvider<${className}Controller, ${className}State>(
  () => ${className}Controller(),
);
''');

      stateFile.writeAsStringSync('''
part of '${name}_controller.dart';

@freezed
abstract class ${className}State with _\$${className}State {
  const factory ${className}State({
    @Default(false) bool isLoading,
    String? data,
    String? error,
  }) = _${className}State;
}
''');
    } else {
      stateFile.writeAsStringSync('''
part of '${name}_controller.dart';

class ${className}State {
  final bool isLoading;
  final String? data;
  final String? error;

  const ${className}State({
    this.isLoading = false,
    this.data,
    this.error,
  });

  ${className}State copyWith({
    bool? isLoading,
    String? data,
    String? error,
  }) {
    return ${className}State(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}
''');

      controllerFile.writeAsStringSync('''
import 'package:flutter_riverpod/flutter_riverpod.dart';

part '${name}_state.dart';

class ${className}Controller extends Notifier<${className}State> {
  @override
  ${className}State build() => const ${className}State();

  Future<void> fetchData() async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(isLoading: false, data: 'Fetched!');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final ${providerName}ControllerProvider = NotifierProvider<${className}Controller, ${className}State>(
  () => ${className}Controller(),
);
''');
    }

    print('✅ Riverpod controller generated');
  }

  void _generateBloc(String path) {
    final blocFile = File('$path/${name}_bloc.dart');
    final eventFile = File('$path/${name}_event.dart');
    final stateFile = File('$path/${name}_state.dart');

    if (useFreezed) {
      blocFile.writeAsStringSync('''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '${name}_bloc.freezed.dart';
part '${name}_event.dart';
part '${name}_state.dart';

class ${className}Bloc extends Bloc<${className}Event, ${className}State> {
  ${className}Bloc() : super(const ${className}State.initial()) {
    on<_FetchData>((event, emit) async {
      emit(const ${className}State.loading());
      try {
        await Future.delayed(const Duration(seconds: 1));
        emit(const ${className}State.loaded('Fetched data'));
      } catch (e) {
        emit(${className}State.error(e.toString()));
      }
    });
  }
}
''');

      eventFile.writeAsStringSync('''
part of '${name}_bloc.dart';

@freezed
class ${className}Event with _\$${className}Event {
  const factory ${className}Event.fetchData() = _FetchData;
}
''');

      stateFile.writeAsStringSync('''
part of '${name}_bloc.dart';

@freezed
class ${className}State with _\$${className}State {
  const factory ${className}State.initial() = _Initial;
  const factory ${className}State.loading() = _Loading;
  const factory ${className}State.loaded(String data) = _Loaded;
  const factory ${className}State.error(String message) = _Error;
}
''');
    } else {
      blocFile.writeAsStringSync('''
import 'package:flutter_bloc/flutter_bloc.dart';
import '${name}_event.dart';
import '${name}_state.dart';

class ${className}Bloc extends Bloc<${className}Event, ${className}State> {
  ${className}Bloc() : super(${className}State.initial()) {
    on<Fetch${className}Event>((event, emit) async {
      emit(${className}State.loading());
      try {
        await Future.delayed(const Duration(seconds: 1));
        emit(${className}State.loaded('Fetched data'));
      } catch (e) {
        emit(${className}State.error(e.toString()));
      }
    });
  }
}
''');

      eventFile.writeAsStringSync('''
abstract class ${className}Event {}

class Fetch${className}Event extends ${className}Event {}
''');

      stateFile.writeAsStringSync('''
class ${className}State {
  final bool isLoading;
  final String? data;
  final String? error;

  const ${className}State({
    required this.isLoading,
    this.data,
    this.error,
  });

  factory ${className}State.initial() => const ${className}State(isLoading: false);
  factory ${className}State.loading() => const ${className}State(isLoading: true);
  factory ${className}State.loaded(String data) => ${className}State(isLoading: false, data: data);
  factory ${className}State.error(String message) => ${className}State(isLoading: false, error: message);
}
''');
    }

    print('✅ BLoC files generated');
  }

  void _generateCubit(String path) {
    final cubitFile = File('$path/${name}_cubit.dart');
    final stateFile = File('$path/${name}_state.dart');

    if (useFreezed) {
      cubitFile.writeAsStringSync('''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '${name}_cubit.freezed.dart';
part '${name}_state.dart';

class ${className}Cubit extends Cubit<${className}State> {
  ${className}Cubit() : super(const ${className}State.initial());

  Future<void> fetchData() async {
    emit(const ${className}State.loading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const ${className}State.loaded('Data loaded successfully'));
    } catch (e) {
      emit(${className}State.error(e.toString()));
    }
  }
}
''');

      stateFile.writeAsStringSync('''
part of '${name}_cubit.dart';

@freezed
class ${className}State with _\$${className}State {
  const factory ${className}State.initial() = _Initial;
  const factory ${className}State.loading() = _Loading;
  const factory ${className}State.loaded(String data) = _Loaded;
  const factory ${className}State.error(String message) = _Error;
}
''');
    } else {
      cubitFile.writeAsStringSync('''
import 'package:flutter_bloc/flutter_bloc.dart';
import '${name}_state.dart';

class ${className}Cubit extends Cubit<${className}State> {
  ${className}Cubit() : super(${className}State.initial());

  Future<void> fetchData() async {
    emit(${className}State.loading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(${className}State.loaded('Data loaded successfully'));
    } catch (e) {
      emit(${className}State.error(e.toString()));
    }
  }
}
''');

      stateFile.writeAsStringSync('''
class ${className}State {
  final bool isLoading;
  final String? data;
  final String? error;

  const ${className}State({
    required this.isLoading,
    this.data,
    this.error,
  });

  factory ${className}State.initial() => const ${className}State(isLoading: false);
  factory ${className}State.loading() => const ${className}State(isLoading: true);
  factory ${className}State.loaded(String data) => ${className}State(isLoading: false, data: data);
  factory ${className}State.error(String message) => ${className}State(isLoading: false, error: message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ${className}State &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          data == other.data &&
          error == other.error;

  @override
  int get hashCode => isLoading.hashCode ^ data.hashCode ^ error.hashCode;
}
''');
    }

    print('✅ Cubit files generated');
  }
}
