import 'package:flutter/material.dart';
import 'package:safe_ways/pages/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/global_data.dart';
import 'package:http/http.dart' as superagent;
import 'dart:async';
import 'dart:convert';

Future<List> _getStationData() async {
  superagent.Response response =
      await superagent.get('https://bikeshare.metro.net/stations/json/');
  return json.decode(response.body)['features'];
}

void main() {
  _getStationData().then((value) {
    GlobalData.stationData = value;
  });
  runApp(MyApp());
}

// ignore: must_be_immutable
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Safe Ways',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(),
    );
  }
}
