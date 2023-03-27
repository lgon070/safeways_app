import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:safe_ways/data/global_data.dart';
import 'package:safe_ways/pages/paths.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as superagent;
import 'package:tuple/tuple.dart';

// ignore: must_be_immutable
class Navigation extends StatefulWidget {
  List _stationData;

  //Navigation constructor
  Navigation(this._stationData);

  //Create state for _NavigationState, calls _NavigationState constructor
  @override
  _NavigationState createState() => _NavigationState(this._stationData);
}

class _NavigationState extends State<Navigation> {
  List _stationData = [];
  LatLng _currentPosition, _originPosition, _destinationPosition;
  bool _readyToNav = false;
  int _navMethodPref = 0;
  Map<MarkerId, Marker> _markers = {};
  Completer<GoogleMapController> _controllerCompleter = Completer();
  GoogleMapController _mapController;
  String _topDestSearchQueryPlaceId, _topOrgSearchQueryPlaceId = '';
  String _navMethod = "Walking";
  Icon _fab = Icon(Icons.directions_walk);
  Color _fabWBColor = Color(0xFF1ba098);
  Color _fabNavColor = Color.fromRGBO(195, 195, 195, 1.0);
  TextEditingController _textFieldDestController = new TextEditingController();
  TextEditingController _textFieldOrgController = new TextEditingController();
  FontWeight _fontWeight = FontWeight.w600;
  Location location = new Location();
  String _textFieldOriginHintText = 'Where from?';
  String _textFieldDestinationHintText = 'Where to?';

  //_NavigationState constructor
  _NavigationState(this._stationData);

  @override
  void initState() {
    _addMarkers();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        .buffer
        .asUint8List();
  }

  Future<void> _locatePosition([bool refresh = false]) async {
    final LocationData locationData = await location.getLocation();
    _currentPosition = LatLng(locationData.latitude, locationData.longitude);
    if (_currentPosition != null && !refresh) {
      _originPosition = LatLng(locationData.latitude, locationData.longitude);
      _mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(locationData.latitude, locationData.longitude),
              zoom: 15.0)));
      setState(() {
        _textFieldOriginHintText = 'Your Location';
      });
    }
  }

  void _addMarkers() async {
    final Uint8List bikeIcon =
        await _getBytesFromAsset('assets/bikemarker.png', 90);

    for (dynamic data in _stationData) {
      final object = data['properties'];
      // creating a new MARKER
      MarkerId markerId = MarkerId(object['addressStreet']);
      Marker marker = Marker(
        icon: BitmapDescriptor.fromBytes(bikeIcon),
        markerId: markerId,
        draggable: false,
        position: LatLng(object['latitude'], object['longitude']),
        infoWindow: InfoWindow(
            title: object['addressStreet'],
            snippet: 'Metro Bikes Left: ${object['bikesAvailable']}'),
        onTap: () {
          _handleMarkerTap(LatLng(object['latitude'], object['longitude']),
              object['addressStreet']);
        },
      );
      _markers[markerId] = marker;
    }
    setState(() {});
  }

  void _setNewOriginPosition(String placeId) async {
    if (placeId.length > 0) {
      if (placeId == 'user_location') {
        _locatePosition(true);

        if (_markers.containsKey(MarkerId('origin-marker'))) {
          _markers.remove(MarkerId('origin-marker'));
        }

        _mapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentPosition, zoom: 15.0)));

        setState(() {
          _topOrgSearchQueryPlaceId = '';
          _textFieldOriginHintText = 'Your Location';
          _originPosition = _currentPosition;
          if (_originPosition != null &&
              _destinationPosition != null &&
              !_readyToNav) {
            _readyToNav = true;
            _fabNavColor = Color.fromRGBO(14, 136, 78, 1.0);
          }
        });
      } else {
        final Uint8List originIcon =
            await _getBytesFromAsset('assets/originMarker.png', 85);

        Response response = await superagent.get(
            'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=${GlobalData.googleApiKey}');

        dynamic jsonData = json.decode(response.body)['result'];

        LatLng nearestPosition = new LatLng(
            jsonData['geometry']['location']['lat'],
            jsonData['geometry']['location']['lng']);
        List<Address> results = await Geocoder.google(GlobalData.googleApiKey)
            .findAddressesFromCoordinates(new Coordinates(
                nearestPosition.latitude, nearestPosition.longitude));
        List<String> addressLineSplit = results.first.addressLine.split(',');

        if (_markers.containsKey(MarkerId('origin-marker'))) {
          _markers.remove(MarkerId('origin-marker'));
        }

        MarkerId markerId = MarkerId('origin-marker');
        Marker marker = Marker(
          markerId: markerId,
          position: nearestPosition,
          icon: BitmapDescriptor.fromBytes(originIcon),
          draggable: false,
          infoWindow: InfoWindow(
              title: '${addressLineSplit[0]}',
              snippet:
                  '${addressLineSplit[1].trim()}, ${addressLineSplit[2].trim()}'),
        );

        _mapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: nearestPosition, zoom: 15.0)));

        setState(() {
          _textFieldOriginHintText = '${addressLineSplit[0]}';
          _originPosition = nearestPosition;
          _markers[markerId] = marker;
          if (_originPosition != null &&
              _destinationPosition != null &&
              !_readyToNav) {
            _readyToNav = true;
            _fabNavColor = Color.fromRGBO(14, 136, 78, 1.0);
          }
        });
      }
    }
    _textFieldOrgController.clear();
  }

  void _setNewDestinationMarker(
      {String placeId = '',
      Tuple2 tappedPosition = const Tuple2<double, double>(0, 0)}) async {
    final Uint8List searchIcon =
        await _getBytesFromAsset('assets/destinationMarker.png', 85);
    LatLng markerPosition;
    bool readyToPlaceMarker = false;
    String address = '';

    if (placeId.length > 0 &&
        tappedPosition.item1 == 0 &&
        tappedPosition.item2 == 0) {
      readyToPlaceMarker = true;
      Response response = await superagent.get(
          'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=${GlobalData.googleApiKey}');
      dynamic jsonData = json.decode(response.body)['result'];
      markerPosition = new LatLng(jsonData['geometry']['location']['lat'],
          jsonData['geometry']['location']['lng']);
    } else if (placeId.length == 0 &&
        tappedPosition.item1 != 0 &&
        tappedPosition.item2 != 0) {
      readyToPlaceMarker = true;
      markerPosition = LatLng(tappedPosition.item1, tappedPosition.item2);
    }

    if (readyToPlaceMarker) {
      List<Address> results = await Geocoder.google(GlobalData.googleApiKey)
          .findAddressesFromCoordinates(new Coordinates(
              markerPosition.latitude, markerPosition.longitude));

      List<String> addressLineSplit = results.length == 0
          ? [
              'Unknown Location',
              'Lat: ${markerPosition.latitude.toStringAsFixed(2)}',
              'Lng: ${markerPosition.longitude.toStringAsFixed(2)}'
            ]
          : results.first.addressLine.split(',');
      address = addressLineSplit[0];
      MarkerId markerId = MarkerId('destination-marker');
      Marker marker = Marker(
        markerId: markerId,
        position: markerPosition,
        icon: BitmapDescriptor.fromBytes(searchIcon),
        draggable: false,
        infoWindow: InfoWindow(
            title: '${addressLineSplit[0]}',
            snippet:
                '${addressLineSplit[1].trim()}, ${addressLineSplit[2].trim()}'),
        onTap: () {
          _handleMarkerTap(markerPosition, address);
        },
      );

      _mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: markerPosition, zoom: 15.0)));

      _markers[markerId] = marker;
    }
    setState(() {
      _handleMarkerTap(markerPosition, address);
    });
  }

  void _handleMapTap(LatLng tappedPosition) {
    _readyToNav = false;
    _setNewDestinationMarker(
        tappedPosition: Tuple2<double, double>(
            tappedPosition.latitude, tappedPosition.longitude));
  }

  void _handleMarkerTap(
      LatLng tappedMarkerPosition, String newTextFieldDestinationHint) {
    setState(() {
      _textFieldDestController.clear();
      _textFieldDestinationHintText = newTextFieldDestinationHint;
      _destinationPosition = tappedMarkerPosition;
      if (_originPosition != null &&
          _destinationPosition != null &&
          !_readyToNav) {
        _readyToNav = true;
        _fabNavColor = Color.fromRGBO(14, 136, 78, 1.0);
      }
    });
  }

  void _startNavigation(LatLng start, LatLng end) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
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

    List<String> history = prefs.getStringList("history") ?? [];
    Queue queue = Queue.from(history);

    if (queue.length >= 25) {
      queue.removeLast();
      queue.addFirst(historyEntry);
    } else {
      queue.addFirst(historyEntry);
    }
    history = List.from(queue.toList());
    prefs.setStringList("history", history);

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Paths(start, end, _navMethodPref)));
  }

  Future<List> findPlace(String pattern, {bool isDest = true}) async {
    //autoComplete will specifically look for results in a 40 mile (64374 meters) radius from the center of Los Angeles City (34.052235,-118.243683) for a destination and origin.
    if (pattern.length > 1) {
      List formattedPredictions = [];
      String autoCompleteOriginParameter = '';
      if (isDest) {
        if (_originPosition != null) {
          autoCompleteOriginParameter =
              '&origin=${_originPosition.latitude},${_originPosition.longitude}';
        }
      } else {
        if (_currentPosition != null) {
          autoCompleteOriginParameter =
              '&origin=${_currentPosition.latitude},${_currentPosition.longitude}';
        }
      }
      String autoComplete =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$pattern$autoCompleteOriginParameter&strictbounds&location=34.0522300,-118.2436800&radius=64374&key=${GlobalData.googleApiKey}";

      Response response = await superagent.get(autoComplete);
      dynamic predictions = json.decode(response.body)['predictions'];
      if (predictions.length != 0) {
        if (!isDest) {
          Map userLocationDefaultPrediction = {
            'place_id': 'user_location',
            'structure': {'main': 'Your Location', 'sub': ''}
          };
          formattedPredictions.insert(0, userLocationDefaultPrediction);
        }

        for (int i = 0; i < predictions.length; i++) {
          dynamic prediction = predictions[i];
          Map formattedPrediction = {
            'place_id': prediction['place_id'],
          };
          if (prediction.containsKey('distance_meters')) {
            String imperialUnits = '';
            if (prediction['distance_meters'] > 805) {
              imperialUnits =
                  '${(prediction['distance_meters'] * 0.00062137).toStringAsFixed(2)} mi';
            } else {
              imperialUnits =
                  '${(prediction['distance_meters'] * 3.2808).toStringAsFixed(2)} ft';
            }

            String distanceFromPoint = isDest
                ? '$imperialUnits from origin'
                : '$imperialUnits from your location';
            if (prediction.containsKey('structured_formatting')) {
              formattedPrediction['structure'] = {
                'main': prediction['structured_formatting']['main_text'],
                'sub':
                    '${prediction['structured_formatting']['secondary_text']} - $distanceFromPoint'
              };
            } else {
              formattedPrediction['structure'] = {
                'main': prediction['description'],
                'sub': '$distanceFromPoint'
              };
            }
          } else {
            if (prediction.containsKey('structured_formatting')) {
              formattedPrediction['structure'] = {
                'main': prediction['structured_formatting']['main_text'],
                'sub': prediction['structured_formatting']['secondary_text']
              };
            } else {
              formattedPrediction['structure'] = {
                'main': prediction['description'],
                'sub': 'No Other Info'
              };
            }
          }
          formattedPredictions.add(formattedPrediction);
        }

        if (isDest) {
          _topDestSearchQueryPlaceId = formattedPredictions[0]['place_id'];
        } else {
          _topOrgSearchQueryPlaceId = formattedPredictions[1]['place_id'];
        }

        return formattedPredictions;
      } else {
        if (isDest) {
          _topDestSearchQueryPlaceId = '';
        } else {
          _topOrgSearchQueryPlaceId = '';
        }
        return [];
      }
    } else {
      if (isDest) {
        _topDestSearchQueryPlaceId = '';
      } else {
        _topOrgSearchQueryPlaceId = '';
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            child: Icon(
              Icons.my_location,
              color: Colors.white,
              size: 25,
            ),
            onPressed: () {
              _setNewOriginPosition('user_location');
            },
          )
        ],
        title: Text("Navigation",
            style: GoogleFonts.roboto(fontWeight: _fontWeight)),
        backgroundColor:
            Color.fromRGBO(35, 113, 231, 1.0), //Blue: 0x2371e7, (35,113,231)
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            initialCameraPosition: CameraPosition(
              target: LatLng(34.052235, -118.243683),
              zoom: 15.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controllerCompleter.complete(controller);
              _mapController = controller;
              _locatePosition();
            },
            myLocationEnabled: true,
            markers: Set.of(_markers.values),
            mapType: MapType.normal,
            onTap: _handleMapTap,
          ),
          Positioned(
            top: 10.0,
            right: 15.0,
            left: 15.0,
            child: Container(
              height: 50.0,
              width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.white),
              child: TypeAheadField(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _textFieldOrgController,
                  onTap: () {
                    setState(() {
                      _originPosition = null;
                      _textFieldOriginHintText = 'Where from?';
                      _readyToNav = false;
                      _fabNavColor = Color.fromRGBO(195, 195, 195, 1.0);
                    });
                  },
                  onSubmitted: (value) {
                    _setNewOriginPosition(_topOrgSearchQueryPlaceId);
                  },
                  decoration: InputDecoration(
                    hintText: _textFieldOriginHintText,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 15.0, top: 15.0),
                    suffixIcon: Icon(
                      Icons.person_pin_circle_outlined,
                      color: Color.fromRGBO(35, 113, 231, 1.0),
                      size: 35,
                    ),
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  return await findPlace(pattern, isDest: false);
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage('assets/tfOrigin.png'),
                      maxRadius: 30,
                      backgroundColor: Colors.transparent,
                    ),
                    title: suggestion.containsKey('structure')
                        ? Text(
                            suggestion['structure']['main'],
                            style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                fontSize: 15),
                          )
                        : Text(
                            suggestion['description'],
                            style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                fontSize: 15),
                          ),
                    subtitle: suggestion.containsKey('structure')
                        ? Text(
                            suggestion['structure']['sub'],
                            style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w300,
                                color: Colors.black,
                                fontSize: 15),
                          )
                        : SizedBox.shrink(),
                  );
                },
                noItemsFoundBuilder: (context) {
                  return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage('assets/tfOrigin.png'),
                        maxRadius: 30,
                        backgroundColor: Colors.transparent,
                      ),
                      title: Text('No Places Found'),
                      subtitle: Text('Modify Your Search'));
                },
                onSuggestionSelected: (suggestion) {
                  _setNewOriginPosition(suggestion['place_id']);
                },
              ),
            ),
          ),
          Positioned(
              top: 64.0,
              right: 15.0,
              left: 15.0,
              child: Image.asset('assets/divider2.png')),
          Positioned(
            top: 70.0,
            right: 15.0,
            left: 15.0,
            child: Container(
              height: 50.0,
              width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.white),
              child: TypeAheadField(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _textFieldDestController,
                  onTap: () {
                    setState(() {
                      _destinationPosition = null;
                      _textFieldDestinationHintText = 'Where to?';
                      _readyToNav = false;
                      _fabNavColor = Color.fromRGBO(195, 195, 195, 1.0);
                    });
                  },
                  onSubmitted: (value) {
                    _setNewDestinationMarker(
                        placeId: _topDestSearchQueryPlaceId);
                  },
                  decoration: InputDecoration(
                    hintText: _textFieldDestinationHintText,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 15.0, top: 15.0),
                    suffixIcon: Icon(
                      Icons.flag_outlined,
                      color: Color.fromRGBO(255, 47, 0, 1.0),
                      size: 35,
                    ),
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  return await findPlace(pattern);
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage('assets/tfDestination.png'),
                      maxRadius: 30,
                      backgroundColor: Colors.transparent,
                    ),
                    title: suggestion.containsKey('structure')
                        ? Text(
                            suggestion['structure']['main'],
                            style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                fontSize: 15),
                          )
                        : Text(
                            suggestion['description'],
                            style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                fontSize: 15),
                          ),
                    subtitle: suggestion.containsKey('structure')
                        ? Text(
                            suggestion['structure']['sub'],
                            style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w300,
                                color: Colors.black,
                                fontSize: 15),
                          )
                        : SizedBox.shrink(),
                  );
                },
                noItemsFoundBuilder: (context) {
                  return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage('assets/tfDestination.png'),
                        maxRadius: 30,
                        backgroundColor: Colors.transparent,
                      ),
                      title: Text('No Places Found'),
                      subtitle: Text('Modify Your Search'));
                },
                onSuggestionSelected: (suggestion) {
                  _setNewDestinationMarker(placeId: suggestion['place_id']);
                },
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 30,
            child: FloatingActionButton.extended(
              heroTag: "wbBtn",
              elevation: 0,
              //Zoe Pepper + Slumber Color Scheme
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
          ),
          Positioned(
            left: 150,
            right: 60,
            bottom: 30,
            child: FloatingActionButton.extended(
              heroTag: "navBtn",
              elevation: 0,
              onPressed: () {
                if (_readyToNav &&
                    _originPosition != null &&
                    _destinationPosition != null) {
                  setState(() {
                    _textFieldDestinationHintText = 'Where to?';
                    _readyToNav = false;
                    _fabNavColor = Color.fromRGBO(195, 195, 195, 1.0);
                  });
                  _startNavigation(_originPosition, _destinationPosition);
                }
              },
              icon: Icon(Icons.timeline),
              label: Text('Navigate?',
                  style: GoogleFonts.roboto(fontWeight: _fontWeight)),
              backgroundColor: _fabNavColor,
            ),
          ),
        ],
      ),
    );
  }
}
