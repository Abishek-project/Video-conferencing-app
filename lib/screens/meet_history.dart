import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MeetHistoryPage extends StatefulWidget {
  const MeetHistoryPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MeetHistoryPageState createState() => _MeetHistoryPageState();
}

class _MeetHistoryPageState extends State<MeetHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Meet History',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: FutureBuilder(
        future: _getMeetingHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No meet history available !'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> meetData = snapshot.data![index];
                DateTime joinedAt = meetData['joinedAt'].toDate();
                String formattedJoinedAt =
                    DateFormat.yMMMd().add_jms().format(joinedAt);

                return ListTile(
                  title: Text(
                    'Room ID: ${meetData['channelId']}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Joined on: $formattedJoinedAt',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getMeetingHistory() async {
    User? user = _auth.currentUser;
    QuerySnapshot historySnapshot = await _firestore
        .collection('meeting_history')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('joinedAt', descending: true)
        .get();

    List<Map<String, dynamic>> historyList = [];
    for (var doc in historySnapshot.docs) {
      historyList.add(doc.data() as Map<String, dynamic>);
    }

    return historyList;
  }
}
