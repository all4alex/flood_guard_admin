import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flood_guard_admin/app/app_toast.dart';
import 'package:flood_guard_admin/flood_alert_model.dart';

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

  Future<void> uploadFloodAlert({required FloodAlertModel floodAlertModel}) {
    return floodAlertRef.add(floodAlertModel).then((value) {
      print("User Added");
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
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        centerTitle: true,
        title: Text(
          'Flood Records',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xff1b2a33),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: floodAlertRef.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("Loading");
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              FloodAlertModel item = document.data() as FloodAlertModel;
              bool isAlert = false;
              if (item.title != null) {
                isAlert = item.title == 'ALERT';
              }
              return ListTile(
                titleAlignment: ListTileTitleAlignment.top,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          data: item,
                        ),
                      ));
                },
                leading: CircleAvatar(
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
                title: Text('${item.title}'),
                subtitle: Text('${item.message}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        '${convertToAgo(DateTime.fromMillisecondsSinceEpoch(item.timestamp ?? 0))}'),
                    Text('${item.location}')
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
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
