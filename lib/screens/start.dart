import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:wokitoki/screens/contact.dart';
import 'package:wokitoki/screens/discover.dart';
import 'package:wokitoki/utils/signaling_server.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            customAppBar(),
            Expanded(child: Container(),),
            Ink(
              decoration: const BoxDecoration(
                color: Colors.white,
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 252, 248, 248),Color.fromARGB(255, 253, 253, 253)],
                ),
                shape: BoxShape.circle
              ),
              child: InkWell(
                splashColor: Color.fromARGB(52, 2, 247, 255),
                customBorder: CircleBorder(),
                onTap:() {
                  MyServer.getInstance().start();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ContactScreen(serverAddress: 'localhost')));
                },
                child: Container(
                  padding: EdgeInsets.all(80),
                  child: Text('Host', style: TextStyle(fontSize: 24,),)
                ),
              ),
            ),
            CustomDivider(),
            Ink(
              decoration: const BoxDecoration(
                color: Colors.white,
                gradient: LinearGradient(
                  colors: [Colors.white,Color.fromARGB(255, 255, 255, 255)],
                ),
                shape: BoxShape.circle
              ),
              child: InkWell(
                splashColor: Color.fromARGB(52, 2, 247, 255),
                customBorder: const CircleBorder(),
                onTap:() {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => DiscoverScreen()));
                },
                child: Container(
                  padding: EdgeInsets.all(80),
                  child: Text('Discover', style: TextStyle(fontSize: 24,),)
                ),
              ),
            ),
            Expanded(child: Container(),),
          ],
        ),
      ),
    );
  }
}


class customAppBar extends StatefulWidget {
  const customAppBar({Key? key}) : super(key: key);

  @override
  State<customAppBar> createState() => _customAppBarState();
}

class _customAppBarState extends State<customAppBar> {


  double posX=0;

  Size? size;

  


  toggleAnimation(){
    if(posX==0){
      setState(() {
        posX=-size!.width+80;
      });
    }
    else{
      setState(() {
        posX=0;
      });
    }
  }


  @override
  void initState() {
    super.initState();
    
  }


  @override
  Widget build(BuildContext context) {

    size=MediaQuery.of(context).size;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(onPressed: (){toggleAnimation();}, icon: Icon(Icons.settings), color: Colors.white,),
              IconButton(onPressed: (){toggleAnimation();}, icon: Icon(Icons.help), color: Colors.white,),
            ],
          ),
        ),
        AnimatedContainer(
          transform: Matrix4.translationValues(posX, 0, 0),
          width: size!.width,
          curve: Curves.easeOut,
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20)
          ),
          duration: Duration(milliseconds: 500),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WokiToki', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),),
              IconButton(onPressed: (){toggleAnimation();}, icon: Icon(posX==0?Icons.menu:Icons.arrow_forward_ios), color: Colors.black,)
            ],
          )
        ),
      ],
    );
  }
}


class CustomDivider extends StatelessWidget {
  const CustomDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.white, thickness: 2, height: 2,),),
          Container(padding:EdgeInsets.all(10),child: Text('OR', style: TextStyle(color: Colors.white),)),
          Expanded(child: Divider(color: Colors.white, thickness: 2, height: 2,),),
        ],
      ),
    );
  }
}

