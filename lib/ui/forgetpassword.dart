import 'dart:convert';
import 'package:untitled3/ui/homepage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';




class forgetPassword extends StatefulWidget {
  const forgetPassword({super.key});

  @override
  State<forgetPassword> createState() => _LoginPageState();
}


class _LoginPageState extends State<forgetPassword> {
  final TextEditingController _emailController = TextEditingController();


  void _login() {
    String email = _emailController.text.trim();

  }

  Future postLogin() async {
    final response = await http.post(
        Uri.parse('https://api.sarbamfoods.com/accounts/forgot_password/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          "email":_emailController.text.toString(),

        }));

    if(response.statusCode==200){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>HomePage()));
    }else{
      Fluttertoast.showToast(
          msg: "Invalid credentials",
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
      );
    }
    return response;
  }



  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body:
        Padding(

          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(


                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  SizedBox(height: 30,),
                  Text("Welcome",style: TextStyle(
                      fontSize: 65,
                      fontWeight: FontWeight.bold
                  ),),


                  Text("TO CHANGE PASSWORD",style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold
                  ),),


                  const SizedBox(height:100 ,),

                  TextFormField(

                    controller: _emailController,
                    decoration: InputDecoration(
                        hintText:'ENTER USERNAME',
                        hintStyle: TextStyle(fontFamily: "poppins", color:Colors.grey,fontSize: 16),
                        prefixIcon: Icon(Icons.email),
                        labelText: "Enter your email",
                        contentPadding: EdgeInsets.symmetric(vertical:20.0,horizontal: 20.0),
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffcbcbcb),width: 18),
                            borderRadius: BorderRadius.all(Radius.elliptical(10, 10))
                        )

                    ),
                  ),



                  SizedBox(height: 40,),


                  Center(
                    child: SizedBox(
                      height: 50,
                      width: 1500,

                      child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(

                              borderRadius: BorderRadius.circular(100.0),

                            ),
                          ),

                          child: Center(child: Text("SUBMIT",style: TextStyle(fontSize: 20,color: Colors.black),))),
                    ),
                  ),





                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



