import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:safe_ways/data/global_data.dart';
import 'package:safe_ways/pages/history.dart';
import 'package:safe_ways/pages/info.dart';
import 'package:safe_ways/pages/navigation.dart';
import 'package:safe_ways/pages/stations.dart';

// ignore: must_be_immutable
class Directory extends StatefulWidget {
  int index;

  Directory({Key key, this.index}) : super(key: key);

  @override
  _DirectoryState createState() => _DirectoryState();
}

class _DirectoryState extends State<Directory> {
  int _currentIndex = 1;
  final _navIconSize = 25.0;
  final _navBarSize = 60.0;

  @override
  void initState() {
    _currentIndex = widget.index == null ? 1 : widget.index;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Color _getPageColor(int index, bool isOpaque) {
    if (index == 0) {
      return isOpaque
          ? Color.fromRGBO(255, 174, 8, 1)
          : Color.fromRGBO(252, 211, 129, 1);
    } else if (index == 1) {
      return isOpaque
          ? Color.fromRGBO(35, 113, 231, 1)
          : Color.fromRGBO(142, 181, 240, 1);
    } else if (index == 2) {
      return isOpaque
          ? Color.fromRGBO(14, 136, 78, 1)
          : Color.fromRGBO(132, 192, 164, 1);
    } else if (index == 3) {
      return isOpaque
          ? Color.fromRGBO(255, 47, 0, 1)
          : Color.fromRGBO(252, 147, 125, 1);
    } else {
      return Color.fromRGBO(255, 255, 255, isOpaque ? 1.0 : 0.5);
    }
  }

  Widget _getPages(int index) {
    if (index == 0) {
      return History();
    } else if (index == 1) {
      return Navigation(GlobalData.stationData);
    } else if (index == 2) {
      return Stations(GlobalData.stationData);
    } else if (index == 3) {
      return Info();
    } else {
      return Directory();
    }
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getPages(_currentIndex),
      bottomNavigationBar: CurvedNavigationBar(
        color: _getPageColor(_currentIndex, true),
        backgroundColor: _getPageColor(_currentIndex, false),
        buttonBackgroundColor: _getPageColor(_currentIndex, true),
        height: _navBarSize,
        items: <Widget>[
          Icon(
            Icons.history_outlined,
            size: _navIconSize,
            color: Colors.black,
          ),
          Icon(
            Icons.navigation_outlined,
            size: _navIconSize,
            color: Colors.black,
          ),
          Icon(
            Icons.directions_bike_outlined,
            size: _navIconSize,
            color: Colors.black,
          ),
          Icon(
            Icons.info_outline,
            size: _navIconSize,
            color: Colors.black,
          ),
        ],
        index: _currentIndex,
        onTap: (index) => {
          setState(() {
            _currentIndex = index;
          })
        },
        animationDuration: Duration(milliseconds: 350),
        animationCurve: Curves.easeInCubic,
      ),
    );
  }
}
