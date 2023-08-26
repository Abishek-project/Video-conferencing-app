import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';

class Meet extends StatefulWidget {
  const Meet({super.key});

  @override
  State<Meet> createState() => _MeetState();
}

class _MeetState extends State<Meet> {
  final AgoraClient client = AgoraClient(
    agoraConnectionData: AgoraConnectionData(
      appId: "14391331f83641d9a063013819ab5b54",
      channelName: "test",
      username: "user",
    ),
  );

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  void initAgora() async {
    await client.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Agora VideoUIKit'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              AgoraVideoViewer(
                client: client,
                layoutType: Layout.floating,
                enableHostControls: true, // Add this to enable host controls
              ),
              AgoraVideoButtons(
                client: client,
                // Add this to enable screen sharing
              ),
            ],
          ),
        ),
      ),
    );
  }
}
