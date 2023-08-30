import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:video_conferencing/screens/login_screen.view.dart';
import 'package:video_conferencing/screens/main_view.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
// Inside your onPressed callback
  void signInWithGoogle(context) async {
    _showLoadingDialog(context);
    final GoogleSignInAccount? googleSignInAccount =
        await GoogleSignIn().signIn();

    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      try {
        final UserCredential authResult =
            await FirebaseAuth.instance.signInWithCredential(credential);
        final User? user = authResult.user;

        if (user != null) {
          Navigator.pop(context);
          // Navigate to the home view
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const MainView()));
        }
      } catch (error) {
        // Handle sign-in error
      }
    }
  }

  signOut(context) async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    // You can navigate to your login screen after signing out
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  Future<void> handleLogout(BuildContext context) async {
    bool confirmLogout = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      if (!context.mounted) return;
      _showLoadingDialog(context);
      await GoogleSignIn().signOut();
      if (!context.mounted) return;
      await AuthService().signOut(context);
      if (!context.mounted) return;
      Navigator.pop(context); // Pop the loading indicator
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _showLoadingDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
