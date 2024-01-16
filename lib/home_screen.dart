import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flood_guard_admin/app/app_toast.dart';
import 'package:flood_guard_admin/flood_alert_model.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:sms_advanced/sms_advanced.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FloodAlertModel alertModel = FloodAlertModel();
  final floodAlertRef = FirebaseFirestore.instance
      .collection('FloodAlerts')
      .withConverter<FloodAlertModel>(
        fromFirestore: (snapshot, _) =>
            FloodAlertModel.fromJson(snapshot.data()!),
        toFirestore: (movie, _) => movie.toJson(),
      );
  final SmsQuery query = SmsQuery();
  //Actual hardware device sim number
  final String targetSender = '+639465011997';
  final String testSender = '+639761215840';

  @override
  void initState() {
    super.initState();
    initSmsListener();
  }

  void sendPushNotifToFloodGuardApp(
      {required String title, required String body}) async {
    var headers = {
      'Content-Type': 'application/json',
      'Authorization':
          'key=AAAAx3gA7cE:APA91bHan4Z5bBbmxHR6ONIciOXECVTGS9NFhXF0JlCr6QTP97WjUH52-ovnYWkAAwAs5sL4_ncGX1vJZK173-JNHFfpFFkNptF1bxxFzD56jfxZ8A34KX8cIAKKAtuZE32gKX2x0nGG'
    };
    var request =
        http.Request('POST', Uri.parse('https://fcm.googleapis.com/fcm/send'));
    request.body = jsonEncode({
      "to": "/topics/floodAlerts",
      "notification": {
        "title": title,
        "body": body,
        "mutable_content": true,
        "sound": "Tri-tone"
      }
    });
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  void initSmsListener() async {
    SmsReceiver receiver = SmsReceiver();
    receiver.onSmsReceived!.listen((SmsMessage msg) {
      print(msg);
      if (msg.address == targetSender || msg.address == testSender) {
        processMessage(msg.body!, msg.date!);
      }
    });
  }

  void processMessage(String body, DateTime dateTime) {
    // Custom function to process message data
    print('Message from $targetSender: $body, received at $dateTime');
    // Add additional processing logic here
    String title = body.toLowerCase().contains('alert') ? 'Alert' : 'Info';
    DateTime now = dateTime;
    String formattedDate = DateFormat('h:mm a of MMM d, yyyy').format(now);
    String place = 'Cagwait Surigao del Sur';
    String message = body.toLowerCase().contains('alert')
        ? 'Flood was detected at $place on $formattedDate'
        : 'Flood Guard device was initiated at $place on $formattedDate';

    uploadFloodAlert(
        floodAlertModel: FloodAlertModel(
            id: '${dateTime.millisecondsSinceEpoch}',
            title: title,
            message: message,
            timestamp: dateTime.millisecondsSinceEpoch,
            location: place));
    sendPushNotifToFloodGuardApp(title: title, body: message);
  }

  Future<void> uploadFloodAlert({required FloodAlertModel floodAlertModel}) {
    return floodAlertRef.add(floodAlertModel).then((value) {
      print("Uploaded...");
      // Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(
      //       builder: (context) => MapScreen(
      //         name: name,
      //         startLoc: startLoc,
      //         endLoc: endLoc,
      //       ),
      //     ));
    }).catchError((error) {
      AppToast.showErrorMessage(
          context, 'Something went wrong. Please try again.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xff1b2a33),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 50, right: 50),
              child: Text(
                'BROADCASTINGFLOOD NOTIFCATIONS FROM THE DEVICE.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            SpinKitWaveSpinner(
              size: 300,
              color: Colors.white60,
              trackColor: Colors.white12,
              waveColor: Colors.blue,
            ),
          ],
        ));
  }
}

class DetailScreen extends StatelessWidget {
  final FloodAlertModel data;

  DetailScreen({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isAlert = false;
    if (data.title != null) {
      isAlert = data.title == 'ALERT';
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Details'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors
                    .blue, // Placeholder for icon, replace with actual image or icon
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: Colors.red,
                child: isAlert
                    ? Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                      )
                    : Icon(
                        Icons.info,
                        color: Colors.white,
                      ),
              ),
            ),
            SizedBox(height: 10),
            Text('${data.title}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(
                'Happened ${convertToAgo(DateTime.fromMillisecondsSinceEpoch(data.timestamp ?? 0))}'),
            SizedBox(height: 20),
            Text("ID: ${data.id}}"),
            Text("Message: ${data.message}"),
            Text("Location: ${data.location}"),
            Text(
                "Date: ${DateTime.fromMillisecondsSinceEpoch(data.timestamp ?? 00)}"),
          ],
        ),
      ),
    );
  }
}

String convertToAgo(DateTime input) {
  Duration diff = DateTime.now().difference(input);

  if (diff.inDays >= 1) {
    return '${diff.inDays} day(s) ago';
  } else if (diff.inHours >= 1) {
    return '${diff.inHours} hour(s) ago';
  } else if (diff.inMinutes >= 1) {
    return '${diff.inMinutes} minute(s) ago';
  } else if (diff.inSeconds >= 1) {
    return '${diff.inSeconds} second(s) ago';
  } else {
    return 'just now';
  }
}
