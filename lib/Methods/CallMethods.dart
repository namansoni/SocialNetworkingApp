import 'package:flutter/cupertino.dart';
import 'package:socialnetworking/Models/CallModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CallMethods{
  final CollectionReference callCollection= Firestore.instance.collection("call");

  Stream<DocumentSnapshot> callStream({String uid}) => callCollection.document(uid).snapshots();

  Future<bool> makeCall({Call call}) async
  {
    try
    {
      print("in Make call");
      call.hasDialed=true;
      Map<String, dynamic> callerMap= call.toMap(call);
      call.hasDialed=false;
      Map<String, dynamic> receiverMap=call.toMap(call);

      await callCollection.document(call.callerID).setData(callerMap);
      await callCollection.document(call.receiverID).setData(receiverMap);
      return true;
    }
    catch(e)
    {
      print("makeCall Failed");
      print(e);
      return false;
    }
  }
  Future<bool> endCall({Call call,context}) async
  {
    try {
      await callCollection.document(call.callerID).delete();
      await callCollection.document(call.receiverID).delete();
      Navigator.pop(context);
      return true;
    }
    catch(e)
    {
      print(e);
      return false;
    }
  }

}
