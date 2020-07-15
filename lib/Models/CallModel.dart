class Call{
  String callerID;
  String callerName;
  String callerPic;
  String receiverID;
  String receiverName;
  String receiverPic;
  String channelId;
  bool hasDialed;

  Call({
    this.callerID,
    this.callerName,
    this.callerPic,
    this.receiverID,
    this.receiverName,
    this.receiverPic,
    this.channelId,
    this.hasDialed});

  Map<String ,dynamic> toMap(Call call)
  {
    Map<String ,dynamic> callMap=Map();
    callMap["caller_id"]=call.callerID;
    callMap["caller_name"]=call.callerName;
    callMap["caller_pic"]=call.callerPic;
    callMap["receiver_id"]=call.receiverID;
    callMap["receiver_name"]=call.receiverName;
    callMap["receiver_pic"]=call.receiverPic;
    callMap["channelId"]=call.channelId;
    callMap["hasDialed"]=call.hasDialed;
    return callMap;
  }
  Call.fromMap(Map callMap)
  {
    this.callerID=callMap["caller_id"];
    this.callerName=callMap["caller_name"];
    this.callerPic=callMap["caller_pic"];
    this.channelId= callMap['channelId'];
    this.receiverID= callMap["receiver_id"];
    this.receiverName= callMap["receiver_name"];
    this.receiverPic= callMap["receiver_pic"];
    this.hasDialed=callMap["hasDialed"];
  }
}