import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:video_conferencing/resources/auth_service.dart';
import 'package:video_conferencing/screens/login_screen.view.dart';
import 'package:video_conferencing/screens/main_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'My App',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color.fromRGBO(36, 36, 36, 1),
        ), // Set dark theme
        home: StreamBuilder<User?>(
          stream: AuthService().authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              final user = snapshot.data;

              if (user == null) {
                // User is not authenticated, show login screen
                return LoginScreen();
              } else {
                // User is authenticated, show home screen
                return MainView();
              }
            } else {
              // Handle loading state
              return CircularProgressIndicator();
            }
          },
        )
        // Set the initial screen to the login screen
        );
  }
}
