import 'package:bonsoir/bonsoir.dart';
import 'package:socket_io/socket_io.dart';


class MyServer{

  BonsoirService service = const BonsoirService(
  name: 'WokiToki', // Put your service name here.
  type: '_woki-toki._tcp', // Put your service type here. Syntax : _ServiceType._TransportProtocolName. (see http://wiki.ros.org/zeroconf/Tutorials/Understanding%20Zeroconf%20Service%20Types).
  port: 3030, // Put your service port here.
  );
  BonsoirBroadcast? broadcast;

  
    List hostCandidates=[];
    List clientCandidates=[];

    Map answer={};
    Map offer={};
    Map sdp={};


  MyServer._(){
    _io = Server();
    
    _io!.on('connection', (client) {
      print('connected to $client');
      

      client.emit('connected',{'client-candidates':clientCandidates,'host-candidates':hostCandidates});

      client.on('set-offer',(data){
        offer=data;
        _io!.emit('offer-recieved', data);
      });

      client.on('set-answer',(data){
        answer=data['answer'];
        print(answer);
        _io!.emit('answer-recieved', answer);
      });

      client.on('add-client-candidate', (data){
        clientCandidates.add(data['candidate']);
        _io!.emit('client-candidate-update',{'candidates':clientCandidates});
      });

      client.on('add-host-candidate', (data){
        hostCandidates.add(data['candidate']);
        _io!.emit('host-candidate-update',{'candidates':hostCandidates});
      });

      client.on('hang-up',(_){
        print('hangup');

        hostCandidates.clear();
        clientCandidates.clear();
        answer={};
        sdp={};
        offer={};
      });


    });

    broadcastServer();
  }


  broadcastServer ()async{
    broadcast = BonsoirBroadcast(service: service);
  }
  
  Server? _io;

  static MyServer? _instance;

  static MyServer getInstance(){
    if(_instance!=null)return _instance!;

    _instance=MyServer._();
    
    return _instance!;
  }


  start()async{
    await broadcast!.ready;
    _io!.listen(3000);
    broadcast!.start();
  }

  stop(){
    _io!.close();
    broadcast!.stop();
    hostCandidates.clear();
    clientCandidates.clear();
    answer={};
    sdp={};
    offer={};

    broadcastServer();
  }




}