/// product_model.dart
///
/// Immutable data model for a product returned by the Fakestore API.
/// Endpoint: GET https://fakestoreapi.com/products
///           GET https://fakestoreapi.com/products/category/{category}
///
/// Example JSON shape:
/// {
///   "id": 1,
///   "title": "Fjallraven - Foldsack No. 1 Backpack",
///   "price": 109.95,
///   "description": "Your perfect pack...",
///   "category": "men's clothing",
///   "image": "https://fakestoreapi.com/img/81fAn1AYn7L._AC_UY879_.jpg",
///   "rating": { "rate": 3.9, "count": 120 }
/// }

class Rating {
  final double rate;
  final int count;

  const Rating({required this.rate, required this.count});

  /// Deserialise from the nested rating object in the API response.
  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      rate: (json['rate'] as num).toDouble(),
      count: (json['count'] as num).toInt(),
    );
  }
}

class Product {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String image;
  final Rating rating;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    required this.rating,
  });

  /// Deserialise a single product object returned by the API.
  /// All numeric fields are cast through `num` first so the API can return
  /// either int or double without throwing a type error.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      category: json['category'] as String,
      image: json['image'] as String,
      rating: Rating.fromJson(json['rating'] as Map<String, dynamic>),
    );
  }

  /// Convenience helper: deserialise a JSON list into a typed List<Product>.
  /// Used by ApiService after fetching /products or /products/category/{cat}.
  static List<Product> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
