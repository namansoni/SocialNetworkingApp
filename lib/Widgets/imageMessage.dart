import 'package:flutter/material.dart';
import 'package:socialnetworking/Widgets/custom_image.dart';
class ImageMessage extends StatefulWidget {
  String url;
  ImageMessage({this.url});
  @override
  _ImageMessageState createState() => _ImageMessageState();
}

class _ImageMessageState extends State<ImageMessage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: cachedNetworkimage(widget.url),
        ),
    );
  }
}