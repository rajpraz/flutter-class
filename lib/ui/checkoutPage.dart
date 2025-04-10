import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../integration/khalti.dart';
import 'homepage.dart';

enum PaymentMethod { esewa, cod, khalti }

class CheckoutPage extends StatefulWidget {
  final double price;
  CheckoutPage({super.key, required this.price});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  String currentAddress = '';
  double latitude = 0.0;
  double longitude = 0.0;
  List<Map<String, dynamic>> cartItems = [];
  PaymentMethod? selectedPaymentMethod;


  Future<void> sendOrderEmail(List<Map<String, dynamic>> cartItems) async {
    final String serviceId = 'service_al7vazj';
    final String templateId = 'template_flcr12v';
    final String userId = 'oPGEMtN0yn6uz_g1n';
    SharedPreferences prefs=await SharedPreferences.getInstance();

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    List<Map<String, dynamic>> formattedCartItems = cartItems.map((item) {
      return {
        'name': item['name'],
        'image_url': item['image'],
        'units': item['quantity'] ?? 1,
        'price': item['price'].toString(),
      };
    }).toList();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'origin': 'http://localhost'
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'order_id': DateTime.now().millisecondsSinceEpoch.toString(),
          'customer_name': phoneController.text,
          'email': "prajapatiraj1225@gmail.com",
          'orders': formattedCartItems,
          'cost': {
            'shipping': '50',
            'tax': '100',
            'total': widget.price.toString(),
          }
        },
      }),
    );

    if (response.statusCode == 200) {


      print('Email sent successfully!');
    } else {
      print('Failed to send email: ${response.body}');
    }
  }



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
    });
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    latitude = position.latitude;
    longitude = position.longitude;

    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
    Placemark place = placemarks[0];
    setState(() {
      currentAddress = '${place.subLocality}, ${place.locality}, ${place.country}';
    });
  }

  void proceedToPayment() {
    if (nameController.text.isEmpty||phoneController.text.isEmpty||currentAddress.isEmpty || emailController.text.isEmpty  || selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a payment method')),
      );
      return;
    }
    KhaltiScope.of(context).pay(
        config: PaymentConfig(
            amount:(widget.price*100).toInt() ,
            productIdentity: 'laptop',
            productName: 'Dell laptop'),
        preferences: [
          PaymentPreference.khalti,
          PaymentPreference.connectIPS,
          PaymentPreference.eBanking,
        ],
        onSuccess: (success){

          print("Payment Success: $success");
          sendOrderEmail(cartItems);
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Payment Successful'),
                content: Text('Response: $success'),
                actions: <Widget>[
                  TextButton(
                    onPressed: ()async {
                      SharedPreferences prefs=await SharedPreferences.getInstance();
                      prefs.remove('cart');
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),

                      );
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        },
        onFailure: (failure){

        });
    // Navigator.push(context, MaterialPageRoute(builder: (context)=>PaymentPage()));
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

              controller: phoneController,
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
            const SizedBox(height: 20),
            DropdownButtonFormField<PaymentMethod>(
              value: selectedPaymentMethod,
              items: PaymentMethod.values.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (method) {
                setState(() {
                  selectedPaymentMethod = method;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Select Payment Method',
                border: OutlineInputBorder(),
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
