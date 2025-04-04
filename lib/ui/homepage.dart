import 'dart:convert';
import 'dart:developer';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled3/ui/cart.dart';
import 'package:untitled3/ui/detail.dart';
import 'package:untitled3/ui/splashScreen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> cartItems = [];
  Future<void> loadCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cart = prefs.getStringList('cart') ?? [];

    setState(() {
      cartItems = cart.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();

    });
  }

  Future<void> addToCart(Map<String, dynamic> list) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>   cart  = prefs.getStringList('cart') ?? [];
    cart.add(jsonEncode(list));
    await prefs.setStringList('cart', cart);
    loadCartItems();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to cart!')),
    );
  }




  final List<String> images = [
    'https://cdn.pixabay.com/photo/2022/06/21/07/04/anime-7275258_1280.jpg',
    'https://cdn.pixabay.com/photo/2020/04/25/09/52/onepiece-5090120_1280.jpg',
    'https://wallpapers.com/images/high/demon-slayer-tanjiro-with-nezuko-3fn68n43wwpmix8c.webp',
  ];

  final List<Map<String, dynamic>> products = [
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/bcd84731a3eda4f4a306250769675065.jpg', 'name': 'One piece', 'rating': '#1'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/65f92e6e315a931ef872da4b312442b8.jpg', 'name': 'Solo leveling', 'rating': '#2'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/2cbe94bcbf18f0f3c205325d4e234d16.jpg', 'name': 'Dragon ball', 'rating': '#3'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/2bbe7ece956bbefc6f385a7a447c182c.jpg', 'name': 'Sakamoto days', 'rating': '#4'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/c7346b9cd930d501d2b6b40770b2b1d0.jpg', 'name': 'Apothecary ', 'rating': '#5'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/c2a246a281ee33d66635458797ce76cf.jpg', 'name': 'Happy marriage', 'rating': '#6'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/ebb78f8688b59abf0409b8799159127a.jpg', 'name': 'Arifureta', 'rating': '#7'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/b8169841c47c010d664f293fcec036fb.jpg', 'name': 'Blue box', 'rating': '#8'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/a8b56a7589ff9edb6c86977c31e27a06.jpg', 'name': 'Dandan', 'rating': '#9'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/d9bb23228e5a641b5a3e9386382dae3a.jpg', 'name': 'Wind breaker', 'rating': '#15343'},
  ];

  final List<Map<String, dynamic>> list = [
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/bcd84731a3eda4f4a306250769675065.jpg', 'name': 'One piece', 'rating': '#1','price':10.0},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/65f92e6e315a931ef872da4b312442b8.jpg', 'name': 'Solo leveling', 'rating': '#2','price':10.0},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/2cbe94bcbf18f0f3c205325d4e234d16.jpg', 'name': 'Dragon ball', 'rating': '#3','price':10.0},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/2bbe7ece956bbefc6f385a7a447c182c.jpg', 'name': 'Sakamoto days', 'rating': '#4','price':10.0},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/c7346b9cd930d501d2b6b40770b2b1d0.jpg', 'name': 'Apothecary dairies', 'rating': '#5','price':10.0},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/c2a246a281ee33d66635458797ce76cf.jpg', 'name': 'Happy marriage', 'rating': '#6','price':10.0},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/ebb78f8688b59abf0409b8799159127a.jpg', 'name': 'Arifureta', 'rating': '#7','price':10.0},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/b8169841c47c010d664f293fcec036fb.jpg', 'name': 'Blue box', 'rating': '#8','price':10.0},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/a8b56a7589ff9edb6c86977c31e27a06.jpg', 'name': 'Dandan', 'rating': '#9','price':10.0},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/d9bb23228e5a641b5a3e9386382dae3a.jpg', 'name': 'Wind breaker', 'rating': '#10','price':10.0},
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(

        title: const Text(
          "ANIMEZONE",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => cartPage()),
                );
              },

              child: const Icon(Icons.shopping_bag),
            ),

          ),
        
        ],
      ),

      drawer: Drawer(
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextButton(
            onPressed: ()async {
              SharedPreferences logoutpref =await SharedPreferences.getInstance();
              setState(() {
                logoutpref.clear();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>SplashScreen()));
              });



            },
            child: const Text('Log out',style: TextStyle(fontSize: 20),),
                  ),
          ),
        ),),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "All time favourite",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  aspectRatio: 16 / 9,
                  viewportFraction: 0.8,
                ),
                items: images.map((imageUrl) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                "TRENDING",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 350, // Adjust height based on content
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      image: products[index]['image'],
                      name: products[index]['name'],
                      rating: products[index]['rating'],
                    );
                  },
                ),
              ),

              SizedBox(height: 40,),
              CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  aspectRatio: 16 / 9,
                  viewportFraction: 0.8,
                ),
                items: images.map((imageUrl) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              const Text(
                "Pre-Book Upcoming Anime",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                height: 150, // Adjust height based on content
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return ListCard(
                      image: list[index]['image'],
                      name: list[index]['name'],
                      rating: list[index]['rating'],
                      price: list[index]['price'],
                      list: list[index],
                      onAddToCart: ()=> addToCart(list[index]),



                    );
                  },
                ),
              ),



            ],
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String image, name, rating;

  ProductCard({super.key, required this.image, required this.name, required this.rating});
  List<String> nameToSend = [];


  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150, // Adjust width
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Image.network(image, fit: BoxFit.cover),
          const SizedBox(height: 15),
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(rating, style: const TextStyle(fontSize: 14, color: Colors.green)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {


            },
            child: const Text('Watch Now'),
          ),
        ],
      ),
    );
  }
}





class ListCard extends StatelessWidget {
  final String image;
  final    String name;
  final    String rating;
  final  double price;
  final VoidCallback onAddToCart;
  final Map<String,dynamic>list;

  const ListCard({
    super.key,
    required this.image,
    required this.name,
    required this.rating,
    required this.price,
    required this.onAddToCart,
    required this.list


  });


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>  DetailPage(list:list,)),
        );
      },
        child: Container(
          width: 350,
          height: 100,


          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                spreadRadius: 2,
              ),
            ],
          ),

            child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Image.network(image, fit: BoxFit.contain),
                  ),
                  SizedBox(width:60),
                  Column(
                    children: [
                      Text(rating, style: const TextStyle(fontSize: 14, color: Colors.green)),
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: onAddToCart,
                        child: const Text('Buy Now'),
                      ),
                    ],
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
