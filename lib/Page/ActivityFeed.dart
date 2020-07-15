import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:socialnetworking/Page/Home.dart';
import 'package:socialnetworking/Page/Profile.dart';
import 'package:socialnetworking/Page/post_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:socialnetworking/Page/Calling/pickup_layout.dart';

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  @override
  Widget build(BuildContext context) {
    return PickupLayout(
      currentUser: currentUser,
      scaffold: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.white,
          title: Text(
            "Activity Feed",
            style: TextStyle(color: Colors.black),
          ),
        ),
        body: buildActivityFeed(),
      ),
    );
  }

  buildActivityFeed() {
    return StreamBuilder(
      stream: Firestore.instance
          .collection('feed')
          .document(currentUser.id)
          .collection('feedItems')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            elevation: 6,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Card(
            child: Text("No data found"),
          );
        }
        return ListView.builder(
          itemCount: snapshot.data.documents.length,
          itemBuilder: (context, index) {
            if (snapshot.data.documents[index]['type'] != 'follow') {
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
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(children: [
                        TextSpan(
                            text: snapshot.data.documents[index]['username'],
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        TextSpan(
                            text: snapshot.data.documents[index]['type'] ==
                                    "comment"
                                ? " commented "
                                : " liked your post",
                            style: TextStyle(color: Colors.grey))
                      ]),
                    ),
                    snapshot.data.documents[index]['type'] == "comment"
                        ? RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: TextStyle(color: Colors.grey),
                              text: snapshot.data.documents[index]['comment'],
                            ),
                          )
                        : Container()
                  ],
                ),
                trailing: GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) => PostScreen(
                                  postId: snapshot.data.documents[index]
                                      ['postId'],
                                  userId: currentUser.id,
                                )));
                  },
                  child: Container(
                      width: 50,
                      height: 50,
                      child: Image.network(
                          snapshot.data.documents[index]['mediaUrl'])),
                ),
                subtitle: Text(timeago.format(
                    snapshot.data.documents[index]['timestamp'].toDate())),
              );
            }
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
                text: TextSpan(children: [
                  TextSpan(
                    text: snapshot.data.documents[index]['username'],
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  TextSpan(
                      text: "  started following you",
                      style: TextStyle(color: Colors.grey))
                ]),
              ),
              subtitle: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                    text: timeago.format(
                        snapshot.data.documents[index]['timestamp'].toDate()),
                    style: TextStyle(color: Colors.grey)),
              ),
            );
          },
        );
      },
    );
  }
}
