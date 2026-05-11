import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/providers/audio_provider.dart';
import 'core/providers/theme_provider.dart';
import 'screens/ruqyah_home_page.dart';

void main() {
  runApp(const RuqyahSolutionApp());
}

class RuqyahSolutionApp extends StatelessWidget {
  const RuqyahSolutionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Ruqyah Solution',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF16A34A),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF16A34A),
                brightness: Brightness.dark,
              ),
            ),
            themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
            home: const RuqyahHomePage(),
          );
        },
      ),
    );
  }
}
