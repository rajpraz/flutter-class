import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled3/login.dart';
import 'package:untitled3/ui/homepage.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  String token = "";

  void checkAccess()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token =  prefs.getString("token")??"";

      if(token.isEmpty){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>LoginPage()));
      }else{
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>HomePage()));
      }
    });

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
    setState(() {
      checkAccess();
    });
    });

  }

  @override
  Widget build(BuildContext context) {
    return SafeArea
      (child: Scaffold(
      backgroundColor: Colors.grey,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    ));
  }
}
