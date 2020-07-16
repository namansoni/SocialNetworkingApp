import 'dart:io';
import 'package:audioplayers/audio_cache.dart';
import 'package:autostart/autostart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialnetworking/Models/UserModel.dart';
import 'package:socialnetworking/Page/ActivityFeed.dart';
import 'package:socialnetworking/Page/CreateUserAccount.dart';
import 'package:socialnetworking/Page/Profile.dart';
import 'package:socialnetworking/Page/Timeline.dart';
import 'package:socialnetworking/Page/Upload.dart';
import 'package:socialnetworking/Widgets/colors.dart';
import 'package:socialnetworking/Widgets/custom_image.dart';
import 'package:socialnetworking/main.dart';
import 'Search.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'Calling/pickup_layout.dart';

class Home extends StatefulWidget {
  var cameras;
  Home({this.cameras});
  @override
  _HomeState createState() => _HomeState();
}

final GoogleSignIn googleSignIn = GoogleSignIn();
final usersRef = Firestore.instance.collection('users');
final storageRef = FirebaseStorage.instance.ref();
final postRef = Firestore.instance.collection('posts');
UserModel currentUser;

class _HomeState extends State<Home> {
  bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;
  bool isLoading = false;

  FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  SharedPreferences sharedPreferences;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getAutoStartPermissions();
    pageController = PageController();
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    });
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }, onError: (error) {
      print("SingIn Error: $error");
    });
    var android = new AndroidInitializationSettings('mipmap/ic_launcher');
    var ios = new IOSInitializationSettings();
    var initSettings = new InitializationSettings(android, ios);
    flutterLocalNotificationsPlugin.initialize(initSettings,
        onSelectNotification: onSelectNotification);
  }

  void getAutoStartPermissions() async {
    sharedPreferences = await SharedPreferences.getInstance();
    bool isAutoStartGiven = await sharedPreferences.getBool('isAutoStartGiven');
    if (isAutoStartGiven == null || isAutoStartGiven == false) {
      showDialog(
          context: context,
          barrierDismissible: false,
          child: AlertDialog(
            title: Text("Enable Autostart"),
            content:
                Text("This app will work properly if you allow autostart."),
            actions: <Widget>[
              FlatButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text("Okay"),
                onPressed: () async {
                  Navigator.of(context).pop();
                  Autostart.getAutoStartPermission();
                  await sharedPreferences.setBool('isAutoStartGiven', true);
                },
              ),
            ],
          ));
    }
  }

  Future<dynamic> onSelectNotification(String payload) {
    print("payload $payload");
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isAuth
        ? PickupLayout(
            scaffold: AuthenticatedWidget(),
            currentUser: currentUser,
          )
        : UnauthenticatedWidget();
  }

  Widget AuthenticatedWidget() {
    return Scaffold(
      body: PageView(
        children: <Widget>[
          Timeline(currentuser: currentUser, cameras: widget.cameras),
          ActivityFeed(),
          Upload(
            currentUser: currentUser,
          ),
          Search(),
          Profile(
            profileId: currentUser?.id,
          ),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        onTap: onTap,
        color: Colors.grey[900],
        buttonBackgroundColor:Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).canvasColor,
        height: 50,
        items: <Widget>[
          Icon(
            Icons.whatshot,
            size: 30,
          ),
          Icon(
            Icons.notifications_active,
            size: 30,
          ),
          Icon(
            Icons.photo_camera,
            size: 30,
          ),
          Icon(
            Icons.search,
            size: 30,
          ),
          CircleAvatar(
            radius: 15,
            backgroundImage: CachedNetworkImageProvider(currentUser.photoUrl),
          )
        ],
      ),
    );
  }

  Scaffold UnauthenticatedWidget() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "InstaShare",
              style: TextStyle(fontFamily: "Signatra", fontSize: 90),
            ),
            GestureDetector(
              onTap: () {
                login();
              },
              child: Container(
                width: 200,
                height: 50,
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Image.asset('assets/images/google_signin_button.png'),
              ),
            )
          ],
        ),
      ),
    );
  }

  void login() {
    googleSignIn.signIn();
  }

  void logout() {
    googleSignIn.signOut();
    setState(() {
      isAuth = false;
    });
  }

  void handleSignIn(GoogleSignInAccount account) async {
    setState(() {
      isLoading = true;
    });
    if (account != null) {
      print(account);
      await createUserInFirebase();
      setState(() {
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      isAuth = false;
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> createUserInFirebase() async {
    final user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(user.id).get();
    if (!doc.exists) {
      final username = await Navigator.push(context,
          MaterialPageRoute(builder: (context) => CreateUserAccount()));
      print(username);
      usersRef.document(user.id).setData({
        "id": user.id,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        'username': username,
        'bio': "",
        'timeStamp': DateTime.now(),
        'isPrivate': true
      });
    }
    doc = await usersRef.document(user.id).get();
    currentUser = UserModel.fromDocument(doc);
    print(currentUser.email);
    Firestore.instance
        .collection('chattingWith')
        .document(currentUser.id)
        .setData({"id": ""});
  }

  void onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  void onTap(int pageIndex) {
    pageController.jumpToPage(pageIndex);
  }

  void configurePushNotifications() {
    final user = googleSignIn.currentUser;
    if (Platform.isIOS) getiosPermissions();

    firebaseMessaging.getToken().then((token) {
      print("Firebase messagin token: $token");
      Firestore.instance.collection('users').document(user.id).updateData({
        "androidNotificationToken": token,
      });
      firebaseMessaging.configure(
        onLaunch: (Map<String, dynamic> message) async {},
        onResume: (Map<String, dynamic> message) async {},
        onMessage: (Map<String, dynamic> message) async {
          showNotification(message);
        },
      );
    });
  }

  void getiosPermissions() {
    firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(alert: true, badge: true, sound: true));
    firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("Settings registered $settings");
    });
  }

  void showNotification(Map<String, dynamic> message) async {
    print("Notification Shown");
    print(message);
    List<String> lines = message['notification']['body'].toString().split('\n');
    InboxStyleInformation inboxStyleInformation = InboxStyleInformation(
      lines,
    );
    var android = new AndroidNotificationDetails(
        'channel Id', 'channel Name', 'description',
        importance: Importance.Max,
        priority: Priority.High,
        playSound: true,
        styleInformation: inboxStyleInformation,
        ticker: 'ticker',
        enableLights: true);
    var ios = new IOSNotificationDetails();
    var platform = new NotificationDetails(android, ios);
    Firestore.instance
        .collection('chattingWith')
        .document(currentUser.id)
        .get()
        .then((value) async {
      if (value.data['id'] != message['data']['senderId']) {
        await flutterLocalNotificationsPlugin.show(
            int.parse(message['data']['senderId'].toString().substring(2, 5)),
            message['notification']['title'] == "New Message"
                ? "New Message"
                : "Alert",
            message['notification']['body'],
            platform);
      }
    });
  }
}
