import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:safe_ways/data/global_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'paths.dart';

//thank you branflake2267 for teaching me how to use future builder :)
// ignore: must_be_immutable
class History extends StatefulWidget {
  History();

  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  String _navMethod = "Walking";
  Icon _fab = Icon(Icons.directions_walk);
  Color _fabWBColor = Color(0xFF1ba098);
  LatLng _currentPosition;
  FontWeight _fontWeight = FontWeight.w600;
  int _navMethodPref = 0;

  _HistoryState();

  @override
  void initState() {
    _locatePosition();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _locatePosition() async {
    final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    _currentPosition = LatLng(position.latitude, position.longitude);
  }

  void _startNavigation(LatLng start, LatLng end) async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    List<Address> results = await Geocoder.google(GlobalData.googleApiKey)
        .findAddressesFromCoordinates(
            new Coordinates(end.latitude, end.longitude));
    List<String> addressLineSplit = results.first.addressLine.split(',');
    String date = DateFormat('MM-dd-yyyy').format(DateTime.now()).toString();
    String time = DateFormat('kk:mm a').format(DateTime.now()).toString();
    String endAsObj =
        '{"latitude": ${end.latitude}, "longitude": ${end.longitude}}';
    String addressObj =
        '{"address": "${addressLineSplit[0]}", "city": "${addressLineSplit[1].trim()}", "statezip": "${addressLineSplit[2].trim()}"}';
    String historyEntry =
        '{"date": "$date", "time": "$time", "end": $endAsObj, "nearestAddress": $addressObj}';

    List<String> history = _prefs.getStringList("history") ?? [];
    Queue queue = Queue.from(history);

    if (queue.length >= 25) {
      queue.removeLast();
      queue.addFirst(historyEntry);
    } else {
      queue.addFirst(historyEntry);
    }
    history = List.from(queue.toList());
    _prefs.setStringList("history", history);

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Paths(start, end, _navMethodPref)));
  }

  Future<List> _getHistory() async {
    List startingHistory = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList("history") ?? [];

    for (int i = 0; i < history.length; i++) {
      dynamic parsedHistoryEntry = jsonDecode(history[i]);
      //debugPrint(parsedHistoryEntry.toString());
      startingHistory.insert(i, parsedHistoryEntry);
    }

    return startingHistory;
  }

  Widget _createListView(BuildContext context, AsyncSnapshot snapshot) {
    List _historyData = snapshot.data;
    return new ListView.builder(
        itemCount: _historyData == null ? 0 : _historyData.length,
        itemBuilder: (BuildContext context, int index) {
          return Card(
            color: Colors.white24,
            elevation: 6.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: CircleAvatar(
                      backgroundImage: AssetImage('assets/bghistory.png'),
                      maxRadius: 20,
                      backgroundColor: Colors.white),
                  title: Text(
                      '${_historyData[index]['nearestAddress']['address']}, ${_historyData[index]['nearestAddress']['city']}, ${_historyData[index]['nearestAddress']['statezip']}',
                      style: GoogleFonts.roboto(
                          color: Colors.white, fontWeight: _fontWeight)),
                  subtitle: Text(
                      'Trip on ${_historyData[index]['date']} at ${_historyData[index]['time']}',
                      style: GoogleFonts.roboto(
                          color: Colors.white, fontWeight: _fontWeight)),
                  onTap: () {
                    if (_currentPosition != null) {
                      _startNavigation(
                          _currentPosition,
                          LatLng(_historyData[index]['end']['latitude'],
                              _historyData[index]['end']['longitude']));
                    }
                  },
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    _locatePosition();
    FutureBuilder futureBuilder = new FutureBuilder(
        future: _getHistory(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return new Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: CircleAvatar(
                          backgroundImage: AssetImage('assets/bghistory.png'),
                          maxRadius: 25,
                          backgroundColor: Colors.white),
                      title: Text(
                        'waiting on Shared Preferences',
                        style: GoogleFonts.roboto(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                    ),
                  ],
                ),
              );
            case ConnectionState.waiting:
              return new Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: CircleAvatar(
                          backgroundImage: AssetImage('assets/bghistory.png'),
                          maxRadius: 25,
                          backgroundColor: Colors.white),
                      title: Text(
                        'loading your History',
                        style: GoogleFonts.roboto(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                    ),
                  ],
                ),
              );
            default:
              if (snapshot.hasError) {
                return new Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        leading: CircleAvatar(
                            backgroundImage: AssetImage('assets/bghistory.png'),
                            maxRadius: 25,
                            backgroundColor: Colors.white),
                        title: Text(
                          'an error occurred :(',
                          style: GoogleFonts.roboto(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return _createListView(context, snapshot);
              }
          }
        });

    return new Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title:
            Text("History", style: GoogleFonts.roboto(fontWeight: _fontWeight)),
        backgroundColor: Color.fromRGBO(255, 174, 8, 1.0),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "wbHistBtn",
        elevation: 6.0,
        onPressed: () => setState(() {
          if (_navMethodPref == 0) {
            _navMethodPref = 1;
            _fab = Icon(Icons.directions_bike);
            _navMethod = "Bicycle";
            _fabWBColor =
                Color(0xFFFF6495); //Color.fromRGBO(120, 14, 103, 1.0);
          } else if (_navMethodPref == 1) {
            _navMethodPref = 2;
            _fab = Icon(Icons.drive_eta);
            _navMethod = "Driving";
            _fabWBColor = Color(0xFF361999); //Color.fromRGBO(255, 120, 1, 1.0);
          } else if (_navMethodPref == 2) {
            _navMethodPref = 0;
            _fab = Icon(Icons.directions_walk);
            _navMethod = "Walking";
            _fabWBColor = Color(0xFF1ba098); //Color.fromRGBO(255, 47, 0, 1.0);
          }
        }),
        icon: _fab,
        label: Text(_navMethod,
            style: GoogleFonts.roboto(fontWeight: _fontWeight)),
        backgroundColor: _fabWBColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Stack(
        children: [
          Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("assets/losangeles_vertical2_bw.jpg"),
                      fit: BoxFit.cover))),
          Container(
            decoration: BoxDecoration(color: Colors.black54),
            height: double.infinity,
            width: double.infinity,
            child: futureBuilder,
          ),
        ],
      ),
    );
  }
}
