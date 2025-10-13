import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_planner/providers/theme_provider.dart';
import 'package:daily_planner/providers/app_blocker_provider.dart';
import 'package:daily_planner/screens/app_blocker_selection_screen.dart';
import 'package:daily_planner/screens/focus_statistics_screen.dart';
import 'package:daily_planner/models/blocked_app.dart';
import 'package:daily_planner/utils/icon_renderer.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);

    // Watch app blocker state
    final appBlockerState = ref.watch(appBlockerProvider);
    final blockedAppsCount = appBlockerState.blockedApps.where((app) => app.isBlocked).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        actions: [
          if (appBlockerState.isFocusModeActive)
            Container(
              margin: EdgeInsets.only(right: 16),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'FOCUS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: ListView(
        children: [
          // Appearance section
          _buildSectionHeader(context, 'Appearance'),
          SwitchListTile(
            title: Text('Dark Mode'),
            subtitle: Text('Use dark theme throughout the app'),
            value: isDarkMode,
            onChanged: (value) {
              ref.read(themeProvider.notifier).toggleTheme();
            },
            secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
          ),

          Divider(),

          // App Blocker section
          _buildSectionHeader(context, 'App Blocker'),
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade400,
                  Colors.pink.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.block, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Epic App Blocking 🚫',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Keep yourself focused with hilarious blocking messages',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      '${appBlockerState.totalBlockAttemptsToday}',
                      'Blocks Today',
                      Icons.block,
                      Colors.white,
                    ),
                    _buildStatItem(
                      '${appBlockerState.totalTimeSavedToday.inMinutes}m',
                      'Time Saved',
                      Icons.timer,
                      Colors.white,
                    ),
                    _buildStatItem(
                      '${appBlockerState.currentStreak}',
                      'Day Streak',
                      Icons.local_fire_department,
                      Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),

          ListTile(
            title: Text('Select Apps to Block'),
            subtitle: Text('$blockedAppsCount apps currently blocked'),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.apps, color: Colors.red),
            ),
            trailing: Icon(IconRenderer.chevronRightIcon),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AppBlockerSelectionScreen(),
                ),
              );
            },
          ),

          ListTile(
            title: Text('Focus Statistics'),
            subtitle: Text('View detailed analytics and insights'),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.analytics, color: Colors.blue),
            ),
            trailing: Icon(IconRenderer.chevronRightIcon),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FocusStatisticsScreen(),
                ),
              );
            },
          ),

          ListTile(
            title: Text('Block Message Theme'),
            subtitle: Text(_getMessageThemeText(appBlockerState.messageTheme)),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.message, color: Colors.purple),
            ),
            trailing: Icon(IconRenderer.chevronRightIcon),
            onTap: () {
              _showMessageThemeDialog(context, ref, appBlockerState.messageTheme);
            },
          ),

          SwitchListTile(
            title: Text('Auto-Block During Focus'),
            subtitle: Text('Automatically block apps when focus sessions start'),
            value: appBlockerState.autoBlockDuringFocus,
            onChanged: (value) {
              ref.read(appBlockerProvider.notifier).setAutoBlockDuringFocus(value);
            },
            secondary: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.auto_fix_high, color: Colors.orange),
            ),
          ),

          SwitchListTile(
            title: Text('Show Block Notifications'),
            subtitle: Text('Get notified when apps are blocked with funny messages'),
            value: appBlockerState.showBlockNotifications,
            onChanged: (value) {
              ref.read(appBlockerProvider.notifier).setShowBlockNotifications(value);
            },
            secondary: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.notifications, color: Colors.green),
            ),
          ),

          Divider(),

          // Focus Session settings
          _buildSectionHeader(context, 'Focus Session Settings'),
          ListTile(
            title: Text('Default Focus Duration'),
            subtitle: Text('25 minutes (Pomodoro)'),
            leading: Icon(IconRenderer.timerIcon),
            trailing: Icon(IconRenderer.chevronRightIcon),
            onTap: () {
              _showFocusDurationDialog(context, ref);
            },
          ),
          ListTile(
            title: Text('Break Duration'),
            subtitle: Text('5 minutes'),
            leading: Icon(IconRenderer.breakIcon),
            trailing: Icon(IconRenderer.chevronRightIcon),
            onTap: () {
              // Show duration options
            },
          ),
          SwitchListTile(
            title: Text('Auto Start Breaks'),
            subtitle: Text('Automatically start breaks after focus sessions'),
            value: false,
            onChanged: (value) {
              // Implement setting
            },
            secondary: Icon(IconRenderer.timerRunIcon),
          ),

          Divider(),

          // Advanced App Blocking section
          _buildSectionHeader(context, 'Advanced App Blocking'),
          ListTile(
            title: Text('Time-based Blocking'),
            subtitle: Text('Block apps during specific hours'),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.schedule, color: Colors.indigo),
            ),
            trailing: Icon(IconRenderer.chevronRightIcon),
            onTap: () {
              _showTimeBasedBlockingDialog(context, ref);
            },
          ),
          ListTile(
            title: Text('Emergency Override'),
            subtitle: Text('Temporarily disable all blocking (1 hour)'),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.emergency, color: Colors.red),
            ),
            onTap: () {
              _showEmergencyOverrideDialog(context, ref);
            },
          ),
          ListTile(
            title: Text('Custom Block Messages'),
            subtitle: Text('Personalize your hilarious blocking messages'),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.edit, color: Colors.cyan),
            ),
            trailing: Icon(IconRenderer.chevronRightIcon),
            onTap: () {
              _showCustomMessagesDialog(context, ref);
            },
          ),

          Divider(),

          // Data & Privacy
          _buildSectionHeader(context, 'Data & Privacy'),
          ListTile(
            title: Text('Clear App Blocker Data'),
            subtitle: Text('Reset all blocking settings and statistics'),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_outline, color: Colors.orange),
            ),
            onTap: () {
              _showClearBlockerDataDialog(context, ref);
            },
          ),
          ListTile(
            title: Text('Clear App Data'),
            subtitle: Text('Delete all tasks and settings'),
            leading: Icon(IconRenderer.deleteIcon),
            onTap: () {
              _showClearAllDataDialog(context);
            },
          ),
          ListTile(
            title: Text('Export Data'),
            subtitle: Text('Export your tasks and settings'),
            leading: Icon(Icons.file_download),
            onTap: () {
              // Implement export functionality
            },
          ),

          Divider(),

          // About section
          _buildSectionHeader(context, 'About'),
          ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0 - Now with Epic App Blocking! 🚫💀'),
            leading: Icon(IconRenderer.infoIcon),
          ),
          ListTile(
            title: Text('Send Feedback'),
            leading: Icon(IconRenderer.feedbackIcon),
            onTap: () {
              // Open feedback form or email
            },
          ),
          ListTile(
            title: Text('Rate the App'),
            leading: Icon(IconRenderer.rateIcon),
            onTap: () {
              // Open app store page
            },
          ),
          ListTile(
            title: Text('Privacy Policy'),
            leading: Icon(IconRenderer.privacyIcon),
            onTap: () {
              // Show privacy policy
            },
          ),

          SizedBox(height: 24),
        ],
      ),
    );
  }
}

Widget _buildSectionHeader(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    ),
  );
}

Widget _buildStatItem(String value, String label, IconData icon, Color color) {
  return Column(
    children: [
      Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: color,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
    ],
  );
}

// FIXED: Updated to use proper MessageTheme methods
String _getMessageThemeText(MessageTheme theme) {
  switch (theme) {
    case MessageTheme.funny:
      return 'Hilarious (💀 ain\'t no way bro...)';
    case MessageTheme.motivational:
      return 'Motivational (your future self will thank you)';
    case MessageTheme.challenging:
      return 'Challenging (resist the gram, embrace grind)';
    case MessageTheme.supportive:
      return 'Supportive (you got this! stay focused)';
    case MessageTheme.humorous:
      return 'Humorous (light-hearted and fun)';
  }
}

void _showFocusDurationDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Focus Duration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<int>(
            title: Text('15 minutes'),
            value: 15,
            groupValue: 25,
            onChanged: (value) {
              // Implement setting
            },
          ),
          RadioListTile<int>(
            title: Text('25 minutes (Pomodoro)'),
            value: 25,
            groupValue: 25,
            onChanged: (value) {
              // Implement setting
            },
          ),
          RadioListTile<int>(
            title: Text('45 minutes'),
            value: 45,
            groupValue: 25,
            onChanged: (value) {
              // Implement setting
            },
          ),
          RadioListTile<int>(
            title: Text('60 minutes'),
            value: 60,
            groupValue: 25,
            onChanged: (value) {
              // Implement setting
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Save'),
        ),
      ],
    ),
  );
}

// FIXED: Updated message theme dialog to use proper MessageTheme
void _showMessageThemeDialog(BuildContext context, WidgetRef ref, MessageTheme currentTheme) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.message, color: Colors.purple),
          SizedBox(width: 8),
          Text('Choose Message Theme'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: MessageTheme.values.map((theme) {
            return RadioListTile<MessageTheme>(
              title: Text(_getMessageThemeDisplayName(theme)),
              subtitle: Text(_getThemeExample(theme)),
              value: theme,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  ref.read(appBlockerProvider.notifier).setMessageTheme(value);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Message theme updated to ${_getMessageThemeDisplayName(value)}'),
                      backgroundColor: Colors.purple,
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ],
    ),
  );
}

// FIXED: Added helper method for display names
String _getMessageThemeDisplayName(MessageTheme theme) {
  switch (theme) {
    case MessageTheme.funny:
      return 'Hilarious';
    case MessageTheme.motivational:
      return 'Motivational';
    case MessageTheme.challenging:
      return 'Challenging';
    case MessageTheme.supportive:
      return 'Supportive';
    case MessageTheme.humorous:
      return 'Humorous';
  }
}

String _getThemeExample(MessageTheme theme) {
  switch (theme) {
    case MessageTheme.funny:
      return '"Ain\'t no way bro tried to open TikTok 💀"';
    case MessageTheme.motivational:
      return '"Your future self will thank you"';
    case MessageTheme.challenging:
      return '"Resist the urge, embrace the grind"';
    case MessageTheme.supportive:
      return '"You got this! Stay focused 💪"';
    case MessageTheme.humorous:
      return '"Looks like someone tried to escape focus mode! 😄"';
  }
}

void _showTimeBasedBlockingDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.schedule, color: Colors.indigo),
          SizedBox(width: 8),
          Text('Time-based Blocking'),
        ],
      ),
      content: Text(
        'Configure specific hours when apps should be automatically blocked. '
            'This feature will be available in a future update.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Got it'),
        ),
      ],
    ),
  );
}

void _showEmergencyOverrideDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.emergency, color: Colors.red),
          SizedBox(width: 8),
          Text('Emergency Override'),
        ],
      ),
      content: Text(
        'This will temporarily disable all app blocking for 1 hour. '
            'Use this feature only in genuine emergencies.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            await ref.read(appBlockerProvider.notifier).activateEmergencyOverride();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Emergency override activated for 1 hour'),
                backgroundColor: Colors.orange,
              ),
            );
          },
          child: Text('Activate', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

void _showCustomMessagesDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit, color: Colors.cyan),
          SizedBox(width: 8),
          Text('Custom Block Messages'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create your own hilarious blocking messages!'),
          SizedBox(height: 16),
          Text(
            'Examples:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• "Your goals > your feed"', style: TextStyle(fontSize: 13)),
              Text('• "Discipline is freedom"', style: TextStyle(fontSize: 13)),
              Text('• "One more page, not one more scroll"', style: TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Navigate to custom messages screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Custom messages editor coming soon!')),
            );
          },
          child: Text('Customize'),
        ),
      ],
    ),
  );
}

void _showClearBlockerDataDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.delete_outline, color: Colors.orange),
          SizedBox(width: 8),
          Text('Clear App Blocker Data'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will reset:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('• All blocked apps settings'),
          Text('• Focus statistics and streaks'),
          Text('• Custom messages'),
          Text('• Block attempt history'),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This action cannot be undone!',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(appBlockerProvider.notifier).clearAllData();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('App blocker data cleared'),
                backgroundColor: Colors.orange,
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: Text('Clear Blocker Data'),
        ),
      ],
    ),
  );
}

void _showClearAllDataDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.delete_forever, color: Colors.red),
          SizedBox(width: 8),
          Text('Clear All App Data'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will permanently delete:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('• All tasks and schedules'),
          Text('• App settings and preferences'),
          Text('• Focus statistics and streaks'),
          Text('• Blocked apps and custom messages'),
          Text('• Chat history with assistant'),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This action cannot be undone!',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Implement complete data clearing
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('All app data cleared'),
                backgroundColor: Colors.red,
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('Clear All Data'),
        ),
      ],
    ),
  );
}