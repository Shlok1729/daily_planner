import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_planner/providers/app_blocker_provider.dart';
import 'package:daily_planner/models/blocked_app.dart';
import 'package:daily_planner/services/app_blocker_service.dart';
import 'package:daily_planner/utils/app_blocker_manager.dart';
import 'package:daily_planner/utils/error_handler.dart';

// ============================================================================
// DEVICE APP MODEL (FIXED - Added missing DeviceApp class)
// ============================================================================

class DeviceApp {
  final String name;
  final String packageName;
  final String icon;
  final String category;
  final bool isBlocked;
  final bool isLaunchable;
  final bool isSystemApp;

  const DeviceApp({
    required this.name,
    required this.packageName,
    required this.icon,
    required this.category,
    this.isBlocked = false,
    this.isLaunchable = true,
    this.isSystemApp = false,
  });

  DeviceApp copyWith({
    String? name,
    String? packageName,
    String? icon,
    String? category,
    bool? isBlocked,
    bool? isLaunchable,
    bool? isSystemApp,
  }) {
    return DeviceApp(
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      isBlocked: isBlocked ?? this.isBlocked,
      isLaunchable: isLaunchable ?? this.isLaunchable,
      isSystemApp: isSystemApp ?? this.isSystemApp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'packageName': packageName,
      'icon': icon,
      'category': category,
      'isBlocked': isBlocked,
      'isLaunchable': isLaunchable,
      'isSystemApp': isSystemApp,
    };
  }

  factory DeviceApp.fromJson(Map<String, dynamic> json) {
    return DeviceApp(
      name: json['name'] ?? '',
      packageName: json['packageName'] ?? '',
      icon: json['icon'] ?? '📱',
      category: json['category'] ?? 'Other',
      isBlocked: json['isBlocked'] ?? false,
      isLaunchable: json['isLaunchable'] ?? true,
      isSystemApp: json['isSystemApp'] ?? false,
    );
  }

  factory DeviceApp.fromAppInfo(AppInfo appInfo) {
    return DeviceApp(
      name: appInfo.name,
      packageName: appInfo.packageName,
      icon: appInfo.icon ?? '📱',
      category: appInfo.category ?? 'Other',
      isLaunchable: appInfo.isLaunchable,
      isSystemApp: appInfo.isSystemApp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceApp && other.packageName == packageName;
  }

  @override
  int get hashCode => packageName.hashCode;
}

// ============================================================================
// APP BLOCKER SELECTION SCREEN - COMPLETE IMPLEMENTATION
// ============================================================================

/// Screen for selecting apps to block during focus sessions
/// COMPLETELY IMPLEMENTED: Real device apps, search, categories, bulk actions
class AppBlockerSelectionScreen extends ConsumerStatefulWidget {
  final bool isInitialSetup;
  final VoidCallback? onSetupComplete;
  final List<String>? preSelectedApps;
  final bool allowMultipleSelection;
  final String? title;
  final String? subtitle;
  final Function(List<String> selectedApps)? onSelectionChanged;

  const AppBlockerSelectionScreen({
    Key? key,
    this.isInitialSetup = false,
    this.onSetupComplete,
    this.preSelectedApps,
    this.allowMultipleSelection = true,
    this.title,
    this.subtitle,
    this.onSelectionChanged,
  }) : super(key: key);

  @override
  ConsumerState<AppBlockerSelectionScreen> createState() => _AppBlockerSelectionScreenState();
}

class _AppBlockerSelectionScreenState extends ConsumerState<AppBlockerSelectionScreen>
    with TickerProviderStateMixin {

  // ========================================
  // STATE VARIABLES
  // ========================================

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final AppBlockerManager _appBlockerManager = AppBlockerManager();

  // App data
  List<DeviceApp> _allDeviceApps = [];
  List<DeviceApp> _filteredDeviceApps = [];
  List<BlockedApp> _selectedApps = [];

  // UI state
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = false;
  bool _showOnlyUnblocked = true;
  String? _error;

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _categories = [
    'All',
    'Social',
    'Entertainment',
    'Games',
    'Communication',
    'Productivity',
    'Shopping',
    'News',
    'Other'
  ];

  // ========================================
  // LIFECYCLE METHODS
  // ========================================

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);

    // Initialize selection from pre-selected apps
    if (widget.preSelectedApps != null) {
      _initializePreSelection();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOut,
    ));
  }

  void _initializePreSelection() {
    if (widget.preSelectedApps != null) {
      for (final packageName in widget.preSelectedApps!) {
        // We'll add these to selection once we load the apps
      }
    }
  }

  // ========================================
  // DATA LOADING (FIXED - Using AppBlockerManager)
  // ========================================

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Initialize app blocker manager
      await _appBlockerManager.initialize();

      // Load device apps using the manager
      await _refreshDeviceApps();

      // Start animations
      _fadeAnimationController.forward();
      _slideAnimationController.forward();

    } catch (e) {
      setState(() {
        _error = ErrorHandler.getUserFriendlyMessage(e);
      });
      ErrorHandler.logError('Load initial data', e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshDeviceApps() async {
    try {
      // Get installed apps from manager
      final appInfoList = await _appBlockerManager.getInstalledApps(forceRefresh: true);

      // Get currently blocked apps to mark them
      final blockedApps = await _appBlockerManager.getBlockedApps();
      final blockedPackageNames = blockedApps.map((app) => app.packageName).toSet();

      // Convert AppInfo to DeviceApp
      final deviceApps = appInfoList.map((appInfo) {
        return DeviceApp(
          name: appInfo.name,
          packageName: appInfo.packageName,
          icon: appInfo.icon ?? _getDefaultIconForCategory(appInfo.category ?? 'Other'),
          category: appInfo.category ?? 'Other',
          isBlocked: blockedPackageNames.contains(appInfo.packageName),
          isLaunchable: appInfo.isLaunchable,
          isSystemApp: appInfo.isSystemApp,
        );
      }).toList();

      setState(() {
        _allDeviceApps = deviceApps;
        _filterApps();
      });

      // Initialize pre-selected apps if provided
      if (widget.preSelectedApps != null && _selectedApps.isEmpty) {
        _initializePreSelectedApps();
      }

    } catch (e) {
      setState(() {
        _error = ErrorHandler.getUserFriendlyMessage(e);
      });
      ErrorHandler.logError('Refresh device apps', e);
    }
  }

  void _initializePreSelectedApps() {
    for (final packageName in widget.preSelectedApps!) {
      final deviceApp = _allDeviceApps.firstWhere(
            (app) => app.packageName == packageName,
        orElse: () => DeviceApp(name: '', packageName: '', icon: '', category: ''),
      );

      if (deviceApp.packageName.isNotEmpty && !_isAppSelected(deviceApp)) {
        _selectedApps.add(BlockedApp(
          name: deviceApp.name,
          packageName: deviceApp.packageName,
          icon: deviceApp.icon,
          category: _getAppCategoryFromString(deviceApp.category),
          isBlocked: true,
        ));
      }
    }

    setState(() {});
    widget.onSelectionChanged?.call(_selectedApps.map((app) => app.packageName).toList());
  }

  // ========================================
  // SEARCH AND FILTERING
  // ========================================

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _filterApps();
    });
  }

  void _filterApps() {
    setState(() {
      _filteredDeviceApps = _allDeviceApps.where((app) {
        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!app.name.toLowerCase().contains(query) &&
              !app.packageName.toLowerCase().contains(query)) {
            return false;
          }
        }

        // Filter by category
        if (_selectedCategory != 'All' && app.category != _selectedCategory) {
          return false;
        }

        // Filter by blocked status
        if (_showOnlyUnblocked && app.isBlocked) {
          return false;
        }

        // Only show launchable apps
        return app.isLaunchable;
      }).toList();

      // Sort by name
      _filteredDeviceApps.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  // ========================================
  // APP SELECTION
  // ========================================

  void _toggleAppSelection(DeviceApp app) {
    setState(() {
      final index = _selectedApps.indexWhere((selected) => selected.packageName == app.packageName);

      if (index >= 0) {
        _selectedApps.removeAt(index);
      } else {
        if (!widget.allowMultipleSelection) {
          _selectedApps.clear();
        }

        _selectedApps.add(BlockedApp(
          name: app.name,
          packageName: app.packageName,
          icon: app.icon,
          category: _getAppCategoryFromString(app.category),
          isBlocked: true,
        ));
      }
    });

    HapticFeedback.selectionClick();
    widget.onSelectionChanged?.call(_selectedApps.map((app) => app.packageName).toList());
  }

  AppCategory _getAppCategoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'social':
        return AppCategory.social;
      case 'entertainment':
        return AppCategory.entertainment;
      case 'communication':
        return AppCategory.messaging;
      case 'games':
        return AppCategory.games;
      case 'productivity':
        return AppCategory.productivity;
      case 'shopping':
        return AppCategory.shopping;
      case 'news':
        return AppCategory.news;
      default:
        return AppCategory.other;
    }
  }

  bool _isAppSelected(DeviceApp app) {
    return _selectedApps.any((selected) => selected.packageName == app.packageName);
  }

  void _selectCategoryApps(String category) {
    final categoryApps = _filteredDeviceApps.where((app) =>
    category == 'All' || app.category == category
    ).toList();

    setState(() {
      for (final app in categoryApps) {
        if (!_isAppSelected(app)) {
          _selectedApps.add(BlockedApp(
            name: app.name,
            packageName: app.packageName,
            icon: app.icon,
            category: _getAppCategoryFromString(app.category),
            isBlocked: true,
          ));
        }
      }
    });

    _showSnackbar('Added ${categoryApps.length} apps from $category category');
    widget.onSelectionChanged?.call(_selectedApps.map((app) => app.packageName).toList());
  }

  void _selectPopularApps() {
    final popularApps = _getPopularApps();

    setState(() {
      for (final popularApp in popularApps) {
        // Check if this app exists on device
        final deviceApp = _allDeviceApps.firstWhere(
              (app) => app.packageName == popularApp.packageName,
          orElse: () => DeviceApp(name: '', packageName: '', icon: '', category: ''),
        );

        if (deviceApp.packageName.isNotEmpty && !_isAppSelected(deviceApp)) {
          _selectedApps.add(popularApp.copyWith(isBlocked: true));
        }
      }
    });

    _showSnackbar('Added popular distracting apps');
    widget.onSelectionChanged?.call(_selectedApps.map((app) => app.packageName).toList());
  }

  void _selectAllApps() {
    setState(() {
      for (final app in _filteredDeviceApps) {
        if (!_isAppSelected(app)) {
          _selectedApps.add(BlockedApp(
            name: app.name,
            packageName: app.packageName,
            icon: app.icon,
            category: _getAppCategoryFromString(app.category),
            isBlocked: true,
          ));
        }
      }
    });

    _showSnackbar('Selected all ${_filteredDeviceApps.length} apps');
    widget.onSelectionChanged?.call(_selectedApps.map((app) => app.packageName).toList());
  }

  void _clearSelection() {
    setState(() {
      _selectedApps.clear();
    });
    _showSnackbar('Selection cleared');
    widget.onSelectionChanged?.call([]);
  }

  // ========================================
  // SAVE SELECTION (FIXED - Using AppBlockerManager)
  // ========================================

  Future<void> _saveSelection() async {
    if (_selectedApps.isEmpty) {
      _showSnackbar('Please select at least one app to block', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Add all selected apps using the manager
      await _appBlockerManager.addMultipleBlockedApps(_selectedApps);

      _showSnackbar('${_selectedApps.length} apps added to blocking list');

      if (widget.isInitialSetup) {
        widget.onSetupComplete?.call();
      }

      Navigator.pop(context, _selectedApps.map((app) => app.packageName).toList());
    } catch (e) {
      _showSnackbar('Failed to save selection: ${ErrorHandler.getUserFriendlyMessage(e)}', isError: true);
      ErrorHandler.logError('Save selection', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ========================================
  // UI BUILDERS
  // ========================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildMainContent(),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A2E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.title ?? (widget.isInitialSetup ? 'Select Apps to Block' : 'Manage Blocked Apps'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (_selectedApps.isNotEmpty)
          IconButton(
            icon: Badge(
              label: Text('${_selectedApps.length}'),
              child: const Icon(Icons.check_circle, color: Colors.white),
            ),
            onPressed: _saveSelection,
            tooltip: 'Save Selection',
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                _loadInitialData();
                break;
              case 'select_all':
                _selectAllApps();
                break;
              case 'clear_all':
                _clearSelection();
                break;
              case 'popular':
                _selectPopularApps();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'refresh', child: Text('Refresh Apps')),
            const PopupMenuItem(value: 'select_all', child: Text('Select All')),
            const PopupMenuItem(value: 'clear_all', child: Text('Clear Selection')),
            const PopupMenuItem(value: 'popular', child: Text('Select Popular Apps')),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF4ECDC4)),
          SizedBox(height: 16),
          Text(
            'Loading installed apps...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_error != null) {
      return _buildErrorState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilters(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Apps',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInitialData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            widget.subtitle ?? 'Block distracting apps during focus time',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_selectedApps.isNotEmpty)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4ECDC4).withOpacity(0.5)),
              ),
              child: Text(
                '${_selectedApps.length} apps selected',
                style: const TextStyle(
                  color: Color(0xFF4ECDC4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search apps...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged();
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Filters
          Row(
            children: [
              // Category filter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      dropdownColor: const Color(0xFF2D2D44),
                      style: const TextStyle(color: Colors.white),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                          _filterApps();
                        });
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Show only unblocked toggle
              FilterChip(
                label: const Text('Unblocked only', style: TextStyle(color: Colors.white)),
                selected: _showOnlyUnblocked,
                backgroundColor: Colors.white.withOpacity(0.1),
                selectedColor: const Color(0xFF4ECDC4).withOpacity(0.3),
                checkmarkColor: Colors.white,
                onSelected: (selected) {
                  setState(() {
                    _showOnlyUnblocked = selected;
                    _filterApps();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: const Color(0xFF4ECDC4),
      unselectedLabelColor: Colors.white70,
      indicatorColor: const Color(0xFF4ECDC4),
      tabs: const [
        Tab(text: 'Device Apps', icon: Icon(Icons.phone_android)),
        Tab(text: 'Popular Apps', icon: Icon(Icons.trending_up)),
        Tab(text: 'Categories', icon: Icon(Icons.category)),
      ],
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildDeviceAppsTab(),
        _buildPopularAppsTab(),
        _buildCategoriesTab(),
      ],
    );
  }

  Widget _buildDeviceAppsTab() {
    if (_filteredDeviceApps.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredDeviceApps.length,
      itemBuilder: (context, index) {
        final app = _filteredDeviceApps[index];
        final isSelected = _isAppSelected(app);

        return _buildAppItem(app, isSelected, index);
      },
    );
  }

  Widget _buildPopularAppsTab() {
    final popularApps = _getPopularApps();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: popularApps.length,
      itemBuilder: (context, index) {
        final popularApp = popularApps[index];
        final deviceApp = _allDeviceApps.firstWhere(
              (app) => app.packageName == popularApp.packageName,
          orElse: () => DeviceApp(name: '', packageName: '', icon: '', category: ''),
        );

        final isInstalled = deviceApp.packageName.isNotEmpty;
        final isSelected = _selectedApps.any((app) => app.packageName == popularApp.packageName);

        return _buildPopularAppItem(popularApp, deviceApp, isInstalled, isSelected, index);
      },
    );
  }

  Widget _buildCategoriesTab() {
    final categoryStats = <String, int>{};

    // Count apps per category
    for (final app in _allDeviceApps) {
      if (app.isLaunchable) {
        categoryStats[app.category] = (categoryStats[app.category] ?? 0) + 1;
      }
    }

    final categories = categoryStats.keys.where((cat) => cat != 'All').toList()
      ..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final count = categoryStats[category] ?? 0;
        final selectedInCategory = _selectedApps.where((app) =>
        app.category.toString().split('.').last.toLowerCase() == category.toLowerCase()
        ).length;

        return _buildCategoryItem(category, count, selectedInCategory, index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apps, size: 64, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No apps found matching "$_searchQuery"'
                : 'No apps found',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _searchController.clear();
                _onSearchChanged();
              },
              child: const Text(
                'Clear search',
                style: TextStyle(color: Color(0xFF4ECDC4)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppItem(DeviceApp app, bool isSelected, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 50)),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF4ECDC4).withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF4ECDC4)
              : Colors.white.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(app.category).withOpacity(0.1),
          child: Text(
            app.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          app.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app.category,
              style: TextStyle(
                color: _getCategoryColor(app.category),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (app.isBlocked) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Currently Blocked',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: AnimatedScale(
          scale: isSelected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isSelected ? Icons.check_circle : Icons.circle_outlined,
            color: isSelected ? const Color(0xFF4ECDC4) : Colors.white.withOpacity(0.3),
            size: 28,
          ),
        ),
        onTap: () => _toggleAppSelection(app),
      ),
    );
  }

  Widget _buildPopularAppItem(BlockedApp popularApp, DeviceApp deviceApp, bool isInstalled, bool isSelected, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 50)),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF4ECDC4).withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF4ECDC4)
              : Colors.white.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(popularApp.category.toString().split('.').last).withOpacity(0.1),
          child: Text(
            popularApp.icon,
            style: TextStyle(
              fontSize: 20,
              color: isInstalled ? null : Colors.grey,
            ),
          ),
        ),
        title: Text(
          popularApp.name,
          style: TextStyle(
            color: isInstalled ? Colors.white : Colors.white60,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              popularApp.category.toString().split('.').last,
              style: TextStyle(
                color: _getCategoryColor(popularApp.category.toString().split('.').last),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '~${popularApp.estimatedTimeSavedPerBlock.inMinutes} min saved per block',
              style: const TextStyle(fontSize: 11, color: Colors.green),
            ),
            if (!isInstalled) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Not installed on device',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: isInstalled
            ? AnimatedScale(
          scale: isSelected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isSelected ? Icons.check_circle : Icons.circle_outlined,
            color: isSelected ? const Color(0xFF4ECDC4) : Colors.white.withOpacity(0.3),
            size: 28,
          ),
        )
            : Icon(Icons.download, color: Colors.grey[400]),
        onTap: isInstalled ? () => _toggleAppSelection(deviceApp) : null,
      ),
    );
  }

  Widget _buildCategoryItem(String category, int count, int selectedInCategory, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 50)),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(category).withOpacity(0.1),
          child: Icon(
            _getCategoryIcon(category),
            color: _getCategoryColor(category),
          ),
        ),
        title: Text(
          category,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '$count apps available',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selectedInCategory > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$selectedInCategory selected',
                  style: TextStyle(
                    fontSize: 10,
                    color: _getCategoryColor(category),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white.withOpacity(0.4)),
          ],
        ),
        onTap: () => _selectCategoryApps(category),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    if (_selectedApps.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Selection count
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedApps.length} apps selected',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Est. ${_selectedApps.fold<int>(0, (sum, app) => sum + app.estimatedTimeSavedPerBlock.inMinutes)} min saved per session',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            TextButton(
              onPressed: _clearSelection,
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.white70),
              ),
            ),

            const SizedBox(width: 8),

            ElevatedButton(
              onPressed: _isLoading ? null : _saveSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  String _getDefaultIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'social':
        return '🌐';
      case 'entertainment':
        return '🎬';
      case 'games':
        return '🎮';
      case 'communication':
        return '💬';
      case 'productivity':
        return '⚡';
      case 'shopping':
        return '🛒';
      case 'news':
        return '📰';
      default:
        return '📱';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'social':
        return const Color(0xFF4267B2);
      case 'entertainment':
        return const Color(0xFFE50914);
      case 'games':
        return const Color(0xFF00C851);
      case 'communication':
        return const Color(0xFF25D366);
      case 'productivity':
        return const Color(0xFF4285F4);
      case 'shopping':
        return const Color(0xFFFF9500);
      case 'news':
        return const Color(0xFF1DA1F2);
      default:
        return const Color(0xFF6C757D);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'social':
        return Icons.people;
      case 'entertainment':
        return Icons.movie;
      case 'games':
        return Icons.games;
      case 'communication':
        return Icons.chat;
      case 'productivity':
        return Icons.work;
      case 'shopping':
        return Icons.shopping_cart;
      case 'news':
        return Icons.article;
      default:
        return Icons.apps;
    }
  }

  // ========================================
  // POPULAR APPS DATA (FIXED - Added missing method)
  // ========================================

  List<BlockedApp> _getPopularApps() {
    return [
      // Social Media Apps
      BlockedApp(
        name: 'Instagram',
        packageName: 'com.instagram.android',
        icon: '📷',
        category: AppCategory.social,
        estimatedTimeSavedPerBlock: const Duration(minutes: 8),
        blockMessages: [
          "ain't no way bro tried to open Instagram 💀",
          "resist the gram, embrace the grind 💪",
          "your future self will thank you for not scrolling",
        ],
      ),
      BlockedApp(
        name: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
        icon: '🎵',
        category: AppCategory.entertainment,
        estimatedTimeSavedPerBlock: const Duration(minutes: 12),
        blockMessages: [
          "TikTok? More like TikNOT during focus time 🚫",
          "the algorithm can wait, your goals can't ⏰",
          "resist the scroll, embrace the goal 🎯",
        ],
      ),
      BlockedApp(
        name: 'Facebook',
        packageName: 'com.facebook.katana',
        icon: '📘',
        category: AppCategory.social,
        estimatedTimeSavedPerBlock: const Duration(minutes: 6),
        blockMessages: [
          "Facebook? More like Focusboring during work time 😴",
          "your timeline isn't going anywhere, but your dreams are 🌟",
        ],
      ),
      BlockedApp(
        name: 'Twitter',
        packageName: 'com.twitter.android',
        icon: '🐦',
        category: AppCategory.social,
        estimatedTimeSavedPerBlock: const Duration(minutes: 5),
        blockMessages: [
          "tweeting can wait, achieving can't ⏰",
          "your hot takes will still be hot after focus time 🔥",
        ],
      ),
      BlockedApp(
        name: 'Snapchat',
        packageName: 'com.snapchat.android',
        icon: '👻',
        category: AppCategory.social,
        estimatedTimeSavedPerBlock: const Duration(minutes: 4),
      ),
      BlockedApp(
        name: 'LinkedIn',
        packageName: 'com.linkedin.android',
        icon: '💼',
        category: AppCategory.productivity,
        estimatedTimeSavedPerBlock: const Duration(minutes: 3),
      ),

      // Entertainment Apps
      BlockedApp(
        name: 'YouTube',
        packageName: 'com.google.android.youtube',
        icon: '📺',
        category: AppCategory.entertainment,
        estimatedTimeSavedPerBlock: const Duration(minutes: 15),
        blockMessages: [
          "YouTube can wait, your future can't 🚀",
          "one more video = one less step toward your goals",
          "those cat videos will still be there after focus time 🐱",
        ],
      ),
      BlockedApp(
        name: 'Netflix',
        packageName: 'com.netflix.mediaclient',
        icon: '🎬',
        category: AppCategory.entertainment,
        estimatedTimeSavedPerBlock: const Duration(minutes: 30),
      ),
      BlockedApp(
        name: 'Spotify',
        packageName: 'com.spotify.music',
        icon: '🎵',
        category: AppCategory.entertainment,
        estimatedTimeSavedPerBlock: const Duration(minutes: 3),
      ),
      BlockedApp(
        name: 'Disney+',
        packageName: 'com.disney.disneyplus',
        icon: '🏰',
        category: AppCategory.entertainment,
        estimatedTimeSavedPerBlock: const Duration(minutes: 25),
      ),

      // Gaming Apps
      BlockedApp(
        name: 'PUBG Mobile',
        packageName: 'com.tencent.ig',
        icon: '🎮',
        category: AppCategory.games,
        estimatedTimeSavedPerBlock: const Duration(minutes: 20),
      ),
      BlockedApp(
        name: 'Candy Crush',
        packageName: 'com.king.candycrushsaga',
        icon: '🍭',
        category: AppCategory.games,
        estimatedTimeSavedPerBlock: const Duration(minutes: 10),
      ),
      BlockedApp(
        name: 'Clash Royale',
        packageName: 'com.supercell.clashroyale',
        icon: '⚔️',
        category: AppCategory.games,
        estimatedTimeSavedPerBlock: const Duration(minutes: 8),
      ),

      // Communication Apps
      BlockedApp(
        name: 'WhatsApp',
        packageName: 'com.whatsapp',
        icon: '💬',
        category: AppCategory.messaging,
        estimatedTimeSavedPerBlock: const Duration(minutes: 5),
      ),
      BlockedApp(
        name: 'Telegram',
        packageName: 'org.telegram.messenger',
        icon: '✈️',
        category: AppCategory.messaging,
        estimatedTimeSavedPerBlock: const Duration(minutes: 4),
      ),
      BlockedApp(
        name: 'Discord',
        packageName: 'com.discord',
        icon: '🎧',
        category: AppCategory.messaging,
        estimatedTimeSavedPerBlock: const Duration(minutes: 7),
      ),

      // Shopping Apps
      BlockedApp(
        name: 'Amazon',
        packageName: 'com.amazon.mShop.android.shopping',
        icon: '🛒',
        category: AppCategory.shopping,
        estimatedTimeSavedPerBlock: const Duration(minutes: 8),
      ),
      BlockedApp(
        name: 'Flipkart',
        packageName: 'com.flipkart.android',
        icon: '🛒',
        category: AppCategory.shopping,
        estimatedTimeSavedPerBlock: const Duration(minutes: 6),
      ),

      // News Apps
      BlockedApp(
        name: 'Reddit',
        packageName: 'com.reddit.frontpage',
        icon: '🔶',
        category: AppCategory.news,
        estimatedTimeSavedPerBlock: const Duration(minutes: 10),
      ),
    ];
  }
}

// ============================================================================
// QUICK SETUP DIALOG (PRESERVED - All existing functionality)
// ============================================================================

/// Quick setup dialog for first-time users
class QuickAppBlockingSetupDialog extends ConsumerWidget {
  const QuickAppBlockingSetupDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2D2D44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.block, color: Colors.red),
          SizedBox(width: 8),
          Text('Quick Setup', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Get started quickly by selecting one of these options:',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),

          _buildQuickOption(
            context,
            ref,
            'Social Media Apps',
            'Block Instagram, Facebook, TikTok, Twitter',
            Icons.people,
            const Color(0xFF4267B2),
                () => _selectPopularApps(context, ref, AppCategory.social),
          ),

          _buildQuickOption(
            context,
            ref,
            'Entertainment Apps',
            'Block YouTube, Netflix, Spotify',
            Icons.movie,
            const Color(0xFFE50914),
                () => _selectPopularApps(context, ref, AppCategory.entertainment),
          ),

          _buildQuickOption(
            context,
            ref,
            'All Popular Apps',
            'Block the most distracting apps',
            Icons.trending_up,
            const Color(0xFFFF9500),
                () => _selectAllPopularApps(context, ref),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Skip', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AppBlockerSelectionScreen(isInitialSetup: true),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4ECDC4),
          ),
          child: const Text('Custom Setup'),
        ),
      ],
    );
  }

  Widget _buildQuickOption(
      BuildContext context,
      WidgetRef ref,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white.withOpacity(0.5),
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _selectPopularApps(BuildContext context, WidgetRef ref, AppCategory category) async {
    try {
      final appBlockerManager = AppBlockerManager();
      await appBlockerManager.initialize();

      // Get popular apps for this category
      final popularApps = _getPopularAppsForCategory(category);

      // Get installed apps
      final installedApps = await appBlockerManager.getInstalledApps();
      final installedPackageNames = installedApps.map((app) => app.packageName).toSet();

      // Filter to only include installed apps
      final appsToBlock = popularApps
          .where((app) => installedPackageNames.contains(app.packageName))
          .toList();

      if (appsToBlock.isNotEmpty) {
        await appBlockerManager.addMultipleBlockedApps(appsToBlock);
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${appsToBlock.length} ${category.name} apps'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add apps: ${ErrorHandler.getUserFriendlyMessage(e)}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _selectAllPopularApps(BuildContext context, WidgetRef ref) async {
    try {
      final appBlockerManager = AppBlockerManager();
      await appBlockerManager.initialize();

      // Get all popular apps
      final popularApps = _getAllPopularApps();

      // Get installed apps
      final installedApps = await appBlockerManager.getInstalledApps();
      final installedPackageNames = installedApps.map((app) => app.packageName).toSet();

      // Filter to only include installed apps
      final appsToBlock = popularApps
          .where((app) => installedPackageNames.contains(app.packageName))
          .toList();

      if (appsToBlock.isNotEmpty) {
        await appBlockerManager.addMultipleBlockedApps(appsToBlock);
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${appsToBlock.length} popular apps to blocking list'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add apps: ${ErrorHandler.getUserFriendlyMessage(e)}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  List<BlockedApp> _getPopularAppsForCategory(AppCategory category) {
    return _getAllPopularApps().where((app) => app.category == category).toList();
  }

  List<BlockedApp> _getAllPopularApps() {
    // This uses the same data as the main screen
    final selectionScreen = _AppBlockerSelectionScreenState();
    return selectionScreen._getPopularApps();
  }
}