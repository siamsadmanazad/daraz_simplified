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

### 1. How horizontal swipe works — and why it ended up this way

The obvious first move was `TabBarView` or a `PageView`. You get swipe for free, the tab bar wires up automatically — it looks like a solved problem. The issue is that both of those are horizontal scrollables, and we already have a `CustomScrollView` doing vertical scroll. When you nest them, Flutter's gesture arena sees two competing recognizers on the same touch events. In practice that means jitter, and more annoyingly, the `SliverAppBar` stops collapsing because the inner scroll is stealing the drag before the outer one can react.

So we stepped back from the scroll system entirely. The whole screen is wrapped in a `GestureDetector` that only listens to `onHorizontalDragEnd`:

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

The key choice here is `onHorizontalDragEnd` instead of `onHorizontalDragUpdate`. Update fires on every frame during any drag — including the slow diagonal movements you make constantly while scrolling a product list. If we used update, we'd be checking velocity dozens of times per second and accidentally switching tabs mid-scroll. End fires once, after the gesture is done, with a final velocity. At 300 px/s it only catches intentional flicks, not incidental horizontal drift.

When the swipe does register, `tabController.animateTo()` fires the `TabController` listener, which writes a new index to `activeTabIndexProvider` (a Riverpod `StateProvider<int>`). The `Consumer` around the `SliverGrid` is watching `activeProductsProvider`, which derives from that index. The grid rebuilds with the new category's products. The `CustomScrollView` and its scroll position are never touched.

---

### 2. Who owns the vertical scroll — and why it has to be exactly one thing

There's only one scrollable in the entire screen: a single `CustomScrollView`. No `ListView`, no `SingleChildScrollView`, no `TabBarView`.

```
CustomScrollView  ← THE ONLY vertical scroll owner in the entire app
├── SliverAppBar            (collapsible banner + search bar)
├── SliverPersistentHeader  (sticky tab bar, pinned: true)
└── SliverGrid              (product cards for the active tab)
```

The reason is simple: the moment you introduce a second scrollable on the same axis, you have two scroll controllers fighting over the same finger. You end up with gesture conflicts, the `SliverAppBar` won't collapse reliably, and the tab bar won't stick correctly. These are not edge cases — they show up immediately and they're annoying to debug.

With a single `CustomScrollView` owning everything, none of those problems exist. The `SliverAppBar` collapses cleanly because it's a native sliver inside the one scroll. The tab bar sticks because `SliverPersistentHeader` with `pinned: true` participates in the same sliver layout pass — no tricks required. When you switch tabs, only the Riverpod state changes; the `CustomScrollView` doesn't know or care, so the scroll position stays exactly where it was. Pull-to-refresh also just works from any position on any tab, because the `RefreshIndicator` wraps the whole `CustomScrollView`.

---

### 3. Honest trade-offs

A few things we made a deliberate call on, and a few that are just limitations worth knowing about.

**Scroll position is shared across tabs.** Switching from Electronics to Jewelery doesn't restore where you were in Jewelery — you stay at the current scroll offset. We could have saved a `ScrollController` per tab and done save/restore on switch, but that adds real complexity for an architecture demo and the UX difference is minimal. Deliberate call.

**The grid rebuilds on every tab switch.** Riverpod makes sure we never re-fetch data from the network, but the widget tree for the `SliverGrid` does rebuild when `activeTabIndexProvider` changes. In a production app you'd cache the grid items. Fine for this scale.

**The 300 px/s velocity threshold is a magic number.** It's not derived from any system constant — we tuned it by feel. Too low and diagonal scrolls trigger tab switches. Too high and swipes feel like they're not registering. 300 works well on both desktop and mobile, but if you're running on a trackpad you might notice it behaves a bit differently than a touch screen.

**User ID is hardcoded to `2`.** The Fakestore API's login endpoint returns a JWT token but doesn't include the user ID in the response or the token payload. To get the actual ID you'd need to decode the JWT or hit a `/me` endpoint — neither of which Fakestore provides in a useful way. Hardcoded for now.

**Token lives in `SharedPreferences`, not secure storage.** `flutter_secure_storage` doesn't work on Flutter Web. `SharedPreferences` is web-compatible and survives page refreshes, but it's not encrypted. That's fine for a demo; not something you'd ship in production.

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
