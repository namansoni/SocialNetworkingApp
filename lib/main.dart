
import 'package:flutter/material.dart';
import 'package:socialnetworking/Page/CreateUserAccount.dart';

import 'Page/Home.dart';

void main(){
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
      routes: {
        'CreateUserAccount': (ctx)=>CreateUserAccount(),
      },
    );
  }
}
