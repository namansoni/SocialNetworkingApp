import 'dart:async';

import 'package:flutter/material.dart';

class CreateUserAccount extends StatefulWidget {
  @override
  _CreateUserAccountState createState() => _CreateUserAccountState();
}

class _CreateUserAccountState extends State<CreateUserAccount> {
  String username;
  final formKey=GlobalKey<FormState>();
  final ScaffoldKey=GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (){},
      child: Scaffold(
        key: ScaffoldKey,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text("Create Your Account"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  TextFormField(
                    onSaved: (val)=>username=val,
                    autovalidate: true,
                    validator: (val){
                      if(val.trim().length<3 || val.isEmpty){
                        return "Username must be of length greater than 3";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10))),hintText: "It must be unique",labelText: "Username"),
                  ),
                  Container(
                    margin: EdgeInsets.all(10),
                    width: 290,
                    height: 50,
                    child: RaisedButton(
                      onPressed: submit,
                      color: Colors.blue,
                      child: Text("Submit",style: TextStyle(color: Colors.white),),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  void submit(){
    if(formKey.currentState.validate()){
      formKey.currentState.save();
      SnackBar snackBar=SnackBar(content: Text("Welcome $username"),);
      ScaffoldKey.currentState.showSnackBar(snackBar);
      Timer(Duration(seconds: 2),(){
        Navigator.pop(context,username);
      });
    }

  }

}
