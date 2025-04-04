import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled3/ui/forgetpassword.dart';
import 'package:untitled3/ui/homepage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:untitled3/ui/signUp.dart';




class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}


class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obsecure=true;
  bool _ischecked=false;
  void _signUp(){
    Navigator.push(context,
        MaterialPageRoute(builder: (context)=>signUp()));
  }
  void _forgetPassword(){

  }
  void _login() {
    String  email  = _emailController.text.trim();
    String  password  = _passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {

  return ;
  }
  postLogin();

}

  Future postLogin() async {
    SharedPreferences save = await SharedPreferences.getInstance();
    final response = await http.post(
        Uri.parse('https://api.sarbamfoods.com/accounts/login/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          "email":_emailController.text.toString(),
          "password":_passwordController.text.toString(),
        }));

    if(response.statusCode==200){
     if( _ischecked=true) {
       save.setString("token", jsonDecode(response.body)["access_token"]);
     }
      log(save.getString("token")!);
      Navigator.push(context, MaterialPageRoute(builder: (context)=>HomePage()));
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


                   Text("Please login",style: TextStyle(
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
                    SizedBox(height: 20,),
                    TextFormField(
                    controller: _passwordController,
                      obscureText: _obsecure,

                      decoration: InputDecoration(
                          hintText:'ENTER PASSWORD',
                          hintStyle: TextStyle(fontFamily: "poppins", color:Colors.grey,fontSize: 16),
                        suffixIcon: GestureDetector(
                            onTap: (){
                              if(_obsecure==true){
                                setState(() {
                                  _obsecure=false;
                                });
                              }else{
                                setState(() {
                                  _obsecure=true;
                                });
                              }
                            },
                            child: Icon(_obsecure?Icons.remove_red_eye:Icons.remove_red_eye_outlined)),
                          labelText: "Enter your password",
                          contentPadding: EdgeInsets.symmetric(vertical:20.0,horizontal: 20.0),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xffcbcbcb),width: 18),
                              borderRadius: BorderRadius.all(Radius.elliptical(10, 10))
                          )

                      ),

                    ),
                  SizedBox(height: 10,),

                  SizedBox(
                    height: 50,
                      width: 300,
                      child: Row (
                        children: [
                          Checkbox(value: _ischecked, onChanged:(bool? value){
                            setState(() {
                              _ischecked=value!;
                            });
                          },
  ),
                          GestureDetector(onTap: (){
                            setState(() {
                              _ischecked==true?_ischecked=false:_ischecked=true;
                            });
                          },

                              child: Text("remeber me")),
                        ]
                      ),


          ),
                  SizedBox(height: 20),
                  SizedBox(
                    child: Center(
                      child: ElevatedButton(
                          onPressed: _forgetPassword,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                          ),
                          child:  Text("Forget password?",style: TextStyle(fontSize: 16,color: Colors.black),)),
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

                            child: Center(child: Text("Log In",style: TextStyle(fontSize: 20,color: Colors.black),))),
                     ),
                   ),




                  SizedBox(height: 60,),
                  Text("------DONT HAVE ACCOUNT?THEN SIGN UP.-------"),
                  SizedBox(height: 40,),
                  Center(
                    child: SizedBox(
                      height: 50,
                      width: 1500,

                      child: ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(

                              borderRadius: BorderRadius.circular(100.0),

                            ),
                          ),

                          child: Center(child: Text("Sign Up",style: TextStyle(fontSize: 20,color: Colors.black),))),
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



