class CategoryModel {
  int? id;
  String? categoryName;

  CategoryModel({this.id, this.categoryName});

  CategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    categoryName = json['category_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = this.id;
    data['category_name'] = this.categoryName;
    return data;
  }
}