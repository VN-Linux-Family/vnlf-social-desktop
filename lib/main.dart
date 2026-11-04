import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/gallery'),
    GoRoute(
      path: '/gallery',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('Thư viện giao diện'))),
    ),
  ],
);

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VNLF Social',
      theme: ThemeData(fontFamily: 'BeVietnamPro'),
      routerConfig: _router,
    );
  }
}
