import 'dart:io';

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:socialnetworking/Models/UserModel.dart';
import 'package:socialnetworking/Page/ChatScreen.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ImageandVideoCapture extends StatefulWidget {
  List<CameraDescription> cameras;
  UserModel currentUser, selectedUser;
  String chatId;
  ImageandVideoCapture(
      {this.cameras, this.chatId, this.currentUser, this.selectedUser});
  @override
  _ImageandVideoCaptureState createState() => _ImageandVideoCaptureState();
}

class _ImageandVideoCaptureState extends State<ImageandVideoCapture> {
  CameraController cameraController;
  int cameraSelected = 0;
  String filePath = null;
  double mirror = 0;
  File file;
  bool isVideoButtonPressed = false;
  bool isPhoto = false;
  VideoPlayerController videoPlayerController;
  VoidCallback listener;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    cameraController =
        new CameraController(widget.cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    cameraController?.dispose();
    videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (cameraController.value.isInitialized) {
      return Scaffold(
        body: filePath == null
            ? Stack(
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: cameraController.value.aspectRatio,
                    child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(mirror),
                        child: CameraPreview(cameraController)),
                  ),
                  !cameraController.value.isRecordingVideo
                      ? Padding(
                          padding: EdgeInsets.only(bottom: 30, left: 30),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                              child: IconButton(
                                  icon: Icon(Icons.cached),
                                  onPressed: () async {
                                    await cameraController.dispose();
                                    if (cameraSelected == 0) {
                                      cameraSelected = 1;
                                      mirror = 22 / 7;
                                    } else {
                                      cameraSelected = 0;
                                      mirror = 0;
                                    }
                                    cameraController = new CameraController(
                                        widget.cameras[cameraSelected],
                                        ResolutionPreset.medium);
                                    cameraController.initialize().then((_) {
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    });
                                  }),
                            ),
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.only(left: 30, bottom: 30),
                          child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25)),
                                child: IconButton(
                                  onPressed: () {
                                    if (cameraController
                                        .value.isRecordingPaused) {
                                      onResumeButtonPressed();
                                    } else {
                                      onPauseButtonPressed();
                                    }
                                  },
                                  icon: Icon(
                                      cameraController.value.isRecordingPaused
                                          ? Icons.play_arrow
                                          : Icons.pause_circle_filled),
                                ),
                              )),
                        ),
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: isVideoButtonPressed ? 30 : 20,
                        right: isVideoButtonPressed ? 25 : 0),
                    child: AnimatedAlign(
                      duration: Duration(milliseconds: 200),
                      alignment: isVideoButtonPressed
                          ? Alignment.bottomRight
                          : Alignment.bottomCenter,
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(35)),
                        child: IconButton(
                            iconSize: isVideoButtonPressed ? 30 : 50,
                            icon: Icon(Icons.camera),
                            onPressed: cameraController.value.isRecordingVideo
                                ? null
                                : () {
                                    if (isVideoButtonPressed == true) {
                                      setState(() {
                                        isVideoButtonPressed = false;
                                      });
                                    } else {
                                      onTakePicture();
                                    }
                                  }),
                      ),
                    ),
                  ),
                  Padding(
                    padding: isVideoButtonPressed
                        ? EdgeInsets.only(bottom: 20)
                        : EdgeInsets.only(bottom: 30, right: 25),
                    child: AnimatedAlign(
                      duration: Duration(milliseconds: 200),
                      alignment: isVideoButtonPressed
                          ? Alignment.bottomCenter
                          : Alignment.bottomRight,
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(35)),
                        child: IconButton(
                            color: cameraController.value.isRecordingVideo
                                ? Colors.red
                                : Colors.black,
                            iconSize: isVideoButtonPressed ? 50 : 30,
                            icon: Icon(isVideoButtonPressed
                                ? cameraController.value.isRecordingVideo
                                    ? Icons.stop
                                    : Icons.play_circle_filled
                                : Icons.videocam),
                            onPressed: () {
                              if (isVideoButtonPressed == false) {
                                setState(() {
                                  isVideoButtonPressed = true;
                                });
                              } else {
                                if (!cameraController.value.isRecordingVideo) {
                                  onVideoRecordingButtonPressed();
                                } else {
                                  onVideoStopButtonPressed();
                                }
                              }
                            }),
                      ),
                    ),
                  )
                ],
              )
            : isPhoto ? showImage() : showVideo(),
      );
    } else {
      return Container();
    }
  }

  void onTakePicture() {
    if (cameraController != null &&
        cameraController.value.isInitialized &&
        !cameraController.value.isRecordingVideo) {
      takePicture().then((_filePath) {
        setState(() {
          filePath = _filePath;
          file = File(_filePath);
          isPhoto = true;
        });
      });
    }
  }

  Future<String> takePicture() async {
    final tempDir = await getTemporaryDirectory();
    final String filePath = tempDir.path + "/${DateTime.now()}.jpg";
    if (cameraController.value.isTakingPicture) {
      return null;
    } else {
      await cameraController.takePicture(filePath);
    }
    return filePath;
  }

  Widget showImage() {
    return Stack(
      children: <Widget>[
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Image.file(
              File(filePath),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 30, right: 30),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              child: IconButton(
                  icon: Icon(Icons.check),
                  onPressed: () {
                    sendImage();
                  }),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 30, left: 30),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              child: IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () {
                    setState(() {
                      filePath = null;
                    });
                  }),
            ),
          ),
        )
      ],
    );
  }

  Widget showVideo() {
    return Stack(
      children: <Widget>[
        SafeArea(
          child: Container(
            width: MediaQuery.of(context).size.width,
            child: AspectRatio(
              aspectRatio: videoPlayerController.value.aspectRatio,
              child: VideoPlayer(videoPlayerController),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 30, left: 30),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              child: IconButton(
                icon: Icon(Icons.cancel),
                onPressed: () {
                  setState(() {
                    file = null;
                    filePath = null;
                    videoPlayerController.pause();
                    videoPlayerController.setLooping(false);
                  });
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 30, right: 30),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              child: IconButton(
                icon: Icon(Icons.check),
                onPressed: () {
                  setState(() {
                    sendVideo();
                  });
                },
              ),
            ),
          ),
        )
      ],
    );
  }

  void sendImage() async {
    String postId = DateTime.now().millisecondsSinceEpoch.toString();
    if (widget.chatId != null && file != null) {
      Firestore.instance
          .collection('chats')
          .document(widget.currentUser.id)
          .collection('userChats')
          .document(widget.chatId)
          .collection('chats')
          .document(postId)
          .setData({
        "sender": widget.currentUser.id,
        "receiver": widget.selectedUser.id,
        "timestamp": DateTime.now(),
        "url": "",
        "type": "image"
      });
      Navigator.of(context).pop();
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
            .add({"message": "shares a image", "timestamp": DateTime.now()});
      }
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
        "lastMessage": "You: shared a image",
        "chatId": widget.chatId
      });
      Firestore.instance
          .collection('chats')
          .document(widget.selectedUser.id)
          .collection('userChats')
          .document(widget.chatId)
          .collection('chats')
          .document(postId)
          .setData({
        "sender": widget.currentUser.id,
        "receiver": widget.selectedUser.id,
        "timestamp": DateTime.now(),
        "url": "",
        "type": "image"
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
        "lastMessage": "${widget.currentUser.displayName}: shared a image",
        "chatId": widget.chatId
      });
      await compressImage(postId);
      StorageUploadTask uploadTask =
          FirebaseStorage.instance.ref().child("message_$postId").putFile(file);
      StorageTaskSnapshot snapshot = await uploadTask.onComplete;
      String url = await snapshot.ref.getDownloadURL();
      print(url);
      createMessageinFirestore(url: url, postId: postId);
    }
  }

  Future<void> compressImage(String postId) async {
    Im.Image image = Im.decodeImage(file.readAsBytesSync());
    final compressedImage = file
      ..writeAsBytesSync(Im.encodeJpg(image, quality: 50));
    file = compressedImage;
  }

  void createMessageinFirestore({String url, String postId}) {
    if (widget.chatId != null) {
      Firestore.instance
          .collection('chats')
          .document(widget.currentUser.id)
          .collection('userChats')
          .document(widget.chatId)
          .collection('chats')
          .document(postId)
          .setData({
        "sender": widget.currentUser.id,
        "receiver": widget.selectedUser.id,
        "timestamp": DateTime.now(),
        "url": url,
        "type": "image"
      });
      Firestore.instance
          .collection('chats')
          .document(widget.selectedUser.id)
          .collection('userChats')
          .document(widget.chatId)
          .collection('chats')
          .document(postId)
          .setData({
        "sender": widget.currentUser.id,
        "receiver": widget.selectedUser.id,
        "timestamp": DateTime.now(),
        "url": url,
        "type": "image"
      });
    }
  }

  void onVideoRecordingButtonPressed() {
    startVideoRecording().then((_filePath) {
      if (mounted) {
        setState(() {
          file = File(_filePath);
        });
      }
    });
  }

  Future<String> startVideoRecording() async {
    final tempDir = await getTemporaryDirectory();
    String filePath = "${tempDir.path}/${DateTime.now()}.mp4";

    await cameraController.startVideoRecording(filePath);
    print("Video recording started");
    return filePath;
  }

  void onVideoStopButtonPressed() {
    stopVideoRecording().then((_) {
      if (mounted) {
        print("video stopped");
        setState(() {
          isPhoto = false;
          filePath = file.path;
        });
      }
    });
  }

  Future<void> stopVideoRecording() async {
    if (cameraController.value.isRecordingVideo) {
      await cameraController.stopVideoRecording();
    }
    await startVideoPlayer();
  }

  Future<void> startVideoPlayer() async {
    videoPlayerController = VideoPlayerController.file(file);
    listener = () {
      if (videoPlayerController != null &&
          videoPlayerController.value.size != null) {
        if (mounted) setState(() {});
        videoPlayerController.removeListener(listener);
      }
    };
    videoPlayerController.addListener(listener);
    await videoPlayerController.initialize();
    await videoPlayerController.setLooping(true);
    await videoPlayerController.play();
  }

  void onPauseButtonPressed() {
    pauseVideoRecording().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> pauseVideoRecording() async {
    if (cameraController.value.isRecordingVideo) {
      await cameraController.pauseVideoRecording();
    }
  }

  void onResumeButtonPressed() {
    resumeVideoRecording().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> resumeVideoRecording() async {
    if (cameraController.value.isRecordingPaused) {
      await cameraController.resumeVideoRecording();
    }
  }

  void sendVideo() async {
    String postId = DateTime.now().millisecondsSinceEpoch.toString();
    if (widget.chatId != null && file != null) {
      Firestore.instance
          .collection('chats')
          .document(widget.currentUser.id)
          .collection('userChats')
          .document(widget.chatId)
          .collection('chats')
          .document(postId)
          .setData({
        "sender": widget.currentUser.id,
        "receiver": widget.selectedUser.id,
        "timestamp": DateTime.now(),
        "url": "",
        "type": "video"
      });
      Navigator.of(context).pop();
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
            .add({"message": "sent a video", "timestamp": DateTime.now()});
      }
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
        "lastMessage": "You: sent a video",
        "chatId": widget.chatId
      });
      Firestore.instance
          .collection('chats')
          .document(widget.selectedUser.id)
          .collection('userChats')
          .document(widget.chatId)
          .collection('chats')
          .document(postId)
          .setData({
        "sender": widget.currentUser.id,
        "receiver": widget.selectedUser.id,
        "timestamp": DateTime.now(),
        "url": "",
        "type": "video"
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
        "lastMessage": "${widget.currentUser.displayName}: sent a video",
        "chatId": widget.chatId
      });
      final bytes= await VideoThumbnail.thumbnailData(
        video: filePath,
      );
      StorageUploadTask uploadTask =
          FirebaseStorage.instance.ref().child("message_$postId").putFile(file);
      StorageTaskSnapshot snapshot = await uploadTask.onComplete;
      String url = await snapshot.ref.getDownloadURL();
      print(url);
      StorageUploadTask uploadTaskthumbnail = FirebaseStorage.instance
          .ref()
          .child("thumbnail_$postId")
          .putData(bytes);
      StorageTaskSnapshot snapshotthumbnail=await uploadTaskthumbnail.onComplete;
      String thumbnailUrl=await snapshotthumbnail.ref.getDownloadURL();
      createVideoMessageinFirestore(url: url, postId: postId,thumbnailUrl: thumbnailUrl);
    }
  }

  void createVideoMessageinFirestore({String url, String postId,String thumbnailUrl}) {
    if (widget.chatId != null) {
      Firestore.instance
          .collection('chats')
          .document(widget.currentUser.id)
          .collection('userChats')
          .document(widget.chatId)
          .collection('chats')
          .document(postId)
          .setData({
        "sender": widget.currentUser.id,
        "receiver": widget.selectedUser.id,
        "timestamp": DateTime.now(),
        "url": url,
        "type": "video",
        "thumbnailUrl":thumbnailUrl
      });
      Firestore.instance
          .collection('chats')
          .document(widget.selectedUser.id)
          .collection('userChats')
          .document(widget.chatId)
          .collection('chats')
          .document(postId)
          .setData({
        "sender": widget.currentUser.id,
        "receiver": widget.selectedUser.id,
        "timestamp": DateTime.now(),
        "url": url,
        "type": "video",
        "thumbnailUrl":thumbnailUrl
      });
    }
  }
}
