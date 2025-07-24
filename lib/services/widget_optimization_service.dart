import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Service for optimizing widget rendering and managing high refresh rates
class WidgetOptimizationService {
  static final WidgetOptimizationService _instance =
      WidgetOptimizationService._internal();
  factory WidgetOptimizationService() => _instance;
  WidgetOptimizationService._internal();

  bool _initialized = false;
  double _currentRefreshRate = 60.0;
  double _targetRefreshRate = 60.0;
  Timer? _performanceMonitorTimer;
  final List<double> _frameRateHistory = [];
  static const int _maxHistoryLength = 100;

  /// Initialize the optimization service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _detectAndSetOptimalRefreshRate();
      _startPerformanceMonitoring();
      _initialized = true;
      debugPrint(
        'WidgetOptimizationService initialized with ${_currentRefreshRate}Hz',
      );
    } catch (e) {
      debugPrint('Error initializing WidgetOptimizationService: $e');
    }
  }

  /// Detect device capabilities and set optimal refresh rate
  Future<void> _detectAndSetOptimalRefreshRate() async {
    try {
      // Get display refresh rate from platform
      final display = PlatformDispatcher.instance.displays.first;
      _currentRefreshRate = display.refreshRate;

      // Set target refresh rate (prefer 120Hz if available)
      if (_currentRefreshRate >= 120.0) {
        _targetRefreshRate = 120.0;
        debugPrint(
          'High refresh rate display detected: ${_currentRefreshRate}Hz, targeting 120Hz',
        );
      } else if (_currentRefreshRate >= 90.0) {
        _targetRefreshRate = 90.0;
        debugPrint(
          'Medium refresh rate display detected: ${_currentRefreshRate}Hz, targeting 90Hz',
        );
      } else {
        _targetRefreshRate = 60.0;
        debugPrint(
          'Standard refresh rate display detected: ${_currentRefreshRate}Hz, targeting 60Hz',
        );
      }

      // Try to enable high refresh rate mode on Android
      if (_targetRefreshRate > 60.0) {
        await _enableHighRefreshRateMode();
      }
    } catch (e) {
      debugPrint('Error detecting refresh rate: $e');
      _currentRefreshRate = 60.0;
      _targetRefreshRate = 60.0;
    }
  }

  /// Enable high refresh rate mode on supported platforms
  Future<void> _enableHighRefreshRateMode() async {
    try {
      // This would typically involve platform-specific code
      // For now, we'll use Flutter's built-in capabilities
      SchedulerBinding.instance.addPostFrameCallback((_) {
        // Ensure smooth animations at high refresh rates
        SchedulerBinding.instance.scheduleWarmUpFrame();
      });
    } catch (e) {
      debugPrint('Error enabling high refresh rate mode: $e');
    }
  }

  /// Start monitoring performance metrics
  void _startPerformanceMonitoring() {
    _performanceMonitorTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _collectPerformanceMetrics(),
    );
  }

  /// Collect and analyze performance metrics
  void _collectPerformanceMetrics() {
    // Calculate current frame rate
    final frameRate = _calculateFrameRate();

    _frameRateHistory.add(frameRate);
    if (_frameRateHistory.length > _maxHistoryLength) {
      _frameRateHistory.removeAt(0);
    }

    // Log performance issues
    if (frameRate < _targetRefreshRate * 0.8) {
      debugPrint(
        'Performance warning: Frame rate dropped to ${frameRate.toStringAsFixed(1)}fps (target: ${_targetRefreshRate}fps)',
      );
    }
  }

  /// Calculate current frame rate
  double _calculateFrameRate() {
    try {
      // This is a simplified calculation
      // In a real implementation, you'd track frame timestamps
      return _currentRefreshRate;
    } catch (e) {
      return 60.0;
    }
  }

  /// Get current performance metrics
  PerformanceMetrics getPerformanceMetrics() {
    final averageFrameRate =
        _frameRateHistory.isEmpty
            ? _currentRefreshRate
            : _frameRateHistory.reduce((a, b) => a + b) /
                _frameRateHistory.length;

    return PerformanceMetrics(
      currentRefreshRate: _currentRefreshRate,
      targetRefreshRate: _targetRefreshRate,
      averageFrameRate: averageFrameRate,
      frameDrops: _countFrameDrops(),
      isHighRefreshRateEnabled: _targetRefreshRate > 60.0,
    );
  }

  /// Count frame drops in recent history
  int _countFrameDrops() {
    if (_frameRateHistory.isEmpty) return 0;

    return _frameRateHistory
        .where((rate) => rate < _targetRefreshRate * 0.9)
        .length;
  }

  /// Optimize widget for high refresh rate
  Widget optimizeForHighRefreshRate(Widget child) {
    if (_targetRefreshRate <= 60.0) {
      return child;
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([]),
        builder: (context, _) => child,
      ),
    );
  }

  /// Create optimized animation controller
  AnimationController createOptimizedAnimationController({
    required TickerProvider vsync,
    Duration? duration,
  }) {
    // Adjust animation duration based on refresh rate
    final adjustedDuration =
        duration != null
            ? Duration(
              milliseconds:
                  (duration.inMilliseconds * (60.0 / _targetRefreshRate))
                      .round(),
            )
            : const Duration(milliseconds: 200);

    return AnimationController(vsync: vsync, duration: adjustedDuration);
  }

  /// Dispose resources
  void dispose() {
    _performanceMonitorTimer?.cancel();
    _frameRateHistory.clear();
    _initialized = false;
  }

  /// Get current refresh rate
  double get currentRefreshRate => _currentRefreshRate;

  /// Get target refresh rate
  double get targetRefreshRate => _targetRefreshRate;

  /// Check if high refresh rate is enabled
  bool get isHighRefreshRateEnabled => _targetRefreshRate > 60.0;
}

/// Performance metrics data class
class PerformanceMetrics {
  final double currentRefreshRate;
  final double targetRefreshRate;
  final double averageFrameRate;
  final int frameDrops;
  final bool isHighRefreshRateEnabled;

  const PerformanceMetrics({
    required this.currentRefreshRate,
    required this.targetRefreshRate,
    required this.averageFrameRate,
    required this.frameDrops,
    required this.isHighRefreshRateEnabled,
  });

  @override
  String toString() {
    return 'PerformanceMetrics('
        'currentRefreshRate: ${currentRefreshRate}Hz, '
        'targetRefreshRate: ${targetRefreshRate}Hz, '
        'averageFrameRate: ${averageFrameRate.toStringAsFixed(1)}fps, '
        'frameDrops: $frameDrops, '
        'isHighRefreshRateEnabled: $isHighRefreshRateEnabled'
        ')';
  }
}

/// Mixin for widgets that need performance optimization
mixin PerformanceOptimizedWidget<T extends StatefulWidget> on State<T> {
  late WidgetOptimizationService _optimizationService;

  @override
  void initState() {
    super.initState();
    _optimizationService = WidgetOptimizationService();
  }

  /// Create optimized animation controller
  AnimationController createOptimizedController({Duration? duration}) {
    return _optimizationService.createOptimizedAnimationController(
      vsync: this as TickerProvider,
      duration: duration,
    );
  }

  /// Wrap widget with high refresh rate optimization
  Widget optimizeWidget(Widget child) {
    return _optimizationService.optimizeForHighRefreshRate(child);
  }

  /// Get current performance metrics
  PerformanceMetrics get performanceMetrics =>
      _optimizationService.getPerformanceMetrics();
}

/// Widget that displays performance information (for debugging)
class PerformanceDebugWidget extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const PerformanceDebugWidget({
    super.key,
    required this.child,
    this.showOverlay = false,
  });

  @override
  State<PerformanceDebugWidget> createState() => _PerformanceDebugWidgetState();
}

class _PerformanceDebugWidgetState extends State<PerformanceDebugWidget> {
  late Timer _updateTimer;
  PerformanceMetrics? _metrics;

  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateMetrics(),
    );
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    super.dispose();
  }

  void _updateMetrics() {
    if (mounted) {
      setState(() {
        _metrics = WidgetOptimizationService().getPerformanceMetrics();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showOverlay || _metrics == null) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 50,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FPS: ${_metrics!.averageFrameRate.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  'Target: ${_metrics!.targetRefreshRate}Hz',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  'Drops: ${_metrics!.frameDrops}',
                  style: TextStyle(
                    color: _metrics!.frameDrops > 5 ? Colors.red : Colors.white,
                    fontSize: 12,
                  ),
                ),
                if (_metrics!.isHighRefreshRateEnabled)
                  const Text(
                    'High Refresh Rate',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
