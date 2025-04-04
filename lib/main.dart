import 'package:flutter/material.dart';
import 'package:untitled3/testpage.dart';
import 'package:untitled3/ui/cart.dart';
import 'package:untitled3/ui/homepage.dart';
import 'package:untitled3/ui/splashScreen.dart';
import 'login.dart';
import 'ui/forgetpassword.dart';
import 'ui/signUp.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(

      ),
    );
  }
}

