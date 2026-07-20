import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/game_service.dart';
import 'services/api_service.dart';
import 'pages/home_page.dart';
import 'pages/play_page.dart';
import 'pages/puzzles_page.dart';
import 'pages/review_page.dart';
import 'pages/courses_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<GameService>(
      create: (_) => ApiService(),
      child: MaterialApp(
        title: '围棋AI老师',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2D5016),
            primary: const Color(0xFF2D5016),
          ),
          useMaterial3: true,
          fontFamily: 'PingFang SC',
        ),
        home: const MainShell(),
        routes: {
          '/play': (_) => const PlayPage(),
          '/puzzles': (_) => const PuzzlesPage(),
          '/review': (_) => const ReviewPage(),
          '/courses': (_) => const CoursesPage(),
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),
    PlayPage(),
    PuzzlesPage(),
    ReviewPage(),
    CoursesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF2D5016).withValues(alpha: 0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF2D5016)),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle, color: Color(0xFF2D5016)),
            label: '对弈',
          ),
          NavigationDestination(
            icon: Icon(Icons.extension_outlined),
            selectedIcon: Icon(Icons.extension, color: Color(0xFF2D5016)),
            label: '做题',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics, color: Color(0xFF2D5016)),
            label: '复盘',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: Color(0xFF2D5016)),
            label: '课程',
          ),
        ],
      ),
    );
  }
}
