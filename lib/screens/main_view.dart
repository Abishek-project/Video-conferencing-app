import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:video_conferencing/screens/home_view.dart';
import 'package:video_conferencing/screens/meet_history.dart';
import 'package:video_conferencing/screens/profile_view.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int _currentIndex = 0;

  final List<Widget> _sections = [
    HomeView(),
    const MeetHistory(),
    const ProfileView()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _sections[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        color: const Color.fromRGBO(29, 29, 29, 1),
        items: const <Widget>[
          Icon(Icons.videocam, size: 30),
          Icon(Icons.history, size: 30),
          Icon(Icons.person, size: 30),
        ],
      ),
    );
  }
}
