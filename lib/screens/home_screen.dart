import 'package:flutter/material.dart';
import '../services/ubys_service.dart';
import 'grades_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final UbysService service;

  const HomeScreen({super.key, required this.service});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      GradesScreen(service: widget.service),
      const CalendarScreen(),
      ProfileScreen(service: widget.service),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF3AAFA9).withAlpha(30),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grade_outlined),
            selectedIcon: Icon(Icons.grade, color: Color(0xFF3AAFA9)),
            label: 'Notlarım',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: Color(0xFF3AAFA9)),
            label: 'Takvim',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF3AAFA9)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
