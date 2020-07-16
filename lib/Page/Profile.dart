import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:socialnetworking/Models/UserModel.dart';
import 'package:socialnetworking/Page/Home.dart';
import 'package:socialnetworking/Widgets/colors.dart';
import 'package:socialnetworking/Widgets/post.dart';
import 'package:socialnetworking/Widgets/post_tile.dart';

import 'EditProfile.dart';

class Profile extends StatefulWidget {
  String profileId;

  @override
  _ProfileState createState() => _ProfileState();

  Profile({this.profileId});
}

class _ProfileState extends State<Profile> {
  bool isLoading = false;
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  String postOrientation = "grid";
  List<Post> posts = [];
  bool isFollowing = false;
  bool hasRequested =false;
  bool isPrivate = true;


  FutureBuilder buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text("No data found");
        } else {
          UserModel user = UserModel.fromDocument(snapshot.data);
          isPrivate=user.isPrivate;
          return Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Hero(
                        tag: "dash",
                        child: Padding(
                          padding: const EdgeInsets.only(right: 50),
                          child: CircleAvatar(
                            backgroundImage:
                            CachedNetworkImageProvider(user.photoUrl),
                            radius: 40,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                buildCountColumn(
                                    postCount: postCount.toString()),
                                buildFollowersColumn(
                                    followersCount: followersCount.toString()),
                                buildFollowingColumn(
                                    followingCount: followingCount.toString())
                              ],
                            ),
                            width: MediaQuery.of(context).size.width * 0.6,
                            height: 50,
                          ),
                          SizedBox(height: 10),
                          buildEditProfile(),
                        ],
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user.displayName,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      Container(
                          width: 100,
                          height: MediaQuery.of(context).size.height * 0.1,
                          padding: EdgeInsets.only(top: 5, bottom: 5),
                          child: Text(
                            user.bio,
                            style: TextStyle(color: Colors.grey),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Profile",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: (){
          setState(() { });
          return Future.value(false);},
        child: StreamBuilder(
          stream: Firestore.instance.collection('users').document(widget.profileId).snapshots(),
          builder: (context,snapshot){
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
              isPrivate=snapshot.data.data['isPrivate']==null?false:snapshot.data.data['isPrivate'];
            return buildWidget();
          },

        ),
      ),
    );
  }

  Widget buildWidget()
  {
    if(isPrivate && !isFollowing && widget.profileId!=currentUser.id){
      return ListView(
        shrinkWrap: true,
        children: <Widget>[
          Container(
              height: MediaQuery.of(context).size.height * 0.28,
              width: MediaQuery.of(context).size.width,
              child: buildProfileHeader()),
          Divider(
            height: 2.0,
          ),
          Container(
            margin: EdgeInsets.fromLTRB(10.0,15.0,5.0,0.0),
            height: MediaQuery
                .of(context)
                .size
                .height * 0.10,
            width: double.infinity,
            child: Row(
              children: <Widget>[
                Icon(Icons.lock_outline,size: 50.0,),
                SizedBox(width: 20.0,),
                Column(
                  children: <Widget>[
                    Text(
                      'This Account is Private',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0
                      ),
                    ),
                    Text(
                      'Follow This Account to see their posts.',
                      style: TextStyle(
                          fontSize: 15.0
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            height: 2.0,
          ),
        ],
      );
    }
    else{
      return ListView(
        shrinkWrap: true,
        children: <Widget>[
          Container(
              height: MediaQuery.of(context).size.height * 0.28,
              width: MediaQuery.of(context).size.width,
              child: buildProfileHeader()
          ),
          buildTogglePostOrientation(),
          Divider(
            height: 2.0,
          ),
          Container(
            height: MediaQuery
                .of(context)
                .size
                .height * 0.53,
            width: double.infinity,
            child: buildProfilePosts(),
          ),
        ],
      );
    }
  }

  Column buildCountColumn({String postCount}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Text(
          postCount,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 25,
          ),
        ),
        Text(
          "Posts",
          style: TextStyle(color: Colors.grey),
        )
      ],
    );
  }

  Column buildFollowersColumn({String followersCount}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Text(followersCount,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 25)),
        Text(
          "Followers",
          style: TextStyle(color: Colors.grey),
        )
      ],
    );
  }

  Column buildFollowingColumn({String followingCount}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Text(followingCount,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 25)),
        Text(
          "Following",
          style: TextStyle(color: Colors.grey),
        )
      ],
    );
  }

  buildButton({String text, Function function}) {
    return GestureDetector(
      onTap: function,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: 30,
        decoration: BoxDecoration(
            border: Border.all(
                color: isFollowing || hasRequested? Colors.grey : Colors.blueAccent),
            color: isFollowing ?Colors.white : ( hasRequested?Colors.grey.shade200:Colors.blue),
            borderRadius: BorderRadius.all(Radius.circular(8))),
        child: Center(
            child: Text(
              text,
              style: TextStyle(color: isFollowing ? Colors.black : hasRequested?Colors.grey.shade700: Colors.white),
            )),
      ),
    );
  }

  void editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (ctx) => EditProfile(
              currentUserId: currentUser.id,
            )));
  }

  buildEditProfile() {
    if (widget.profileId == currentUser.id) {
      return buildButton(text: "Edit Profile", function: editProfile);
    } else {
      return isFollowing
          ? buildButton(text: "Unfollow", function: unFollowaUser)
          : (isPrivate && hasRequested)
          ? buildButton(text: "Requested", function: requestedAction):
            buildButton(text: "Follow", function: followaUser);
    }
  }

  void followaUser() {
    if(!isPrivate)
    {
      setState(() {
        isFollowing = true;
        followersCount = followersCount + 1;
      });
      Firestore.instance
          .collection('Followers')
          .document(widget.profileId)
          .collection('usersFollower')
          .document(currentUser.id)
          .setData({});
      Firestore.instance
          .collection('Following')
          .document(currentUser.id)
          .collection('usersFollowing')
          .document(widget.profileId)
          .setData({});
      Firestore.instance
          .collection('feed')
          .document(widget.profileId)
          .collection('feedItems')
          .document(currentUser.id)
          .setData({
        "type": "follow",
        "ownerId": widget.profileId,
        "username": currentUser.username,
        "userId": currentUser.id,
        "userProfileImage": currentUser.photoUrl,
        "timestamp": DateTime.now()
      });
    }
    else{
      setState(() {
        hasRequested=true;
      });
      Firestore.instance
          .collection('Followers')
          .document(widget.profileId)
          .collection('followRequests')
          .document(currentUser.id)
          .setData({
        "ownerId": widget.profileId,
        "username": currentUser.username,
        "userId": currentUser.id,
        "userProfileImage": currentUser.photoUrl,
        "timestamp": DateTime.now()
      });
      Firestore.instance
          .collection('Following')
          .document(currentUser.id)
          .collection('Requested')
          .document(widget.profileId)
          .setData({
        "ownerId": widget.profileId,
        "username": currentUser.username,
        "userId": currentUser.id,
        "userProfileImage": currentUser.photoUrl,
        "timestamp": DateTime.now()
      });
    }
  }

  void unFollowaUser() {
    setState(() {
      isFollowing = false;
      followersCount = followersCount - 1;
    });
    Firestore.instance
        .collection('Followers')
        .document(widget.profileId)
        .collection('usersFollower')
        .document(currentUser.id)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    Firestore.instance
        .collection('Following')
        .document(currentUser.id)
        .collection('usersFollowing')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    Firestore.instance
        .collection('feed')
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUser.id)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }
  requestedAction()
  {
    setState(() {
      hasRequested=false;
    });
    Firestore.instance
        .collection('Followers')
        .document(widget.profileId)
        .collection('followRequests')
        .document(currentUser.id)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    Firestore.instance
        .collection('Following')
        .document(currentUser.id)
        .collection('Requested')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  buildProfilePosts() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (posts.isEmpty) {
      return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          child: SvgPicture.asset('assets/images/upload.svg'));
    } else if (postOrientation == "grid") {
      List<Container> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200])),
          child: GridTile(
            child: PostTile(post: post),
          ),
        ));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOrientation == "list") {
      return Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: ListView(
          shrinkWrap: true,
          children: posts,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
    checkIfRequested();
  }

  void getFollowers() async {
    QuerySnapshot followers = await Firestore.instance
        .collection('Followers')
        .document(widget.profileId)
        .collection('usersFollower')
        .getDocuments();
    followersCount = followers.documents.length;
  }

  void getFollowing() async {
    QuerySnapshot following = await Firestore.instance
        .collection('Following')
        .document(widget.profileId)
        .collection('usersFollowing')
        .getDocuments();
    followingCount = following.documents.length;
  }

  void checkIfFollowing() async {
    DocumentSnapshot doc = await Firestore.instance
        .collection('Followers')
        .document(widget.profileId)
        .collection('usersFollower')
        .document(currentUser.id)
        .get();
    if (doc.exists) {
      setState(() {
        isFollowing = true;
      });
    } else {
      setState(() {
        isFollowing = false;
      });
    }
  }

  void checkIfRequested() async {
    DocumentSnapshot doc = await Firestore.instance
        .collection('Followers')
        .document(widget.profileId)
        .collection('followRequests')
        .document(currentUser.id)
        .get();
    if (doc.exists) {
      setState(() {
        hasRequested = true;
      });
    } else {
      setState(() {
        hasRequested = false;
      });
    }
  }
  void getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    final postsnapshot = await Firestore.instance
        .collection('posts')
        .document(widget.profileId)
        .collection('UsersPost')
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = postsnapshot.documents.length;
      posts = postsnapshot.documents.map((doc) {
        return Post.fromDocument(doc);
      }).toList();
    });
  }

  buildTogglePostOrientation() {
    return Container(
      color: colors.mainBackgroundColor,
      child: Column(
        children: <Widget>[
          Divider(
            height: 2.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(
                color: postOrientation == "grid" ? Colors.blue : Colors.grey,
                icon: Icon(
                  Icons.grid_on,
                  size: 30,
                ),
                onPressed: () {
                  setState(() {
                    postOrientation = "grid";
                  });
                },
              ),
              IconButton(
                color: postOrientation == "list" ? Colors.blue : Colors.grey,
                icon: Icon(
                  Icons.list,
                  size: 30.0,
                ),
                onPressed: () {
                  setState(() {
                    postOrientation = "list";
                  });
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}
