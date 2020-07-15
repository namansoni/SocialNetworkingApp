import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialnetworking/Models/UserModel.dart';
import 'package:socialnetworking/Page/ChatPage.dart';
import 'package:socialnetworking/Page/Home.dart';
import 'package:socialnetworking/Widgets/colors.dart';
import 'package:socialnetworking/Widgets/post.dart';
import 'package:socialnetworking/main.dart';
import 'Calling/pickup_layout.dart';
import 'Profile.dart';
import 'Calling/pickup_layout.dart';

class Timeline extends StatefulWidget {
  UserModel currentuser;
  var cameras;
  @override
  _TimelineState createState() => _TimelineState();

  Timeline({this.currentuser,this.cameras});
}

class _TimelineState extends State<Timeline> with WidgetsBindingObserver {
  List<Post> posts = [];
  List<String> _followersId = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getUserTimeline();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("from resumed");
      print(widget.currentuser.id);
      Firestore.instance
          .collection('usersStatus')
          .document(widget.currentuser.id)
          .setData(
        {"status": "online", "id": widget.currentuser.id},
      );
    } else {
      print("from not resumed");
      print(widget.currentuser.id);
      Firestore.instance
          .collection('usersStatus')
          .document(widget.currentuser.id)
          .setData(
        {"status": "offline", "id": widget.currentuser.id},
      );
    }
  }

  Future<void> getUserTimeline() async {
    QuerySnapshot timelineposts = await Firestore.instance
        .collection("timeline")
        .document(widget.currentuser.id)
        .collection("timelinePosts")
        .orderBy("timestamp", descending: true)
        .getDocuments();
    QuerySnapshot snapshot = await Firestore.instance
        .collection('Followers')
        .document(widget.currentuser.id)
        .collection('usersFollower')
        .getDocuments();
    List<Post> post1 =
        timelineposts.documents.map((doc) => Post.fromDocument(doc)).toList();
    List<String> followersId =
        snapshot.documents.map((doc) => doc.documentID).toList();
    setState(() {
      posts = post1;
      _followersId = followersId;
    });
    //setUser satus online or offline
    print("get Timeline");
    Firestore.instance
        .collection('usersStatus')
        .document(widget.currentuser.id)
        .setData(
      {"status": "online", "id": widget.currentuser.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    return PickupLayout(
      currentUser: currentUser,
      scaffold: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.camera_alt,
            size: 30,

          ),
          onPressed: () {},
          color: Colors.black
        ),
        centerTitle: true,
        title: Text(
          "InstaShare",
          style: TextStyle(
              fontFamily: 'Signatra', fontSize: 35, color: Colors.black),
        ),
        actions: <Widget>[
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Stack(
              children: <Widget>[
                Transform.rotate(
                    angle: -22 / 40,
                    child: IconButton(
                        icon: Icon(
                          Icons.send,
                          color: Colors.black,
                          size: 30,
                        ),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                        currentUser: currentUser,
                                        followersId: _followersId,
                                        cameras:widget.cameras
                                      )));
                        })),
              ],
            ),
          )
        ],
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        backgroundColor: Colors.white,
          onRefresh: () => getUserTimeline(), child: buildTimeline()),
    ),);
  }

  buildTimeline() {
    if (posts == null) {
      return CircularProgressIndicator();
    }
    if (posts.isEmpty) {
      return ListView(
        children: <Widget>[
          Container(
            color: colors.mainBackgroundColor,
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.1,
            child: Padding(
              padding: const EdgeInsets.only(left: 22, top: 22),
              child: Text(
                "Suggestions",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ),
          Container(
            color: colors.mainBackgroundColor,
              height: MediaQuery.of(context).size.height * 0.9,
              child: buildSuggestionforUser())
        ],
      );
    }
    return ListView(
      children: posts,
    );
  }

  StreamBuilder buildSuggestionforUser() {
    return StreamBuilder(
      stream: Firestore.instance
          .collection('users')
          .orderBy("timeStamp", descending: false)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return CircularProgressIndicator();
        }
        return ListView.builder(
          itemCount: snapshot.data.documents.length,
          itemBuilder: (context, index) {
            UserModel user =
                UserModel.fromDocument(snapshot.data.documents[index]);
            return user.id != currentUser.id
                ? ListTile(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (ctx) => Profile(
                                    profileId: user.id,
                                  )));
                    },
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage:
                          CachedNetworkImageProvider(user.photoUrl),
                    ),
                    title: RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        text: user.displayName,
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                    subtitle: RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                          text: user.username,
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : Container();
          },
        );
      },
    );
  }
}
