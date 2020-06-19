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
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back,color: Colors.black,),onPressed: (){
          Navigator.of(context).pop();
        },),
        title: Text(
          "Shared Location",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: GoogleMap(
          markers: _markers,
          mapType: MapType.hybrid,
          initialCameraPosition: CameraPosition(
              zoom: 18,
              target:
                  LatLng(widget.location.latitude, widget.location.longitude))),
    );
  }
}
