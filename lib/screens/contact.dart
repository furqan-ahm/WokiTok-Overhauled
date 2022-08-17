import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final Map<String ,RTCVideoRenderer> _remoteRenderers={};


  late SignalingClient client;
  bool isHost=true;
  bool loading=true;

  @override
  void initState() {
    _localRenderer.initialize();
       
    client=SignalingClient(widget.serverAddress,isHost, _localRenderer);

     client.initialize().then((val){
      setState(() {loading=false;});
     });

    client.onAddRemoteStream = ((stream) async{
      var renderer= RTCVideoRenderer();      
      await renderer.initialize();
      _remoteRenderers[stream.id]=renderer;
      renderer.srcObject=stream;
      setState(() {});
    });

    super.initState();
  }

  bool speak=false;


  Talk(){
    _localRenderer.srcObject!.getAudioTracks()[0].enabled=true;
    _remoteRenderers.forEach((key,element) async{
      element.srcObject!.getAudioTracks()[0].enabled=false;
    });
    setState(() {
      speak=true;
    });
  }


  Listen(){
    _localRenderer.srcObject!.getAudioTracks()[0].enabled=false;
    _remoteRenderers.forEach((key,element) async{
      element.srcObject!.getAudioTracks()[0].enabled=true;
    });
    setState(() {
      speak=false;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: loading?CircularProgressIndicator():GestureDetector(
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