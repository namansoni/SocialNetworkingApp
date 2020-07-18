import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'Home.dart';
import 'package:socialnetworking/Page/Calling/pickup_layout.dart';
class Comment extends StatefulWidget {
  final String postId;
  final String postownerId;
  final String postmediaUrl;

  @override
  _CommentState createState() => _CommentState();

  Comment({this.postId, this.postmediaUrl, this.postownerId});
}

class _CommentState extends State<Comment> {
  TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return PickupLayout(
      currentUser: currentUser,
      scaffold: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.clear),
            onPressed: (){
              Navigator.of(context).pop();
            },
          ),
          title: Text("Comments",),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: buildComments(),
            ),
            Divider(),
            ListTile(
                title: TextFormField(
                  controller: commentController,
                  decoration: InputDecoration(labelText: "Write a comment..."),
                ),
                trailing: OutlineButton(
                  onPressed: addComment,
                  child: Text("Post"),
                  borderSide: BorderSide.none,
                ))
          ],
        ),
      ),
    );
  }

  buildComments() {
    return StreamBuilder(
      stream: Firestore.instance
          .collection('comments')
          .document(widget.postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Text("No Comments yet...");
        }
        return ListView.builder(
          reverse: true,
          itemCount: snapshot.data.documents.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(
                    snapshot.data.documents[index]['avatarUrl']),
              ),
              title: Row(
                children: <Widget>[
                  Text(snapshot.data.documents[index]['username']+"  ",style: TextStyle(fontWeight: FontWeight.bold),),
                  Expanded(
                    child: Text(snapshot.data.documents[index]['comment']),
                  ),
                ],
              ),
              subtitle: Text(timeago.format(snapshot.data.documents[index]['timestamp'].toDate())),
            );
          },
        );
      },
    );
  }

  void addComment() {
    Firestore.instance
        .collection('comments')
        .document(widget.postId)
        .collection('comments')
        .add({
      "username": currentUser.username,
      "comment": commentController.text,
      "timestamp": DateTime.now(),
      "avatarUrl": currentUser.photoUrl,
      "userId": currentUser.id
    });
    if(currentUser.id!=widget.postownerId){
      Firestore.instance.collection('feed').document(widget.postownerId).collection('feedItems').add({
        "type":"comment",
        "comment":commentController.text,
        "username":currentUser.username,
        "userId":currentUser.id,
        "userProfileImage":currentUser.photoUrl,
        "postId":widget.postId,
        "mediaUrl":widget.postmediaUrl,
        "timestamp":DateTime.now()

      });
    }
    commentController.clear();
  }
}
