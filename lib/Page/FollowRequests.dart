import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'Calling/pickup_layout.dart';
import 'Home.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'Profile.dart';

class FollowRequests extends StatefulWidget {
  @override
  _FollowRequestsState createState() => _FollowRequestsState();
}

class _FollowRequestsState extends State<FollowRequests> {
  @override
  Widget build(BuildContext context) {
    return PickupLayout(
      currentUser: currentUser,
      scaffold: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Follow Requests",
          ),
        ),
        body: buildRequestList(),
      ),
    );
  }

  buildRequestList() {
    return StreamBuilder(
      stream: Firestore.instance
          .collection('Followers')
          .document(currentUser.id)
          .collection('followRequests')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Container(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Container(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return ListView.builder(
          itemCount: snapshot.data.documents.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) => Profile(
                                profileId: snapshot.data.documents[index]
                                    ['userId'],
                              )));
                },
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(
                      snapshot.data.documents[index]['userProfileImage']),
                ),
              ),
              title: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                    text: snapshot.data.documents[index]['username'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    )),
              ),
              subtitle: Text(
                timeago.format(
                    snapshot.data.documents[index]['timestamp'].toDate()),
                style: TextStyle(color: Colors.grey[500]),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  GestureDetector(
                    child: Container(
                      padding: EdgeInsets.all(8),
                      child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: "Confirm",
                          )),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: new BorderRadius.circular(5),
                      ),
                    ),
                    onTap: () {
                      followUser(snapshot.data.documents[index]['userId']);
                    },
                  ),
                  GestureDetector(
                    onTap: () {
                      deleteRequest(snapshot.data.documents[index]['userId']);
                    },
                    child: Container(
                      padding: EdgeInsets.only(left: 5),
                      child: Icon(
                        Icons.clear,
                        size: 20,
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  followUser(String userId) {
    deleteRequest(userId);
    Firestore.instance
        .collection('Followers')
        .document(currentUser.id)
        .collection('usersFollower')
        .document(userId)
        .setData({});
    Firestore.instance
        .collection('Following')
        .document(userId)
        .collection('usersFollowing')
        .document(currentUser.id)
        .setData({});
    Firestore.instance
        .collection('feed')
        .document(userId)
        .collection('feedItems')
        .document(currentUser.id+"accepted")
        .setData({
      "type": "accepted",
      "ownerId": userId,
      "username": currentUser.username,
      "userId": currentUser.id,
      "userProfileImage": currentUser.photoUrl,
      "timestamp": DateTime.now()
    });
    Firestore.instance.collection('users').document(userId).get().then((value) {
      Firestore.instance
          .collection('feed')
          .document(currentUser.id)
          .collection('feedItems')
          .document(userId+"follow")
          .setData({
        "type": "follow",
        "ownerId": currentUser.id,
        "username": value['username'],
        "userId": userId,
        "userProfileImage": value['photoUrl'],
        "timestamp": DateTime.now()
      });
    });
  }

  deleteRequest(String userId) {
    Firestore.instance
        .collection('Followers')
        .document(currentUser.id)
        .collection('followRequests')
        .document(userId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    Firestore.instance
        .collection('Following')
        .document(userId)
        .collection('Requested')
        .document(currentUser.id)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }
}
