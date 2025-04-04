import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'homepage.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController PhoneController = TextEditingController();
  List<Map<String, dynamic>> cartItems = [];
  String currentAddress = '';
  double latitude = 0.0;
  double longitude = 0.0;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    loadCartItems();

  }
  Future<void> loadCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cart = prefs.getStringList('cart') ?? [];

    setState(() {
      cartItems = cart.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
      log(cartItems.toString());

    });
  }
  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();


    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever||permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always) {

        return;
      }
    }
    if (!serviceEnabled) {

      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    latitude = position.latitude;
    longitude = position.longitude;
    log(latitude.toString());
    log(longitude.toString());

    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
    Placemark place = placemarks[0];
    log(place.toString());
    setState(() {

      currentAddress = '${place.subLocality}, ${place.locality}, ${place.country}';
    });
  }


  void proceedToPayment() {
    if (nameController.text.isEmpty || currentAddress.isEmpty||addressController.text.isEmpty||PhoneController.text.isEmpty||emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proceeding to payment')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(

              controller: emailController,
              decoration: InputDecoration(
                  labelText: "Email",
                  contentPadding: EdgeInsets.symmetric(vertical:20.0,horizontal: 20.0),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xffcbcbcb),width: 18),
                      borderRadius: BorderRadius.all(Radius.elliptical(10, 10))
                  )

              ),
            ),
            SizedBox(height: 16,),
            TextFormField(

              controller: PhoneController,
              decoration: InputDecoration(
                  labelText: "Phone number",
                  contentPadding: EdgeInsets.symmetric(vertical:20.0,horizontal: 20.0),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xffcbcbcb),width: 18),
                      borderRadius: BorderRadius.all(Radius.elliptical(10, 10))
                  )

              ),
            ),
            SizedBox(height: 16,),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Address:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(currentAddress.isEmpty ? 'Fetching address...' : currentAddress),
                ],
              ),
            ),
            SizedBox(height: 20,),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,  // Background color
          ),
          child: DataTable(
            columnSpacing: 15,

            columns:  [
              DataColumn(label: Text('Image')),
              DataColumn(label: Text('Product')),
              DataColumn(label: Text('Price')),
              DataColumn(label: Text('Remove')),
            ],
            rows: cartItems.map((item) {
              return DataRow(
                cells: [
                  DataCell(
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.network(
                        item['image'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  DataCell(Text(item['name'])),
                  DataCell(Text('Rs.${item['price']}')),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        int index = cartItems.indexOf(item);

                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),




    SizedBox(height: 20),
            ElevatedButton(
              onPressed: proceedToPayment,
              child: const Text('Proceed to Payment'),
            ),
          ],
        ),
      ),
    );
  }
}