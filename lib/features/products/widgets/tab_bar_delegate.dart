/// tab_bar_delegate.dart
///
/// A [SliverPersistentHeaderDelegate] that wraps a [TabBar].
///
/// Why we need a custom delegate:
///   [SliverPersistentHeader] requires a delegate that specifies
///   [minExtent] and [maxExtent] and renders into a [build] method.
///   Flutter does not provide a built-in delegate for tab bars, so
///   we implement one here.
///
/// Design choices:
///   - minExtent == maxExtent == kToolbarHeight (56 dp)
///     → the header never collapses; it's always the same height.
///   - A subtle shadow appears via BoxDecoration to visually separate
///     the sticky tab bar from the scrolling product list below.
///
/// Usage inside CustomScrollView:
///   SliverPersistentHeader(
///     pinned: true,           // stays visible after SliverAppBar collapses
///     delegate: TabBarDelegate(tabController: _tabController, tabs: [...]),
///   )

import 'package:flutter/material.dart';

class TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<Widget> tabs;

  const TabBarDelegate({
    required this.tabController,
    required this.tabs,
  });

  // ── SliverPersistentHeaderDelegate overrides ──────────────────────────────

  /// The maximum height this header can occupy.
  /// We use kTextTabBarHeight (48 dp) — the standard Flutter TabBar height —
  /// instead of kToolbarHeight (56 dp) to match the actual TabBar render size
  /// and avoid SliverGeometry layoutExtent > paintExtent assertion errors.
  @override
  double get maxExtent => kTextTabBarHeight;

  /// The minimum height when the header is pinned after collapsing.
  /// Equal to maxExtent because we don't want the tab bar to collapse.
  @override
  double get minExtent => kTextTabBarHeight;

  /// [shrinkOffset] = how many pixels have been scrolled past the header's
  /// natural position (0 = fully expanded, maxExtent = fully collapsed).
  ///
  /// We use it to drive a subtle elevation effect: as the header pins, a
  /// light shadow appears to indicate content is scrolling behind it.
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Clamp so elevation never goes negative or absurdly high.
    final shadowElevation = (shrinkOffset / maxExtent * 4).clamp(0.0, 4.0);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            // Shadow only appears when pinned (overlapsContent = true).
            color: Colors.black.withValues(alpha: overlapsContent ? 0.08 : 0.0),
            blurRadius: shadowElevation,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: tabController,
        tabs: tabs,
        // Scrollable so many categories don't overflow on small screens.
        isScrollable: true,
        tabAlignment: TabAlignment.start,

        // Daraz-style orange indicator.
        indicatorColor: const Color(0xFFFF6000),
        indicatorWeight: 3,
        labelColor: const Color(0xFFFF6000),
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  /// Called by the framework to decide whether to rebuild the header.
  /// We rebuild whenever the tab controller or tabs list changes, which
  /// happens if categories are refetched.
  @override
  bool shouldRebuild(TabBarDelegate oldDelegate) {
    return oldDelegate.tabController != tabController ||
        oldDelegate.tabs != tabs;
  }
}
