import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Performance optimization utilities for widget rendering and lazy loading
class PerformanceOptimizer {
  static const int _defaultCacheSize = 50;
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  /// Cache for expensive widget builds
  static final Map<String, Widget> _widgetCache = {};

  /// Debounce timer for search operations
  static Timer? _debounceTimer;

  /// Get cached widget or build and cache new one
  static Widget getCachedWidget(String key, Widget Function() builder) {
    if (_widgetCache.containsKey(key)) {
      return _widgetCache[key]!;
    }

    final widget = builder();

    // Limit cache size to prevent memory issues
    if (_widgetCache.length >= _defaultCacheSize) {
      _widgetCache.remove(_widgetCache.keys.first);
    }

    _widgetCache[key] = widget;
    return widget;
  }

  /// Clear widget cache
  static void clearCache() {
    _widgetCache.clear();
  }

  /// Debounced search function
  static void debounceSearch(VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, callback);
  }

  /// Check if frame is available for expensive operations
  static bool get canPerformExpensiveOperation {
    return SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle;
  }

  /// Schedule expensive operation for next frame
  static void scheduleExpensiveOperation(VoidCallback callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (canPerformExpensiveOperation) {
        callback();
      } else {
        // Reschedule for next frame
        scheduleExpensiveOperation(callback);
      }
    });
  }

  /// Dispose resources
  static void dispose() {
    _debounceTimer?.cancel();
    clearCache();
  }
}

/// Lazy loading controller for ListView optimization
class LazyLoadingController<T> {
  final ScrollController scrollController = ScrollController();
  final int itemsPerPage;
  final Future<List<T>> Function(int page, int limit) loadItems;

  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;

  LazyLoadingController({required this.itemsPerPage, required this.loadItems}) {
    scrollController.addListener(_onScroll);
  }

  List<T> get items => _items;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      loadMore();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;

    try {
      final newItems = await loadItems(_currentPage, itemsPerPage);

      if (newItems.length < itemsPerPage) {
        _hasMore = false;
      }

      _items.addAll(newItems);
      _currentPage++;
    } catch (e) {
      debugPrint('Error loading more items: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    _items.clear();
    _currentPage = 0;
    _hasMore = true;
    _isLoading = false;
    await loadMore();
  }

  void dispose() {
    scrollController.dispose();
  }
}

/// Optimized loading indicator widget
class OptimizedLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;

  const OptimizedLoadingIndicator({super.key, this.message, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Optimized list view with lazy loading
class OptimizedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function()? onRefresh;
  final LazyLoadingController? lazyController;
  final EdgeInsets? padding;
  final Widget? emptyWidget;
  final bool shrinkWrap;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onRefresh,
    this.lazyController,
    this.padding,
    this.emptyWidget,
    this.shrinkWrap = false,
  });

  @override
  State<OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<OptimizedListView<T>> {
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && widget.emptyWidget != null) {
      return widget.emptyWidget!;
    }

    Widget listView = ListView.builder(
      controller: widget.lazyController?.scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount:
          widget.items.length +
          (widget.lazyController?.hasMore == true ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          // Loading indicator for lazy loading
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: OptimizedLoadingIndicator(message: 'Loading more...'),
          );
        }

        return widget.itemBuilder(context, widget.items[index], index);
      },
    );

    if (widget.onRefresh != null) {
      listView = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: listView,
      );
    }

    return listView;
  }
}
