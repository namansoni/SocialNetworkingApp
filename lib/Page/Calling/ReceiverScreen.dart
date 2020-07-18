import 'package:flutter/material.dart';

import 'package:socialnetworking/Methods/CallMethods.dart';
import 'package:socialnetworking/Models/CallModel.dart';
import 'package:socialnetworking/Models/UserModel.dart';
import 'package:socialnetworking/Page/Calling/CallerScreen.dart';
import 'package:socialnetworking/Utils/permission.dart';

class ReceiverPage extends StatelessWidget {
  final Call call;
  final UserModel currentUser;
  CallMethods callMethods = CallMethods();
  ReceiverPage({@required this.call, @required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Incomming....',
                style: TextStyle(
                  fontSize: 30.0,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: CircleAvatar(
                radius: 100.0,
                child: Image.network(
                  call.callerPic,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                call.callerName,
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 50),
                    child: Card(
                      color: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      child: IconButton(
                        icon: Icon(Icons.call),
                        onPressed: () async => await Permissions
                                .cameraAndMicrophonePermissionsGranted()
                            ? Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CallerPage(
                                    call: call,
                                    currentUser: currentUser,
                                  ),
                                ))
                            : {},
                        color: Colors.green.shade500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 50),
                    child: Card(
                      color: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      child: IconButton(
                        icon: Icon(Icons.call_end),
                        color: Colors.redAccent,
                        onPressed: () async {
                          await callMethods.endCall(call: call);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
