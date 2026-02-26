/// product_listing_screen.dart
///
/// The main home screen of the app.
///
/// ╔══════════════════════════════════════════════════════════════════════╗
/// ║  SCROLL ARCHITECTURE — READ THIS BEFORE EDITING                     ║
/// ╠══════════════════════════════════════════════════════════════════════╣
/// ║  There is EXACTLY ONE vertical scroll owner: the [CustomScrollView]. ║
/// ║  No ListView, no SingleChildScrollView, no TabBarView exist in      ║
/// ║  this widget tree.                                                   ║
/// ║                                                                      ║
/// ║  CustomScrollView                                                    ║
/// ║  ├─ SliverAppBar         (collapsible banner + search bar)           ║
/// ║  ├─ SliverPersistentHeader (sticky TabBar via TabBarDelegate)        ║
/// ║  └─ SliverGrid           (product cards for the current tab)         ║
/// ║                                                                      ║
/// ║  Tab switching:                                                      ║
/// ║    Tapping / swiping updates [activeTabIndexProvider].               ║
/// ║    The SliverGrid Consumer rebuilds with the new product list.       ║
/// ║    The scroll position is NEVER reset — it stays where it is.       ║
/// ║                                                                      ║
/// ║  Horizontal swipe:                                                   ║
/// ║    GestureDetector wraps the body. onHorizontalDragEnd checks        ║
/// ║    velocity (threshold: 300 px/s) to avoid triggering on slow       ║
/// ║    diagonal scrolls.                                                 ║
/// ║                                                                      ║
/// ║  Pull-to-refresh:                                                    ║
/// ║    RefreshIndicator wraps the CustomScrollView.  Calls              ║
/// ║    ref.refresh(productsByTabProvider(category)) to re-fetch.        ║
/// ╚══════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/products_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/tab_bar_delegate.dart';

class ProductListingScreen extends ConsumerStatefulWidget {
  const ProductListingScreen({super.key});

  @override
  ConsumerState<ProductListingScreen> createState() =>
      _ProductListingScreenState();
}

class _ProductListingScreenState extends ConsumerState<ProductListingScreen>
    with TickerProviderStateMixin {
  // ── TabController ────────────────────────────────────────────────────────

  /// Manages the selected tab index and the animated indicator.
  /// Initialised with length = 1 and resized once categories are loaded.
  TabController? _tabController;

  /// Cache the last known category count so we can detect when it changes.
  int _lastTabCount = 0;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    // Always dispose AnimationController-backed objects.
    _tabController?.dispose();
    super.dispose();
  }

  // ── TabController management ──────────────────────────────────────────────

  /// Creates or recreates the [TabController] when the categories list changes.
  ///
  /// We must recreate (not just update) because [TabController.length] is
  /// final — it cannot change after construction.
  ///
  /// The "All" tab is always prepended, so length = categories.length + 1.
  void _initTabController(int tabCount) {
    if (tabCount == _lastTabCount) return; // nothing changed

    _tabController?.dispose();

    _tabController = TabController(
      length: tabCount,
      vsync: this,
      // Restore the selected tab from Riverpod state so recreating the
      // controller (e.g. after hot reload) doesn't reset the selection.
      initialIndex: ref.read(activeTabIndexProvider).clamp(0, tabCount - 1),
    );

    // Sync Riverpod state when the user taps a tab in the TabBar.
    // We use addListener instead of onTap so programmatic changes
    // (e.g. from swipe) also propagate.
    _tabController!.addListener(() {
      if (_tabController!.indexIsChanging) return; // wait for animation to end
      ref.read(activeTabIndexProvider.notifier).state = _tabController!.index;
    });

    _lastTabCount = tabCount;
  }

  // ── Pull-to-refresh ───────────────────────────────────────────────────────

  /// Refreshes the product list for the currently active tab.
  /// Called by [RefreshIndicator] when the user pulls down.
  Future<void> _onRefresh() async {
    final category = ref.read(activeCategoryProvider);
    // Invalidate the provider so it is marked stale, then await the new fetch.
    // Using invalidate + read(.future) separates invalidation from the await
    // and avoids the `unused_result` lint on ref.refresh().
    ref.invalidate(productsByTabProvider(category));
    await ref.read(productsByTabProvider(category).future);
  }

  // ── Horizontal swipe ─────────────────────────────────────────────────────

  /// Handles a completed horizontal drag.
  ///
  /// We only act on intentional, fast swipes (velocity ≥ 300 px/s) to avoid
  /// interfering with slow diagonal scrolls. The threshold is configurable.
  void _onHorizontalDragEnd(DragEndDetails details) {
    const double velocityThreshold = 300.0; // px per second

    final tabController = _tabController;
    if (tabController == null) return;

    final velocity = details.primaryVelocity ?? 0;

    if (velocity < -velocityThreshold) {
      // Swiped LEFT → go to next tab.
      final next = (tabController.index + 1).clamp(0, tabController.length - 1);
      tabController.animateTo(next);
    } else if (velocity > velocityThreshold) {
      // Swiped RIGHT → go to previous tab.
      final prev = (tabController.index - 1).clamp(0, tabController.length - 1);
      tabController.animateTo(prev);
    }
    // Slow swipe or near-zero velocity → ignore; don't switch tabs.
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watch categories — they drive both the tab bar and the tab controller.
    final categoriesAsync = ref.watch(productCategoriesProvider);

    return Scaffold(
      body: categoriesAsync.when(
        // ── Loading state ─────────────────────────────────────────────────
        loading: () => const Center(child: CircularProgressIndicator()),

        // ── Error state ───────────────────────────────────────────────────
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Could not load categories'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(productCategoriesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),

        // ── Data state ────────────────────────────────────────────────────
        data: (categories) {
          // Tab count = "All" + one per category.
          final tabCount = categories.length + 1;
          _initTabController(tabCount);

          final tabController = _tabController!;

          // Build tab labels once so they're not recreated each frame.
          final tabs = [
            const Tab(text: 'All'),
            ...categories.map((c) => Tab(text: _formatCategory(c))),
          ];

          return _buildBody(
            context,
            tabController: tabController,
            tabs: tabs,
          );
        },
      ),
    );
  }

  /// Builds the GestureDetector + RefreshIndicator + CustomScrollView tree.
  ///
  /// Separated from [build] to keep it readable after the categories
  /// AsyncValue is resolved.
  Widget _buildBody(
    BuildContext context, {
    required TabController tabController,
    required List<Widget> tabs,
  }) {
    return GestureDetector(
      // ── Horizontal swipe gesture ────────────────────────────────────────
      // We listen to the END of the drag (not each delta) so we can use
      // velocity to distinguish an intentional swipe from a scroll.
      onHorizontalDragEnd: _onHorizontalDragEnd,

      // ── Pull-to-refresh ─────────────────────────────────────────────────
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFFFF6000),

        // ── THE SINGLE VERTICAL SCROLL OWNER ────────────────────────────
        child: CustomScrollView(
          // physics: AlwaysScrollableScrollPhysics is required so
          // RefreshIndicator can activate even when the list is short.
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── 1. Collapsible banner app bar ──────────────────────────
            _buildSliverAppBar(context),

            // ── 2. Sticky tab bar ──────────────────────────────────────
            SliverPersistentHeader(
              // pinned: true → stays glued to the top after the SliverAppBar
              // collapses. Products scroll behind it, never under it.
              pinned: true,
              delegate: TabBarDelegate(
                tabController: tabController,
                tabs: tabs,
              ),
            ),

            // ── 3. Product grid (content for current tab) ──────────────
            // This Consumer rebuilds ONLY the grid when the active tab or
            // product data changes — the SliverAppBar and tab bar are
            // completely unaffected.
            _buildProductSliver(),
          ],
        ),
      ),
    );
  }

  // ── Sliver builders ────────────────────────────────────────────────────────

  /// Builds the collapsible header with banner image and search bar.
  ///
  /// Property breakdown:
  ///   expandedHeight : full height when scrolled to top
  ///   pinned         : collapsed toolbar stays visible at all times
  ///   floating       : false → header does NOT re-appear on small upward scrolls
  ///   bottom         : a PreferredSize widget that always sticks below the toolbar
  ///                    (we use it for the persistent search bar)
  ///   flexibleSpace  : fills the expanded area; shrinks on scroll
  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFFFF6000),
      expandedHeight: 180,
      pinned: true,
      floating: false,

      // ── Collapsed toolbar content ───────────────────────────────────────
      // Shown when the user has scrolled past the expanded header.
      title: const Text(
        'Daraz Clone',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline, color: Colors.white),
          tooltip: 'Profile',
          onPressed: () => context.push('/profile'),
        ),
      ],

      // ── Always-visible search bar (bottom of AppBar) ──────────────────
      // PreferredSize tells the AppBar how much vertical space this takes.
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          height: 40,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              SizedBox(width: 10),
              Icon(Icons.search, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text(
                'Search in Daraz',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ),

      // ── Expandable banner area ────────────────────────────────────────
      flexibleSpace: FlexibleSpaceBar(
        // collapseMode: parallax causes the image to scroll slower than
        // the finger, giving a pleasant depth effect.
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner image — a generic e-commerce hero image from picsum.
            Image.network(
              'https://picsum.photos/seed/daraz/800/300',
              fit: BoxFit.cover,
              // Faded placeholder while loading.
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(color: const Color(0xFFFF8C42));
              },
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFFFF8C42)),
            ),

            // Gradient overlay so the title text is legible.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x88000000)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the SliverGrid that renders product cards.
  ///
  /// We use a [Consumer] widget (not [ConsumerWidget]) to scope the rebuild
  /// to just the grid — the SliverAppBar and tab bar above it are NOT
  /// affected when the product list changes.
  Widget _buildProductSliver() {
    return Consumer(
      builder: (context, ref, _) {
        final productsAsync = ref.watch(activeProductsProvider);

        return productsAsync.when(
          // ── Loading ───────────────────────────────────────────────────
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),

          // ── Error ─────────────────────────────────────────────────────
          error: (err, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.grey, size: 40),
                  const SizedBox(height: 8),
                  const Text('Failed to load products'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      final category = ref.read(activeCategoryProvider);
                      // invalidate marks the provider stale; Consumer rebuilds automatically.
                      ref.invalidate(productsByTabProvider(category));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),

          // ── Data ──────────────────────────────────────────────────────
          data: (products) {
            if (products.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('No products found.')),
              );
            }

            // ── SliverGrid — the ONLY place products are rendered ───────
            // Using SliverGrid instead of GridView keeps everything inside
            // the single CustomScrollView scroll tree.
            return SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverGrid(
                // 2-column fixed cross-axis layout — standard Daraz grid.
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62, // taller than wide to fit all content
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ProductCard(
                    product: products[index],
                    // Cart functionality is a placeholder for this demo.
                    onAddToCart: () => _showAddedToCartSnackbar(context),
                  ),
                  childCount: products.length,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Capitalises the first letter of a category name for display in the tab.
  /// e.g. "men's clothing" → "Men's Clothing"
  String _formatCategory(String category) {
    return category
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  void _showAddedToCartSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to cart!'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
