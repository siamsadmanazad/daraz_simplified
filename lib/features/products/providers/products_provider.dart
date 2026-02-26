/// products_provider.dart
///
/// All Riverpod providers related to the product listing feature.
///
/// Provider hierarchy:
///
///   productCategoriesProvider  (FutureProvider<List<String>>)
///     └─ fetches all category strings from /products/categories
///
///   activeTabIndexProvider  (StateProvider<int>)
///     └─ tracks which tab index (0 = All, 1 = first category, …) is selected
///
///   activeCategoryProvider  (Provider<String?>)
///     └─ derives the category name for the active tab (null = All)
///
///   productsByTabProvider  (FutureProvider.family<List<Product>, String?>)
///     └─ fetches products; null → all products, "electronics" → by category
///
/// The SliverList on the home screen watches [productsByTabProvider] with the
/// value from [activeCategoryProvider], so changing [activeTabIndexProvider]
/// automatically triggers a new fetch and rebuilds only the list — the scroll
/// position is NOT touched.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/services/api_service.dart';

// ── 1. Categories ────────────────────────────────────────────────────────────

/// Fetches the complete list of categories from the Fakestore API once.
/// Riverpod caches this — no repeated network calls on tab switch.
///
/// Example result: ["electronics", "jewelery", "men's clothing", "women's clothing"]
final productCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final api = ApiService();
  return api.getCategories();
});

// ── 2. Active tab index ─────────────────────────────────────────────────────

/// Holds the index of the currently selected tab.
///
/// Index 0 is always "All" (no category filter).
/// Index 1..n correspond to the categories returned by [productCategoriesProvider].
///
/// This is a simple [StateProvider] because we only need read/write of an int.
final activeTabIndexProvider = StateProvider<int>((ref) => 0);

// ── 3. Derived active category ───────────────────────────────────────────────

/// Derives the category string for the currently active tab.
///
/// Returns null when "All" is selected (tab index 0), which tells
/// [productsByTabProvider] to fetch all products without a filter.
///
/// Returns a category name string (e.g. "electronics") for index ≥ 1.
final activeCategoryProvider = Provider<String?>((ref) {
  // Wait for categories to load; return null (= All) if they haven't yet.
  final categoriesAsync = ref.watch(productCategoriesProvider);
  final tabIndex = ref.watch(activeTabIndexProvider);

  return categoriesAsync.whenOrNull(
    data: (categories) {
      // Index 0 → All products.
      if (tabIndex == 0) return null;
      // Index 1..n → map to categories list (0-indexed into categories).
      final categoryIndex = tabIndex - 1;
      if (categoryIndex < categories.length) {
        return categories[categoryIndex];
      }
      return null; // Out of range guard — show all products.
    },
  );
});

// ── 4. Products by category (family) ────────────────────────────────────────

/// Fetches products for a given category, or all products if category is null.
///
/// This is a [FutureProvider.family] — the category string is the "family
/// parameter". Riverpod automatically caches one result per unique parameter
/// so switching from Electronics → All → Electronics doesn't re-fetch.
///
/// Usage:
///   ref.watch(productsByTabProvider(null))           // All products
///   ref.watch(productsByTabProvider("electronics"))  // Electronics only
final productsByTabProvider =
    FutureProvider.family<List<Product>, String?>((ref, category) async {
  final api = ApiService();

  if (category == null) {
    // No filter — return everything.
    return api.getProducts();
  } else {
    // Category filter — return only matching products.
    return api.getProductsByCategory(category);
  }
});

// ── 5. Active products (convenience) ────────────────────────────────────────

/// Shortcut: the product list for whichever tab is currently selected.
/// The home screen watches this directly so it doesn't have to chain two
/// providers manually.
///
/// Returns AsyncLoading while fetching, AsyncError on failure,
/// AsyncData<List<Product>> when ready.
final activeProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final category = ref.watch(activeCategoryProvider);
  return ref.watch(productsByTabProvider(category));
});
