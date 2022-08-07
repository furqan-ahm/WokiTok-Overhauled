import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:wokitoki/utils/signaling_client.dart';

import '../utils/signaling_server.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({Key? key, required this.serverAddress}) : super(key: key);

  final String serverAddress;

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {

  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  late SignalingClient client;
  bool isHost=true;


  @override
  void initState() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();
    isHost=widget.serverAddress=='localhost';
    
    client=SignalingClient(widget.serverAddress,isHost);

    client.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });
    client.initialize(_localRenderer, _remoteRenderer).then((value){
      _localRenderer.srcObject!.getAudioTracks()[0].enabled=false;
    });

    super.initState();
  }

  bool speak=false;


  Talk(){
    _localRenderer.srcObject!.getAudioTracks()[0].enabled=true;
    if(_remoteRenderer.srcObject!.getAudioTracks().isNotEmpty)_remoteRenderer.srcObject!.getAudioTracks()[0].enabled=true;
    setState(() {
      speak=true;
    });
  }


  Listen(){
    if(_remoteRenderer.srcObject!.getAudioTracks().isNotEmpty)_remoteRenderer.srcObject!.getAudioTracks()[0].enabled=true;
    _localRenderer.srcObject!.getAudioTracks()[0].enabled=false;
    setState(() {
      speak=false;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: GestureDetector(
                onTapDown: (details){Talk();},
                onTapCancel: (){Listen();},
                onTapUp: (details){Listen();},
                child: Container(
                  decoration: BoxDecoration(
                    color: speak?Colors.teal:Colors.blueGrey,
                    shape: BoxShape.circle
                  ),
                  child: Container(
                    padding: EdgeInsets.all(60),
                    child: Icon(speak?Icons.mic:Icons.headphones, size: 70,)
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    if(isHost)MyServer.getInstance().stop();
    client.hangUp(_localRenderer);
    
    super.dispose();
  }


}