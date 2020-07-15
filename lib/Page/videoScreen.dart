import 'package:flutter/material.dart';
import 'package:socialnetworking/Widgets/custom_image.dart';
import 'package:video_player/video_player.dart';

class VideoScreen extends StatefulWidget {
  var videoUrl;
  var thumbnailUrl;
  VideoScreen({this.videoUrl, this.thumbnailUrl});
  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  VideoPlayerController _videoPlayerController;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _videoPlayerController.play();
        });
      });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _videoPlayerController.pause();
    _videoPlayerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoPlayerController.value.initialized) {
      return Scaffold(
        body: Center(
          child: Container(
              child: AspectRatio(
            aspectRatio: _videoPlayerController.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController),
          )),
        ),
      );
    } else {
      return Scaffold(
        body: Stack(
          children: <Widget>[
            Center(
              child: Container(
                child: cachedNetworkimage(widget.thumbnailUrl),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 20,
                height: 20,
                child:CircularProgressIndicator(
                  strokeWidth: 1.0,
                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
                )
              ),
            )
          ],
        ),
      );
    }
  }
}
