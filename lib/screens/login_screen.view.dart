import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_conferencing/resources/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Welcome to Video Conferencing !',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12), // Adjust the spacing
                Text(
                  'Start or Join New Meeting', // Add a description
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white60,
                  ),
                ),
                // const SizedBox(height: 20),
                Image.asset('assets/Telecommuting-rafiki.png'),
                ElevatedButton(
                  onPressed: () {
                    // Implement Google Sign-In logic
                    AuthService().signInWithGoogle(context);
                  },
                  child:
                      Text('Sign In with Google', style: GoogleFonts.poppins()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
