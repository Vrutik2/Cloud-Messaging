import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';

Future<void> _messageHandler(RemoteMessage message) async {
  print('background message ${message.notification!.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_messageHandler);
  runApp(MessagingTutorial());
}

class MessagingTutorial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Messaging',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Firebase Messaging'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? fcmToken;
  String? _appInstanceId;
  String _notificationMessage = "No new notifications";

  void _getToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      setState(() {
        fcmToken = token;
      });
      print("FCM Token: $fcmToken");
    } catch (e) {
      print("Error fetching FCM token: $e");
    }
  }

  Future<void> _getAppInstanceId() async {
    try {
      String? instanceId = await FirebaseInstallations.instance.getId(); 
      setState(() {
        _appInstanceId = instanceId;
      });
      print("App Instance ID: $_appInstanceId");
    } catch (e) {
      print("Error fetching App Instance ID: $e");
    }
  }

  void _showNotification(RemoteMessage message) {
    setState(() {
      _notificationMessage = message.notification?.title ?? "No Title";
    });
  }

  @override
  void initState() {
    super.initState();
    _getAppInstanceId();
    _getToken();
    
    messaging.subscribeToTopic("messaging");
    messaging.getToken().then((value) {
      print(value);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      print("message received");
      print(event.notification!.body);
      print(event.data.values);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: event.data['Type'] == "important"
                ? Text("Important Notification")
                : Text("Regular Notification"),
            content: Text(event.notification?.body ?? "No message body"),
            backgroundColor:
                event.data['Type'] == "important" ? Colors.red : Colors.green,
            actions: [
              TextButton(
                child: Text("Ok"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      _showNotification(event);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Message clicked!');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? "Firebase Messaging"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Messaging Tutorial"),
            SizedBox(height: 20),
            Text(
              fcmToken != null
                  ? "FCM Token: $fcmToken"
                  : "Fetching FCM Token...",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(_notificationMessage),
          ],
        ),
      ),
    );
  }
}