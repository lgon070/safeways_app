import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_ways/data/delayed_animation.dart';
import 'package:safe_ways/pages/directory.dart';

//SplashScreen made using sagarshende23 Reflectly Login Screen splash page
//https://github.com/sagarshende23/Reflectly-Login-Screen
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final int _delayedAmount = 500;
  double _scale;
  AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 200,
      ),
      lowerBound: 0.0,
      upperBound: 0.1,
    )..addListener(() {
        setState(() {});
      });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Colors.white;
    final fontWeight = FontWeight.w600;
    _scale = 1 - _controller.value;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color.fromRGBO(195, 195, 195, 1.0),
        body: Stack(
          children: [
            Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/losangeles_lax_bw_ext.jpg"),
                        fit: BoxFit.cover))),
            Container(
              decoration: BoxDecoration(color: Colors.black54),
              height: double.infinity,
              width: double.infinity,
              child: Center(
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: 50.0,
                    ),
                    AvatarGlow(
                      endRadius: 120,
                      duration: Duration(seconds: 2),
                      glowColor: Colors.white24,
                      repeat: true,
                      repeatPauseDuration: Duration(seconds: 2),
                      startDelay: Duration(seconds: 1),
                      child: Image.asset(
                        'assets/safeways.png',
                        height: 125,
                        width: 125,
                      ),
                    ),
                    DelayedAnimation(
                      child: Text(
                        "Hi There!",
                        style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                            fontSize: 35.0,
                            color: color),
                      ),
                      delay: _delayedAmount + 1000,
                    ),
                    DelayedAnimation(
                      child: Text(
                        "I'm SafeWays",
                        style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                            fontSize: 35.0,
                            color: color),
                      ),
                      delay: _delayedAmount + 1500,
                    ),
                    SizedBox(
                      height: 30.0,
                    ),
                    DelayedAnimation(
                      child: Text(
                        "Your New Personal",
                        style: GoogleFonts.roboto(
                            fontSize: 20.0,
                            color: color,
                            fontWeight: fontWeight),
                      ),
                      delay: _delayedAmount + 2000,
                    ),
                    DelayedAnimation(
                      child: Text(
                        "Traveling companion",
                        style: GoogleFonts.roboto(
                            fontSize: 20.0,
                            color: color,
                            fontWeight: fontWeight),
                      ),
                      delay: _delayedAmount + 2500,
                    ),
                    SizedBox(
                      height: 50.0,
                    ),
                    DelayedAnimation(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Directory(index: 1)));
                        },
                        onTapDown: _onTapDown,
                        onTapUp: _onTapUp,
                        child: Transform.scale(
                          scale: _scale,
                          child: _animatedContinueButtonUI,
                        ),
                      ),
                      delay: _delayedAmount + 3000,
                    ),
                    SizedBox(
                      height: 25.0,
                    ),
                    DelayedAnimation(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Directory(index: 3)));
                        },
                        onTapDown: _onTapDown,
                        onTapUp: _onTapUp,
                        child: Transform.scale(
                          scale: _scale,
                          child: _animatedTourButtonUI,
                        ),
                      ),
                      delay: _delayedAmount + 3500,
                    ),
                    SizedBox(
                      height: 25.0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _animatedTourButtonUI => Container(
        height: 60,
        width: 270,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100.0),
          color: Color.fromRGBO(195, 195, 195, 1.0),
        ),
        child: Center(
          child: Text(
            'How to Use?',
            style: GoogleFonts.roboto(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );

  Widget get _animatedContinueButtonUI => Container(
        height: 60,
        width: 270,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100.0),
          color: Color.fromRGBO(195, 195, 195, 1.0),
        ),
        child: Center(
          child: Text(
            'Let\'s Continue',
            style: GoogleFonts.roboto(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }
}
