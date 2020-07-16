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
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.of(context).pop();
                },
            ),
            title: Text(
              "Follow Requests",
              style: TextStyle(color: Colors.black),
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
          return Card(
            child: Text("No Follow Requests"),
          );
        }
        if (snapshot.hasError) {
          return Card(
            child: Text("No Follow Requests"),
          );
        }
        return ListView.builder(
          itemCount: snapshot.data.documents.length,
          itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Card(

                    child: Row(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (ctx) => Profile(
                                    profileId: snapshot.data.documents[index]
                                    ['userId'],
                                    currentUser: currentUser,
                                  )));
                        },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(
                                snapshot.data.documents[index]['userProfileImage']),
                        ),
                          ),
                      ),
                        SizedBox(width:10.0),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              RichText(
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                    text: snapshot.data.documents[index]['username'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      fontSize: 20.0
                                    )
                                ),
                              ),
                              SizedBox(
                                height: 5.0,
                              ),
                              Text(timeago.format(
                                  snapshot.data.documents[index]['timestamp'].toDate())
                              ),
                            ]
                        ),
                        SizedBox(
                          width: 35.0,
                        ),
                        GestureDetector(

                          child: Container(
                            padding: EdgeInsets.all(5.0),
                            child: RichText(
                              text: TextSpan(
                                text:"Confirm",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17.0
                                )
                              ),
                            ),
                            decoration: BoxDecoration(
                              borderRadius: new BorderRadius.circular(10.0),
                              border: Border.all()
                            ),
                          ),
                          onTap: (){
                            followUser(snapshot.data.documents[index]['userId']);
                          },
                        ),
                        SizedBox(width: 15.0,),
                        GestureDetector(
                          onTap: (){deleteRequest(snapshot.data.documents[index]['userId']);},
                          child: Container(
                            padding: EdgeInsets.all(5.0),
                            child: Icon(Icons.delete_outline,color: Colors.white,),
                            decoration: BoxDecoration(
                              borderRadius: new BorderRadius.circular(10.0),
                              color: Colors.redAccent,
                            ),
                          ),
                        )
                      ],
                    )
                  ),
                ),
              );
          },
        );
      },
    );
  }
  followUser(String userId)
  {
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
        .document(currentUser.id)
        .setData({
      "type": "accepted",
      "ownerId": userId,
      "username": currentUser.username,
      "userId": currentUser.id,
      "userProfileImage": currentUser.photoUrl,
      "timestamp": DateTime.now()
    });
  }
  deleteRequest(String userId)
  {
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
