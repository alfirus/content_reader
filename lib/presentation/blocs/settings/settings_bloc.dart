import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/datasources/database_helper.dart';

// Events
abstract class SettingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class ToggleDarkMode extends SettingsEvent {}

// States
class SettingsState extends Equatable {
  final bool isDarkMode;
  
  const SettingsState({this.isDarkMode = false});
  
  SettingsState copyWith({bool? isDarkMode}) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
  
  @override
  List<Object?> get props => [isDarkMode];
}

// BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<ToggleDarkMode>(_onToggleDarkMode);
  }

  Future<void> _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    final isDarkMode = await DatabaseHelper.instance.getSetting('darkMode') == 'true';
    emit(SettingsState(isDarkMode: isDarkMode));
  }

  Future<void> _onToggleDarkMode(ToggleDarkMode event, Emitter<SettingsState> emit) async {
    final newValue = !state.isDarkMode;
    await DatabaseHelper.instance.setSetting('darkMode', newValue.toString());
    emit(state.copyWith(isDarkMode: newValue));
  }
}
