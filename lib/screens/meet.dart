// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class Meet extends StatefulWidget {
  const Meet({
    Key? key,
    required this.channelName,
    required this.userName,
  }) : super(key: key);

  final String channelName;
  final String userName;

  @override
  State<Meet> createState() => _MeetState();
}

class _MeetState extends State<Meet> {
  static const String appId = "14391331f83641d9a063013819ab5b54";

  RtcEngine? _engine;
  User? user;
  Timer? _timer;
  int _seconds = 0;
  bool _isJoined = false;
  bool _isDisposing = false;

  // Local user ID
  int _localUid = 0;

  // Remote users
  final Set<int> _remoteUids = {};

  // Media controls
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isFrontCamera = true;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _initAgora();
    _startTimer();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  // Initialize Agora
  Future<void> _initAgora() async {
    try {
      // Request permissions
      await [Permission.microphone, Permission.camera].request();

      // Create engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // Set up event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('Joined channel: ${connection.channelId}');
            setState(() {
              _isJoined = true;
              _localUid = connection.localUid!;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('User joined: $remoteUid');
            setState(() {
              _remoteUids.add(remoteUid);
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint('User left: $remoteUid');
            setState(() {
              _remoteUids.remove(remoteUid);
            });
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint('Left channel');
            setState(() {
              _isJoined = false;
              _remoteUids.clear();
            });
          },
        ),
      );

      // Enable video
      await _engine!.enableVideo();
      await _engine!.startPreview();

      // Set client role
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Join channel
      await _engine!.joinChannel(
        token: '', // Add your token if using token authentication
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      // Store meeting history
      await _storeMeetingHistory();
    } catch (e) {
      debugPrint('Agora initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join meeting: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  // Cleanup resources
  Future<void> _cleanup() async {
    if (_isDisposing) return;
    _isDisposing = true;

    try {
      // Cancel timer
      _timer?.cancel();

      // Leave channel and release engine
      await _engine?.leaveChannel();
      await _engine?.release();

      debugPrint('Resources cleaned up');
    } catch (e) {
      debugPrint('xCleanup error: $e');
    }
  }

  // Timer
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _seconds++);
      }

      if (_seconds >= 30 * 60) {
        timer.cancel();
        _showExpiredDialog();
      }
    });
  }

  String _getFormattedTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Store meeting history
  Future<void> _storeMeetingHistory() async {
    if (user == null) return;

    await FirebaseFirestore.instance.collection('meeting_history').add({
      'userId': user!.uid,
      'channelId': widget.channelName,
      'joinedAt': DateTime.now(),
    });
  }

  // Toggle microphone
  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _engine?.muteLocalAudioStream(_isMuted);
  }

  // Toggle camera
  Future<void> _toggleCamera() async {
    setState(() => _isCameraOff = !_isCameraOff);
    await _engine?.muteLocalVideoStream(_isCameraOff);
  }

  // Switch camera
  Future<void> _switchCamera() async {
    await _engine?.switchCamera();
    setState(() => _isFrontCamera = !_isFrontCamera);
  }

  // End call
  Future<void> _endCall() async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.grey[900],
        title: Text(
          'End Call?',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to leave?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('End Call',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldEnd == true && mounted) {
      await _cleanup();
      if (mounted) Navigator.pop(context);
    }
  }

  // Share invite
  Future<void> _shareInvite() async {
    await Share.share('Join my video call using code: ${widget.channelName}');
  }

  // Show expired dialog
  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.grey[900],
        title: Text(
          'Meeting Expired',
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Text(
          'This meeting has ended.',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _cleanup();
              if (!mounted) return;
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        await _endCall();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Video views
              _buildVideoViews(),

              // Top bar with timer
              _buildTopBar(),

              // Bottom controls
              _buildBottomControls(),

              // Invite button
              Positioned(
                bottom: 150,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton.extended(
                    onPressed: _shareInvite,
                    backgroundColor: Colors.blue,
                    icon: const Icon(Icons.person_add,
                        size: 18, color: Colors.white),
                    label: Text(
                      'Invite Others',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build video views
  Widget _buildVideoViews() {
    if (!_isJoined) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      children: [
        // Remote users (full screen)
        if (_remoteUids.isNotEmpty)
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine!,
              canvas: VideoCanvas(uid: _remoteUids.first),
              connection: RtcConnection(channelId: widget.channelName),
            ),
          )
        else
          Center(
            child: Text(
              'Waiting for others to join...',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),

        // Local user (small view in corner)
        Positioned(
          top: 20,
          right: 20,
          child: SizedBox(
            width: 120,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _isCameraOff
                  ? Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(Icons.videocam_off,
                            color: Colors.white, size: 40),
                      ),
                    )
                  : AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // Build top bar
  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _getFormattedTime(_seconds),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build bottom controls
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            onPressed: _toggleMute,
            isActive: !_isMuted,
          ),

          // Camera button
          _buildControlButton(
            icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
            onPressed: _toggleCamera,
            isActive: !_isCameraOff,
          ),

          // Switch camera button
          _buildControlButton(
            icon: Icons.cameraswitch,
            onPressed: _switchCamera,
            isActive: true,
          ),

          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            onPressed: _endCall,
            backgroundColor: Colors.red,
            isActive: true,
          ),
        ],
      ),
    );
  }

  // Build control button
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    required bool isActive,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? (isActive ? Colors.white : Colors.grey[800]),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: backgroundColor != null
              ? Colors.white
              : (isActive ? Colors.black : Colors.white),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
