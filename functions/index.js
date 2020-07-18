const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const firestore = admin.firestore();
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });
exports.onCreateFollower = functions.firestore.document("/Followers/{userId}/usersFollower/{followerId}").onCreate(async (snapshot, context) => {
     console.log("Follower Created", snapshot.data());
     const userId = context.params.userId;
     const followerId = context.params.followerId;

     const followedUserPostRef = admin.firestore().collection('posts').doc(userId).collection("UsersPost");

     const timelinePostRef = admin.firestore().collection('timeline').doc(followerId).collection('timelinePosts');

     const querySnapshot = await followedUserPostRef.get();

     querySnapshot.forEach((doc) => {
          if (doc.exists) {
               const postId = doc.id;
               const postData = doc.data();
               timelinePostRef.doc(postId).set(postData);
          }
     });
}
);
exports.onDeleteFollower = functions.firestore.document("/Followers/{userId}/usersFollower/{followerId}")
     .onDelete(async (snapshot, context) => {
          console.log("Follower Deleted", snapshot.id);
          const userId = context.params.userId;
          const followerId = context.params.followerId;

          const timelinePostRef = admin.firestore().collection('timeline').doc(followerId).collection('timelinePosts')
               .where("ownerId", "==", userId);
          const querySnapshot = await timelinePostRef.get();
          querySnapshot.forEach((doc) => {
               if (doc.exists) {
                    doc.ref.delete();
               }
          });

     });

exports.onCreatePost = functions.firestore.document("/posts/{userId}/UsersPost/{postId}")
     .onCreate(async (snapshot, context) => {
          const postCreated = snapshot.data();
          const userId = context.params.userId;
          const postId = context.params.postId;

          const userFollowersRef = admin.firestore().collection('Followers')
               .doc(userId).collection('usersFollower');
          const querySnapshot = await userFollowersRef.get();
          querySnapshot.forEach(doc => {
               const followerId = doc.id;

               admin.firestore().collection('timeline')
                    .doc(followerId).collection('timelinePosts')
                    .doc(postId).set(postCreated);

          });

     });

exports.onUpdatePost = functions.firestore.document("/posts/{userId}/UsersPost/{postId}")
     .onUpdate(async (change, context) => {
          const postUpdated = change.after.data();
          const userId = context.params.userId;
          const postId = context.params.postId;
          const userFollowersRef = admin.firestore().collection('Followers')
               .doc(userId).collection('usersFollower');
          const querySnapshot = await userFollowersRef.get();
          querySnapshot.forEach(doc => {
               const followerId = doc.id;

               admin.firestore().collection('timeline')
                    .doc(followerId).collection('timelinePosts')
                    .doc(postId).get().then(doc => {
                         if (doc.exists) {
                              doc.ref.update(postUpdated);
                         }
                    });

          });

     });

exports.onDeletePost = functions.firestore.document("/posts/{userId}/UsersPost/{postId}")
     .onDelete(async (snapshot, context) => {
          const userId = context.params.userId;
          const postId = context.params.postId;
          const userFollowersRef = admin.firestore().collection('Followers')
               .doc(userId).collection('usersFollower');
          const querySnapshot = await userFollowersRef.get();
          querySnapshot.forEach(doc => {
               const followerId = doc.id;
               admin.firestore().collection('timeline')
                    .doc(followerId).collection('timelinePosts')
                    .doc(postId).get().then(doc => {
                         if (doc.exists) {
                              doc.ref.delete();
                         }
                    });

          });

     });

exports.onCreateActivityFeedItem = functions.firestore
     .document("/feed/{userId}/feedItems/{activityFeedItem}")
     .onCreate(async (snapshot, context) => {
          console.log('Activity Feed Item Created', snapshot.data());
          const userId = context.params.userId;
          const usersRef = admin.firestore()
               .doc(`users/${userId}`);
          const doc = await usersRef.get();

          const androidNotificationToken = doc.data().androidNotificationToken;
          if (androidNotificationToken) {
               sendNotification(androidNotificationToken, snapshot.data());
          } else {
               console.log('No token for user ,cannot send notification')
          }

          function sendNotification(androidNotificationToken, activityFeedItem) {
               let body;
               switch (activityFeedItem.type) {
                    case "comment":
                         body = `${activityFeedItem.username} commented: ${activityFeedItem.comment}`
                         break;
                    case "like":
                         body = `${activityFeedItem.username} liked your post.`
                         break;
                    case "follow":
                         body = `${activityFeedItem.username} started following you.`
                         break;
                    case "accepted":
                         body = `${activityFeedItem.username} accepted your follow request.`
                         break;
                    default:
                         break;
               }
               const message = {
                    notification: {
                         body: body,
                         title: "Alert",
                    },
                    token: androidNotificationToken,
                    data: { recepient: userId, senderId: activityFeedItem.userId },
                    android: {
                         notification: {
                              sound: 'default',
                         },
                         priority: 'high',
                         ttl: 0
                    }

               };
               admin.messaging().send(message).then(res => {
                    console.log("message sent successfully ", res);
               }).catch(error => {
                    console.log("Error : ", error);
               });
          }

     });

exports.onMessageSend = functions.firestore
     .document('chats/{userId}/userChats/{chatId}/chats/{messageId}')
     .onCreate(async (snapshot, context) => {
          const chatId = context.params.chatId;
          const senderId = snapshot.data().sender;
          const receiverId = snapshot.data().receiver;
          const senderRef = admin.firestore().doc(`users/${senderId}`);
          const receiversRef = admin.firestore().doc(`users/${receiverId}`);
          const senderDoc = await senderRef.get();
          const receiverDoc = await receiversRef.get();
          const receiversAndroidNotificationToken = receiverDoc.data().androidNotificationToken;
          const receiversDisplayName = receiverDoc.data().displayName;
          const senderDisplayName = senderDoc.data().displayName;
          const receiverAllunreadChatsRef = admin.firestore().collection(`unreadChats/${receiverId}/unreadchats/${chatId}/${chatId}`);
          const unreadChatsDocuments = await receiverAllunreadChatsRef.orderBy('timestamp', 'desc').limit(7).get();
          let arrayOfMessages = [];
          unreadChatsDocuments.forEach((doc) => {
               arrayOfMessages.push(doc.data().message);
          });
          const reversedArayofMessages = arrayOfMessages.reverse();
          let body = "";
          reversedArayofMessages.forEach((mes) => {
               body = body + "\n" + senderDisplayName + ": " + mes;
          });
          if (context.params.userId != senderId) {
               sendNotification(receiversAndroidNotificationToken, body, chatId);
          }


          function sendNotification(receiversAndroidNotificationToken, body, chatId) {
               const message = {
                    notification: {
                         body: body,
                         title: "New Message",

                    },

                    data: {
                         'senderId': senderId
                    },

                    token: receiversAndroidNotificationToken,
                    android: {
                         notification: {
                              sound: 'default',
                              tag: chatId,
                              color: "#4dd2ff"
                         },
                         priority: 'high',
                         ttl: 0,
                         collapseKey: chatId
                    }
               };
               admin.messaging().send(message).then(result => {
                    console.log(`Message sent successfully ${result}`);
               }).catch(error => {
                    console.log(error);
               });
          }
     });

exports.onCallCreated = functions.firestore.document('call/{userId}').onCreate(async (snapshot, context) => {
     const userId = context.params.userId;
     const caller_id = snapshot.data().caller_id;
     if (userId != caller_id) {
          const receiver_id = snapshot.data().receiver_id;
          const receiversRef = admin.firestore().doc(`users/${receiver_id}`);
          const receiversDoc = await receiversRef.get();
          const callerName = snapshot.data().caller_name;
          const androidNotificationToken = receiversDoc.data().androidNotificationToken;
          const message = {
               notification: {
                    body: `${callerName} is video calling you on instashare..`,
                    title: "Video Call",

               },
               token: androidNotificationToken,
               android: {
                    notification: {
                         sound: 'default',
                         tag: caller_id,
                         color: "#4dd2ff",
                         sticky: true,
                         sound: "default",
                         default_vibrate_timings: true,
                         default_light_settings: true
                    },
                    priority: 'high',
                    ttl: 0,
                    collapseKey: caller_id
               }
          };
          admin.messaging().send(message).then(result => {
               console.log(`Message sent successfully ${result}`);
          }).catch(error => {
               console.log(error);
          });
     }

});

exports.onCallDeleted = functions.firestore.document('call/{userId}').onDelete(async (snapshot, context) => {
     const userId = context.params.userId;
     const caller_id = snapshot.data().caller_id;
     if (userId != caller_id) {
          const receiver_id = snapshot.data().receiver_id;
          const receiversRef = admin.firestore().doc(`users/${receiver_id}`);
          const receiversDoc = await receiversRef.get();
          const callerName = snapshot.data().caller_name;
          const androidNotificationToken = receiversDoc.data().androidNotificationToken;
          const message = {
               notification: {
                    body: `Video call ended with ${callerName}`,
                    title: "Video Call Ended",

               },
               token: androidNotificationToken,
               android: {
                    notification: {
                         sound: 'default',
                         tag: caller_id,
                         color: "#4dd2ff",
                         sticky: true,
                         sound: "default",
                         default_vibrate_timings: true,
                         default_light_settings: true
                    },
                    priority: 'high',
                    ttl: 0,
                    collapseKey: caller_id
               }
          };
          admin.messaging().send(message).then(result => {
               console.log(`Message sent successfully ${result}`);
          }).catch(error => {
               console.log(error);
          });
     }

});
exports.onFollowRequestCreated = functions.firestore.document('Followers/{userId}/followRequests/{currentUserId}').onCreate(async (snapshot, context) => {
     const receiver_id = context.params.userId;
     const receiversRef = admin.firestore().doc(`users/${receiver_id}`);
     const receiversDoc = await receiversRef.get();
     const senderName=snapshot.data().username;
     const androidNotificationToken = receiversDoc.data().androidNotificationToken;
     const message = {
          notification: {
               body: `${senderName} requested to follow you..`,
               title: "Follow Request",

          },
          token: androidNotificationToken,
          android: {
               notification: {
                    sound: 'default',
                    color: "#4dd2ff",
                    sticky: true,
                    sound: "default",
                    default_vibrate_timings: true,
                    default_light_settings: true
               },
               priority: 'high',
               ttl: 0,
          }
     };
     admin.messaging().send(message).then(result => {
          console.log(`Message sent successfully ${result}`);
     }).catch(error => {
          console.log(error);
     });


});