# Daraz Clone — Flutter Web App

A Daraz-style product listing app built with Flutter Web, powered by the [Fakestore API](https://fakestoreapi.com/).

> **Live demo:** *(deploy to Netlify and paste URL here)*

---

## Quick Start

```bash
flutter pub get
flutter run -d chrome
```

### Test credentials (Fakestore API)
| Field    | Value      |
|----------|------------|
| Username | `mor_2314` |
| Password | `83r5^_`   |

---

## Features

- Login / logout with JWT token persisted across page refreshes
- Collapsible banner header with search bar
- Sticky category tab bar (Electronics, Jewelry, Men's Clothing, Women's Clothing)
- Horizontal swipe to switch tabs (conflict-free with vertical scroll)
- Pull-to-refresh from any tab position
- 2-column product grid with cached images, star ratings, prices
- User profile screen with full address details

---

## Scroll Architecture

### The single-owner rule

There is **exactly one vertical scroll owner** in the entire app: the `CustomScrollView` on the product listing screen. No `ListView`, `SingleChildScrollView`, or `TabBarView` exists anywhere in the scroll tree.

```
CustomScrollView  ← THE ONLY vertical scroll owner
├── SliverAppBar          collapsible banner + search bar
├── SliverPersistentHeader  sticky tab bar (pinned: true)
└── SliverGrid            product cards for the current tab
```

This matters because nested scrollables (e.g. a `TabBarView` inside a `CustomScrollView`) create competing scroll controllers that cause jitter, gesture conflicts, and layout overflows.

### Why no TabBarView?

`TabBarView` introduces its own `PageView`-based horizontal scroll, which immediately conflicts with the parent vertical scroll. Instead, tab switching works by:

1. The user taps a tab or swipes horizontally.
2. `activeTabIndexProvider` (a Riverpod `StateProvider<int>`) updates.
3. `activeCategoryProvider` derives the matching category string.
4. The `Consumer` around `SliverGrid` rebuilds with the new product list.
5. The scroll position is **never touched** — it stays exactly where it was.

### How horizontal swipe works

A `GestureDetector` wraps the `CustomScrollView`. Its `onHorizontalDragEnd` callback fires when a drag completes:

```dart
void _onHorizontalDragEnd(DragEndDetails details) {
  const double velocityThreshold = 300.0; // px/s

  if (details.primaryVelocity! < -velocityThreshold) {
    tabController.animateTo(tabController.index + 1); // swipe left → next tab
  } else if (details.primaryVelocity! > velocityThreshold) {
    tabController.animateTo(tabController.index - 1); // swipe right → prev tab
  }
  // Slow/diagonal swipes are ignored — vertical scroll wins.
}
```

The key is using **velocity** (not just direction) to distinguish an intentional tab swipe from a slow diagonal scroll. The `GestureDetector` does not block the `CustomScrollView`'s internal vertical gesture recogniser — they co-exist because `GestureDetector` only acts on `onHorizontalDragEnd`, not `onVerticalDragUpdate`.

### Pull-to-refresh

`RefreshIndicator` wraps the `CustomScrollView`. It works because:
- `CustomScrollView` has `physics: AlwaysScrollableScrollPhysics()` — required so the indicator activates even when the list is shorter than the viewport.
- The refresh callback calls `ref.invalidate(productsByTabProvider(category))` then awaits `ref.read(productsByTabProvider(category).future)` so the spinner stays until data arrives.

---

## Trade-offs & Limitations

| Trade-off | Decision | Rationale |
|---|---|---|
| Scroll position | **Shared** across all tabs | Switching tabs does not restore per-tab scroll position. Deliberate — simplicity and zero scroll conflict. |
| Tab content | `SliverGrid` replaces items in place | Items are rebuilt, not cached per tab. Re-fetch is deduplicated by Riverpod's cache. |
| User ID | Hardcoded to `2` | Fakestore's `/auth/login` doesn't return a userId — a real app would decode the JWT or call `/me`. |
| Web storage | `SharedPreferences` (not `flutter_secure_storage`) | `flutter_secure_storage` doesn't support Flutter Web; prefs are sufficient for this demo. |

---

## Project Structure

```
lib/
  core/
    router/app_router.dart         GoRouter + auth redirect
    theme/app_theme.dart           Material 3 theme
  features/
    auth/
      providers/auth_provider.dart  Login/logout AsyncNotifier
      screens/login_screen.dart     Login UI
      screens/profile_screen.dart   User profile + logout
    products/
      providers/products_provider.dart  Category + product providers
      screens/product_listing_screen.dart  Main scroll screen
      widgets/product_card.dart     Single product card
      widgets/tab_bar_delegate.dart Sticky SliverPersistentHeaderDelegate
  shared/
    models/product_model.dart      Product + Rating models
    models/user_model.dart         User + Address + LoginResponse models
    providers/shared_preferences_provider.dart  Prefs injection
    services/api_service.dart      Dio-based Fakestore client
  main.dart                        Entry point + ProviderScope
```

---

## Deployment

```bash
flutter build web --release
# Drag build/web/ into Netlify — you get a live URL instantly.
```

See `guideline.md` Phase 8 for full deployment steps and CORS notes.
