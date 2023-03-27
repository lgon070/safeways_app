import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as superagent;
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoder/geocoder.dart';
import 'package:safe_ways/data/global_data.dart';
import 'package:bubble_bottom_bar/bubble_bottom_bar.dart';

// ignore: must_be_immutable
class Paths extends StatefulWidget {
  LatLng _start;
  LatLng _end;
  int _navMethodPref;

  Paths(this._start, this._end, this._navMethodPref);

  @override
  _PathsState createState() =>
      _PathsState(this._start, this._end, this._navMethodPref);
}

class _PathsState extends State<Paths> with SingleTickerProviderStateMixin {
  Animation<double> _animation;
  AnimationController _animationController;
  LatLng _start;
  LatLng _end;
  int _navMethodPref;
  String _statusMessage = 'NO_STATUS';
  String _statusErrorMessage = 'NO_ERROR';
  int _statusCode = 0;
  List<Marker> _markers = [];
  List _weightedRoutes = []; // List that contains List of weighted routes
  List<List<String>> _allSteps =
      []; // List that contains List of weighted routes' html directions/instructions
  List<List> _allWarnings =
      []; // Google Directions API terms of service requires us to display any warnings to the user. List of that contains List of weighted routes' warnings
  List<Map> _allDurationsDistances = [];
  LatLng _midpoint; // Starting camera position
  FontWeight _fontWeight = FontWeight.w600;
  int _currentRoute = 0;
  int _weightedRoutesReturned = 0;
  bool _useOriginalColors = true;
  List<Color> _safetyColors = [
    Color.fromRGBO(87, 187, 138, 1.0),
    Color.fromRGBO(171, 200, 120, 1.0),
    Color.fromRGBO(255, 214, 102, 1.0),
    Color.fromRGBO(243, 169, 108, 1.0),
    Color.fromRGBO(235, 64, 52, 1.0)
  ];
  List<Color> _safetyColorsOriginal = [
    Color.fromRGBO(59, 202, 109, 1.0),
    Color.fromRGBO(255, 174, 66, 1.0),
    Color.fromRGBO(255, 127, 1, 1.0),
    Color.fromRGBO(236, 80, 18, 1.0),
    Color.fromRGBO(237, 41, 56, 1.0)
  ];
  Color _greyColor = Color.fromRGBO(185, 187, 190, 1.0);
  List<Bubble> _bubbleMenuItems = [];
  Map<int, Polyline> _allPolylines = {};
  int _currentPage = 0;
  bool _isVisible = false;

  _PathsState(this._start, this._end, this._navMethodPref);

  @override
  void initState() {
    _getSafestPath();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 260),
    );

    final curvedAnimation =
        CurvedAnimation(curve: Curves.easeInOut, parent: _animationController);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
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

  Future<void> _getSafestPath() async {
    superagent.Response response = await superagent.get(
        '${GlobalData.polarHollows}origin=${_start.latitude},${_start.longitude}&destination=${_end.latitude},${_end.longitude}&method=${_navMethodPref == 2 ? 'driving' : _navMethodPref == 0 ? 'walking' : 'bicycling'}&use_edge=${_navMethodPref == 2 ? 0 : 1}');

    if (response.statusCode == 200) {
      final Uint8List originIcon =
          await _getBytesFromAsset('assets/originIcon.png', 90);

      final Uint8List destinationIcon =
          await _getBytesFromAsset('assets/destinationIcon.png', 90);

      var originResults = await Geocoder.google(GlobalData.googleApiKey)
          .findAddressesFromCoordinates(
              new Coordinates(_start.latitude, _start.longitude));

      var destinationResults = await Geocoder.google(GlobalData.googleApiKey)
          .findAddressesFromCoordinates(
              new Coordinates(_end.latitude, _end.longitude));

      var originAddressLineSplit = originResults.first.addressLine.split(',');
      var destinationAddressLineSplit =
          destinationResults.first.addressLine.split(',');

      var jsonData = json.decode(response.body);

      if (jsonData['status'] == 'OK') {
        _weightedRoutes = jsonData['weighted_routes'];

        _weightedRoutesReturned = _weightedRoutes.length;

        int fauxZeroCounter = 0;
        for (int i = 0; i < _weightedRoutesReturned; i++) {
          //Route leg translated to LatLng object
          List routeObj = _weightedRoutes[i]['route'];
          List<LatLng> route = [];
          for (int j = 0; j < routeObj.length; j++) {
            List leg = routeObj[j];
            route.insert(j, LatLng(leg[1], leg[0]));
          }

          //Setting camera position to the midpoint of the first route shown
          if (i == 0) {
            _midpoint = route[route.length ~/ 2];
          }

          //Translation and insertion of route steps into allSteps array
          List stepsObj = _weightedRoutes[i]['steps'];
          List<String> steps = [];
          for (int j = 0; j < stepsObj.length; j++) {
            if (j != 0) {
              steps.insert(j, '<p>${stepsObj[j]['html_instructions']}</p>');
            } else {
              steps.insert(j, '');
            }
          }
          _allSteps.insert(i, steps);

          //Route warnings from Google and route warning if the route is outside LA City bounds.
          List warnings = [];
          warnings.insert(0, '');
          warnings.addAll(_weightedRoutes[i]['warnings']);
          if (!(jsonData['within_la_bounds'])) {
            warnings.add(
                'Parts of your route appear to be outside the Los Angeles City limits, please be aware, as the Risk Index of your route(s) may not be correct!');
          }

          //Route distance and duration inserted to all distances and durations array
          _allDurationsDistances.insert(i, {
            'distance': _weightedRoutes[i]['distance']['text'],
            'duration': _weightedRoutes[i]['duration']['text']
          });

          //Route weight color calculated and warning is the route has little to no data available
          String weight = '${_weightedRoutes[i]['weight']}';
          if (weight == '0' && !(_weightedRoutes[i]['accurate_zero_weight'])) {
            warnings.add(
                'Your route is in a region with little to no data, the Risk Index of your route(s) is unknown');
            weight = 'N/A';
            _bubbleMenuItems.add(Bubble(
                title: 'Route ${i + 1} | $weight',
                icon: Icons.alt_route,
                iconColor: Colors.black,
                bubbleColor: _greyColor,
                titleStyle: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    backgroundColor: _greyColor),
                onPress: () {
                  _chooseRoute(i);
                  _animationController.reverse();
                }));
            _allPolylines[i] = Polyline(
                polylineId: PolylineId('route$i'),
                visible: true,
                points: route,
                width: 8,
                color: _greyColor,
                startCap: Cap.roundCap,
                endCap: Cap.buttCap);
          } else {
            _bubbleMenuItems.add(Bubble(
                title: 'Route ${i + 1} | Risk Index: $weight',
                icon: Icons.alt_route,
                iconColor: Colors.black,
                bubbleColor: _useOriginalColors
                    ? _safetyColorsOriginal[fauxZeroCounter]
                    : _safetyColors[fauxZeroCounter],
                titleStyle: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    backgroundColor: _useOriginalColors
                        ? _safetyColorsOriginal[fauxZeroCounter]
                        : _safetyColors[fauxZeroCounter]),
                onPress: () {
                  _chooseRoute(i);
                  _animationController.reverse();
                }));
            _allPolylines[i] = Polyline(
                polylineId: PolylineId('route$i'),
                visible: true,
                points: route,
                width: 8,
                color: _useOriginalColors
                    ? _safetyColorsOriginal[fauxZeroCounter]
                    : _safetyColors[fauxZeroCounter],
                startCap: Cap.roundCap,
                endCap: Cap.buttCap);
            fauxZeroCounter += 1;
          }
          _allWarnings.insert(i, warnings);
        }

        Marker markerOrigin = Marker(
            markerId: MarkerId('origin'),
            position: _start,
            icon: BitmapDescriptor.fromBytes(originIcon),
            draggable: false,
            infoWindow: InfoWindow(
                title: 'Start: ${originAddressLineSplit[0]}',
                snippet:
                    '${originAddressLineSplit[1].trim()}, ${originAddressLineSplit[2].trim()}'));

        Marker markerDestination = Marker(
            markerId: MarkerId('destination'),
            position: _end,
            icon: BitmapDescriptor.fromBytes(destinationIcon),
            draggable: false,
            infoWindow: InfoWindow(
                title: 'End: ${destinationAddressLineSplit[0]}',
                snippet:
                    '${destinationAddressLineSplit[1].trim()}, ${destinationAddressLineSplit[2].trim()}'));

        setState(() {
          _statusMessage = jsonData['status'];
          _statusCode = response.statusCode;
          _markers.add(markerOrigin);
          _markers.add(markerDestination);
          _isVisible = true;
        });
      } else {
        setState(() {
          _statusMessage = jsonData['status'];
          _statusErrorMessage = jsonData['error_message'];
          _statusCode = response.statusCode;
        });
      }
    } else {
      setState(() {
        _statusCode = response.statusCode;
      });
    }
  }

  void _chooseRoute(int index) {
    if (_currentRoute != index) {
      setState(() {
        _currentRoute = index;
      });
    }
  }

  Widget _getBody() {
    if (_statusCode == 0) {
      return Center(
          child: SpinKitCircle(
        color: Color.fromRGBO(255, 120, 1, 1.0),
        size: 50.0,
      ));
    } else if (_statusCode == 200) {
      if (_statusMessage == 'OK') {
        return Stack(children: <Widget>[
          Container(
              child: _currentPage == 0
                  ? GoogleMap(
                      mapToolbarEnabled: false,
                      myLocationButtonEnabled: false,
                      initialCameraPosition: CameraPosition(
                        target: _midpoint,
                        zoom: 15.0,
                      ),
                      mapType: MapType.normal,
                      polylines: <Polyline>{_allPolylines[_currentRoute]},
                      markers: Set.from(_markers),
                    )
                  : _currentPage == 1
                      ? ListView.builder(
                          itemCount: _allSteps[_currentRoute].length,
                          itemBuilder: (BuildContext context, int index) {
                            return Container(
                                padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
                                child: index != 0
                                    ? Column(
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundImage: AssetImage(
                                                    'assets/instructions_paths.png'),
                                                maxRadius: 30,
                                                backgroundColor:
                                                    Colors.transparent,
                                                child: Text(
                                                  '$index',
                                                  style: GoogleFonts.roboto(
                                                      fontSize: 30,
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              Flexible(
                                                child: Html(
                                                  data:
                                                      '${_allSteps[_currentRoute][index]}',
                                                  style: {
                                                    "p": Style(
                                                      color: Colors.black,
                                                      fontSize: FontSize(25),
                                                      fontWeight:
                                                          FontWeight.w300,
                                                      fontFamily: 'Roboto',
                                                    ),
                                                    "div": Style(
                                                      color: Colors.red,
                                                      fontSize: FontSize(20),
                                                      fontWeight: _fontWeight,
                                                      fontFamily: 'Roboto',
                                                    )
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          Image.asset(
                                              'assets/divider3_lines.png'),
                                        ],
                                      )
                                    : SizedBox(
                                        height: 35,
                                      ));
                          })
                      : ListView.builder(
                          itemCount: _allWarnings[_currentRoute].length,
                          itemBuilder: (BuildContext context, int index) {
                            return Container(
                                padding: EdgeInsets.fromLTRB(15, 5, 5, 5),
                                child: index != 0
                                    ? Column(
                                        children: [
                                          RichText(
                                            text: TextSpan(
                                                style: GoogleFonts.roboto(
                                                    color: Colors.black,
                                                    fontSize: 20,
                                                    fontWeight: _fontWeight),
                                                children: [
                                                  WidgetSpan(
                                                      child: Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 1),
                                                    child: Icon(
                                                      Icons.warning,
                                                      color: Colors.red,
                                                    ),
                                                  )),
                                                  TextSpan(
                                                      text: _allWarnings[
                                                              _currentRoute]
                                                          [index]),
                                                ]),
                                          ),
                                          Image.asset('assets/divider3.png'),
                                        ],
                                      )
                                    : SizedBox(
                                        height: 35,
                                      ));
                          })),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black54, width: 5),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    new BoxShadow(
                      color: Colors.black87,
                    )
                  ]),
              child: Center(
                child: Text(
                  'Distance - ${_allDurationsDistances[_currentRoute]['distance']} | Duration - ${_allDurationsDistances[_currentRoute]['duration']}',
                  style: GoogleFonts.lato(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ]);
      } else {
        return Text('$_statusMessage\n$_statusErrorMessage');
      }
    } else {
      return Text('SafeWays Encountered an Unexpected Error');
    }
  }

  void _changePage(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                    Text(
                      'BACK',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    )
                  ],
                )),
          ],
          automaticallyImplyLeading: false,
          title: Text("Safest Path",
              style: GoogleFonts.roboto(fontWeight: _fontWeight)),
          backgroundColor: Color.fromRGBO(255, 120, 1, 1.0),
        ),
        body: _getBody(),
        bottomNavigationBar: BubbleBottomBar(
          opacity: 0.2,
          fabLocation: BubbleBottomBarFabLocation.end,
          backgroundColor: Color.fromRGBO(255, 120, 1, 1.0),
          elevation: 10,
          currentIndex: _currentPage,
          hasNotch: false,
          onTap: _changePage,
          items: <BubbleBottomBarItem>[
            BubbleBottomBarItem(
                icon: Icon(
                  Icons.map_outlined,
                  color: Colors.white,
                ),
                backgroundColor: Colors.white,
                activeIcon: Icon(
                  Icons.map_outlined,
                  color: Colors.black,
                ),
                title: Text(
                  'Map',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 18),
                )),
            BubbleBottomBarItem(
                icon: Icon(
                  Icons.list_alt_outlined,
                  color: Colors.white,
                ),
                backgroundColor: Colors.white,
                activeIcon: Icon(
                  Icons.list_alt_outlined,
                  color: Colors.black,
                ),
                title: Text(
                  'Directions',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 18),
                )),
            BubbleBottomBarItem(
                icon: Icon(
                  Icons.warning_amber_outlined,
                  color: Colors.white,
                ),
                backgroundColor: Colors.white,
                activeIcon: Icon(
                  Icons.warning_amber_outlined,
                  color: Colors.black,
                ),
                title: Text(
                  'Warnings',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 18),
                ))
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        floatingActionButton: Visibility(
          visible: _isVisible,
          child: FloatingActionBubble(
            items: _bubbleMenuItems,
            animation: _animation,
            onPress: () => _animationController.isCompleted
                ? _animationController.reverse()
                : _animationController.forward(),
            iconColor: Colors.white,
            iconData: Icons.alt_route_outlined,
            backGroundColor: Colors.black,
          ),
        ));
  }
}
