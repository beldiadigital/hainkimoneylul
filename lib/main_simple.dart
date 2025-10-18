import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'additional_classes.dart';

// Basit main - Firebase/AdMob olmadan
void main() {
  runApp(const KimHainApp());
}

class KimHainApp extends StatelessWidget {
  const KimHainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Kim Hain?',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.purple,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.purple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: themeProvider.themeMode,
            home: const KimHainHome(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
