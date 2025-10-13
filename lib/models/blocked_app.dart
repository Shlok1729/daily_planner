import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Enum for different app categories used in the blocker
enum AppCategory {
  social,
  entertainment,
  games,
  messaging,
  productivity,
  shopping,
  news,
  communication,
  education,
  health,
  finance,
  other,
}

/// Enum for different blocking message themes
enum MessageTheme {
  motivational, // "your future self will thank you"
  humorous,     // "ain't no way bro tried to open TikTok"
  challenging,  // "resist the gram, embrace the grind"
  supportive,   // "you got this! stay focused"
  funny,        // "deadass thought you could break focus mode"
}

/// Enum for blocking context
enum BlockingContext {
  focusSession,
  scheduledBlock,
  manualBlock,
  locationBlock,
}

/// Model representing a blocked app with all necessary data
class BlockedApp {
  final String id;
  final String name;
  final String packageName;
  final String icon;
  final AppCategory category;
  final Color primaryColor;
  final Color gradientStartColor;
  final Color gradientEndColor;
  final bool isBlocked;
  final bool blockDuringFocus;
  final bool alwaysBlocked;
  final DateTime? blockedUntil;
  final List<String> blockMessages;
  final MessageTheme messageTheme;
  final int blockAttempts;
  final DateTime lastBlockedAttempt;
  final Duration totalTimeSaved;
  final Duration estimatedTimeSavedPerBlock;
  final bool hasCustomMessages;
  final List<String> customMessages;
  final BlockingContext context;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime? lastUpdated;

  BlockedApp({
    String? id,
    required this.name,
    required this.packageName,
    required this.icon,
    required this.category,
    Color? primaryColor,
    Color? gradientStartColor,
    Color? gradientEndColor,
    this.isBlocked = false,
    this.blockDuringFocus = false,
    this.alwaysBlocked = false,
    this.blockedUntil,
    List<String>? blockMessages,
    this.messageTheme = MessageTheme.funny,
    this.blockAttempts = 0,
    DateTime? lastBlockedAttempt,
    Duration? totalTimeSaved,
    Duration? estimatedTimeSavedPerBlock,
    this.hasCustomMessages = false,
    List<String>? customMessages,
    this.context = BlockingContext.manualBlock,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    this.lastUpdated,
  })  : id = id ?? const Uuid().v4(),
        primaryColor = primaryColor ?? _getDefaultColor(category),
        gradientStartColor = gradientStartColor ?? _getDefaultGradientStart(category),
        gradientEndColor = gradientEndColor ?? _getDefaultGradientEnd(category),
        blockMessages = blockMessages ?? _getDefaultMessages(name, category),
        lastBlockedAttempt = lastBlockedAttempt ?? DateTime.now(),
        totalTimeSaved = totalTimeSaved ?? Duration.zero,
        estimatedTimeSavedPerBlock = estimatedTimeSavedPerBlock ?? Duration(minutes: 2),
        customMessages = customMessages ?? [],
        settings = settings ?? {},
        createdAt = createdAt ?? DateTime.now();

  // ============================================================================
  // COMPUTED PROPERTIES
  // ============================================================================

  /// Check if the app is currently being blocked
  bool get isCurrentlyBlocked {
    if (!isBlocked) return false;

    // Check if temporary block has expired
    if (blockedUntil != null && DateTime.now().isAfter(blockedUntil!)) {
      return false;
    }

    return true;
  }

  /// Get the display name (app name or package name if name is empty)
  String get displayName {
    return name.isNotEmpty ? name : packageName.split('.').last;
  }

  /// Get appropriate block message for current context
  String get currentBlockMessage {
    if (hasCustomMessages && customMessages.isNotEmpty) {
      final index = blockAttempts % customMessages.length;
      return customMessages[index];
    }

    if (blockMessages.isNotEmpty) {
      final index = blockAttempts % blockMessages.length;
      return blockMessages[index];
    }

    return _getDefaultMessage(name, messageTheme);
  }

  /// Get formatted time saved today
  String get formattedTimeSaved {
    final hours = totalTimeSaved.inHours;
    final minutes = totalTimeSaved.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // ============================================================================
  // FACTORY CONSTRUCTORS
  // ============================================================================

  /// Factory constructor from JSON
  factory BlockedApp.fromJson(Map<String, dynamic> json) {
    return BlockedApp(
      id: json['id'] ?? const Uuid().v4(),
      name: json['name'] ?? '',
      packageName: json['packageName'] ?? '',
      icon: json['icon'] ?? '📱',
      category: AppCategory.values[json['category'] ?? AppCategory.other.index],
      primaryColor: Color(json['primaryColor'] ?? Colors.blue.value),
      gradientStartColor: Color(json['gradientStartColor'] ?? Colors.blue.value),
      gradientEndColor: Color(json['gradientEndColor'] ?? Colors.purple.value),
      isBlocked: json['isBlocked'] ?? false,
      blockDuringFocus: json['blockDuringFocus'] ?? false,
      alwaysBlocked: json['alwaysBlocked'] ?? false,
      blockedUntil: json['blockedUntil'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['blockedUntil'])
          : null,
      blockMessages: List<String>.from(json['blockMessages'] ?? []),
      messageTheme: MessageTheme.values[json['messageTheme'] ?? MessageTheme.funny.index],
      blockAttempts: json['blockAttempts'] ?? 0,
      lastBlockedAttempt: json['lastBlockedAttempt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastBlockedAttempt'])
          : DateTime.now(),
      totalTimeSaved: Duration(seconds: json['totalTimeSaved'] ?? 0),
      estimatedTimeSavedPerBlock: Duration(seconds: json['estimatedTimeSavedPerBlock'] ?? 120),
      hasCustomMessages: json['hasCustomMessages'] ?? false,
      customMessages: List<String>.from(json['customMessages'] ?? []),
      context: BlockingContext.values[json['context'] ?? BlockingContext.manualBlock.index],
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'])
          : null,
    );
  }

  /// Factory constructor from device app data
  factory BlockedApp.fromDeviceApp(Map<String, dynamic> deviceAppData) {
    final packageName = deviceAppData['packageName'] ?? '';
    final appName = deviceAppData['name'] ?? packageName.split('.').last;
    final category = _getCategoryFromPackageName(packageName);

    return BlockedApp(
      name: appName,
      packageName: packageName,
      icon: deviceAppData['icon'] ?? _getDefaultIconForCategory(category),
      category: category,
      isBlocked: false,
      blockDuringFocus: true,
    );
  }

  // ============================================================================
  // SERIALIZATION
  // ============================================================================

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'packageName': packageName,
      'icon': icon,
      'category': category.index,
      'primaryColor': primaryColor.value,
      'gradientStartColor': gradientStartColor.value,
      'gradientEndColor': gradientEndColor.value,
      'isBlocked': isBlocked,
      'blockDuringFocus': blockDuringFocus,
      'alwaysBlocked': alwaysBlocked,
      'blockedUntil': blockedUntil?.millisecondsSinceEpoch,
      'blockMessages': blockMessages,
      'messageTheme': messageTheme.index,
      'blockAttempts': blockAttempts,
      'lastBlockedAttempt': lastBlockedAttempt.millisecondsSinceEpoch,
      'totalTimeSaved': totalTimeSaved.inSeconds,
      'estimatedTimeSavedPerBlock': estimatedTimeSavedPerBlock.inSeconds,
      'hasCustomMessages': hasCustomMessages,
      'customMessages': customMessages,
      'context': context.index,
      'settings': settings,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
    };
  }

  /// Convert to device-friendly map for native calls
  Map<String, dynamic> toDeviceMap() {
    return {
      'packageName': packageName,
      'name': name,
      'isBlocked': isCurrentlyBlocked,
      'icon': icon,
      'category': category.name,
    };
  }

  // ============================================================================
  // COPY WITH
  // ============================================================================

  /// Create a copy with updated values
  BlockedApp copyWith({
    String? id,
    String? name,
    String? packageName,
    String? icon,
    AppCategory? category,
    Color? primaryColor,
    Color? gradientStartColor,
    Color? gradientEndColor,
    bool? isBlocked,
    bool? blockDuringFocus,
    bool? alwaysBlocked,
    DateTime? blockedUntil,
    List<String>? blockMessages,
    MessageTheme? messageTheme,
    int? blockAttempts,
    DateTime? lastBlockedAttempt,
    Duration? totalTimeSaved,
    Duration? estimatedTimeSavedPerBlock,
    bool? hasCustomMessages,
    List<String>? customMessages,
    BlockingContext? context,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return BlockedApp(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      primaryColor: primaryColor ?? this.primaryColor,
      gradientStartColor: gradientStartColor ?? this.gradientStartColor,
      gradientEndColor: gradientEndColor ?? this.gradientEndColor,
      isBlocked: isBlocked ?? this.isBlocked,
      blockDuringFocus: blockDuringFocus ?? this.blockDuringFocus,
      alwaysBlocked: alwaysBlocked ?? this.alwaysBlocked,
      blockedUntil: blockedUntil ?? this.blockedUntil,
      blockMessages: blockMessages ?? this.blockMessages,
      messageTheme: messageTheme ?? this.messageTheme,
      blockAttempts: blockAttempts ?? this.blockAttempts,
      lastBlockedAttempt: lastBlockedAttempt ?? this.lastBlockedAttempt,
      totalTimeSaved: totalTimeSaved ?? this.totalTimeSaved,
      estimatedTimeSavedPerBlock: estimatedTimeSavedPerBlock ?? this.estimatedTimeSavedPerBlock,
      hasCustomMessages: hasCustomMessages ?? this.hasCustomMessages,
      customMessages: customMessages ?? this.customMessages,
      context: context ?? this.context,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Record a block attempt
  BlockedApp recordBlockAttempt() {
    return copyWith(
      blockAttempts: blockAttempts + 1,
      lastBlockedAttempt: DateTime.now(),
      totalTimeSaved: totalTimeSaved + estimatedTimeSavedPerBlock,
    );
  }

  /// Toggle block status
  BlockedApp toggleBlock() {
    return copyWith(
      isBlocked: !isBlocked,
      lastUpdated: DateTime.now(),
    );
  }

  /// Set temporary block until specific time
  BlockedApp blockUntil(DateTime until) {
    return copyWith(
      isBlocked: true,
      blockedUntil: until,
      lastUpdated: DateTime.now(),
    );
  }

  // ============================================================================
  // STATIC HELPER METHODS
  // ============================================================================

  /// Get default color for category
  static Color _getDefaultColor(AppCategory category) {
    switch (category) {
      case AppCategory.social:
        return const Color(0xFF4267B2); // Facebook blue
      case AppCategory.entertainment:
        return const Color(0xFFE50914); // Netflix red
      case AppCategory.games:
        return const Color(0xFF00C851); // Game green
      case AppCategory.messaging:
        return const Color(0xFF25D366); // WhatsApp green
      case AppCategory.productivity:
        return const Color(0xFF4285F4); // Google blue
      case AppCategory.shopping:
        return const Color(0xFFFF9500); // Amazon orange
      case AppCategory.news:
        return const Color(0xFF1DA1F2); // Twitter blue
      case AppCategory.communication:
        return const Color(0xFF7289DA); // Discord purple
      case AppCategory.education:
        return const Color(0xFF34A853); // Education green
      case AppCategory.health:
        return const Color(0xFFFF6B6B); // Health red
      case AppCategory.finance:
        return const Color(0xFF00D4AA); // Finance teal
      case AppCategory.other:
      default:
        return const Color(0xFF6C757D); // Gray
    }
  }

  /// Get default gradient start color
  static Color _getDefaultGradientStart(AppCategory category) {
    return _getDefaultColor(category);
  }

  /// Get default gradient end color
  static Color _getDefaultGradientEnd(AppCategory category) {
    final baseColor = _getDefaultColor(category);
    return Color.lerp(baseColor, Colors.purple, 0.3) ?? baseColor;
  }

  /// Get default messages for app and category
  static List<String> _getDefaultMessages(String appName, AppCategory category) {
    final appSpecific = _getAppSpecificMessages(appName);
    final categoryGeneric = _getCategoryMessages(category);

    return [...appSpecific, ...categoryGeneric];
  }

  /// Get app-specific funny messages
  static List<String> _getAppSpecificMessages(String appName) {
    final lowerName = appName.toLowerCase();

    if (lowerName.contains('instagram')) {
      return [
        "ain't no way bro tried to open Instagram 💀",
        "resist the gram, embrace the grind 💪",
        "your future self will thank you for not scrolling",
        "deadass thought you could break focus mode 🤡"
      ];
    } else if (lowerName.contains('tiktok')) {
      return [
        "TikTok? More like TikNOT during focus time 🚫",
        "the algorithm can wait, your goals can't ⏰",
        "resist the scroll, embrace the goal 🎯",
        "sir this is a focus session, not a dance party 💃❌"
      ];
    } else if (lowerName.contains('youtube')) {
      return [
        "YouTube can wait, your future can't 🚀",
        "one more video = one less step toward your goals",
        "the rabbit hole is deep, but your focus is deeper 🐰❌",
        "those cat videos will still be there after focus time 🐱"
      ];
    } else if (lowerName.contains('facebook')) {
      return [
        "Facebook? More like Focusboring during work time 😴",
        "your timeline isn't going anywhere, but your dreams are 🌟",
        "resist the book, embrace the focus 📚❌➡️🎯",
        "Mark Zuckerberg wants your time, but your goals need it more"
      ];
    } else if (lowerName.contains('twitter') || lowerName.contains('x')) {
      return [
        "tweeting can wait, achieving can't ⏰",
        "your hot takes will still be hot after focus time 🔥",
        "resist the bird, embrace the grind 🐦❌➡️💪",
        "the timeline will survive without you for an hour"
      ];
    }

    return [];
  }

  /// Get category-specific messages
  static List<String> _getCategoryMessages(AppCategory category) {
    switch (category) {
      case AppCategory.social:
        return [
          "social media is temporary, success is permanent 💎",
          "your followers will still be there after focus time",
          "likes don't pay the bills, but productivity does 💰",
        ];
      case AppCategory.entertainment:
        return [
          "entertainment is the enemy of achievement 🎯",
          "binge-watching won't build your future 📺❌",
          "choose productivity over procrastination",
        ];
      case AppCategory.games:
        return [
          "games are fun, but goals are forever 🏆",
          "level up in real life instead 📈",
          "your high score won't matter if you don't reach your goals",
        ];
      default:
        return [
          "stay focused, you got this! 💪",
          "resist the distraction, embrace the grind 🎯",
          "your future self will thank you 🙏",
        ];
    }
  }

  /// Get single default message for theme
  static String _getDefaultMessage(String appName, MessageTheme theme) {
    switch (theme) {
      case MessageTheme.motivational:
        return "Your future self will thank you for staying focused! 🌟";
      case MessageTheme.humorous:
        return "Nice try! But this app is taking a timeout ⏰";
      case MessageTheme.challenging:
        return "Champions resist distractions. Are you a champion? 🏆";
      case MessageTheme.supportive:
        return "You're doing great! Stay focused on your goals 💪";
      case MessageTheme.funny:
      default:
        return "Deadass thought you could break focus mode? 🤡";
    }
  }

  /// Determine category from package name
  static AppCategory _getCategoryFromPackageName(String packageName) {
    final lower = packageName.toLowerCase();

    // Social Media
    if (lower.contains('instagram') || lower.contains('facebook') ||
        lower.contains('twitter') || lower.contains('snapchat') ||
        lower.contains('tiktok') || lower.contains('linkedin')) {
      return AppCategory.social;
    }

    // Entertainment
    if (lower.contains('youtube') || lower.contains('netflix') ||
        lower.contains('spotify') || lower.contains('disney') ||
        lower.contains('prime') || lower.contains('twitch')) {
      return AppCategory.entertainment;
    }

    // Games
    if (lower.contains('game') || lower.contains('play') ||
        lower.contains('candy') || lower.contains('clash') ||
        lower.contains('pubg') || lower.contains('fortnite')) {
      return AppCategory.games;
    }

    // Messaging
    if (lower.contains('whatsapp') || lower.contains('telegram') ||
        lower.contains('discord') || lower.contains('messenger') ||
        lower.contains('signal')) {
      return AppCategory.messaging;
    }

    // Shopping
    if (lower.contains('amazon') || lower.contains('flipkart') ||
        lower.contains('shop') || lower.contains('buy') ||
        lower.contains('cart')) {
      return AppCategory.shopping;
    }

    // Productivity
    if (lower.contains('chrome') || lower.contains('office') ||
        lower.contains('docs') || lower.contains('sheet') ||
        lower.contains('gmail') || lower.contains('calendar')) {
      return AppCategory.productivity;
    }

    return AppCategory.other;
  }

  /// Get default icon for category
  static String _getDefaultIconForCategory(AppCategory category) {
    switch (category) {
      case AppCategory.social:
        return '🌐';
      case AppCategory.entertainment:
        return '🎬';
      case AppCategory.games:
        return '🎮';
      case AppCategory.messaging:
        return '💬';
      case AppCategory.productivity:
        return '⚡';
      case AppCategory.shopping:
        return '🛒';
      case AppCategory.news:
        return '📰';
      case AppCategory.communication:
        return '📞';
      case AppCategory.education:
        return '📚';
      case AppCategory.health:
        return '🏥';
      case AppCategory.finance:
        return '💳';
      case AppCategory.other:
      default:
        return '📱';
    }
  }

  // ============================================================================
  // EQUALITY AND HASH
  // ============================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlockedApp && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BlockedApp{id: $id, name: $name, packageName: $packageName, isBlocked: $isBlocked}';
  }
}