import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:socket_io_client/socket_io_client.dart';

typedef void StreamStateCallback(MediaStream stream);



class SignalingClient {
  Map<String, dynamic> configuration = {
  };

  bool isHost;
  int index=-1;
  bool initialized=false;
  RTCVideoRenderer localRenderer;

  SignalingClient(String serverAddress, this.isHost, this.localRenderer){
    socket = io('http://$serverAddress:3000', 
    OptionBuilder()
      .setTransports(['websocket']) // for Flutter or Dart VM
      .disableAutoConnect() 
      .build()
    );
  }


  Future initialize() async{
    socket.onConnect((data){

      //candidate handling
      socket.on('candidate-recieved',(data)async{
        connections[data['from']]?.addCandidate(
            RTCIceCandidate(
              data['candidate']['candidate'],
              data['candidate']['sdpMid'],
              data['candidate']['sdpMLineIndex'],
            ),
          );
        print('recieved candidate');
      });
      ///

      ///answer handling
      socket.on('answer-recieved', (data) async{
        
        print('answer recieved from ${data['from']}');

        var answer = RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          );

        print("setting answer from ${data['from']}");
        await connections[data['from']]!.setRemoteDescription(answer);
      });
      ///
      
      
      ///offer handling
      socket.on('offer-recieved',(data)async{
        connections[data['from']]=await createPeerConnection(configuration);

        print('offer recieved from ${data['from']}');

        registerPeerConnectionListener(connections[data['from']], data['from']);

        localStream?.getTracks().forEach((track) {
          connections[data['from']]?.addTrack(track, localStream!);
        });

        connections[data['from']]!.onIceCandidate = (RTCIceCandidate? candidate) {
          if (candidate == null) {
            print('onIceCandidate: complete!');
            return;
          }
          socket.emit('add-candidate',{'to':data['from'],'from':index,'candidate':candidate.toMap()});    
        };

        connections[data['from']]?.onTrack = (RTCTrackEvent event) {
          print('Got remote track: ${event.streams[0]}');
          event.streams[0].getTracks().forEach((track) {
            print('Add a track to the remoteStream: $track');
            remoteStreams[data['from']]?.addTrack(track);
          });
        };

        var offer = RTCSessionDescription(
          data['offer']['sdp'],
          data['offer']['type'],
        );
        await connections[data['from']]?.setRemoteDescription(offer);

        var answer = await connections[data['from']]!.createAnswer();
        
        await connections[data['from']]?.setLocalDescription(answer);


        socket.emit('send-answer',{'to':data['from'],'from':index,'answer':answer.toMap()});
      });
      ///

      ///initializing connections
      socket.on('index', (data)async{
        index=data;
        print('connected at index: $index');
        if(index!=0){
          for(int i=0;i<index;i++){

            connections[i]=await createPeerConnection(configuration);
            registerPeerConnectionListener(connections[i], i);

            localStream?.getTracks().forEach((track) {
              connections[i]?.addTrack(track, localStream!);
            });
            connections[i]!.onIceCandidate = (RTCIceCandidate? candidate) {
              if (candidate == null) {
                print('onIceCandidate: complete!');
                return;
              }
              print('executes');
              socket.emit('add-candidate',{'to':i,'from':index,'candidate':candidate.toMap()});    
            };

            var offer=await connections[i]!.createOffer();
            await connections[i]?.setLocalDescription(offer);
            socket.emit('send-offer',{
              'from':index,
              'to':i,
              'offer':offer.toMap()
            });

            peerConnection?.onTrack = (RTCTrackEvent event) {
              print('Got remote track: ${event.streams[0]}');

              event.streams[0].getTracks().forEach((track) {
                print('Add a track to the remoteStream $track');
                remoteStreams[i]?.addTrack(track);
              });
            };

          }
        }
      });
      ///
    });
    await openUserMedia(localRenderer);
    socket.connect();
    initialized=true;
  }

  late Socket socket;

  RTCPeerConnection? peerConnection;

  Map<int, RTCPeerConnection> connections={};
  Map<int, MediaStream> remoteStreams={}; 

  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  List clientCandidates=[];
  List hostCandidates=[];
  String? currentRoomText;
  StreamStateCallback? onAddRemoteStream;



  Future<void> openUserMedia(
    RTCVideoRenderer localVideo,
  ) async {
    var stream;
    try{
      stream = await navigator.mediaDevices
        .getUserMedia({'video': false, 'audio': true,});
    }
    catch(e){
      print(e);
    }
    localVideo.srcObject = stream;
    localVideo.srcObject!.getAudioTracks()[0].enabled=false;
    localStream = stream;

    //remoteVideo.srcObject = await createLocalMediaStream('key');
  }

  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
    tracks.forEach((track) {
      track.stop();
    });

    remoteStreams.forEach((key, value) {value.getTracks().forEach((track) => track.stop());});
      
    if (peerConnection != null) peerConnection!.close();

    socket.emit('hangup');
    socket.disconnect();

    localStream!.dispose();
    remoteStreams.forEach((key, value) {value.dispose();});
    
  }



  void registerPeerConnectionListener(RTCPeerConnection? peerConnection, int index){
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('SignalingClient state change: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      print("Add remote stream");
      onAddRemoteStream?.call(stream);
      remoteStreams[index] = stream;
    };
  }

}





// class SignalingClient {
//   Map<String, dynamic> configuration = {
    
//   };

//   bool isHost;

//   SignalingClient(String serverAddress, this.isHost){
//     socket = io('http://$serverAddress:3000', 
//     OptionBuilder()
//       .setTransports(['websocket']) // for Flutter or Dart VM
//       .disableAutoConnect() 
//       .build()
//     );
    
//     socket.connect();

//     // if(!(isHost)){
//     //   socket.on('connected',(data) {
//     //     hostCandidates=data['host-candidates'];
//     //     print(data);
//     //     print('this execs');
//     //   });
//     // }
//   }


//   Future initialize(RTCVideoRenderer local, RTCVideoRenderer remote)async{
//     await openUserMedia(local, remote);

//     if(isHost){
//       responseGenerator('roomId', remote);
//     }
//     else{
//       joinRoom(remote, 'roomId');
//     }

//   }



//   late Socket socket;

//   RTCPeerConnection? peerConnection;
//   MediaStream? localStream;
//   MediaStream? remoteStream;
//   String? roomId;
//   List clientCandidates=[];
//   List hostCandidates=[];
//   String? currentRoomText;
//   StreamStateCallback? onAddRemoteStream;

//   Future<String> joinRoom(RTCVideoRenderer remoteRenderer, String roomPass) async {


//     print('Create PeerConnection with configuration: $configuration');

//     peerConnection = await createPeerConnection(configuration);


//     registerPeerConnectionListeners();

//     localStream?.getTracks().forEach((track) {
//       print(track.muted);
//       peerConnection?.addTrack(track, localStream!);
//     });

//     // Code for collecting ICE candidates below

//     peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
//       print('Got candidate: ${candidate.toMap()}');
//       socket.emit('add-host-candidate',{'room':roomId,'candidate':candidate.toMap()});
//     };

//     // Finish Code for collecting ICE candidate

//     // Add code for creating a room
//     RTCSessionDescription offer = await peerConnection!.createOffer();
//     await peerConnection!.setLocalDescription(offer);
//     print('Created offer: $offer');


//     socket.emit('set-offer',offer.toMap());
    
//     print('New room created with SDK offer. Room ID: $roomId');
//     currentRoomText = 'Current room is $roomId - You are the caller!';
//     // Created a Room

//     peerConnection?.onTrack = (RTCTrackEvent event) {
//       print('Got remote track: ${event.streams[0]}');

//       event.streams[0].getTracks().forEach((track) {
//         print('Add a track to the remoteStream $track');
//         remoteStream?.addTrack(track);
//       });
//     };

//     // Listening for remote session description below


//     socket.on('answer-recieved', (data) async{
//       var answer = RTCSessionDescription(
//           data['sdp'],
//           data['type'],
//         );

//       print("Someone tried to connect");
//       await peerConnection?.setRemoteDescription(answer);
//     });

//     // Listening for remote session description above

//     // Listen for remote Ice candidates below

//     socket.on('client-candidate-update',(data){
//       if(data['candidates'].length>clientCandidates.length){
//         (data['candidates']).sublist(clientCandidates.length).forEach((data) {
//           print('Got new remote ICE candidate: ${jsonEncode(data)}');
//           peerConnection!.addCandidate(
//             RTCIceCandidate(
//               data['candidate'],
//               data['sdpMid'],
//               data['sdpMLineIndex'],
//             ),
//           );
//         });
//         clientCandidates.addAll((data['candidates']).sublist(clientCandidates.length));
//       }
    
//     });
//     return roomPass;
//   }

//   Future<void> responseGenerator(String roomId, RTCVideoRenderer remoteVideo) async {

//       print('Create PeerConnection with configuration: $configuration');
//       peerConnection = await createPeerConnection(configuration);

//       print('works i think');

//       registerPeerConnectionListeners();

//       localStream?.getTracks().forEach((track) {
//         peerConnection?.addTrack(track, localStream!);
//       });

//       // Code for collecting ICE candidates below
//       peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
//         if (candidate == null) {
//           print('onIceCandidate: complete!');
//           return;
//         }
//         print('onIceCandidate: ${candidate.toMap()}');
//         socket.emit('add-client-candidate',{'room':roomId,'candidate':candidate.toMap()});    
//       };  
//       // Code for collecting ICE candidate above

//       peerConnection?.onTrack = (RTCTrackEvent event) {
//         print('Got remote track: ${event.streams[0]}');
//         event.streams[0].getTracks().forEach((track) {
//           print('Add a track to the remoteStream: $track');
//           remoteStream?.addTrack(track);
//         });
//       };

//       // Code for creating SDP answer below

//       socket.on('offer-recieved',(data)async{
//         var offer = data;
//         await peerConnection?.setRemoteDescription(
//           RTCSessionDescription(offer['sdp'], offer['type']),
//         );
//         var answer = await peerConnection!.createAnswer();
//         print('Created Answer $answer');

//         await peerConnection!.setLocalDescription(answer);

//         socket.emit('set-answer',{'room':roomId,'answer':answer.toMap()});


//         print('host length:'+hostCandidates.length.toString());

//         hostCandidates.forEach((data) {
//           print('Got new remote ICE candidate: $data');
//           peerConnection!.addCandidate(
//             RTCIceCandidate(
//               data['candidate'],
//               data['sdpMid'],
//               data['sdpMLineIndex'],
//             ),
//           );
//         });

//       });


//       // Listening for remote ICE candidates below
//       socket.on('host-candidate-update',(data){

//       print('host update length:'+data['candidates'].length.toString());

//       if(data['candidates'].length>hostCandidates.length){
//         (data['candidates']).sublist(hostCandidates.length).forEach((data) {
//           print('Got new remote ICE candidate: $data');
//           peerConnection!.addCandidate(
//             RTCIceCandidate(
//               data['candidate'],
//               data['sdpMid'],
//               data['sdpMLineIndex'],
//             ),
//           );
//         });
//         hostCandidates.addAll((data['candidates']).sublist(hostCandidates.length));
//       }
//       });
//   }

//   Future<void> openUserMedia(
//     RTCVideoRenderer localVideo,
//     RTCVideoRenderer remoteVideo,
//   ) async {
//     var stream = await navigator.mediaDevices
//         .getUserMedia({'video': false, 'audio': true,});

//     localVideo.srcObject = stream;
//     localStream = stream;

//     remoteVideo.srcObject = await createLocalMediaStream('key');
//   }

//   Future<void> hangUp(RTCVideoRenderer localVideo) async {
//     List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
//     tracks.forEach((track) {
//       track.stop();
//     });

//     if (remoteStream != null) {
//       remoteStream!.getTracks().forEach((track) => track.stop());
//     }
//     if (peerConnection != null) peerConnection!.close();

//     socket.emit('hangup');


//     localStream!.dispose();
//     remoteStream?.dispose();
//   }

//   void registerPeerConnectionListeners() {
//     peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
//       print('ICE gathering state changed: $state');
//     };

//     peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
//       print('Connection state change: $state');
//     };

//     peerConnection?.onSignalingState = (RTCSignalingState state) {
//       print('SignalingClient state change: $state');
//     };

//     peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
//       print('ICE connection state change: $state');
//     };

//     peerConnection?.onAddStream = (MediaStream stream) {
//       print("Add remote stream");
//       onAddRemoteStream?.call(stream);
//       remoteStream = stream;
//     };
//   }
// }
