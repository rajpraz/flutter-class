import 'dart:io';
import 'package:flutter/material.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}
class _PaymentPageState extends State<PaymentPage> {
  /// Variables
  TextEditingController price = TextEditingController();

  getAmt(){
    return int.parse(price.text) *100;
  }

  /// Widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Khalti payment"),
        ),
        body:  Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Form(

                child: Column(
                  children: [
                    TextField(

                      // The validator receives the text that the user has entered.
                        controller: price,
                        cursorColor: Colors.brown.shade800,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {

                        },
                        style: const TextStyle(color: Colors.grey),
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelStyle: TextStyle(color: Colors.grey,fontSize: 14),
                          hintStyle: TextStyle(color: Colors.grey,fontSize: 14),
                          hintText: 'Enter a Value',
                          contentPadding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 18.0),
                          border: OutlineInputBorder(

                            borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white, width: 3.0),
                            borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white, width: 3.0),
                            borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          ),
                        )
                    ),


                  ],
                ),
              ),
              ElevatedButton(
                style:
                ElevatedButton.styleFrom(backgroundColor: const Color(0xff2424143)),
                onPressed: () {
                  KhaltiScope.of(context).pay(
                      config: PaymentConfig(
                          amount:getAmt() ,
                          productIdentity: 'laptop',
                          productName: 'Dell laptop'),
                      preferences: [
                        PaymentPreference.khalti,
                        PaymentPreference.connectIPS
                      ],
                      onSuccess: (success){





                      },
                      onFailure: (failure){

                      });
                },
                child: const Text('Complete'),
              ),
            ],
          ),
        )
    );
  }
}