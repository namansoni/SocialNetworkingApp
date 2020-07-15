import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shimmer/flutter_shimmer.dart';
import 'package:socialnetworking/Models/UserModel.dart';
import 'package:socialnetworking/Page/Comment.dart';
import 'package:socialnetworking/Page/Home.dart';
import 'package:socialnetworking/Page/Profile.dart';
import 'package:socialnetworking/Widgets/custom_image.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post(
      {this.postId,
      this.ownerId,
      this.username,
      this.location,
      this.description,
      this.mediaUrl,
      this.likes});

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      description: doc['caption'],
      likes: doc['likes'],
      location: doc['location'],
      mediaUrl: doc['mediaUrl'],
      ownerId: doc['ownerId'],
      username: doc['username'],
    );
  }

  int getLikesCount(Map likes) {
    if (likes == null) {
      return null;
    }
    int count = 0;
    likes.values.forEach((val) {
      if (val == true) {
        count = count + 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        location: this.location,
        username: this.username,
        description: this.description,
        likeCounts: getLikesCount(this.likes),
        likes: this.likes,
        mediaUrl: this.mediaUrl,
        ownerId: this.ownerId,
        postId: this.postId,
      );
}

class _PostState extends State<Post> {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  int likeCounts;
  Map likes;

  _PostState(
      {this.postId,
      this.ownerId,
      this.username,
      this.location,
      this.description,
      this.mediaUrl,
      this.likes,
      this.likeCounts});

  String currentuserId = currentUser?.id;
  bool isLiked;
  bool showHeart = false;

  @override
  Widget build(BuildContext context) {
    isLiked = likes[currentuserId] == true;
    return Container(
      color: Colors.white,
      child: Column(
        children: <Widget>[
          buildPostHeader(),
          buildPostImage(),
          buildPostFooter(),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Divider(
              height: 2.0,
            ),
          )
        ],
      ),
    );
  }

  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: 200,
            height: 62,
            child: ListTileShimmer(
              hasCustomColors: true,
              colors: [
                // Dark color
                Color(0xFF1769aa),
                // light color
                Color(0xFF4dabf5),
                // Medium color
                Color(0xFF2196f3)
              ],
            ),
          );
        }
        UserModel postOwner = UserModel.fromDocument(snapshot.data);
        return Container(
          height: 62,
          color: Colors.white,
          child: ListTile( 
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(postOwner.photoUrl),
              radius: 20,
              backgroundColor: Colors.grey,
            ),
            title: GestureDetector(
                onTap: () {
                  if (ownerId != currentUser.id) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) => Profile(
                                  profileId: ownerId,
                                )));
                  }
                },
                child: Text(
                  postOwner.username,
                  style:
                      TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                )),
            subtitle: location != "" ? Text(location) : null,
            trailing: ownerId == currentUser.id
                ? IconButton(
                    icon: Icon(Icons.delete_outline),
                    onPressed: () {
                      ShowDialog();
                    },
                  )
                : Text(""),
          ),
        );
      },
    );
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top:6),
            child: cachedNetworkimage(mediaUrl),
          ),
          showHeart
              ? Animator<double>(
                  duration: Duration(milliseconds: 300),
                  cycles: 0,
                  tween: Tween<double>(begin: 10, end: 100),
                  curve: Curves.elasticOut,
                  builder: (context, animatorState, child) => Center(
                    child: Icon(
                      Icons.favorite,
                      size: animatorState.value,
                      color: Colors.white,
                    ),
                  ),
                )
              : Container()
        ],
      ),
    );
  }

  buildPostFooter() {
    return Container(
      color: Colors.white,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                color: Colors.red[600],
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 28.0,
                ),
                onPressed: handleLikePost,
              ),
              IconButton(
                color: Colors.blue,
                icon: Icon(
                  Icons.comment,
                  size: 28.0,
                ),
                onPressed: () {
                  showComments(
                      context: context,
                      postId: postId,
                      ownerId: ownerId,
                      mediaUrl: mediaUrl);
                },
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              children: <Widget>[
                Text(
                  "$likeCounts likes",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                )
              ],
            ),
          ),
          description != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 10, top: 5),
                  child: Row(
                    children: <Widget>[
                      Text(
                        "$username ",
                        style:
                            TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text("$description")
                    ],
                  ),
                )
              : Container()
        ],
      ),
    );
  }

  void handleLikePost() {
    bool _isLiked = likes[currentuserId] == true;
    if (_isLiked) {
      Firestore.instance
          .collection('posts')
          .document(ownerId)
          .collection('UsersPost')
          .document(postId)
          .updateData({
        "likes.$currentuserId": false,
      });
      removeLikefromActivityFeed();
      setState(() {
        isLiked = false;
        likeCounts = likeCounts - 1;
        likes[currentuserId] = false;
      });
    } else if (!_isLiked) {
      Firestore.instance
          .collection('posts')
          .document(ownerId)
          .collection('UsersPost')
          .document(postId)
          .updateData({
        "likes.$currentuserId": true,
      });
      addLiketoActivityFeed();
      setState(() {
        isLiked = true;
        likeCounts = likeCounts + 1;
        likes[currentuserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  void showComments(
      {BuildContext context, String postId, String ownerId, String mediaUrl}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Comment(
                  postId: postId,
                  postmediaUrl: mediaUrl,
                  postownerId: ownerId,
                )));
  }

  void addLiketoActivityFeed() {
    if (currentUser.id != ownerId) {
      Firestore.instance
          .collection('feed')
          .document(ownerId)
          .collection('feedItems')
          .add({
        "type": "like",
        "username": currentUser.username,
        "userId": currentUser.id,
        "userProfileImage": currentUser.photoUrl,
        "postId": postId,
        "mediaUrl": mediaUrl,
        "timestamp": DateTime.now()
      });
    }
  }

  void removeLikefromActivityFeed() async {
    if (currentUser.id != ownerId) {
      QuerySnapshot querySnapshot = await Firestore.instance
          .collection('feed')
          .document(ownerId)
          .collection('feedItems')
          .where("postId", isEqualTo: postId)
          .getDocuments();
      querySnapshot.documents.forEach((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  void ShowDialog() {
    showDialog(
        context: context,
        builder: (ctx) => SimpleDialog(
              title: Text("Remove this post?"),
              elevation: 6,
              children: <Widget>[
                SimpleDialogOption(
                  onPressed: () {
                    Navigator.of(context).pop();
                    deletePost();
                  },
                  child: Text("Delete post"),
                )
              ],
            ));
  }

  void deletePost() async {
    Firestore.instance
        .collection('posts')
        .document(ownerId)
        .collection('UsersPost')
        .document(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    storageRef.child("post_$postId.jpg").delete();

    QuerySnapshot activityFeedSnapshot = await Firestore.instance
        .collection('feed')
        .document(ownerId)
        .collection('feedItems')
        .where('postId', isEqualTo: postId)
        .getDocuments();
    activityFeedSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    QuerySnapshot commentssnapshot = await Firestore.instance
        .collection('comments')
        .document(postId)
        .collection('comments')
        .getDocuments();
    commentssnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }
}
