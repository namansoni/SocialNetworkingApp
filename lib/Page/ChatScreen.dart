import 'dart:io';
import 'dart:io' as io;
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_time_format/date_time_format.dart';
import 'package:file/local.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socialnetworking/Models/UserModel.dart';
import 'package:image/image.dart' as Im;
import 'package:socialnetworking/Page/ShareLocationScreen.dart';
import 'package:socialnetworking/Page/showSharedLocation.dart';
import 'package:socialnetworking/Widgets/customPopupMenu.dart';
import 'package:socialnetworking/Widgets/custom_image.dart';
import 'package:socialnetworking/Widgets/imageMessage.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

class ChatScreen extends StatefulWidget {
  UserModel currentUser;
  UserModel selectedUser;
  ChatScreen({this.currentUser, this.selectedUser});
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
  }

  @override
  void dispose() async {
    // TODO: implement dispose
    super.dispose();
    await _stopWatchTimer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                            sendImage(ImageSource.camera);
                          },
                          icon: Icon(
                            Icons.photo_camera,
                            size: 35,
                            color: Colors.blue,
                          )),
                      SizedBox(
                        width: 10,
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.4 - 4,
                        constraints: BoxConstraints(maxHeight: 200),
                        child: TextFormField(
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
                          sendImage(ImageSource.gallery);
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
              return CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text("Has Error");
            }
            snapshot.data.documents.forEach((value) {
              isPlaying.add(false);
              audioPlayer.add(AudioPlayer());
              _duration.add(Duration());
              _position.add(Duration());
            });

            return ListView.builder(
              itemBuilder: (context, index) {
                return snapshot.data.documents[index]['sender'] ==
                        widget.currentUser.id
                    ? Container(
                        decoration: BoxDecoration(
                            color: Colors.amber[200],
                            borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20))),
                        margin: EdgeInsets.only(
                            left: 80, right: 10, top: 10, bottom: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
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
                                        ? GestureDetector(
                                            onTap: () {
                                              Navigator.push(context,
                                                  MaterialPageRoute(
                                                      builder: (context) {
                                                return ImageMessage(
                                                    url: snapshot.data
                                                            .documents[index]
                                                        ['url']);
                                              }));
                                            },
                                            child: Hero(
                                              tag: snapshot
                                                  .data.documents[index]['url'],
                                              child: Container(
                                                child: cachedNetworkimage(
                                                    snapshot.data
                                                            .documents[index]
                                                        ['url']),
                                              ),
                                            ),
                                          )
                                        : snapshot.data.documents[index]
                                                    ['type'] ==
                                                "audio"
                                            ? buildAudioPlayerInChat(
                                                snapshot: snapshot,
                                                index: index)
                                            : buildLocationShowInChat(
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
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                    topRight: Radius.circular(20))),
                            margin: EdgeInsets.only(
                                left: 30, right: 80, top: 10, bottom: 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
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
                                            ? GestureDetector(
                                                onTap: () {
                                                  Navigator.push(context,
                                                      MaterialPageRoute(
                                                          builder: (context) {
                                                    return ImageMessage(
                                                        url: snapshot
                                                                .data.documents[
                                                            index]['url']);
                                                  }));
                                                },
                                                child: Hero(
                                                  tag: snapshot.data
                                                      .documents[index]['url'],
                                                  child: Container(
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
                                                : buildLocationShowInChat(
                                                    snapshot: snapshot,
                                                    index: index,
                                                  ),
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
                              padding: EdgeInsets.only(left: 10),
                              child: CircleAvatar(
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
              reverse: true,
            );
          },
        ),
      ),
    );
  }

  void sendMessage() {
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
        "lastMessage": message
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
        "lastMessage": message
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
      ..writeAsBytesSync(Im.encodeJpg(image, quality: 50));
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
              createAudioMessageInFirestore(url: "", id: audioId);
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
              activeColor: Colors.white,
              inactiveColor: Colors.blue,
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
      onTap: (){
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
}
