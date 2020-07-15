import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:socialnetworking/Models/UserModel.dart';
import 'package:socialnetworking/Page/Home.dart';
import 'package:socialnetworking/Widgets/colors.dart';
import 'Calling/pickup_layout.dart';
import 'Profile.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> with AutomaticKeepAliveClientMixin<Search>{
  Future<QuerySnapshot> searchedUsers;
  final searchController = TextEditingController();
  String currentSearchingValue;

  AppBar buildSearchBar() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        autofocus: false,
        controller: searchController,
        onChanged: (val) {
          handleSearch(val);
        },
        decoration: InputDecoration(
            hintText: "Search for a user",
            filled: true,
            prefixIcon: Icon(
              Icons.search,
              size: 28,
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                searchController.clear();
              },
            )),
      ),
    );
  }

  Container NoContentBody() {
    return Container(
      color: colors.mainBackgroundColor,
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.all(10),
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/no_content.svg',
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
          ),
          Center(
              child: Text(
            "Find Users",
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w600),
          ))
        ],
      ),
    );
  }

  FutureBuilder BuildSearchResults() {
    return FutureBuilder(
      future: searchedUsers,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          print("Searching");
          return Container(
            padding: EdgeInsets.only(left: 50,top: 20),
            child: Row(
              children: <Widget>[
                Container(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    )),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                      width: MediaQuery.of(context).size.width-100,
                      child: Text(
                    "Searching $currentSearchingValue",
                    softWrap: true,
                    maxLines: 50,
                  )),
                )
              ],
            ),
          );
        }
        if (snapshot.hasError) {
           print("has Error");
          return Text("Not Found");
        } else {
          List<UserModel> searchedUsers = [];
          snapshot.data.documents.forEach((doc) {
            UserModel user = UserModel.fromDocument(doc);
            searchedUsers.add(user);
            print(user.username);
          });
          if(searchedUsers.length==0){
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("No result found for \"${currentSearchingValue}\""),
            );
          }
          return ListView(
            children: searchedUsers.map((user) {
              return Column(
                children: <Widget>[
                  ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey,
                      backgroundImage:
                          CachedNetworkImageProvider(user.photoUrl),
                    ),
                    title: Text(user.displayName),
                    subtitle: Text(user.username),
                    onTap: (){
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (ctx) => Profile(
                                profileId: user.id,
                              )));
                    },
                  ),
                  Divider(
                    height: 2.0,
                    indent: MediaQuery.of(context).size.width * 0.25,
                  )
                ],
              );
            }).toList(),
          );
        }
      },
    );
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    searchedUsers=null;
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PickupLayout(
      currentUser: currentUser,
     scaffold: Scaffold(
      backgroundColor: colors.mainBackgroundColor,
      appBar: buildSearchBar(),
      body: searchedUsers == null ? NoContentBody() : BuildSearchResults(),
    ),
   );
  }

  void handleSearch(String val) {
    if (val.isNotEmpty) {
      Future<QuerySnapshot> users = usersRef
          .where("displayName", isGreaterThanOrEqualTo: val)
          .getDocuments();
      setState(() {
        currentSearchingValue = val;
        searchedUsers = users;
      });
    }
    if (val.isEmpty) {
      setState(() {
        searchedUsers = null;
      });
    }
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => false;
}
