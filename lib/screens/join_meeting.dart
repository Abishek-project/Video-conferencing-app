import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_conferencing/screens/meet.dart';

class JoinMeeting extends StatefulWidget {
  const JoinMeeting({super.key});

  @override
  State<JoinMeeting> createState() => _JoinMeetingState();
}

class _JoinMeetingState extends State<JoinMeeting> {
  final TextEditingController _channelController = TextEditingController();
  User? user;
  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  Future<bool> checkIfChannelExists(String channelName) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('channels')
        .doc(channelName)
        .get();
    return snapshot.exists;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Join Meeting',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(70), // Adjust the radius as needed
                child: Image.asset(
                  "assets/groupCall.jpg",
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Enter meeting code below',
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _channelController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter Channel Name',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      // fontWeight: FontWeight.w500,
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final channelName = _channelController.text;

                  if (channelName.isNotEmpty) {
                    bool channelExists =
                        await checkIfChannelExists(channelName);

                    if (channelExists) {
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Meet(
                            channelName: channelName,
                            userName: user!.displayName.toString(),
                          ),
                        ),
                      );
                    } else {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid channel name'),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a channel name'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Join'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
