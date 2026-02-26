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

### Step 8.1 — Web Build

**Prompt:**
> "I have a Flutter web app and need to deploy the build/web/ folder to a static hosting service. Walk me through: (1) running flutter build web --release, (2) what's inside build/web/ and what each file does, (3) deploying to Netlify via drag-and-drop (the fastest option for submission), (4) deploying to GitHub Pages as an alternative, (5) deploying to Vercel as another alternative. Include what CORS issues I might face with Fakestore API from a deployed domain and how to handle them."

### Step 8.2 — Deploy to Netlify (Recommended for Speed)

Steps:
1. Run `flutter build web --release`
2. Go to [netlify.com](https://netlify.com) → drag your `build/web/` folder into the deploy zone
3. Get your live URL instantly (something like `https://random-name.netlify.app`)
4. Done — this is your submission URL

**Prompt for CORS handling if needed:**
> "My Flutter web app deployed on Netlify is calling Fakestore API at fakestoreapi.com. I'm getting CORS errors in the browser console. Fakestore API supports CORS, so this might be a configuration issue. What could cause CORS errors with Fakestore API specifically from Flutter web, and how do I fix it? Should I use a netlify.toml with proxy rules, or is there another approach?"

---

## Phase 9: GitHub Repository Setup

### Step 9.1 — Repo Structure

**Prompt:**
> "Give me a .gitignore for a Flutter project and tell me which folders/files I should commit. Should I commit the build/web/ folder? What should my repository README include at the top to make it easy for evaluators to: (1) clone and run locally, (2) visit the live deployed URL, (3) understand the architecture in under 2 minutes?"

Steps:
1. `git init` in project root
2. Add `.gitignore` (Flutter default)
3. `git add .` and commit
4. Push to GitHub
5. Add live URL to the repo description and README

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