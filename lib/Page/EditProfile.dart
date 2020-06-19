import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:socialnetworking/Models/UserModel.dart';
import 'package:socialnetworking/Page/Home.dart';
import 'package:socialnetworking/Page/Timeline.dart';

class EditProfile extends StatefulWidget {
  String currentUserId;
  @override
  _EditProfileState createState() => _EditProfileState();

  EditProfile({this.currentUserId});
}

class _EditProfileState extends State<EditProfile> {
  bool isLoading = false;
  UserModel currentUser = null;
  TextEditingController displayNameController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool displayNameValid = true;
  bool usernameValid = true;
  bool bioValid = true;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    final doc = await usersRef.document(widget.currentUserId).get();
    UserModel user = UserModel.fromDocument(doc);
    setState(() {
      displayNameController.text = user.displayName;
      userNameController.text = user.username;
      bioController.text = user.bio;
      currentUser = user;
      isLoading = false;
    });
  }

  buildEditForm() {
    if (currentUser != null) {
      return SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.only(left: 20, right: 20, top: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Hero(
                tag: "dash",
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage:
                      CachedNetworkImageProvider(currentUser.photoUrl),
                ),
              ),
              TextFormField(
                controller: displayNameController,
                decoration: InputDecoration(
                    errorText:
                        displayNameValid ? null : "Display name too short",
                    labelText: "Name",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)))),
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: userNameController,
                decoration: InputDecoration(
                    errorText: usernameValid ? null : "Username is too short",
                    labelText: "Username",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)))),
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: bioController,
                decoration: InputDecoration(
                    errorText: bioValid ? null : "Bio is too long",
                    labelText: "Bio",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)))),
              ),
              SizedBox(
                height: 10,
              ),
              GestureDetector(
                onTap: logout,
                child: Container(
                  width: 165,
                  height: 30,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  child: Center(child: Text("Logout")),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.clear),
          color: Colors.black,
        ),
        title: Text(
          "Edit your profile",
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: updateProfileData,
            icon: Icon(Icons.check),
            color: Colors.black,
          )
        ],
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30))),
                child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator()),
              ),
            )
          : buildEditForm(),
    );
  }

  void updateProfileData() {
    setState(() {
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.trim().isEmpty
          ? displayNameValid = false
          : displayNameValid = true;
      userNameController.text.trim().length < 3 ||
              userNameController.text.trim().isEmpty
          ? usernameValid = false
          : usernameValid = true;
      bioController.text.length > 50 ? bioValid = false : bioValid = true;
    });
    if (displayNameValid && usernameValid && bioValid) {
      usersRef.document(widget.currentUserId).updateData({
        "displayName": displayNameController.text,
        "username": userNameController.text,
        "bio": bioController.text,
      });
      SnackBar snackBar = SnackBar(
        content: Text("Profile Updated.."),
      );
      scaffoldKey.currentState.showSnackBar(snackBar);
      Timer(Duration(seconds: 2), () {
        Navigator.of(context).pop();
      });
    }
  }

  void logout() {
    googleSignIn.signOut();
    //set user offline
    Firestore.instance.collection('usersStatus').document(widget.currentUserId).setData({
        "status":"offline",
        "id":widget.currentUserId
      },);
    Navigator.of(context).pop();
  }
}
