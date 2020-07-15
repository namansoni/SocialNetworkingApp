import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

Widget cachedNetworkimage(String mediaUrl) {
  return CachedNetworkImage(
    imageUrl: mediaUrl,
    fit: BoxFit.cover,
    width: double.infinity,
    placeholder: (context, url) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: 30),
          child: Container(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 1)),
        ),
      );
    },
    errorWidget: (context, url, error) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: 30),
          child: Container(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 1)),
        ),
      );
    },
  );
}
