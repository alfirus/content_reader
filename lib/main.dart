import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'presentation/blocs/feed/feed_bloc.dart';
import 'presentation/blocs/article/article_bloc.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/blocs/category/category_bloc.dart';
import 'data/datasources/database_helper.dart';
import 'core/api/api_service.dart';
import 'presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  
  // Start API server in background (don't block UI)
  ApiService().start().catchError((e) {
    print('API Server error: $e');
  });
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CategoryBloc()..add(LoadCategories())),
        BlocProvider(create: (_) => FeedBloc()..add(LoadFeeds())),
        BlocProvider(create: (_) => ArticleBloc()..add(LoadArticles())),
        BlocProvider(create: (_) => SettingsBloc()..add(LoadSettings())),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Content Reader',
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(useMaterial3: true),
            darkTheme: ThemeData.dark(useMaterial3: true),
            themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
