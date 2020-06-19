import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel{
  final String id;
  final String email;
  final String username;
  final String photoUrl;
  final String displayName;
  final String bio;
  UserModel({this.username,this.photoUrl,this.displayName,this.email,this.id,this.bio});

  factory UserModel.fromDocument(DocumentSnapshot doc){
    return UserModel(
      id: doc['id'],
      displayName: doc['displayName'],
      bio: doc['bio'],
      email: doc['email'],
      photoUrl: doc['photoUrl'],
      username: doc['username'],
    );
  }
}