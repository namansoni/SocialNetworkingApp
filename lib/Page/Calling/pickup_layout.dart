import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:insta_clone/Models/UserModel.dart';
import 'package:provider/provider.dart';
import 'package:insta_clone/Methods/CallMethods.dart';
import 'file:///C:/Users/PULKI/Desktop/SocialNetworkingApp/lib/Models/CallModel.dart';
import 'package:insta_clone/Page/Calling/ReceiverScreen.dart';
import 'package:insta_clone/Page/ChatScreen.dart';


class PickupLayout extends StatelessWidget {
  final CallMethods callMethods=CallMethods();
  final Widget scaffold;
  final UserModel currentUser;
  PickupLayout({@required this.scaffold,@required this.currentUser});
  @override
  Widget build(BuildContext context) {

    return StreamBuilder<DocumentSnapshot>(
      stream:  callMethods.callStream(uid: currentUser.id ),
      builder: (context,snapshot){
        if(snapshot.hasData && snapshot.data.data!=null){
          print('Call Exists');
          print(snapshot.data.data['receiver_name']);
          Call call = Call.fromMap(snapshot.data.data);
          print(call.hasDialed);
          if(!call.hasDialed){
            print('calling reciverPage');
            print(call.channelId);
          return ReceiverPage(call: call,currentUser: currentUser,);}
          else
            {
              return scaffold;
            }
        }
        else{
          return scaffold;
        }
      },
    );
  }
}
