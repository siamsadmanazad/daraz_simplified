# Comprehensive Guide: Daraz-Style Flutter App with Fakestore API

## Overview of What You're Building

Before diving in, understand the core challenge: **one vertical scroll controller** that owns all scrolling, a **collapsible sliver header**, a **sticky tab bar**, and **horizontal tab switching** (swipe + tap) without scroll conflict. This is an architecture problem, not a UI problem.

---

## Phase 1: Project Setup & Architecture Planning ✅

### Step 1.1 — Create the Flutter Project ✅

**Prompt to use with Claude/AI:**
> "I'm building a Flutter web app. Create the project structure for a Daraz-style product listing app with the following feature modules: auth (login + profile), products (listing with tabs), and shared (models, services, providers). Use flutter_riverpod for state management, dio for HTTP, and cached_network_image for images. List all packages I need in pubspec.yaml with their latest stable versions as of early 2025."

**What to do:**
1. Run `flutter create daraz_clone --platforms web`
2. Set up your folder structure: `lib/features/auth/`, `lib/features/products/`, `lib/shared/`
3. Add packages: `flutter_riverpod`, `dio`, `cached_network_image`, `go_router`

---

### Step 1.2 — Understand the Scroll Architecture FIRST ✅

**Prompt:**
> "Explain the difference between NestedScrollView, CustomScrollView with Slivers, and a raw ScrollController approach for building a screen with: a collapsible header, a sticky tab bar, and tab content that all share ONE vertical scroll. What are the trade-offs of each? Which approach avoids scroll jitter and duplicate scrollControllers?"

**Key decision you must make here:** You will use a single `CustomScrollView` with Slivers as the outer scroll, and the tab content will render items directly into that same sliver list — NOT inside their own scrollable widgets. This is the most important architectural decision in the whole project.

---

## Phase 2: Fakestore API Integration ✅

### Step 2.1 — Model the API Data ✅

**Prompt:**
> "Based on the Fakestore API at https://fakestoreapi.com/, I need Dart data models for: Product (id, title, price, description, category, image, rating.rate, rating.count), User (id, email, username, name.firstname, name.lastname, phone, address), and LoginResponse (token). Use freezed-style immutable classes with fromJson factory constructors. Also write the API endpoints I need: GET /products, GET /products/category/{category}, GET /products/categories, POST /auth/login, GET /users/{id}."

**What to do:**
1. Create `lib/shared/models/product_model.dart`
2. Create `lib/shared/models/user_model.dart`
3. Create `lib/shared/services/api_service.dart` with Dio

---

### Step 2.2 — Auth Flow (Login + Profile) ✅

**Prompt:**
> "I need a login screen for a Flutter app using Fakestore API. The login endpoint is POST https://fakestoreapi.com/auth/login with body {username, password}. Valid test credentials are username: 'mor_2314', password: '83r5^_'. After login, store the JWT token using flutter_secure_storage (or shared_preferences for web compatibility). Then fetch the user profile from GET /users/2 to display on a profile page. Walk me through the state management approach using Riverpod — what providers do I need?"

**Steps:**
1. Build `LoginScreen` with username/password fields
2. On success, store token + userId
3. Navigate to main product listing screen
4. Create a Profile tab or drawer using the user data

---

## Phase 3: The Core Scroll Architecture (Most Critical Phase) ✅

### Step 3.1 — Plan the Sliver Layout on Paper First ✅

Before writing any code, draw this hierarchy:

```
CustomScrollView (THE ONLY VERTICAL SCROLL OWNER)
├── SliverAppBar (collapsible banner + search bar)
├── SliverPersistentHeader (sticky tab bar)
└── SliverList / SliverGrid (product items for current tab)
```

**Prompt:**
> "I'm building a Flutter screen with a CustomScrollView that contains: (1) a SliverAppBar with a banner image and search bar that collapses on scroll, (2) a SliverPersistentHeader that becomes sticky after the SliverAppBar collapses — this holds a TabBar, (3) a SliverList that renders the product items for the currently selected tab. Explain how SliverPersistentHeader with pinned: true works, what delegate I need, and how the pinned height should be calculated without magic numbers."

### Step 3.2 — The Tab Switching Architecture ✅

**Prompt:**
> "In my Flutter app, I have a CustomScrollView as the single vertical scroll owner. I have a TabController managing 3 tabs (Electronics, Jewelry, Men's Clothing). When the user switches tabs, I need to: (1) keep the vertical scroll position exactly where it is — do NOT reset to top, (2) replace the items in my SliverList with the new tab's products, (3) NOT use a TabBarView because that introduces a second vertical scroll. Explain how I should manage which tab's data is shown in the SliverList, using Riverpod state. What provider holds the current tab index and current product list?"

**Key insight here:** You are NOT using `TabBarView`. The tab bar is just a visual selector. The actual content swap happens by updating a state provider that controls what items the `SliverList` renders.

### Step 3.3 — Horizontal Swipe Without Scroll Conflict ✅

**Prompt:**
> "I need horizontal swipe to switch tabs in my Flutter app, but I'm NOT using TabBarView. My vertical scroll is owned by a CustomScrollView. I want to add a horizontal swipe gesture that: (1) detects intentional horizontal swipes (velocity-based, not just any movement), (2) calls tabController.animateTo() to change tab, (3) does NOT interfere with vertical scrolling. Should I use GestureDetector with onHorizontalDragEnd, or PageView with physics: NeverScrollableScrollPhysics, or something else? Explain the gesture ownership strategy."

**The answer you should understand:** Use a `GestureDetector` wrapping the `CustomScrollView` body with `onHorizontalDragEnd` checking the velocity. Alternatively, wrap with a `PageView` set to `NeverScrollableScrollPhysics` and control it programmatically — but the GestureDetector approach is cleaner for your case.

### Step 3.4 — Pull-to-Refresh Across All Tabs ✅

**Prompt:**
> "I have a CustomScrollView with a SliverList. I want pull-to-refresh that works from any tab. Since I'm using a CustomScrollView (not ListView), I should use RefreshIndicator with a ScrollController, or SliverToBoxAdapter wrapping a RefreshIndicator. What is the correct way to add pull-to-refresh to a CustomScrollView in Flutter? The refresh action should re-fetch the current tab's products from Fakestore API and update the Riverpod provider."

---

## Phase 4: Building Each Screen Component ✅

### Step 4.1 — The Collapsible Header ✅

**Prompt:**
> "Design a SliverAppBar for a Flutter Daraz-style app. It should have: (1) an expandedHeight of about 180 pixels, (2) a FlexibleSpaceBar with a banner image (use a placeholder network image), (3) a search bar that appears when collapsed — use the 'bottom' property of SliverAppBar for a persistent search bar below the app bar, (4) pinned: true so the collapsed toolbar remains visible, (5) floating: false to avoid the header re-appearing on small upward scrolls. Describe each property and what visual effect it produces."

### Step 4.2 — The Sticky Tab Bar ✅

**Prompt:**
> "I need a SliverPersistentHeader with pinned: true that holds a TabBar for 3 tabs: 'Electronics', 'Jewelry', 'Clothing'. The delegate must: (1) have a fixed minExtent and maxExtent equal to the TabBar height (about 48px), (2) build a Container with the TabBar inside, (3) show a subtle elevation shadow when pinned. Describe the SliverPersistentHeaderDelegate structure I need to implement and what the build, maxExtent, and shouldRebuild methods must do."

### Step 4.3 — Product Item Design ✅

**Prompt:**
> "Design a product card widget for a Flutter app using Fakestore API data. The card should show: product image (cached), product title (max 2 lines), price with BDT or $ currency, star rating display, and an 'Add to Cart' button placeholder. The card should work in both a grid (2-column) and list layout. No business logic needed, just the presentational widget. Make it look like a Daraz product card."

---

## Phase 5: State Management with Riverpod ✅

### Step 5.1 — Define All Providers ✅

**Prompt:**
> "I'm building a Flutter app with Riverpod. List all the providers I need for this feature set: (1) authProvider — holds login state (loading, authenticated, error) and the JWT token, (2) userProfileProvider — fetches user from Fakestore API using the userId, (3) productCategoriesProvider — fetches all categories, (4) productsByTabProvider — a family provider that takes a category string and returns AsyncValue<List<Product>>, (5) activeTabIndexProvider — a simple StateProvider<int> for the current tab. Describe what type each provider should be (StateProvider, FutureProvider, AsyncNotifierProvider, etc.) and why."

### Step 5.2 — Tab Switching State Flow ✅

**Prompt:**
> "In my Riverpod-based Flutter app, when the user taps a tab or swipes horizontally: (1) activeTabIndexProvider updates to the new index, (2) the SliverList rebuilds showing productsByTabProvider(newCategory), (3) the vertical scroll position does NOT change. Describe the data flow between the TabController, the activeTabIndexProvider, and the Consumer widget that wraps the SliverList. How do I keep TabController in sync with Riverpod state without causing infinite update loops?"

---

## Phase 6: Profile Screen ✅

### Step 6.1 — User Profile ✅

**Prompt:**
> "I need a Profile screen for my Flutter app using Fakestore API. It fetches user data from GET /users/2 (or whatever userId was returned at login). Display: full name, email, phone, full address (street, city, zip), and a logout button that clears the stored token and navigates back to login. Use Riverpod to watch the userProfileProvider and handle loading/error/data states gracefully with appropriate UI feedback."

---

## Phase 7: README Documentation ✅

### Step 7.1 — Write the Mandatory README ✅

**Prompt:**
> "Write a README.md for a Flutter app called 'Daraz Clone' that explains: (1) How horizontal swipe was implemented — describe the GestureDetector/PageView approach used and why it doesn't conflict with vertical scrolling, (2) Who owns the vertical scroll and why — explain the single CustomScrollView architecture, why TabBarView was avoided, and how SliverList renders tab content without owning scroll, (3) Trade-offs and limitations — mention that scroll position is shared across all tabs (not per-tab), that this means switching tabs doesn't restore per-tab scroll position, and that this is a deliberate trade-off for simplicity and conflict-free scrolling, (4) Run instructions: flutter pub get, flutter run -d chrome, (5) Test credentials for Fakestore API login. Format this as a professional README with clear sections."

---

## Phase 8: Build & Deploy for Web

### Step 8.1 — Fix SPA routing before building

Flutter web uses client-side routing (GoRouter). Netlify serves static files, so refreshing any URL other than `/` returns a 404. Fix this by adding a `_redirects` file to the `web/` source folder — Flutter copies it into `build/web/` automatically during the build.

Create `web/_redirects` with exactly this content:
```
/* /index.html 200
```

That's it. One line. Every URL gets served `index.html` and Flutter's router takes over from there.

### Step 8.2 — Build the release bundle

```bash
flutter build web --release
```

This produces `build/web/`. The key files inside:
- `index.html` — entry point Netlify serves for every route (thanks to `_redirects`)
- `main.dart.js` — your compiled Flutter app (several MB, minified)
- `flutter.js` / `flutter_bootstrap.js` — Flutter web engine loader
- `assets/` — fonts, images, and asset manifest
- `_redirects` — the routing fix from Step 8.1

Do **not** commit `build/web/` to git. It's regenerated every build and is large.

### Step 8.3 — Deploy via drag-and-drop (fastest path)

1. Go to [netlify.com](https://netlify.com) and sign in (or create a free account)
2. From your dashboard, click **"Add new site"** → **"Deploy manually"**
3. Drag your `build/web/` folder into the upload zone
4. Netlify processes it (takes ~10–30 seconds) and gives you a live URL like `https://random-name.netlify.app`
5. Test the URL — open it, log in with `mor_2314` / `83r5^_`, navigate around, and **refresh on an inner page** to confirm the `_redirects` fix is working

That URL is your submission URL.

### Step 8.4 — Optional: rename the site

In Netlify → Site settings → Site details → **Change site name** → set something readable like `daraz-clone-yourname`. Your URL becomes `https://daraz-clone-yourname.netlify.app`.

### Step 8.5 — Optional: Git-based continuous deployment

If you push code to GitHub and want Netlify to redeploy automatically on every push:

1. In Netlify → **"Add new site"** → **"Import an existing project"** → Connect to GitHub
2. Select your repo
3. Set these build settings:
   - **Build command:** `flutter/bin/flutter build web --release`
   - **Publish directory:** `build/web`
   - **Environment variable:** `FLUTTER_VERSION` = `3.27.0` (or your current version)
4. Netlify will install Flutter and build on every push to `main`

For CI builds you also need a `netlify.toml` at the project root:
```toml
[build]
  command = "flutter/bin/flutter build web --release"
  publish = "build/web"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

The `[[redirects]]` block here replaces the `_redirects` file — use one or the other, not both.

---

## Phase 9: GitHub Repository Setup

### Step 9.1 — Repo Structure ✅ (partial)

**Status:** `git init`, initial commits, and project structure are done. Remaining: push to GitHub and add the live URL.

Steps completed:
- ✅ `git init` in project root
- ✅ `.gitignore` (Flutter default)
- ✅ Initial commit(s) pushed locally

Steps remaining:
1. Push to GitHub:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/daraz-clone.git
   git push -u origin main
   ```
2. Add live Netlify URL to the repo description field on GitHub
3. Add live URL near the top of `README.md`:
   ```markdown
   **Live demo:** https://your-site-name.netlify.app
   ```

---

## Evaluation Checklist — Verify Before Submission

Go through each point and use this prompt to self-review:

**Final Review Prompt:**
> "Review my Flutter app architecture against these criteria and tell me if I pass each one: (1) There is exactly ONE vertical scrollable — a CustomScrollView. No ListView, SingleChildScrollView, or TabBarView anywhere in the scroll tree. (2) Pull-to-refresh works from any tab position. (3) Switching tabs does not jump or reset the scroll position. (4) The tab bar sticks at the top after the header collapses. (5) Horizontal swipe changes tabs without affecting vertical scroll. (6) No magic numbers — all sizes derived from theme or layout constraints. (7) The README explains scroll ownership, horizontal gesture handling, and trade-offs."

---

## Summary of Key Architecture Decisions

| Decision | What to do | Why |
|---|---|---|
| Scroll owner | Single `CustomScrollView` | Eliminates all scroll conflicts |
| Tab content | Rendered in `SliverList`, no `TabBarView` | Avoids nested scrollables |
| Tab switching | Update Riverpod state, `SliverList` rebuilds | Scroll position untouched |
| Horizontal swipe | `GestureDetector` with velocity check | Doesn't create new scroll axis |
| Pull-to-refresh | `RefreshIndicator` wrapping `CustomScrollView` | Works on the single scroll |
| Header | `SliverAppBar` with `pinned: true` | Sliver-native collapse |
| Sticky tabs | `SliverPersistentHeader` with `pinned: true` | Sliver-native pinning |

Follow the phases in order. Phase 3 is the most critical — don't start building UI until you've fully understood and decided on the scroll architecture. Everything else is straightforward.