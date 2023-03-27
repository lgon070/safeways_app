import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_ways/data/global_data.dart';
import 'package:weather/weather.dart';

// ignore: must_be_immutable
class Info extends StatefulWidget {
  Info();

  @override
  _InfoState createState() => _InfoState();
}

class _InfoState extends State<Info> {
  WeatherFactory _wf;
  Color _color = Colors.white;

  _InfoState();

  void initState() {
    _wf = WeatherFactory(GlobalData.openWeatherApiKey,
        language: Language.ENGLISH);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<Weather> _getWeather() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    Weather weatherNearUser = await _wf.currentWeatherByLocation(
        position.latitude, position.longitude);
    return weatherNearUser;
  }

  Widget _createWeatherCard(BuildContext context, AsyncSnapshot snapshot) {
    Weather w = snapshot.data;
    String assetName = "";
    int hour = w.date.hour;

    if (hour >= 4 && hour <= 8) {
      assetName = "sunrise.jpg";
    } else if (hour >= 9 && hour <= 15) {
      assetName = "midday.jpg";
    } else if (hour >= 16 && hour <= 19) {
      assetName = "sunset.jpg";
    } else {
      assetName = "nighttime.jpg";
    }

    return Container(
      child: Stack(
        children: <Widget>[
          Image.asset(
            'assets/losangeles-$assetName',
            height: 125,
            width: double.infinity,
            fit: BoxFit.fitWidth,
          ),
          Container(
              decoration: BoxDecoration(color: Colors.black26),
              height: 125,
              width: double.infinity),
          Container(
            height: 125,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(5, 25, 0, 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${w.weatherDescription}',
                            style: GoogleFonts.lato(
                                fontSize:
                                    w.weatherDescription.length >= 15 ? 20 : 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text(
                          '${w.areaName}',
                          style: GoogleFonts.lato(
                              fontSize: w.areaName.length >= 18 ? 15 : 20,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 125,
                  padding: EdgeInsets.fromLTRB(25, 0, 5, 0),
                  child: Text(
                    '${w.temperature.fahrenheit.toStringAsFixed(0)} \u2109',
                    style: GoogleFonts.lato(
                        fontSize: 60,
                        fontWeight: FontWeight.w300,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _directoryContainer() {
    return Container(
        padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
        child: Column(
          children: <Widget>[
            Text(
              "Directory",
              style: GoogleFonts.roboto(
                  fontSize: 35, fontWeight: FontWeight.bold, color: _color),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Color.fromRGBO(255, 174, 8, 1.0),
                    width: 5,
                  )),
              child: Image.asset("assets/directory_info.png"),
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              "The main directory of the application is located on the bottom of the device. "
              "The directory is broken in four main pages to keep navigation "
              "simple and effective. From left to right we have the History, Navigation, Stations, and Information",
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.normal,
                color: _color,
              ),
            ),
            SizedBox(
              height: 10,
            ),
          ],
        ));
  }

  Widget _navigationContainer() {
    return Container(
        padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
        child: Column(
          children: <Widget>[
            Text(
              "Navigation",
              style: GoogleFonts.roboto(
                  fontSize: 35, fontWeight: FontWeight.bold, color: _color),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Color.fromRGBO(35, 113, 231, 1.0),
                    width: 5,
                  )),
              child: Image.asset("assets/navigation_info.png"),
            ),
            SizedBox(
              height: 5,
            ),
            RichText(
                text: TextSpan(
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                      color: _color,
                    ),
                    children: [
                  TextSpan(
                      text:
                          "The navigation page allows you travel to a specified location using the safest path available. "
                          "You can choose between walking or cycling by tapping the button on the lower left of the screen. "
                          "To navigate you will first need to place a marker ("),
                  WidgetSpan(
                      child: Padding(
                    padding: EdgeInsets.fromLTRB(1, 0, 1, 0),
                    child: Image.asset("assets/destinationMarker.png",
                        height: 25, width: 25),
                  )),
                  TextSpan(
                      text:
                          "). To place a marker you can either tap on the map or search a location using the Where To? search bar. "
                          "Once you have placed a marker, you can tap on the marker and the Navigate button will turn green. "
                          "You can also tap on a metro bike station marker ("),
                  WidgetSpan(
                      child: Padding(
                    padding: EdgeInsets.fromLTRB(1, 0, 1, 0),
                    child: Image.asset("assets/bikemarker.png",
                        height: 25, width: 25),
                  )),
                  TextSpan(
                      text: ") to travel directly to the station location."),
                ])),
            SizedBox(
              height: 10,
            ),
          ],
        ));
  }

  Widget _historyContainer() {
    return Container(
        padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
        child: Column(
          children: <Widget>[
            Text(
              "History",
              style: GoogleFonts.roboto(
                  fontSize: 35, fontWeight: FontWeight.bold, color: _color),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Color.fromRGBO(14, 136, 78, 1.0),
                    width: 5,
                  )),
              child: Image.asset("assets/history_info.png"),
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              "The history page allows you to see all the locations you have chosen to navigate to. A history entry shows you the address, date, and time you traveled to. "
              "The button on the lower center allows you to toggle between walking and cycling.",
              style: GoogleFonts.roboto(
                  fontSize: 20, fontWeight: FontWeight.normal, color: _color),
            ),
            SizedBox(
              height: 10,
            ),
          ],
        ));
  }

  Widget _stationContainer() {
    return Container(
        padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
        child: Column(
          children: <Widget>[
            Text(
              "Stations",
              style: GoogleFonts.roboto(
                  fontSize: 35, fontWeight: FontWeight.bold, color: _color),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Color.fromRGBO(255, 47, 0, 1.0),
                    width: 5,
                  )),
              child: Image.asset("assets/stations_info.png"),
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              "The stations page allows you to see all the Metro Bike Stations location in Los Angeles. "
              "A station entry shows you the name, and address of the station as well as the number of bikes available in the station circled on the left of the entry. "
              "The button on the lower center allows you to toggle between walking or cycling.",
              style: GoogleFonts.roboto(
                  fontSize: 20, fontWeight: FontWeight.normal, color: _color),
            ),
            SizedBox(
              height: 10,
            ),
          ],
        ));
  }

  Widget _pathsContainer() {
    return Container(
        padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
        child: Column(
          children: <Widget>[
            Text(
              "Paths",
              style: GoogleFonts.roboto(
                  fontSize: 35, fontWeight: FontWeight.bold, color: _color),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Color.fromRGBO(255, 120, 1, 1.0),
                    width: 5,
                  )),
              child: Image.asset("assets/paths_info.png"),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Color.fromRGBO(120, 14, 103, 1.0),
                    width: 5,
                  )),
              child: Image.asset("assets/paths_rm_info.png"),
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              "The paths page displays by default the safest path from your chosen origin and destination points. "
              "You can change or view all available routes by tapping the center bottom button. "
              "Any warnings given by SafeWays or Google about the route can be seen by selecting the warning button on the bottom left. "
              "You can return at any time by selecting the back button located on the top and bottom right sides ",
              style: GoogleFonts.roboto(
                  fontSize: 20, fontWeight: FontWeight.normal, color: _color),
            ),
            SizedBox(
              height: 10,
            ),
          ],
        ));
  }

  Widget _tips() {
    return Container(
        padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
        child: Column(
          children: <Widget>[
            Text(
              "Safety Suggestions",
              style: GoogleFonts.roboto(
                  fontSize: 35, fontWeight: FontWeight.bold, color: _color),
            ),
            Container(
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset('assets/bike_info.png',
                          height: 80, width: 80),
                      SizedBox(width: 25),
                      Text(
                        "Bikes and Lanes",
                        style: GoogleFonts.roboto(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: _color),
                      ),
                    ],
                  ),
                  Text(
                    "If you are a bicyclist and no bicycle lanes are present, it is recommended to use the sidewalks until a bicycle lane reemerges.",
                    style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.normal,
                        color: _color),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 5,
            ),
            Container(
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset('assets/phone_info.png',
                          height: 80, width: 80),
                      SizedBox(width: 25),
                      Text(
                        "Electronics",
                        style: GoogleFonts.roboto(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: _color),
                      ),
                    ],
                  ),
                  Text(
                    "When crossing a street or walking through a narrow sidewalk do not use your electronic devices and maintain your eyes on the path.",
                    style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.normal,
                        color: _color),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 5,
            ),
            Container(
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset('assets/vest_info.png',
                          height: 80, width: 80),
                      SizedBox(width: 25),
                      Text(
                        "Clothing Styles",
                        style: GoogleFonts.roboto(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: _color),
                      ),
                    ],
                  ),
                  Text(
                    "Using reflective or bright clothes helps pedestrians and bicyclists be more visible to drivers and other people in the road.",
                    style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.normal,
                        color: _color),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 5,
            ),
            Container(
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset('assets/beer_info.png',
                          height: 80, width: 80),
                      SizedBox(width: 25),
                      Text(
                        "Drugs and Alcohol",
                        style: GoogleFonts.roboto(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: _color),
                      ),
                    ],
                  ),
                  Text(
                    "Using drugs, alcohol, or medicine that impairs your driving should be avoided at all costs. Remember Driving Under the Influence does not just mean driving a car drunk. "
                    "For example if you take medicine that makes impairs your driving, so you decide to bike home, you can still get a DUI",
                    style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.normal,
                        color: _color),
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  Widget _otherInfo() {
    return Container(
        padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
        child: Column(
          children: <Widget>[
            Text(
              "SafeWays is currently in its beta stages of development. You may encounter bugs and glitches that may impact your performance or "
              "even cause the app to not function. SafeWays is meant to be an aide to your travel destination. SafeWays relies on LA City collision data gathered from police, and civilian reports, so "
              "your calculated route may still pose a risk to your safety because of unknown or never reported accidents. The route displayed is also not a route where there is zero chances of risk, it is simply "
              "the safest path the SafeWays algorithm calculated from a pool of various other paths. SafeWays does not store any personal data on our servers, all search and location history is kept within the device. Uninstalling SafeWays removes all "
              "your search and location data.",
              style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(195, 195, 195, 1.0)),
            )
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    FutureBuilder weatherContainer = new FutureBuilder(
        future: _getWeather(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return new Container(
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/losangeles_weatherplaceholder.jpg',
                      fit: BoxFit.cover,
                      height: 125,
                      width: double.infinity,
                    ),
                    Container(
                        decoration: BoxDecoration(color: Colors.black26),
                        height: 125,
                        width: double.infinity),
                    Container(
                      child: Text('waiting on Open Weather',
                          style: GoogleFonts.lato(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ],
                ),
              );
            case ConnectionState.waiting:
              return new Container(
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/losangeles_weatherplaceholder.jpg',
                      fit: BoxFit.cover,
                      height: 125,
                      width: double.infinity,
                    ),
                    Container(
                        decoration: BoxDecoration(color: Colors.black26),
                        height: 125,
                        width: double.infinity),
                    Container(
                      child: Text('fetching weather',
                          style: GoogleFonts.lato(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ],
                ),
              );
            default:
              if (snapshot.hasError) {
                return new Container(
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/losangeles_weatherplaceholder.jpg',
                        fit: BoxFit.cover,
                        height: 125,
                        width: double.infinity,
                      ),
                      Container(
                          decoration: BoxDecoration(color: Colors.black26),
                          height: 125,
                          width: double.infinity),
                      Container(
                        child: Text('an error occured :(',
                            style: GoogleFonts.lato(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                );
              } else {
                return _createWeatherCard(context, snapshot);
              }
          }
        });

    return new Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text("Info and Tips"),
          backgroundColor: Color.fromRGBO(255, 47, 0, 1.0)),
      body: Stack(
        children: [
          Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("assets/losangeles_vertical3_bw.jpg"),
                      fit: BoxFit.cover))),
          Container(
            decoration: BoxDecoration(color: Colors.black54),
            height: double.infinity,
            width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  weatherContainer,
                  Image.asset(
                    "assets/divider.png",
                  ),
                  _directoryContainer(),
                  _navigationContainer(),
                  _historyContainer(),
                  _stationContainer(),
                  _pathsContainer(),
                  SizedBox(height: 10),
                  Image.asset(
                    "assets/divider.png",
                  ),
                  _tips(),
                  SizedBox(height: 10),
                  Image.asset(
                    "assets/divider.png",
                  ),
                  _otherInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
