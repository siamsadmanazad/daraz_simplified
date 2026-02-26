/// api_service.dart
///
/// Centralised HTTP layer using Dio. All calls to the Fakestore API go through
/// this class so that base URL, timeouts, and error handling are configured
/// in exactly one place.
///
/// Endpoints used:
///   POST /auth/login                  → LoginResponse
///   GET  /products                    → List<Product>
///   GET  /products/category/{cat}     → List<Product>
///   GET  /products/categories         → List<String>
///   GET  /users/{id}                  → User
///
/// Usage:
///   final api = ApiService();
///   final products = await api.getProducts();

import 'package:dio/dio.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

class ApiService {
  // ── Dio instance ─────────────────────────────────────────────────────────

  /// Single Dio instance shared for all requests from this service.
  /// BaseOptions sets the root URL so every method only needs the path.
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://fakestoreapi.com',

      // Timeout after 15 s on connect and 15 s waiting for data.
      // Fakestore is a free public API — give it a generous window.
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),

      // Fakestore always returns JSON; tell Dio so it auto-parses responses.
      responseType: ResponseType.json,
    ),
  );

  // ── Auth ─────────────────────────────────────────────────────────────────

  /// Authenticates with username + password.
  /// Returns a [LoginResponse] containing the JWT token on success.
  /// Throws a [DioException] on network error or invalid credentials.
  Future<LoginResponse> login(String username, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    return LoginResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Products ─────────────────────────────────────────────────────────────

  /// Fetches ALL products (no category filter) — used for the "All" tab.
  Future<List<Product>> getProducts() async {
    final response = await _dio.get('/products');
    return Product.listFromJson(response.data as List<dynamic>);
  }

  /// Fetches products for a specific [category] — used for individual tabs.
  ///
  /// Example: category = "electronics"
  ///   → GET https://fakestoreapi.com/products/category/electronics
  Future<List<Product>> getProductsByCategory(String category) async {
    final response = await _dio.get('/products/category/$category');
    return Product.listFromJson(response.data as List<dynamic>);
  }

  /// Fetches the list of all available categories.
  /// Returns something like: ["electronics", "jewelery", "men's clothing", "women's clothing"]
  /// Used to populate the tab bar dynamically — no hardcoded tab names.
  Future<List<String>> getCategories() async {
    final response = await _dio.get('/products/categories');
    return (response.data as List<dynamic>).cast<String>();
  }

  // ── Users ────────────────────────────────────────────────────────────────

  /// Fetches a single user's profile by [userId].
  /// The Fakestore API stores userId as an integer (e.g., 2).
  Future<User> getUser(int userId) async {
    final response = await _dio.get('/users/$userId');
    return User.fromJson(response.data as Map<String, dynamic>);
  }
}
