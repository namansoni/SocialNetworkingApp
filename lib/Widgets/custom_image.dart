
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';


Widget cachedNetworkimage(String mediaUrl){
  return CachedNetworkImage(
    imageUrl: mediaUrl,
    fit: BoxFit.fill,
    height: 300,
    width: double.infinity,
    placeholder: (context,url){
      return Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      );
    },
    errorWidget: (context,url,error){
      return  Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      );
    },
  );
}