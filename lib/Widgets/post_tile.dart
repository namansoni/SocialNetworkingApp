import 'package:flutter/material.dart';
import 'package:socialnetworking/Widgets/custom_image.dart';
import 'package:socialnetworking/Widgets/post.dart';
class PostTile extends StatefulWidget {
  final Post post;

  @override
  _PostTileState createState() => _PostTileState();
  PostTile({this.post});
}

class _PostTileState extends State<PostTile> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=>print("showing post"),
      child: cachedNetworkimage(widget.post.mediaUrl),
    );
  }
}
