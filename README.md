# Daraz Clone — Flutter Web App

A Daraz-style product listing app built with Flutter Web, powered by the [Fakestore API](https://fakestoreapi.com/).

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

## Mandatory Explanation

### 1. How horizontal swipe was implemented

A `GestureDetector` wraps the entire `CustomScrollView` body and listens to `onHorizontalDragEnd`:

```dart
void _onHorizontalDragEnd(DragEndDetails details) {
  const double velocityThreshold = 300.0; // px/s

  if (details.primaryVelocity! < -velocityThreshold) {
    tabController.animateTo(tabController.index + 1); // swipe left → next tab
  } else if (details.primaryVelocity! > velocityThreshold) {
    tabController.animateTo(tabController.index - 1); // swipe right → prev tab
  }
  // Slow or diagonal swipes fall through — vertical scroll wins.
}
```

**Why `onHorizontalDragEnd` and not `onHorizontalDragUpdate`?**
Using the drag *end* event (with a velocity threshold of 300 px/s) means we only act on fast, intentional horizontal flicks. Slow diagonal movements — which happen constantly during normal vertical scrolling — never reach the threshold, so vertical scroll is never interrupted.

**Why not `TabBarView` or `PageView`?**
Both introduce a second horizontal scrollable inside the vertical scroll tree. Flutter's gesture arena then has two competing recognisers on the same axis family, which causes jitter and unpredictable behaviour. The `GestureDetector` approach keeps the gesture completely outside the scroll system — it runs alongside the `CustomScrollView` without competing with it.

**How tab content changes without `TabBarView`:**
`tabController.animateTo()` fires the `TabController` listener, which writes to `activeTabIndexProvider` (a Riverpod `StateProvider<int>`). The `Consumer` wrapping the `SliverGrid` watches `activeProductsProvider`, which derives from that index. The grid rebuilds with new products; the scroll position is never touched.

---

### 2. Who owns the vertical scroll and why

**Owner: a single `CustomScrollView` on `ProductListingScreen`.**

```
CustomScrollView  ← THE ONLY vertical scroll owner in the entire app
├── SliverAppBar            (collapsible banner + search bar)
├── SliverPersistentHeader  (sticky tab bar, pinned: true)
└── SliverGrid              (product cards for the active tab)
```

There is no `ListView`, `SingleChildScrollView`, `TabBarView`, or any other scrollable anywhere in this widget tree.

**Why this architecture?**

The core problem with most naive implementations is nested scrollables: placing a `TabBarView` (which contains `PageView` + per-tab `ListView`) inside a `CustomScrollView` creates two scroll controllers competing for the same touch events. The result is scroll jitter, gesture conflicts, and the `SliverAppBar` not collapsing correctly.

By owning scroll in a single `CustomScrollView`:

- The `SliverAppBar` collapses correctly because it is a native sliver inside the one scroll.
- The `SliverPersistentHeader` (`pinned: true`) sticks after collapse because it participates in the same sliver layout pass.
- Tab switching never resets scroll because switching only updates a Riverpod provider — the `CustomScrollView` and its position are completely unaffected.
- Pull-to-refresh via `RefreshIndicator` wrapping the `CustomScrollView` works from any scroll position on any tab.

---

### 3. Trade-offs and limitations

| Area | Decision made | Why / limitation |
|---|---|---|
| Scroll position | **Shared** across all tabs | Switching tabs does not restore a per-tab scroll position. This is deliberate — per-tab scroll would require one `ScrollController` per tab and careful save/restore logic, adding complexity with no benefit to the architecture goal. |
| Tab content | `SliverGrid` rebuilds in place | Items are not cached per tab between switches. Riverpod deduplicates network re-fetches so data is never re-requested, but the widget tree is rebuilt. |
| Horizontal swipe | Velocity threshold (300 px/s) | The threshold is a tuned constant. Too low → diagonal scrolls accidentally switch tabs. Too high → swipes feel unresponsive. The value works well in practice but is not derived from a system metric. |
| User ID | Hardcoded to `2` | Fakestore's `POST /auth/login` returns only a JWT token, not a user ID. Decoding the JWT or calling a `/me` endpoint would be the real-world fix. |
| Token storage | `SharedPreferences` | `flutter_secure_storage` does not support Flutter Web. `SharedPreferences` is web-compatible but not encrypted. Acceptable for a demo, not for production. |
| Gesture priority | `GestureDetector` does not block vertical scroll | The `CustomScrollView` handles all vertical gestures internally. The outer `GestureDetector` only fires on `onHorizontalDragEnd`, so it never blocks vertical scroll. This means a perfectly horizontal drag at the start of a scroll is correctly identified as a tab swipe rather than a scroll attempt. |

---

## Architecture Overview

```
CustomScrollView (single scroll owner)
├── SliverAppBar
│     ├── expandedHeight: 180      full banner when at top
│     ├── pinned: true             toolbar stays on collapse
│     ├── flexibleSpace            banner image + gradient (collapses)
│     └── bottom                  search bar (always visible)
├── SliverPersistentHeader
│     ├── pinned: true             locks to top after SliverAppBar collapses
│     └── TabBarDelegate           custom delegate, minExtent == maxExtent == 48
└── SliverGrid  ←── Consumer
      └── watches activeProductsProvider (Riverpod)
            └── derived from activeTabIndexProvider
                  └── updated by tab tap or horizontal swipe
```

**State separation:**

| Layer | Responsible for |
|---|---|
| UI | `ProductListingScreen`, `ProductCard`, `TabBarDelegate` |
| Scroll / gesture | `CustomScrollView` (vertical), `GestureDetector` (horizontal swipe) |
| State | Riverpod providers: `activeTabIndexProvider`, `productsByTabProvider`, `authNotifierProvider` |
| Data | `ApiService` (Dio) → Fakestore API |

---

## Features

- Login / logout with JWT token persisted across page refreshes
- Collapsible banner header with search bar
- Sticky category tab bar — Electronics, Jewelery, Men's Clothing, Women's Clothing
- Horizontal swipe to switch tabs (conflict-free with vertical scroll)
- Pull-to-refresh from any tab position
- 2-column product grid with images, star ratings, prices
- User profile screen (name, email, phone, address, logout)

---

## Project Structure

```
lib/
  core/
    router/app_router.dart              GoRouter + auth redirect
  features/
    auth/
      providers/auth_provider.dart      Login/logout AsyncNotifier
      screens/login_screen.dart         Login UI
      screens/profile_screen.dart       User profile + logout
    products/
      providers/products_provider.dart  Category + product providers
      screens/product_listing_screen.dart  Main scroll screen
      widgets/product_card.dart         Single product card
      widgets/tab_bar_delegate.dart     SliverPersistentHeaderDelegate
  shared/
    models/product_model.dart           Product + Rating
    models/user_model.dart              User + Address + LoginResponse
    providers/shared_preferences_provider.dart
    services/api_service.dart           Dio-based Fakestore client
  main.dart                             Entry point + ProviderScope
```

---

## Deployment

```bash
flutter build web --release
# Drag build/web/ into netlify.com — live URL in seconds.
```
