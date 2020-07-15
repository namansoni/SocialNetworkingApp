import 'dart:io';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:animations/animations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_time_format/date_time_format.dart';
import 'package:file/local.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:socialnetworking/Models/UserModel.dart';
import 'package:image/image.dart' as Im;
import 'package:socialnetworking/Page/Imageandvideocapture.dart';
import 'package:socialnetworking/Page/ShareLocationScreen.dart';
import 'package:socialnetworking/Page/showSharedLocation.dart';
import 'package:socialnetworking/Page/videoScreen.dart';
import 'package:socialnetworking/Widgets/customPopupMenu.dart';
import 'package:socialnetworking/Widgets/custom_image.dart';
import 'package:socialnetworking/Widgets/imageMessage.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:socialnetworking/Page/Calling/pickup_layout.dart';

class ChatScreen extends StatefulWidget {
  UserModel currentUser;
  UserModel selectedUser;
  var cameras;

  ChatScreen({this.currentUser, this.selectedUser, this.cameras});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String chatId;
  TextEditingController messageController = TextEditingController();
  File file;
  String postId;
  bool isRecording = false;
  StopWatchTimer _stopWatchTimer = StopWatchTimer();
  var recorder;
  LocalFileSystem localFileSystem = LocalFileSystem();
  List<bool> isPlaying = [];
  List<AudioPlayer> audioPlayer = [];
  List<Duration> _duration = [];
  List<Duration> _position = [];
  List choices = [
    CustomPopupMenu(icon: Icons.map, title: "Share Your Location")
  ];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    createChatId();
    Firestore.instance
        .collection('unreadChats')
        .document(widget.currentUser.id)
        .collection('unreadchats')
        .document(chatId)
        .collection(chatId)
        .getDocuments()
        .then((value) {
      value.documents.forEach((element) {
        element.reference.delete();
      });
    });
    Firestore.instance
        .collection('chattingWith')
        .document(widget.currentUser.id)
        .setData({"id": widget.selectedUser.id});
    BackButtonInterceptor.add(myInterceptor);
  }

  @override
  void dispose() async {
    // TODO: implement dispose
    super.dispose();
    await _stopWatchTimer.dispose();
    audioPlayer.forEach((element) {
      element.stop();
    });
    BackButtonInterceptor.remove(myInterceptor);
  }

  bool myInterceptor(bool stopDefaultButtonEvent) {
    Firestore.instance
        .collection('chattingWith')
        .document(widget.currentUser.id)
        .setData({"id": ""});
    Navigator.of(context).pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PickupLayout(
      currentUser: widget.currentUser,
      scaffold: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: isRecording
                ? null
                : () {
                    Firestore.instance
                        .collection('chattingWith')
                        .document(widget.currentUser.id)
                        .setData({"id": ""});
                    Navigator.of(context).pop();
                  },
          ),
          title: ListTile(
            contentPadding: EdgeInsets.only(left: 0),
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.selectedUser.photoUrl),
            ),
            title: Text(widget.selectedUser.displayName),
            subtitle: Text(widget.selectedUser.username),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.videocam,
                color: Colors.black,
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(
                Icons.info_outline,
                color: Colors.black,
              ),
              onPressed: () {},
            ),
            PopupMenuButton(
              icon: Icon(
                Icons.more_vert,
                color: Colors.black,
              ),
              itemBuilder: (context) {
                return choices.map((choice) {
                  return PopupMenuItem(
                    value: choice,
                    child: Text(
                      choice.title,
                    ),
                  );
                }).toList();
              },
              onSelected: (value) {
                if (value.title == "Share Your Location") {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return ShareLocationScreen(
                      chatId: chatId,
                      currentUser: widget.currentUser,
                      selectedUser: widget.selectedUser,
                    );
                  }));
                }
              },
            )
          ],
        ),
        body: SingleChildScrollView(child: buildChats()),
       ),
    );
  }

  Widget buildChats() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.87,
      color: Colors.white,
      child: Column(
        children: <Widget>[
          ChatList(),
          isRecording
              ? buildRecordingBar()
              : Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey[200]),
                      borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      IconButton(
                          onPressed: () {
                            //sendImage(ImageSource.camera);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ImageandVideoCapture(
                                          cameras: widget.cameras,
                                          chatId: chatId,
                                          currentUser: widget.currentUser,
                                          selectedUser: widget.selectedUser,
                                        )));
                          },
                          icon: Icon(
                            Icons.photo_camera,
                            size: 35,
                            color: Colors.black,
                          )),
                      SizedBox(
                        width: 10,
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.4 - 4,
                        constraints: BoxConstraints(maxHeight: 200),
                        child: TextFormField(
                          focusNode: FocusNode(canRequestFocus: false),
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          style: TextStyle(color: Colors.black, fontSize: 18),
                          controller: messageController,
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Message..",
                              hintStyle: TextStyle(
                                  fontSize: 18, color: Colors.grey[500])),
                        ),
                      ),
                      GestureDetector(
                        onLongPressStart: (_) {
                          print("Long pressed");
                          setState(() {
                            isRecording = true;
                          });
                        },
                        child: Icon(
                          Icons.mic,
                          color: Colors.grey[900],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.insert_photo,
                          color: Colors.grey[900],
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  ListTile(
                                    leading: Icon(Icons.image),
                                    title: Text("Image"),
                                    onTap: () async {
                                      Navigator.of(context).pop();
                                      sendImage(ImageSource.gallery);
                                    },
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.videocam),
                                    title: Text("Video"),
                                    onTap: () async {
                                      Navigator.of(context).pop();
                                      File file = await ImagePicker.pickVideo(
                                          source: ImageSource.gallery);
                                      sendVideo(file);
                                    },
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.send,
                          color: Colors.grey[900],
                        ),
                        onPressed: () {
                          sendMessage();
                        },
                      )
                    ],
                  ),
                )
        ],
      ),
    );
  }

  Widget ChatList() {
    return Expanded(
      child: Container(
        height: MediaQuery.of(context).size.height - 148,
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: StreamBuilder(
          stream: Firestore.instance
              .collection('chats')
              .document(widget.currentUser.id)
              .collection('userChats')
              .document(chatId)
              .collection('chats')
              .orderBy("timestamp", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                  child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 6,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      )));
            }
            if (snapshot.hasError) {
              return Text("Has Error");
            }
            snapshot.data.documents.forEach((value) async {
              isPlaying.add(false);
              audioPlayer.add(AudioPlayer());
              _duration.add(Duration());
              _position.add(Duration());
            });

            return ScrollablePositionedList.builder(
              initialScrollIndex: 0,
              reverse: true,
              itemBuilder: (context, index) {
                return snapshot.data.documents[index]['sender'] ==
                        widget.currentUser.id
                    ? Card(
                        color: Color.fromRGBO(255, 250, 250, 1),
                        borderOnForeground: true,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8))),
                        elevation: 2,
                        margin: EdgeInsets.only(
                            left: 80, right: 10, top: 10, bottom: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding:
                                snapshot.data.documents[index]['type'] == "text"
                                    ? EdgeInsets.only(
                                        left: 15,
                                        top: 10,
                                        bottom: 10,
                                        right: 10)
                                    : EdgeInsets.only(
                                        left: 0, top: 0, bottom: 10, right: 0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                snapshot.data.documents[index]['type'] == "text"
                                    ? Text(
                                        snapshot.data.documents[index]
                                            ['message'],
                                        style: TextStyle(
                                            fontSize: 18, color: Colors.black),
                                      )
                                    : snapshot.data.documents[index]['type'] ==
                                            "image"
                                        ? OpenContainer(
                                            transitionDuration:
                                                Duration(milliseconds: 500),
                                            openBuilder: (context, action) =>
                                                ImageMessage(
                                                    url: snapshot.data
                                                            .documents[index]
                                                        ['url']),
                                            closedBuilder: (context, action) =>
                                                Container(
                                              constraints: BoxConstraints(
                                                  maxHeight: 150),
                                              child: cachedNetworkimage(snapshot
                                                  .data
                                                  .documents[index]['url']),
                                            ),
                                          )
                                        : snapshot.data.documents[index]
                                                    ['type'] ==
                                                "audio"
                                            ? buildAudioPlayerInChat(
                                                snapshot: snapshot,
                                                index: index)
                                            : snapshot.data.documents[index]
                                                        ['type'] ==
                                                    'location'
                                                ? buildLocationShowInChat(
                                                    snapshot: snapshot,
                                                    index: index)
                                                : buildVideoPlayerinChat(
                                                    snapshot: snapshot,
                                                    index: index),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 5, right: 10),
                                    child: Text(
                                      DateTimeFormat.format(
                                          DateTime.fromMillisecondsSinceEpoch(
                                              int.parse(snapshot
                                                      .data
                                                      .documents[index]
                                                          ['timestamp']
                                                      .seconds
                                                      .toString()) *
                                                  1000),
                                          format: 'D, M j, H:i'),
                                      style: TextStyle(
                                          color: Colors.black.withOpacity(0.3)),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: <Widget>[
                          Card(
                            elevation: 2,
                            color: Colors.blue[100],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                    bottomRight: Radius.circular(8))),
                            margin: EdgeInsets.only(
                                left: 30, right: 80, top: 10, bottom: 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: snapshot.data.documents[index]
                                            ['type'] ==
                                        "text"
                                    ? EdgeInsets.only(
                                        left: 15,
                                        top: 10,
                                        bottom: 10,
                                        right: 10)
                                    : EdgeInsets.only(
                                        left: 0, top: 0, bottom: 10, right: 0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    snapshot.data.documents[index]['type'] ==
                                            "text"
                                        ? Text(
                                            snapshot.data.documents[index]
                                                ['message'],
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.black),
                                          )
                                        : snapshot.data.documents[index]
                                                    ['type'] ==
                                                "image"
                                            ? OpenContainer(
                                                transitionDuration:
                                                    Duration(milliseconds: 500),
                                                openBuilder:
                                                    (context, action) =>
                                                        ImageMessage(
                                                            url: snapshot.data
                                                                    .documents[
                                                                index]['url']),
                                                closedBuilder:
                                                    (context, action) => Hero(
                                                  tag: snapshot.data
                                                      .documents[index]['url'],
                                                  child: Container(
                                                    constraints: BoxConstraints(
                                                        maxHeight: 150),
                                                    child: cachedNetworkimage(
                                                        snapshot.data.documents[
                                                            index]['url']),
                                                  ),
                                                ),
                                              )
                                            : snapshot.data.documents[index]
                                                        ['type'] ==
                                                    "audio"
                                                ? buildAudioPlayerInChat(
                                                    snapshot: snapshot,
                                                    index: index)
                                                : snapshot.data.documents[index]
                                                            ['type'] ==
                                                        'location'
                                                    ? buildLocationShowInChat(
                                                        snapshot: snapshot,
                                                        index: index,
                                                      )
                                                    : buildVideoPlayerinChat(
                                                        snapshot: snapshot,
                                                        index: index),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            top: 5, right: 10),
                                        child: Text(
                                          DateTimeFormat.format(
                                              DateTime
                                                  .fromMillisecondsSinceEpoch(
                                                      int.parse(snapshot
                                                              .data
                                                              .documents[index]
                                                                  ['timestamp']
                                                              .seconds
                                                              .toString()) *
                                                          1000),
                                              format: 'D, M j, H:i'),
                                          style: TextStyle(
                                              color: Color.fromRGBO(
                                                  95, 95, 95, 10)),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Container(
                              padding: EdgeInsets.only(left: 10, top: 5),
                              child: CircleAvatar(
                                  radius: 12,
                                  backgroundImage: CachedNetworkImageProvider(
                                      widget.selectedUser.photoUrl)),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          )
                        ],
                      );
              },
              itemCount: snapshot.data.documents.length,
            );
          },
        ),
      ),
    );
  }

  void sendMessage() async {
    String message = messageController.text;
    messageController.clear();
    if (chatId != null && message.isNotEmpty) {
      Firestore.instance
          .collection('chats')
          .document(widget.currentUser.id)
          .collection('userChats')
          .document(chatId)
          .collection('chats')
          .add({
        "sender": widget.currentUser.id,
        "receiver": widget.selectedUser.id,
        "timestamp": DateTime.now(),
        "message": message,
        "type": "text"
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
            .document(chatId)
            .collection(chatId)
            .add({"message": message, "timestamp": DateTime.now()});
      }
      Firestore.instance
          .collection('chats')
          .document(widget.currentUser.id)
          .collection('userChats')
          .document(chatId)
          .setData({
        "id": widget.selectedUser.id,
        "bio": widget.selectedUser.bio,
        "displayName": widget.selectedUser.displayName,
        "username": widget.selectedUser.username,
        "photoUrl": widget.selectedUser.photoUrl,
        "lastMessage": "You: " + message,
        "chatId": chatId
      });
      Firestore.instance
          .collection('chats')
          .document(widget.selectedUser.id)
          .collection('userChats')
          .document(chatId)
          .collection('chats')
          .add({
        "sender": widget.currentUser.id,
        "receiver": widget.selectedUser.id,
        "timestamp": DateTime.now(),
        "message": message,
        "type": "text"
      });
      Firestore.instance
          .collection('chats')
          .document(widget.selectedUser.id)
          .collection('userChats')
          .document(chatId)
          .setData({
        "id": widget.currentUser.id,
        "bio": widget.currentUser.bio,
        "displayName": widget.currentUser.displayName,
        "username": widget.currentUser.username,
        "photoUrl": widget.currentUser.photoUrl,
        "lastMessage": "${widget.currentUser.displayName}: " + message,
        "chatId": chatId
      });
    }
  }

  void sendImage(ImageSource source) async {
    setState(() {
      postId = DateTime.now().millisecondsSinceEpoch.toString();
    });
    File file1 = await ImagePicker.pickImage(
        source: source, maxHeight: 675, maxWidth: 960);
    if (chatId != null && file1 != null) {
      Firestore.instance
          .collection('chats')
          .document(widget.currentUser.id)
          .collection('userChats')
          .document(chatId)
          .collection('chats')
          .document(postId)
          .setData({
        "sender": widget.currentUser.id,
        "receiver": widget.selectedUser.id,
        "timestamp": DateTime.now(),
        "url": "",
        "type": "image"
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
            .document(chatId)
            .collection(chatId)
            .add({"message": "shares a image", "timestamp": DateTime.now()});
      }

      Firestore.instance
          .collection('chats')
          .document(widget.currentUser.id)
          .collection('userChats')
          .document(chatId)
          .setData({
        "id": widget.selectedUser.id,
        "bio": widget.selectedUser.bio,
        "displayName": widget.selectedUser.displayName,
        "username": widget.selectedUser.username,
        "photoUrl": widget.selectedUser.photoUrl,
        "lastMessage": "You: shared a image",
        "chatId": chatId
      });
      Firestore.instance
          .collection('chats')
          .document(widget.selectedUser.id)
          .collection('userChats')
          .document(chatId)
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
          .document(chatId)
          .setData({
        "id": widget.currentUser.id,
        "bio": widget.currentUser.bio,
        "displayName": widget.currentUser.displayName,
        "username": widget.currentUser.username,
        "photoUrl": widget.currentUser.photoUrl,
        "lastMessage": "${widget.currentUser.displayName}: shared a image",
        "chatId": chatId
      });
      setState(() {
        file = file1;
      });

      await compressImage();

      StorageUploadTask uploadTask =
          FirebaseStorage.instance.ref().child("message_$postId").putFile(file);
      StorageTaskSnapshot snapshot = await uploadTask.onComplete;
      String url = await snapshot.ref.getDownloadURL();

      createMessageinFirestore(url: url);
    }
  }

  void createChatId() {
    if (widget.currentUser.id.hashCode > widget.selectedUser.id.hashCode) {
      setState(() {
        chatId = widget.currentUser.id + widget.selectedUser.id;
      });
    } else {
      setState(() {
        chatId = widget.selectedUser.id + widget.currentUser.id;
      });
    }
  }

  Future<void> compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image image = Im.decodeImage(file.readAsBytesSync());
    final compressedImage = File("$path/img_$postId.jpg")
      ..writeAsBytesSync(Im.encodeJpg(image, quality: 80));
    setState(() {
      file = compressedImage;
    });
  }

  void createMessageinFirestore({String url}) {
    if (chatId != null) {
      Firestore.instance
          .collection('chats')
          .document(widget.currentUser.id)
          .collection('userChats')
          .document(chatId)
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
          .document(chatId)
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

  Widget buildRecordingBar() {
    startRecording();
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient:
              LinearGradient(colors: [Colors.lightBlue, Colors.blue[100]])),
      margin: EdgeInsets.all(8),
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          StreamBuilder<int>(
            stream: _stopWatchTimer.rawTime,
            initialData: 0,
            builder: (context, snapshot) {
              final value = snapshot.data;
              final displayTime = StopWatchTimer.getDisplayTime(value);
              return Text(displayTime);
            },
          ),
          IconButton(
            icon: Icon(Icons.stop),
            onPressed: () async {
              setState(() {
                isRecording = false;
              });
              _stopWatchTimer.onExecute.add(StopWatchExecute.stop);
              _stopWatchTimer.onExecute.add(StopWatchExecute.reset);
              var results = await recorder.stop();
              String audioId = DateTime.now().millisecondsSinceEpoch.toString();
              Firestore.instance
                  .collection('chats')
                  .document(widget.currentUser.id)
                  .collection('userChats')
                  .document(chatId)
                  .collection('chats')
                  .document(audioId)
                  .setData({
                "sender": widget.currentUser.id,
                "receiver": widget.selectedUser.id,
                "timestamp": DateTime.now(),
                "url": "",
                "type": "audio"
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
                    .document(chatId)
                    .collection(chatId)
                    .add({
                  "message": "sent a audio clip.",
                  "timestamp": DateTime.now()
                });
              }
              Firestore.instance
                  .collection('chats')
                  .document(widget.selectedUser.id)
                  .collection('userChats')
                  .document(chatId)
                  .collection('chats')
                  .document(audioId)
                  .setData({
                "sender": widget.currentUser.id,
                "receiver": widget.selectedUser.id,
                "timestamp": DateTime.now(),
                "url": "",
                "type": "audio"
              });

              Firestore.instance
                  .collection('chats')
                  .document(widget.currentUser.id)
                  .collection('userChats')
                  .document(chatId)
                  .setData({
                "id": widget.selectedUser.id,
                "bio": widget.selectedUser.bio,
                "displayName": widget.selectedUser.displayName,
                "username": widget.selectedUser.username,
                "photoUrl": widget.selectedUser.photoUrl,
                "lastMessage": "You: sent a audio clip",
                "chatId": chatId
              });
              Firestore.instance
                  .collection('chats')
                  .document(widget.selectedUser.id)
                  .collection('userChats')
                  .document(chatId)
                  .setData({
                "id": widget.currentUser.id,
                "bio": widget.currentUser.bio,
                "displayName": widget.currentUser.displayName,
                "username": widget.currentUser.username,
                "photoUrl": widget.currentUser.photoUrl,
                "lastMessage":
                    "${widget.currentUser.displayName}: sent a audio clip",
                "chatId": chatId
              });
              File file = localFileSystem.file(results.path);
              StorageUploadTask uploadTask = FirebaseStorage.instance
                  .ref()
                  .child("Audio")
                  .child("AudioMessage_${DateTime.now()}")
                  .putFile(file);
              StorageTaskSnapshot snapshot = await uploadTask.onComplete;
              String url = await snapshot.ref.getDownloadURL();
              createAudioMessageInFirestore(url: url, id: audioId);
            },
          )
        ],
      ),
    );
  }

  void startRecording() async {
    bool hasPermissions = await FlutterAudioRecorder.hasPermissions;
    if (hasPermissions) {
      _stopWatchTimer.onExecute.add(StopWatchExecute.start);
      _stopWatchTimer.rawTime.listen((event) {});
      io.Directory appDocDirectory = await getExternalStorageDirectory();
      String path = appDocDirectory.path +
          DateTime.now().millisecondsSinceEpoch.toString() +
          ".mp4";
      recorder = FlutterAudioRecorder(path, audioFormat: AudioFormat.AAC);
      await recorder.initialized;
      await recorder.start();
    }
  }

  void createAudioMessageInFirestore({String url, String id}) {
    if (chatId != null) {
      Firestore.instance
          .collection('chats')
          .document(widget.currentUser.id)
          .collection('userChats')
          .document(chatId)
          .collection('chats')
          .document(id)
          .setData({
        "sender": widget.currentUser.id,
        "receiver": widget.selectedUser.id,
        "timestamp": DateTime.now(),
        "url": url,
        "type": "audio"
      });
      Firestore.instance
          .collection('chats')
          .document(widget.selectedUser.id)
          .collection('userChats')
          .document(chatId)
          .collection('chats')
          .document(id)
          .setData({
        "sender": widget.currentUser.id,
        "receiver": widget.selectedUser.id,
        "timestamp": DateTime.now(),
        "url": url,
        "type": "audio"
      });
    }
  }

  Widget buildAudioPlayerInChat({var snapshot, int index}) {
    if (snapshot.data.documents[index]['url'] == "") {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: 30),
          child: Container(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 1)),
        ),
      );
    }
    audioPlayer[index].onPlayerStateChanged.listen((event) {
      if (event == AudioPlayerState.PAUSED) {
        setState(() {
          isPlaying[index] = false;
        });
      }
      if (event == AudioPlayerState.PLAYING) {
        setState(() {
          isPlaying[index] = true;
        });
      }
      if (event == AudioPlayerState.STOPPED) {
        setState(() {
          isPlaying[index] = false;
        });
      }
      if (event == AudioPlayerState.COMPLETED) {
        setState(() {
          isPlaying[index] = false;
          _position[index] = Duration();
          _duration[index] = Duration();
        });
      }
    });
    audioPlayer[index].onAudioPositionChanged.listen((event) {
      setState(() {
        _position[index] = event;
      });
    });
    audioPlayer[index].onDurationChanged.listen((event) {
      setState(() {
        _duration[index] = event;
      });
    });
    return Row(
      children: <Widget>[
        isPlaying[index]
            ? IconButton(
                icon: Icon(Icons.pause),
                onPressed: () async {
                  await audioPlayer[index].pause();
                },
              )
            : IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: () async {
                  await audioPlayer[index]
                      .play(snapshot.data.documents[index]['url']);
                }),
        Stack(
          alignment: Alignment.bottomRight,
          children: <Widget>[
            Slider(
              activeColor: Colors.black,
              inactiveColor: Colors.black12,
              value: _position[index].inMicroseconds.toDouble(),
              min: 0.0,
              max: _duration[index].inMicroseconds.toDouble(),
              onChanged: (value) {},
            ),
            Container(
              padding: EdgeInsets.only(right: 5),
              child: _duration[index].inSeconds == 0
                  ? Container()
                  : Text(
                      "${_duration[index].inSeconds - _position[index].inSeconds}",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
            )
          ],
        ),
      ],
    );
  }

  Widget buildLocationShowInChat({var snapshot, int index}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return ShowSharedLocation(
            location: snapshot.data.documents[index]['location'],
          );
        }));
      },
      child: Container(
        padding: EdgeInsets.only(left: 10, top: 15),
        child: Row(
          children: <Widget>[
            Image.asset(
              'assets/images/mapsimage.png',
              height: 30,
              width: 30,
            ),
            SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                snapshot.data.documents[index]['sender'] ==
                        widget.currentUser.id
                    ? Text("You shared your location")
                    : Text(
                        "${widget.selectedUser.displayName} shared his/her location."),
                Text(
                  "Tap to View",
                  style: TextStyle(color: Colors.grey[500]),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildVideoPlayerinChat({var snapshot, int index}) {
    if (snapshot.data.documents[index]['url'] == "") {
      return Container(
        constraints: BoxConstraints(maxHeight: 150),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: 30),
            child: Container(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 1)),
          ),
        ),
      );
    }
    return Container(
      constraints: BoxConstraints(maxHeight: 150),
      child: Stack(
        children: <Widget>[
          Container(
              constraints: BoxConstraints(maxHeight: 150),
              child: cachedNetworkimage(
                  snapshot.data.documents[index]['thumbnailUrl'])),
          Align(
              alignment: Alignment.center,
              child: OpenContainer(
                closedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                transitionDuration: Duration(milliseconds: 500),
                openBuilder: (context, action) => VideoScreen(
                  videoUrl: snapshot.data.documents[index]['url'],
                  thumbnailUrl: snapshot.data.documents[index]['thumbnailUrl'],
                ),
                closedBuilder: (context, action) => Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.play_circle_filled,
                    size: 40,
                    color: Colors.black54,
                  ),
                ),
              ))
        ],
      ),
    );
  }

  void sendVideo(File file) async {
    String postId = DateTime.now().millisecondsSinceEpoch.toString();
    if (file != null) {
      Firestore.instance
          .collection('chats')
          .document(widget.currentUser.id)
          .collection('userChats')
          .document(chatId)
          .collection('chats')
          .document(postId)
          .setData({
        "sender": widget.currentUser.id,
        "receiver": widget.selectedUser.id,
        "timestamp": DateTime.now(),
        "url": "",
        "type": "video"
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
            .document(chatId)
            .collection(chatId)
            .add({"message": "sent a video", "timestamp": DateTime.now()});
      }
      Firestore.instance
          .collection('chats')
          .document(widget.currentUser.id)
          .collection('userChats')
          .document(chatId)
          .setData({
        "id": widget.selectedUser.id,
        "bio": widget.selectedUser.bio,
        "displayName": widget.selectedUser.displayName,
        "username": widget.selectedUser.username,
        "photoUrl": widget.selectedUser.photoUrl,
        "lastMessage": "You: sent a video",
        "chatId": chatId
      });
      Firestore.instance
          .collection('chats')
          .document(widget.selectedUser.id)
          .collection('userChats')
          .document(chatId)
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
          .document(chatId)
          .setData({
        "id": widget.currentUser.id,
        "bio": widget.currentUser.bio,
        "displayName": widget.currentUser.displayName,
        "username": widget.currentUser.username,
        "photoUrl": widget.currentUser.photoUrl,
        "lastMessage": "${widget.currentUser.displayName}: sent a video",
        "chatId": chatId
      });
      final bytes = await VideoThumbnail.thumbnailData(
        video: file.path,
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
      StorageTaskSnapshot snapshotthumbnail =
          await uploadTaskthumbnail.onComplete;
      String thumbnailUrl = await snapshotthumbnail.ref.getDownloadURL();
      createVideoMessageinFirestore(
          url: url, postId: postId, thumbnailUrl: thumbnailUrl);
    }
  }

  void createVideoMessageinFirestore(
      {String url, String postId, String thumbnailUrl}) {
    if (chatId != null) {
      Firestore.instance
          .collection('chats')
          .document(widget.currentUser.id)
          .collection('userChats')
          .document(chatId)
          .collection('chats')
          .document(postId)
          .setData({
        "sender": widget.currentUser.id,
        "receiver": widget.selectedUser.id,
        "timestamp": DateTime.now(),
        "url": url,
        "type": "video",
        "thumbnailUrl": thumbnailUrl
      });
      Firestore.instance
          .collection('chats')
          .document(widget.selectedUser.id)
          .collection('userChats')
          .document(chatId)
          .collection('chats')
          .document(postId)
          .setData({
        "sender": widget.currentUser.id,
        "receiver": widget.selectedUser.id,
        "timestamp": DateTime.now(),
        "url": url,
        "type": "video",
        "thumbnailUrl": thumbnailUrl
      });
    }
  }
}
