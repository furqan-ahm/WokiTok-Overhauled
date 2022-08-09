import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:wokitoki/modals/broadcastServiceModal.dart';
import 'package:wokitoki/screens/contact.dart';
import 'package:wokitoki/utils/signaling_server.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);
  
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {


  BonsoirDiscovery discovery = BonsoirDiscovery(type: '_woki-toki._tcp');
  List<BroadcastModal> servicesFound=[];

  startDiscovery()async{
    
    await discovery.ready;
    
    discovery.eventStream!.listen((event) {
  
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
        setState(() {
          servicesFound.add(BroadcastModal.fromJson(event.service!.toJson(prefix: '')));
        });
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
        print('hmm');
        setState(() {
          servicesFound.removeWhere((e)=>e.ip.contains(event.service!.toJson(prefix: '')['ip']));
        });
      }
    
  });

  await discovery.start();
  }


  @override
  void initState() {
    startDiscovery();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: servicesFound.length,
                itemBuilder: (context, index){
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: ListTile(
                      onTap:() {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ContactScreen(serverAddress: servicesFound[index].ip),));
                      },
                      title: Text(servicesFound[index].name, style: TextStyle(),),
                      subtitle: Text(servicesFound[index].ip, style: TextStyle(),),
                    ),
                  );
                }
              ),
            )
          ],
        ),
      ),
    );   
  }


  @override
  void dispose() {
    discovery.stop();
    super.dispose();
  }
}