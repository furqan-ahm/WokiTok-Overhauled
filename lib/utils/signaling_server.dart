import 'package:bonsoir/bonsoir.dart';
import 'package:socket_io/socket_io.dart';


class MyServer{

  BonsoirService service = const BonsoirService(
  name: 'WokiToki', // Put your service name here.
  type: '_woki-toki._tcp', // Put your service type here. Syntax : _ServiceType._TransportProtocolName. (see http://wiki.ros.org/zeroconf/Tutorials/Understanding%20Zeroconf%20Service%20Types).
  port: 3030, // Put your service port here.
  );
  BonsoirBroadcast? broadcast;


    List clients=[];


  MyServer._(){
    _io = Server();
    
   _io!.on('connection', (client) {
      print('connected to $client');


      
      client.emit('index', clients.length);      
      clients.add(client);
      client.join('dummy');

      client.on('disconnect',(_){
        clients.removeWhere((e)=>e.id==client.id);
      });

      client.on('send-offer',(data){
        client.to(clients[data['to']].id).emit('offer-recieved',data);
      });

      client.on('send-answer',(data){
        client.to(clients[data['to']].id).emit('answer-recieved',data);
      });

      client.on('add-candidate',(data){
        client.to(clients[data['to']].id).emit('candidate-recieved',data);
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
    broadcastServer();
  }




}