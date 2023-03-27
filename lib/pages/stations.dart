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
import 'paths.dart';

// ignore: must_be_immutable
class Stations extends StatefulWidget {
  List _stationData;

  //Stations Constructor
  Stations(this._stationData);

  //Create state for _StationsState, calls _StationsState constructor
  @override
  _StationsState createState() => _StationsState(this._stationData);
}

/*
          Navigation Colors by Metro Rail Stations:
            Gold: 0xffae08, (255,174,8)
            Blue: 0x2371e7, (35,113,231)
            Green: 0x0e884e, (14,136,78)
            Red: 0xff2f00, (255,47,0)
            Orange: 0xff7801, (255,120,1)
            Purple: 0x780e67, (120,14,103)
            Silver: 0xc3c3c3, (195,195,195)
 */
class _StationsState extends State<Stations> {
  List _stationData;
  LatLng _currentPosition;
  String _navMethod = "Walking";
  Icon _fab = Icon(Icons.directions_walk);
  Color _fabWBColor = Color(0xFF1ba098);
  FontWeight _fontWeight = FontWeight.bold;
  int _navMethodPref = 0;

  //Stations constructor
  _StationsState(this._stationData);

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

  Future<void> _startNavigation(LatLng start, LatLng end) async {
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

  @override
  Widget build(BuildContext context) {
    _locatePosition();
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text("Metro Bike Stations",
              style: GoogleFonts.roboto(fontWeight: _fontWeight)),
          backgroundColor: Color.fromRGBO(14, 136, 78, 1.0),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: "wbBtn",
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
              _fabWBColor =
                  Color(0xFF361999); //Color.fromRGBO(255, 120, 1, 1.0);
            } else if (_navMethodPref == 2) {
              _navMethodPref = 0;
              _fab = Icon(Icons.directions_walk);
              _navMethod = "Walking";
              _fabWBColor =
                  Color(0xFF1ba098); //Color.fromRGBO(255, 47, 0, 1.0);
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
                        image: AssetImage("assets/losangeles_vertical4_bw.jpg"),
                        fit: BoxFit.cover))),
            Container(
                decoration: BoxDecoration(color: Colors.black54),
                height: double.infinity,
                width: double.infinity,
                child: ListView.builder(
                  itemCount: _stationData == null ? 0 : _stationData.length,
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
                              backgroundImage:
                                  AssetImage('assets/bgbikenum.png'),
                              maxRadius: 25,
                              backgroundColor: Colors.white,
                              child: Text(
                                  '${_stationData[index]['properties']['bikesAvailable']}',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 25.0)),
                            ),
                            title: Text(
                                '${_stationData[index]['properties']['name']}',
                                style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontWeight: _fontWeight)),
                            subtitle: Text(
                                '${_stationData[index]['properties']['addressStreet']}, ${_stationData[index]['properties']['addressCity']}, ${_stationData[index]['properties']['addressZipCode']}',
                                style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontWeight: _fontWeight)),
                            onTap: () {
                              if (_currentPosition != null) {
                                _startNavigation(
                                    _currentPosition,
                                    LatLng(
                                        _stationData[index]['properties']
                                            ['latitude'],
                                        _stationData[index]['properties']
                                            ['longitude']));
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                )),
          ],
        ));
  }
}
