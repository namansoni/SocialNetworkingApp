import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:socialnetworking/Models/UserModel.dart';

class ShareLocationScreen extends StatefulWidget {
  UserModel currentUser;
  UserModel selectedUser;
  String chatId;
  ShareLocationScreen({this.currentUser, this.selectedUser, this.chatId});
  @override
  _ShareLocationScreenState createState() => _ShareLocationScreenState();
}

class _ShareLocationScreenState extends State<ShareLocationScreen> {
  GoogleMapController _mapController;
  Set<Marker> _markers = HashSet<Marker>();
  bool isLocated = false;
  bool isLoading = false;
  Location location = new Location();
  LocationData position;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        body: Stack(
          children: <Widget>[
            GoogleMap(
              zoomControlsEnabled: false,
              markers: _markers,
              mapType: MapType.hybrid,
              initialCameraPosition: CameraPosition(
                  target: LatLng(22.7717549, 78.5372043), zoom: 12, tilt: 10),
              onMapCreated: onMapCreated,
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: EdgeInsets.only(top: 10),
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 60,
                  child: Row(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.6),
                          radius: 30,
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                          height: 50,
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: Card(
                              color: Colors.white.withOpacity(0.6),
                              elevation: 5,
                              child: Center(
                                  child: Text(
                                "Share your location",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ))))
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withOpacity(0.6)),
                child: IconButton(
                    icon: Icon(
                      isLocated ? Icons.my_location : Icons.location_searching,
                      size: 30,
                      color: Colors.blue,
                    ),
                    onPressed: () async {
                      Location location = new Location();
                      bool serviceEnabled;
                      PermissionStatus _permissionStatus;
                      serviceEnabled = await location.serviceEnabled();
                      if (!serviceEnabled) {
                        serviceEnabled = await location.requestService();
                        if (!serviceEnabled) {
                          return;
                        }
                      }
                      _permissionStatus = await location.hasPermission();
                      if (_permissionStatus == PermissionStatus.denied) {
                        _permissionStatus = await location.requestPermission();
                        if (_permissionStatus != PermissionStatus.granted) {
                          return;
                        }
                      }
                      await location.changeSettings(
                        accuracy: LocationAccuracy.high,
                      );
                      location.getLocation().then((value) {
                        CameraPosition cameraPosition = new CameraPosition(
                            zoom: 18,
                            target: LatLng(value.latitude, value.longitude));
                        _mapController.animateCamera(
                            CameraUpdate.newCameraPosition(cameraPosition));
                        Marker marker = new Marker(
                            markerId: MarkerId("0"),
                            position: LatLng(value.latitude, value.longitude));
                        setState(() {
                          position = value;
                          _markers.clear();
                          _markers.add(marker);
                          isLocated = true;
                        });
                      });
                    }),
              ),
            ),
            buildSendButton()
          ],
        ));
  }

  Widget buildSendButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: () async {
          print("shared");
          if (position != null) {
            setState(() {
              isLoading = true;
            });
            DocumentSnapshot docSnapshot = await Firestore.instance
                .collection('chattingWith')
                .document(widget.selectedUser.id)
                .get();
            if (docSnapshot['id'] != widget.currentUser.id) {
              Firestore.instance
                  .collection('unreadChats')
                  .document(widget.selectedUser.id)
                  .collection('unreadchats')
                  .document(widget.chatId)
                  .collection(widget.chatId)
                  .add({
                "message": "shares his/her location.",
                "timestamp": DateTime.now()
              });
            }
            Firestore.instance
                .collection('chats')
                .document(widget.currentUser.id)
                .collection('userChats')
                .document(widget.chatId)
                .collection('chats')
                .add({
              "sender": widget.currentUser.id,
              "receiver": widget.selectedUser.id,
              "timestamp": DateTime.now(),
              "type": "location",
              "location": GeoPoint(position.latitude, position.longitude)
            });
            Firestore.instance
                .collection('chats')
                .document(widget.currentUser.id)
                .collection('userChats')
                .document(widget.chatId)
                .setData({
              "id": widget.selectedUser.id,
              "bio": widget.selectedUser.bio,
              "displayName": widget.selectedUser.displayName,
              "username": widget.selectedUser.username,
              "photoUrl": widget.selectedUser.photoUrl,
              "lastMessage": "You: shared your location.",
              "chatId": widget.chatId
            });
            Firestore.instance
                .collection('chats')
                .document(widget.selectedUser.id)
                .collection('userChats')
                .document(widget.chatId)
                .collection('chats')
                .add({
              "sender": widget.currentUser.id,
              "receiver": widget.selectedUser.id,
              "timestamp": DateTime.now(),
              "type": "location",
              "location": GeoPoint(position.latitude, position.longitude)
            });
            Firestore.instance
                .collection('chats')
                .document(widget.selectedUser.id)
                .collection('userChats')
                .document(widget.chatId)
                .setData({
              "id": widget.currentUser.id,
              "bio": widget.currentUser.bio,
              "displayName": widget.currentUser.displayName,
              "username": widget.currentUser.username,
              "photoUrl": widget.currentUser.photoUrl,
              "lastMessage":
                  "${widget.currentUser.displayName}: shared his/her location.",
              "chatId": widget.chatId
            });
            setState(() {
              isLoading = false;
            });
            SnackBar snackBar =
                new SnackBar(content: Text("Location Shared.."));
            scaffoldKey.currentState.showSnackBar(snackBar);
            Timer(Duration(seconds: 2), () {
              Navigator.of(context).pop();
            });
          } else {
            SnackBar snackBar = new SnackBar(
              content: Text("set your current location first"),
              duration: Duration(seconds: 1),
            );
            scaffoldKey.currentState.showSnackBar(snackBar);
          }
        },
        child: Container(
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withOpacity(0.6)),
          width: MediaQuery.of(context).size.width * 0.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              isLoading
                  ? Container(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ))
                  : Icon(
                      Icons.send,
                      color: Colors.blue,
                    ),
              Text(
                "Share your location",
                style: TextStyle(color: Colors.blue),
              )
            ],
          ),
        ),
      ),
    );
  }
}
