// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube/features/home/main_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/auth_provider.dart';
import 'splash_screen.dart';  // Import the new splash screen

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isSplashScreenVisible = true;

  @override
  void initState() {
    super.initState();
    // Delay to show the splash screen for a certain time
    Future.delayed(const Duration(seconds: 4), () {
      setState(() {
        _isSplashScreenVisible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    if (_isSplashScreenVisible) {
      return const MaterialApp(
        home: SplashScreen(), // Show splash screen first
      );
    }

    return MaterialApp(
      title: 'YouTube Clone',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: authState.when(
        data: (user) => user == null ? const LoginPage() : const MainPage(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}
