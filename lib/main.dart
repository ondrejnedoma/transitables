// import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'screens/home_screen.dart';
import 'services/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  await store.load();
  runApp(const TransitablesApp());
}

class TransitablesApp extends StatelessWidget {
  const TransitablesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // 1. Fallback Light ColorScheme if system dynamic colors aren't available
        final fallbackLightScheme = ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        );

        // 2. Fallback Dark ColorScheme if system dynamic colors aren't available
        final fallbackDarkScheme = ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        );

        return MaterialApp(
          title: 'Material 3 Dynamic Theme',
          debugShowCheckedModeBanner: false,

          // Automatically follow system light/dark brightness settings
          themeMode: ThemeMode.system,

          // Light Theme configuration
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightDynamic ?? fallbackLightScheme,
          ),

          // Dark Theme configuration
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkDynamic ?? fallbackDarkScheme,
          ),

          home: const HomeScreen(),
        );
      },
    );
  }
}
