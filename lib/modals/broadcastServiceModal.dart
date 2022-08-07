class BroadcastModal{
  String ip;
  String name;

 BroadcastModal({required this.ip, required this.name});

 static fromJson(jsonData){
  return BroadcastModal(ip: jsonData['ip'], name: jsonData['name']);
 }

}