import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tidytask_new/providers/theme_provider.dart';
import 'package:tidytask_new/screens/splash_screen.dart'; // pastikan ini benar

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'TidyTask',
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(), // splash sebelum masuk home
          );
        },
      ),
    );
  }
}
