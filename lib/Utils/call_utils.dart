import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:socialnetworking/Methods/CallMethods.dart';
import 'package:socialnetworking/Models/CallModel.dart';
import 'package:socialnetworking/Models/UserModel.dart';
import 'dart:math';
import 'package:socialnetworking/Page/Calling/CallerScreen.dart';

class CallUtils{
  static final CallMethods callMethods=CallMethods();

  static dial({UserModel from,UserModel to, context}) async {
    Call call = Call(
      callerID: from.id,
      callerPic: from.photoUrl,
      callerName: from.displayName,
      receiverID: to.id,
      receiverName: to.displayName,
      receiverPic: to.photoUrl,
      channelId: Random().nextInt(1000).toString(),
    );
    print("calling MakeCall");
    bool callMade =await callMethods.makeCall(call: call);
    print("Done MakeCall");
    call.hasDialed=true;
    if(callMade){
      print("Going to Caller Page");
      Navigator.push(context, MaterialPageRoute(builder:(context)=> CallerPage(call: call,currentUser: from,)));
    }
  }
}