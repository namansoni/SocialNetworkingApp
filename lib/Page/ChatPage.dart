import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:socialnetworking/Models/UserModel.dart';
import 'package:socialnetworking/Page/ChatScreen.dart';
import 'package:socialnetworking/Page/SearchChat.dart';
import 'package:socialnetworking/Widgets/colors.dart';
import 'package:socialnetworking/Page/Calling/pickup_layout.dart';

class ChatPage extends StatefulWidget {
  UserModel currentUser;
  List<String> followersId;
  var cameras;
  ChatPage({this.currentUser, this.followersId, this.cameras});
  @override
  _ChatpageState createState() => _ChatpageState();
}

class _ChatpageState extends State<ChatPage> {
  List<int> countUnreadMessages = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PickupLayout(
      currentUser: widget.currentUser,
      scaffold: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back,),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Direct",
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              buildSearchBar(),
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 10),
                child: Text(
                  "Messages",
                  style: TextStyle(color: Colors.blueGrey[400], fontSize: 18),
                ),
              ),
              buildChats()
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: EdgeInsets.only(left: 20, top: 20, right: 20),
      child: OpenContainer(
        closedColor: Theme.of(context).canvasColor,
        closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        transitionDuration: Duration(milliseconds: 500),
        openBuilder: (context, action) => SearchChat(
          currentUser: widget.currentUser,
          followersId: widget.followersId,
        ),
        closedBuilder: (context, action) => Container(
            height: 45,
            width: double.infinity,
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.search,
                      color: Colors.grey[100],
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      "Search",
                      style: TextStyle(color: Colors.grey[100], fontSize: 20),
                    )
                  ],
                ),
              ),
            )),
      ),
    );
  }

  Widget buildChats() {
    return StreamBuilder(
      stream: Firestore.instance
          .collection('chats')
          .document(widget.currentUser.id)
          .collection('userChats')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ));
        }
        if (snapshot.hasError) {
          return Text("Has Error");
        } else {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            child: ListView.builder(
              itemBuilder: (context, index) {
                UserModel selectedUser =
                    UserModel.fromDocument(snapshot.data.documents[index]);
                return GestureDetector(
                   onTap: (){
                     Navigator.push(context,MaterialPageRoute(builder: (context) => ChatScreen(
                        cameras: widget.cameras,
                        currentUser: widget.currentUser,
                        selectedUser: selectedUser,
                      ),));
                   },
                    child: ListTile(
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundImage: CachedNetworkImageProvider(
                                selectedUser.photoUrl),
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: StreamBuilder(
                                stream: Firestore.instance
                                    .collection("usersStatus")
                                    .where("id", isEqualTo: selectedUser.id)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return SizedBox(
                                      width: 2,
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return IconButton(
                                      icon: Icon(Icons.error),
                                      onPressed: () {},
                                    );
                                  } else {
                                    if (snapshot.data.documents[0]['status'] ==
                                        'online') {
                                      return Stack(
                                        children: <Widget>[
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Container(
                                              height: 20,
                                              width: 20,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Card(
                                            elevation: 6,
                                            color: Colors.green,
                                            child: Container(
                                              height: 12,
                                              width: 12,
                                            ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      return SizedBox(
                                        width: 0,
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                          title: Text(
                            selectedUser.displayName,
                            style: TextStyle(fontSize: 18),
                          ),
                          subtitle: Container(
                            height: 15,
                            child: Text(
                              snapshot.data.documents[index]['lastMessage'],
                              style: TextStyle(
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: StreamBuilder(
                            stream: Firestore.instance
                                .collection('unreadChats')
                                .document(widget.currentUser.id)
                                .collection('unreadchats')
                                .document(
                                    snapshot.data.documents[index]['chatId'])
                                .collection(
                                    snapshot.data.documents[index]['chatId'])
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container(
                                  width: 2,
                                  height: 2,
                                );
                              }
                              if (snapshot.hasError) {
                                return Container(width: 2, height: 2);
                              }
                              if (snapshot.data.documents.length == 0 ||
                                  snapshot.data.documents.length == null) {
                                return Container(width: 2, height: 2);
                              }
                              return Card(
                                elevation: 6,
                                color: Colors.green,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 2, bottom: 2, right: 10, left: 10),
                                  child: Text(
                                    snapshot.data.documents.length.toString(),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    );
              },
              itemCount: snapshot.data.documents.length,
            ),
          );
        }
      },
    );
  }
}
