import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:socialnetworking/Models/UserModel.dart';
import 'package:socialnetworking/Page/ChatScreen.dart';
import 'package:socialnetworking/Widgets/colors.dart';
import 'Calling/pickup_layout.dart';

class SearchChat extends StatefulWidget {
  UserModel currentUser;
  List<String> followersId;
  SearchChat({this.currentUser, this.followersId});
  @override
  _SearchChatState createState() => _SearchChatState();
}

class _SearchChatState extends State<SearchChat> {
  Future<QuerySnapshot> searchedUser;
  Future<QuerySnapshot> followers;
  String currentSearchingValue;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getFollowersDetails();
  }

  @override
  Widget build(BuildContext context) {
    return PickupLayout(
      currentUser: widget.currentUser,
     scaffold: Scaffold(
      backgroundColor: colors.mainBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            SafeArea(
              child: Container(
                color: colors.mainBackgroundColor,
                margin: EdgeInsets.only(top: 30),
                width: MediaQuery.of(context).size.width,
                height: 50,
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.black.withOpacity(0.9),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Container(
                        padding: EdgeInsets.only(bottom:5),
                        color: colors.mainBackgroundColor,
                        height: 50,
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Card(
                          elevation: 6,
                          child: Row(
                            children: <Widget>[
                              SizedBox(width: 10,),
                              Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.6,
                                child: TextFormField(
                                  onChanged: (value) {
                                    handleSearch(value);
                                  },
                                  decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "Search",
                                      hintStyle: TextStyle(fontSize: 20)),
                                ),
                              )
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            searchedUser == null
                ? followers == null ? Text("No Followers") : emptyBody()
                : buildSearchResults()
          ],
        ),
      ),
     ),
    );
  }

  FutureBuilder emptyBody() {
    return FutureBuilder(
      future: followers,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: EdgeInsets.all(10),
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          );
        }
        if (snapshot.hasError) {
          return Text("Has Error");
        } else {
          List<UserModel> followersDetails = [];
          snapshot.data.documents.forEach((doc) {
            UserModel singlefollowerDetails = UserModel.fromDocument(doc);
            followersDetails.add(singlefollowerDetails);
          });
          return Container(
            color: colors.mainBackgroundColor,
            height: MediaQuery.of(context).size.height * 0.9,
            child: ListView.builder(
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ChatScreen(
                                  currentUser: widget.currentUser,
                                  selectedUser: followersDetails[index],
                                )));
                  },
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber,
                    backgroundImage: CachedNetworkImageProvider(
                        followersDetails[index].photoUrl),
                  ),
                  title: Text(followersDetails[index].displayName),
                  subtitle: Text(followersDetails[index].username),
                );
              },
              itemCount: followersDetails.length,
            ),
          );
        }
      },
    );
  }

  FutureBuilder buildSearchResults() {
    return FutureBuilder(
      future: searchedUser,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
              color: colors.mainBackgroundColor,
              margin: EdgeInsets.only(left: 50, top: 10),
              padding: EdgeInsets.all(3),
              child: Row(
                children: <Widget>[
                  Container(
                    height: 15,
                    width: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text("Searching for user \"$currentSearchingValue\"")
                ],
              ));
        }
        if (snapshot.hasError) {
          return Text("Has Error");
        } else {
          List<UserModel> users = [];
          snapshot.data.documents.forEach((doc) {
            UserModel user = UserModel.fromDocument(doc);
            if (widget.currentUser.id != user.id) {
              users.add(user);
            }
          });
          if (users.length == 0) {
            return Text("No Result Found",style: TextStyle(color: Colors.grey[500],fontSize: 18),);
          } else {
            return Container(
              color: colors.mainBackgroundColor,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.9,
              child: ListView.builder(
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                    currentUser: widget.currentUser,
                                    selectedUser: users[index],
                                  )));
                    },
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber,
                      backgroundImage:
                          CachedNetworkImageProvider(users[index].photoUrl),
                    ),
                    title: Text(users[index].displayName),
                    subtitle: Text(users[index].username),
                  );
                },
                itemCount: users.length,
              ),
            );
          }
        }
      },
    );
  }

  void handleSearch(String value) {
    setState(() {
      currentSearchingValue = value;
    });
    if (value.isNotEmpty) {
      Future<QuerySnapshot> users = Firestore.instance
          .collection('users')
          .where("displayName", isGreaterThanOrEqualTo: value)
          .limit(50)
          .getDocuments();
      setState(() {
        searchedUser = users;
      });
    } else {
      searchedUser = null;
    }
  }

  void getFollowersDetails() {
    Future<QuerySnapshot> followers1 = Firestore.instance
        .collection('users')
        .where("id", whereIn: widget.followersId)
        .limit(50)
        .getDocuments();
    setState(() {
      followers = followers1;
    });
  }
}
