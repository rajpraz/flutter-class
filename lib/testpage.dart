
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';


class testPage extends StatefulWidget {
  const testPage({super.key});

  @override
  State<testPage> createState() => _testPageState();
}

class _testPageState extends State<testPage> {
  final List<String> images = [
    'https://cdn.pixabay.com/photo/2022/06/21/07/04/anime-7275258_1280.jpg',
    'https://cdn.pixabay.com/photo/2020/04/25/09/52/onepiece-5090120_1280.jpg',
    'https://wallpapers.com/images/high/demon-slayer-tanjiro-with-nezuko-3fn68n43wwpmix8c.webp',
  ];

  final List<Map<String, dynamic>> products = [
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/bcd84731a3eda4f4a306250769675065.jpg', 'name': ' One piece', 'price': '#1'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/65f92e6e315a931ef872da4b312442b8.jpg', 'name': 'Solo leveling', 'price': '#2'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/2cbe94bcbf18f0f3c205325d4e234d16.jpg', 'name': 'Dragon ball', 'price': '#3'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/2bbe7ece956bbefc6f385a7a447c182c.jpg', 'name': 'Sakamoto days', 'price': '#4'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/c7346b9cd930d501d2b6b40770b2b1d0.jpg', 'name': 'Apothecary dairies', 'price': '#5'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/c2a246a281ee33d66635458797ce76cf.jpg', 'name': 'Happy marriage', 'price': '#6'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/ebb78f8688b59abf0409b8799159127a.jpg', 'name': 'Arifureta', 'price': '#7'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/b8169841c47c010d664f293fcec036fb.jpg', 'name': 'Blue box', 'price': '#8'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/a8b56a7589ff9edb6c86977c31e27a06.jpg', 'name': 'Dandan', 'price': '#9'},
    {'image': 'https://cdn.noitatnemucod.net/thumbnail/300x400/100/d9bb23228e5a641b5a3e9386382dae3a.jpg', 'name': 'Wind breaker', 'price': '#10'},

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
       title: Text("ANIMEZONE",style:TextStyle(
         fontSize: 40,
         fontWeight: FontWeight.bold,


       )
         ,),
      ),

      body: Padding(
        padding:  EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("All time favourite",style: TextStyle(
              fontSize: 30,
              fontWeight:FontWeight.bold
            ),),
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

            SizedBox(height: 20,),
            Text("TRENDING",style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold
            ),),
            SizedBox(
              height: 200, // Adjust height based on content
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return ProductCard(
                    image: products[index]['image'],
                    name: products[index]['name'],
                    price: products[index]['price'],
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String image, name, price;
  const ProductCard({super.key, required this.image, required this.name, required this.price});

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
          Image.network(image,  fit: BoxFit.cover),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(price, style: const TextStyle(fontSize: 14, color: Colors.green)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Watch now'),
          ),
        ],
      ),
    );
  }
}