import 'dart:convert';
import 'package:untitled3/ui/forgetpassword.dart';
import 'package:untitled3/login.dart';
import 'package:untitled3/ui/homepage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';




class signUp extends StatefulWidget {
  const signUp({super.key});

  @override
  State<signUp> createState() => _signUpState();
}


class _signUpState extends State<signUp> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phone_numberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirm_passwordController = TextEditingController();
  bool _obsecure=true;
  bool _obsecure1=true;
  void _login() {
    String  name  = _nameController.text.trim();
    String  address = _addressController.text.trim();
    String  phone_number  = _phone_numberController.text.trim();
    String  email  = _emailController.text.trim();
    String  password  = _passwordController.text.trim();
    String  confirm_password  = _confirm_passwordController.text.trim();


    if (email.isEmpty || password.isEmpty|| name.isEmpty || phone_number.isEmpty|| confirm_password.isEmpty|| address.isEmpty) {

      return ;
    }
    postLogin();

  }

  Future postLogin() async {
    final response = await http.post(
        Uri.parse('https://api.sarbamfoods.com/accounts/signup/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          "name":_nameController.text.toString(),
          "phone_number":_phone_numberController.text.toString(),
          "address":_addressController.text.toString(),
          "email":_emailController.text.toString(),
          "password":_passwordController.text.toString(),
          "confirm_password":_confirm_passwordController.text.toString(),
        }));

    if(response.statusCode==200 ||response.statusCode==201 ){
      Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginPage()));
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
                  Text("SIGN UP",style: TextStyle(
                      fontSize: 65,
                      fontWeight: FontWeight.bold
                  ),),


                  Text("SignUp to continue",style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold
                  ),),


                  const SizedBox(height:50 ,),
                  TextFormField(

                    controller: _nameController,
                    decoration: InputDecoration(
                        hintText:'ENTER FIRST NAME',
                        hintStyle: TextStyle(fontFamily: "poppins", color:Colors.grey,fontSize: 16),
                        prefixIcon: Icon(Icons.account_box),
                        labelText: "Enter your first name",
                        contentPadding: EdgeInsets.symmetric(vertical:20.0,horizontal: 20.0),
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffcbcbcb),width: 18),
                            borderRadius: BorderRadius.all(Radius.elliptical(10, 10))
                        )

                    ),
                  ),
                  SizedBox(height: 20,),

                  TextFormField(

                    controller: _phone_numberController,
                    decoration: InputDecoration(
                        hintText:'ENTER PHONE NUMBER',
                        hintStyle: TextStyle(fontFamily: "poppins", color:Colors.grey,fontSize: 16),
                        prefixIcon: Icon(Icons.phone),
                        labelText: "Enter your Phone number",
                        contentPadding: EdgeInsets.symmetric(vertical:20.0,horizontal: 20.0),
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffcbcbcb),width: 18),
                            borderRadius: BorderRadius.all(Radius.elliptical(10, 10))
                        )

                    ),
                  ),
                  SizedBox(height: 20,),

                  TextFormField(

                    controller: _addressController,
                    decoration: InputDecoration(
                        hintText:'ENTER YOUR ADDRESS',
                        hintStyle: TextStyle(fontFamily: "poppins", color:Colors.grey,fontSize: 16),
                        prefixIcon: Icon(Icons.location_history),
                        labelText: "Enter your adress",
                        contentPadding: EdgeInsets.symmetric(vertical:20.0,horizontal: 20.0),
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffcbcbcb),width: 18),
                            borderRadius: BorderRadius.all(Radius.elliptical(10, 10))
                        )

                    ),
                  ),
                  SizedBox(height: 20,),
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
                        prefixIcon: Icon(Icons.password),
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
                  SizedBox(height: 20,),
                  TextFormField(
                    controller: _confirm_passwordController,
                    obscureText: _obsecure,

                    decoration: InputDecoration(
                        hintText:'ENTER PASSWORD',
                        hintStyle: TextStyle(fontFamily: "poppins", color:Colors.grey,fontSize: 16),
                        prefixIcon: Icon(Icons.password_sharp),
                        suffixIcon: GestureDetector(
                            onTap: (){
                              if(_obsecure1==true){
                                setState(() {
                                  _obsecure1=false;
                                });
                              }else{
                                setState(() {
                                  _obsecure1=true;
                                });
                              }
                            },
                            child: Icon(_obsecure1?Icons.remove_red_eye:Icons.remove_red_eye_outlined)),
                        labelText: "Confirm password",
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

                          child: Center(child: Text("Sign up",style: TextStyle(fontSize: 20,color: Colors.black),))),
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



