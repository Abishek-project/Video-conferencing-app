// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';

// class VideoMeetingScreen extends StatefulWidget {
//   // final RtcEngine engine;
//   final String channelName;

//   const VideoMeetingScreen({
//     Key? key,
//     required this.channelName,
//   }) : super(key: key);

//   @override
//   // ignore: library_private_types_in_public_api
//   _VideoMeetingScreenState createState() => _VideoMeetingScreenState();
// }

// class _VideoMeetingScreenState extends State<VideoMeetingScreen> {
//   int? _remoteUid;
//   bool _localUserJoined = false;
//   late RtcEngine _engine;
//   @override
//   void initState() {
//     super.initState();
//     initAgora();
//   }

//   Future<void> initAgora() async {
//     await [Permission.microphone, Permission.camera].request();

//     _engine = createAgoraRtcEngine();
//     await _engine.initialize(const RtcEngineContext(
//       appId: "14391331f83641d9a063013819ab5b54",
//       channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
//     ));
//     _engine.registerEventHandler(
//       RtcEngineEventHandler(
//         onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
//           debugPrint("local user ${connection.localUid} joined");
//           setState(() {
//             _localUserJoined = true;
//           });
//         },
//         onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
//           debugPrint("remote user $remoteUid joined");
//           setState(() {
//             _remoteUid = remoteUid;
//           });
//         },
//         onUserOffline: (RtcConnection connection, int remoteUid,
//             UserOfflineReasonType reason) {
//           debugPrint("remote user $remoteUid left channel");
//           setState(() {
//             _remoteUid = null;
//           });
//         },
//         onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
//           debugPrint(
//               '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
//         },
//       ),
//     );
//     await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
//     await _engine.enableVideo();
//     await _engine.startPreview();

//     await _engine.joinChannel(
//       token: "",
//       channelId: "test",
//       uid: 0,
//       options: const ChannelMediaOptions(),
//     );
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     _engine.leaveChannel();
//     // widget.engine.destroy();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Video Meeting: ${widget.channelName}'),
//       ),
//       body: Stack(
//         children: [
//           Center(
//             child: _remoteVideo(),
//           ),
//           Align(
//             alignment: Alignment.topLeft,
//             child: SizedBox(
//               width: 100,
//               height: 150,
//               child: Center(
//                 child: _localUserJoined
//                     ? AgoraVideoView(
//                         controller: VideoViewController(
//                           rtcEngine: _engine,
//                           canvas: VideoCanvas(uid: 0),
//                         ),
//                       )
//                     : const CircularProgressIndicator(),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Display remote user's video
//   Widget _remoteVideo() {
//     if (_remoteUid != null) {
//       return AgoraVideoView(
//         controller: VideoViewController.remote(
//           rtcEngine: _engine,
//           canvas: VideoCanvas(uid: _remoteUid),
//           connection: RtcConnection(channelId: widget.channelName),
//         ),
//       );
//     } else {
//       return const Text(
//         'Please wait for remote user to join',
//         textAlign: TextAlign.center,
//       );
//     }
//   }
// }
