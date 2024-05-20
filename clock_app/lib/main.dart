import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clock App',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    ClockScreen(),
    AlarmPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: LayoutBuilder(

        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.selected,
                  destinations: const [

                    NavigationRailDestination(

                      icon: Icon(Icons.access_time),
                      label: Text('Clock' , style:TextStyle(fontWeight: FontWeight.bold, fontSize: 12),),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.alarm),
                      label: Text('Alarm' , style: TextStyle(fontWeight: FontWeight.bold , fontSize: 12),),
                    ),
                  ],
                ),
                Expanded(
                  child: Container(
                    color: Colors.blue,
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _pages,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Container(
              color: Colors.blue,
              child: IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
            );
          }
        },
      ),
      bottomNavigationBar: LayoutBuilder(

        builder: (context, constraints) {

          return constraints.maxWidth <= 600
              ? BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.access_time),
                label: 'Clock',

              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.alarm ),
                label: 'Alarm',

              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.white70,
            backgroundColor: Colors.blue,
            onTap: _onItemTapped,
          )
              : Container(

          ); // Return an empty container instead of null
        },
      ),
    );
  }
}

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  _ClockScreenState createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  String _timeString = '';

  @override
  void initState() {
    _timeString = _formatDateTime(DateTime.now());
    Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    super.initState();
  }

  void _getTime() {
    final String formattedDateTime = _formatDateTime(DateTime.now());
    setState(() {
      _timeString = formattedDateTime;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        title: const Text(
          'Clock',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold , color: Colors.white ),
        ),
      ),
      body: Center(

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

            const Text(
              'Current Time:',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(

              _timeString,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  List<TimeOfDay> alarms = [];

  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid =
    const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = const DarwinInitializationSettings();
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
  }

  Future<void> _scheduleAlarm(TimeOfDay alarmTime) async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'alarm_notif',
      'Alarm notification',
      channelDescription: 'Channel for alarm notifications',
      icon: '@mipmap/ic_launcher',
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails(
      sound: 'alarm_sound.aiff',
    );
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    DateTime now = DateTime.now();
    tz.TZDateTime scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      alarmTime.hour,
      alarmTime.minute,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      alarms.length + 1,
      'Alarm',
      'Wake up!',
      scheduledTime,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  void _addAlarm() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((selectedTime) {
      if (selectedTime != null) {
        setState(() {
          alarms.add(selectedTime);
          _scheduleAlarm(selectedTime);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Set Alarm',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: alarms.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    '${alarms[index].hour}:${alarms[index].minute}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        alarms.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
