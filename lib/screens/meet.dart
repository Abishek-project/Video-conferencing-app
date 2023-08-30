import 'dart:async';

import 'package:agora_uikit/agora_uikit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

// ignore: must_be_immutable
class Meet extends StatefulWidget {
  Meet({Key? key, required this.channelName, required this.userName})
      : super(key: key);
  String channelName;
  String userName;
  @override
  State<Meet> createState() => _MeetState();
}

class _MeetState extends State<Meet> {
  late AgoraClient client;

  User? user;
  late Timer _timer;
  int _seconds = 0;
  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    client = AgoraClient(
      agoraConnectionData: AgoraConnectionData(
          appId: "14391331f83641d9a063013819ab5b54",
          channelName: widget.channelName,
          username: widget.userName),
    );
    initAgora();
    startTimer();
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        setState(() {
          _seconds = _seconds + 1;
        });

        if (_seconds >= 30 * 60) {
          timer.cancel(); // Stop the timer
          showExpiredMessage(); // Show expired message
        }
      },
    );
  }

  String getFormattedTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    String formattedTime =
        '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    return formattedTime;
  }

  void initAgora() async {
    await storeMeetingHistory();
    await client.initialize();
  }

  @override
  void dispose() {
    super.dispose();
    client.engine.leaveChannel();
    _timer.cancel();
  }

  storeMeetingHistory() async {
    String userId = user!.uid;
    String channelId = widget.channelName;
    DateTime currentTime = DateTime.now();

    await FirebaseFirestore.instance.collection('meeting_history').add({
      'userId': userId,
      'channelId': channelId,
      'joinedAt': currentTime,
    });
  }

  shareChannelName() async {
    String channelCode = widget.channelName;
    await Share.share(
        'Join my video call using this channel code: $channelCode');
  }

  void showExpiredMessage() async {
    String channelName = widget.channelName; // Get the channel name

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Meeting Expired',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Text(
            'This meeting has ended.',
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                client.engine.leaveChannel();
                await FirebaseFirestore
                    .instance // Delete the channel document from Firestore
                    .collection('channels')
                    .doc(channelName)
                    .delete();
                // check "mounted" property
                if (!context.mounted) return;
                Navigator.pop(context);
                Navigator.pop(context); // Go back to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 90),
          child: FloatingActionButton.extended(
            onPressed: () {
              shareChannelName();
              // Handle the action when the button is pressed
            },
            backgroundColor: Colors.blue,
            label: Row(
              children: [
                const Icon(
                  Icons.person_add,
                  size: 15,
                  color: Colors.white,
                ), // Invite Others icon
                const SizedBox(width: 10),
                Text(
                  'Invite Others',
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: SafeArea(
          child: Stack(
            children: [
              AgoraVideoViewer(
                client: client,
                layoutType: Layout.floating,
              ),
              AgoraVideoButtons(
                verticalButtonPadding: 10,
                client: client,
                onDisconnect: () async {
                  Navigator.pop(context);
                },
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          getFormattedTime(_seconds),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
