import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socialnetworking/Models/UserModel.dart';
import 'package:image/image.dart' as Im;

class Upload extends StatefulWidget {
  UserModel currentUser;
  Upload({this.currentUser});
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> with AutomaticKeepAliveClientMixin<Upload>{
  File imageFile = null;
  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  bool isLocation = false;
  bool isUploading = false;
  String postId = DateTime.now().millisecondsSinceEpoch.toString();
  @override
  Widget build(BuildContext context) {
    return PickupLayout(
      currentUser: widget.currentUser,
      scaffold: imageFile == null ? buildUploadImage() : buildUploadForm());
  }

  Widget buildUploadImage() {
    return Container(
      child: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 50),
            child: SvgPicture.asset('assets/images/upload.svg',
                height: MediaQuery.of(context).size.height * 0.4,
                width: double.infinity),
          ),
          GestureDetector(
            onTap: () {
              pickImage();
            },
            child: Center(
              child: Container(
                margin: EdgeInsets.only(top: 20),
                padding:
                    EdgeInsets.only(top: 10, left: 50, right: 50, bottom: 10),
                child: Text(
                  "Upload",
                  style: TextStyle(color: Colors.white),
                ),
                decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    border: Border.all(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              imageFile = null;
            });
          },
        ),
        title: Text("Caption the post"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.check),
            onPressed: isUploading ? null : upload,
          ),
        ],
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            isUploading
                ? LinearProgressIndicator(
                    backgroundColor: Colors.white,
                  )
                : Container(),
            Container(
                child: Image.file(
              imageFile,
              fit: BoxFit.fill,
              alignment: Alignment.center,
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.6,
            )),
            ListTile(
              leading: Icon(
                Icons.textsms,
                color: Colors.blue,
                size: 40,
              ),
              title: TextFormField(
                decoration: InputDecoration(labelText: "Write your caption.."),
                controller: captionController,
                enabled: isUploading ? false : true,
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.location_on,
                size: 40,
                color: Colors.blue,
              ),
              title: TextFormField(
                decoration: InputDecoration(labelText: "Location"),
                controller: locationController,
                enabled: isUploading ? false : true,
              ),
              trailing: IconButton(
                icon: isLocation
                    ? Icon(
                        Icons.my_location,
                        color: Colors.blue,
                      )
                    : Icon(Icons.location_searching),
                onPressed: () async {
                  Position position = await Geolocator().getCurrentPosition();
                  List<Placemark> placemarks = await Geolocator()
                      .placemarkFromCoordinates(
                          position.latitude, position.longitude);
                  Placemark placemark = placemarks[0];
                  String address =
                      "${placemark.locality}, ${placemark.administrativeArea}";
                  setState(() {
                    isLocation = true;
                    locationController.text = address;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void createPostInfirestore(
      {String mediaUrl, String caption, String location}) {
        print(caption);
    Firestore.instance
        .collection("posts")
        .document(widget.currentUser.id)
        .collection("UsersPost")
        .document(postId)
        .setData({
          "postId":postId,
          "ownerId":widget.currentUser.id,
          "username":widget.currentUser.username,
          "mediaUrl":mediaUrl,
          "description":caption,
          "location":location,
          "timestamp":DateTime.now().millisecondsSinceEpoch.toString(),
          "likes": {}
        });
        captionController.clear();
        locationController.clear();
        setState(() {
          isUploading=false;
          isLocation=false;
          imageFile=null;
          postId=DateTime.now().millisecondsSinceEpoch.toString();
        });
  }

  void upload() async {
    captionController.text="";
    setState(() {
      isUploading = true;
    });
    await compressImage();
    StorageUploadTask uploadTask =
        FirebaseStorage.instance.ref().child("post_$postId").putFile(imageFile);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String url = await storageSnap.ref.getDownloadURL();
    createPostInfirestore(
        mediaUrl: url,
        caption: captionController.text,
        location: locationController.text);
  }

  Future<void> compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image image = Im.decodeImage(imageFile.readAsBytesSync());
    final compressedImage = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(image, quality: 85));
    setState(() {
      imageFile = compressedImage;
    });
  }

  void pickImage() async {
    ImageSource source;
    showDialog(
        context: context,
        builder: (context) {
          return Container(
            child: AlertDialog(
              title: Text("Choose Image from "),
              content: Container(
                width: 150,
                height: 100,
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(
                        Icons.camera,
                        color: Colors.amber,
                      ),
                      title: Text("Camera"),
                      onTap: () async {
                        source = ImageSource.camera;
                        Navigator.of(context).pop();
                        File file = await ImagePicker.pickImage(
                            source: ImageSource.camera,
                            maxHeight: 675,
                            maxWidth: 960);
                        setState(() {
                          imageFile = file;
                        });
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.folder,
                        color: Colors.amber,
                      ),
                      title: Text("Gallery"),
                      onTap: () async {
                        source = ImageSource.gallery;
                        Navigator.of(context).pop();
                        final file = await ImagePicker.pickImage(
                            source: ImageSource.gallery);
                        setState(() {
                          imageFile = file;
                        });
                      },
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
