import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ShowSharedLocation extends StatefulWidget {
  GeoPoint location;
  ShowSharedLocation({this.location});
  @override
  _ShowSharedLocationState createState() => _ShowSharedLocationState();
}

class _ShowSharedLocationState extends State<ShowSharedLocation> {
  Set<Marker> _markers = HashSet<Marker>();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Marker marker = Marker(
        markerId: MarkerId("0"),
        position: LatLng(widget.location.latitude, widget.location.longitude));
    _markers.add(marker);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
              markers: _markers,
              mapType: MapType.hybrid,
              initialCameraPosition: CameraPosition(
                  zoom: 18,
                  target: LatLng(
                      widget.location.latitude, widget.location.longitude))),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: EdgeInsets.only(top:10),
                width: MediaQuery.of(context).size.width * 0.9,
                height: 60,
                child: Row(
                  children: <Widget>[
                    GestureDetector(
                      onTap: (){
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
                              "Shared Location",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ))))
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
