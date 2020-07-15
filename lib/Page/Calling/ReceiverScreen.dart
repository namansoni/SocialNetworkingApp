import 'package:flutter/material.dart';
import 'file:///C:/Users/PULKI/Desktop/SocialNetworkingApp/lib/Models/CallModel.dart';
import 'package:insta_clone/Methods/CallMethods.dart';
import 'package:insta_clone/Models/UserModel.dart';
import 'package:insta_clone/Page/Calling/CallerScreen.dart';
import 'package:insta_clone/Utils/permission.dart';

class ReceiverPage extends StatelessWidget {

  final Call call;
  final UserModel currentUser;
  CallMethods callMethods=CallMethods();
  ReceiverPage({@required this.call,@required this.currentUser});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 100.0),
          child: Column(
            children: <Widget>[
              Text(
                'Incomming....',
                style: TextStyle(
                  fontSize: 30.0,
                ),
              ),
              SizedBox(height:50.0,),
              CircleAvatar(
                radius: 100.0,
                child: Image.network(
                  call.callerPic,
                ),
              ),
              SizedBox(height: 15.0,),
              Text(
                call.callerName,
                style:TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 75,),
              Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.call),
                    onPressed: () async => await Permissions.cameraAndMicrophonePermissionsGranted()?
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context)=>CallerPage(call: call,currentUser: currentUser,),)
                    ):{},
                    color: Colors.green.shade500,
                  ),
                  SizedBox(width: 65,),
                  IconButton(
                    icon: Icon(Icons.call_end),
                    color: Colors.redAccent,
                    onPressed: () async{
                      await callMethods.endCall(call: call);
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
