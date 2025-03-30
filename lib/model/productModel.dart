class ProductModel {
  final String id;
  final String name;
  final String photo;
  final String description;
  final double price;
  final int qty;
  final double weight;
  final String categoryName;

  ProductModel({
    required this.id,
    required this.name,
    required this.photo,
    required this.description,
    required this.price,
    required this.qty,
    required this.weight,
    required this.categoryName,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      photo: json['photo'],
      description: json['description'],
      price: json['price'].toDouble(),
      qty: json['qty'],
      weight: json['weight'].toDouble(),
      categoryName: json['category']['category_name'],
    );
  }
}