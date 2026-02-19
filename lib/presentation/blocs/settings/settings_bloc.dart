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

class ToggleAiSummarization extends SettingsEvent {}

class ToggleBackgroundRefresh extends SettingsEvent {}

class ToggleOpenClawIntegration extends SettingsEvent {}

class UpdateOpenClawUrl extends SettingsEvent {
  final String url;
  UpdateOpenClawUrl(this.url);
  @override
  List<Object?> get props => [url];
}

// States
class SettingsState extends Equatable {
  final bool isDarkMode;
  final bool aiSummarizationEnabled;
  final bool backgroundRefreshEnabled;
  final bool openClawEnabled;
  final String openClawUrl;
  
  const SettingsState({
    this.isDarkMode = false,
    this.aiSummarizationEnabled = false,
    this.backgroundRefreshEnabled = false,
    this.openClawEnabled = false,
    this.openClawUrl = 'http://localhost:18789',
  });
  
  SettingsState copyWith({
    bool? isDarkMode,
    bool? aiSummarizationEnabled,
    bool? backgroundRefreshEnabled,
    bool? openClawEnabled,
    String? openClawUrl,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      aiSummarizationEnabled: aiSummarizationEnabled ?? this.aiSummarizationEnabled,
      backgroundRefreshEnabled: backgroundRefreshEnabled ?? this.backgroundRefreshEnabled,
      openClawEnabled: openClawEnabled ?? this.openClawEnabled,
      openClawUrl: openClawUrl ?? this.openClawUrl,
    );
  }
  
  @override
  List<Object?> get props => [isDarkMode, aiSummarizationEnabled, backgroundRefreshEnabled, openClawEnabled, openClawUrl];
}

// BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<ToggleDarkMode>(_onToggleDarkMode);
    on<ToggleAiSummarization>(_onToggleAiSummarization);
    on<ToggleBackgroundRefresh>(_onToggleBackgroundRefresh);
    on<ToggleOpenClawIntegration>(_onToggleOpenClawIntegration);
    on<UpdateOpenClawUrl>(_onUpdateOpenClawUrl);
  }

  Future<void> _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    final db = DatabaseHelper.instance;
    final isDarkMode = await db.getSetting('darkMode') == 'true';
    final aiSummarization = await db.getSetting('aiSummarization') == 'true';
    final backgroundRefresh = await db.getSetting('backgroundRefresh') == 'true';
    final openClawEnabled = await db.getSetting('openClawEnabled') == 'true';
    final openClawUrl = await db.getSetting('openClawUrl') ?? 'http://localhost:18789';
    
    emit(SettingsState(
      isDarkMode: isDarkMode,
      aiSummarizationEnabled: aiSummarization,
      backgroundRefreshEnabled: backgroundRefresh,
      openClawEnabled: openClawEnabled,
      openClawUrl: openClawUrl,
    ));
  }

  Future<void> _onToggleDarkMode(ToggleDarkMode event, Emitter<SettingsState> emit) async {
    final newValue = !state.isDarkMode;
    await DatabaseHelper.instance.setSetting('darkMode', newValue.toString());
    emit(state.copyWith(isDarkMode: newValue));
  }

  Future<void> _onToggleAiSummarization(ToggleAiSummarization event, Emitter<SettingsState> emit) async {
    final newValue = !state.aiSummarizationEnabled;
    await DatabaseHelper.instance.setSetting('aiSummarization', newValue.toString());
    emit(state.copyWith(aiSummarizationEnabled: newValue));
  }

  Future<void> _onToggleBackgroundRefresh(ToggleBackgroundRefresh event, Emitter<SettingsState> emit) async {
    final newValue = !state.backgroundRefreshEnabled;
    await DatabaseHelper.instance.setSetting('backgroundRefresh', newValue.toString());
    emit(state.copyWith(backgroundRefreshEnabled: newValue));
  }

  Future<void> _onToggleOpenClawIntegration(ToggleOpenClawIntegration event, Emitter<SettingsState> emit) async {
    final newValue = !state.openClawEnabled;
    await DatabaseHelper.instance.setSetting('openClawEnabled', newValue.toString());
    emit(state.copyWith(openClawEnabled: newValue));
  }

  Future<void> _onUpdateOpenClawUrl(UpdateOpenClawUrl event, Emitter<SettingsState> emit) async {
    await DatabaseHelper.instance.setSetting('openClawUrl', event.url);
    emit(state.copyWith(openClawUrl: event.url));
  }
}
