import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:socialnetworking/Page/Home.dart';
import 'package:socialnetworking/Page/Profile.dart';
import 'package:socialnetworking/Page/post_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:socialnetworking/Page/Calling/pickup_layout.dart';
import 'package:socialnetworking/Page/FollowRequests.dart';

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
          title: Text(
            "Activity Feed",
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
          return Container(
            child: Center(child: Container(
                height: 20,
                width: 20,
                child: CircularProgressIndicator())),
          );
        }
        if (snapshot.hasError) {
          return Card(
            child: Text("No data found"),
          );
        }
        return ListView.builder(
          itemCount: snapshot.data.documents.length+1,
          itemBuilder: (context, index) {
            if(index==0){
              return Container(
                child: GestureDetector(
                  onTap: (){
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) => FollowRequests()
                        )
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: new BorderRadius.circular(5.0),
                      color: Theme.of(context).cardColor,
                    ),
                    child: ListTile(
                      title: RichText(
                        text: TextSpan(
                            text: "Follow Requests",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            )
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios,size: 25.0,),
                    ),
                  ),
                ),
              );
            }
            if (snapshot.data.documents[index-1]['type'] != 'follow' && snapshot.data.documents[index-1]['type'] != 'accepted') {
              return ListTile(
                leading: GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) => Profile(
                              profileId: snapshot.data.documents[index-1]
                              ['userId'],
                            )));
                  },
                  child: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(
                        snapshot.data.documents[index-1]['userProfileImage']),
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
                            text: snapshot.data.documents[index-1]['username'],
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                               )),
                        TextSpan(
                            text: snapshot.data.documents[index-1]['type'] ==
                                "comment"
                                ? " commented "
                                : " liked your post",
                            style: TextStyle(color: Colors.grey))
                      ]),
                    ),
                    snapshot.data.documents[index-1]['type'] == "comment"
                        ? RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey),
                        text: snapshot.data.documents[index-1]['comment'],
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
                              postId: snapshot.data.documents[index-1]
                              ['postId'],
                              userId: currentUser.id,
                            )));
                  },
                  child: Container(
                      width: 50,
                      height: 50,
                      child: Image.network(
                          snapshot.data.documents[index-1]['mediaUrl'])),
                ),
                subtitle: Text(timeago.format(
                    snapshot.data.documents[index-1]['timestamp'].toDate())),
              );
            }
            return ListTile(
              leading: GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) => Profile(
                            profileId: snapshot.data.documents[index-1]
                            ['userId'],
                          )));
                },
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(
                      snapshot.data.documents[index-1]['userProfileImage']),
                ),
              ),
              title: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(children: [
                  TextSpan(
                    text: snapshot.data.documents[index-1]['username'],
                    style: TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                      text: snapshot.data.documents[index-1]['type'] ==
                          "follow"
                          ? " started following you "
                          : " accepted your follow request",
                      style: TextStyle(color: Colors.grey))
                ]),
              ),
              subtitle: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                    text: timeago.format(
                        snapshot.data.documents[index-1]['timestamp'].toDate()),
                    style: TextStyle(color: Colors.grey)),
              ),
            );
          },
        );
      },
    );
  }
}
