import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel{
  final String id;
  final String email;
  final String username;
  final String photoUrl;
  final String displayName;
  final String bio;
  final bool isPrivate;
  UserModel({this.username,this.photoUrl,this.displayName,this.email,this.id,this.bio,this.isPrivate});

  factory UserModel.fromDocument(DocumentSnapshot doc){
    return UserModel(
      id: doc['id'],
      displayName: doc['displayName'],
      bio: doc['bio'],
      email: doc['email'],
      photoUrl: doc['photoUrl'],
      username: doc['username'],
      isPrivate: doc['isPrivate']
    );
  }
}
