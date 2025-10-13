import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;

/// A utility class to handle platform-specific icon rendering
class IconRenderer {
  /// Returns the appropriate icon based on the current platform (iOS or Android)
  static Widget getPlatformIcon({
    required IconData androidIcon,
    IconData? iOSIcon,
    required BuildContext context,
    double size = 24.0,
    Color? color,
  }) {
    final iconColor = color ?? Theme.of(context).iconTheme.color;

    if (Platform.isIOS && iOSIcon != null) {
      return Icon(
        iOSIcon,
        size: size,
        color: iconColor,
      );
    }

    return Icon(
      androidIcon,
      size: size,
      color: iconColor,
    );
  }

  /// Get platform appropriate icon data based on icon type
  static IconData getPlatformIconData({
    required IconData androidIcon,
    IconData? iOSIcon,
  }) {
    if (Platform.isIOS && iOSIcon != null) {
      return iOSIcon;
    }
    return androidIcon;
  }

  /// Common app icons mapped to platform-specific implementations
  static IconData get homeIcon =>
      Platform.isIOS ? CupertinoIcons.home : Icons.home_outlined;

  static IconData get homeFilled =>
      Platform.isIOS ? CupertinoIcons.house_fill : Icons.home;

  static IconData get taskIcon =>
      Platform.isIOS ? CupertinoIcons.square_list : Icons.task_outlined;

  static IconData get taskFilled =>
      Platform.isIOS ? CupertinoIcons.square_list_fill : Icons.task;

  static IconData get timerIcon =>
      Platform.isIOS ? CupertinoIcons.timer : Icons.timer_outlined;

  static IconData get timerFilled =>
      Platform.isIOS ? CupertinoIcons.timer_fill : Icons.timer;

  static IconData get chatIcon =>
      Platform.isIOS ? CupertinoIcons.chat_bubble : Icons.chat_outlined;

  static IconData get chatFilled =>
      Platform.isIOS ? CupertinoIcons.chat_bubble_fill : Icons.chat;

  static IconData get settingsIcon =>
      Platform.isIOS ? CupertinoIcons.settings : Icons.settings;

  static IconData get personIcon =>
      Platform.isIOS ? CupertinoIcons.person : Icons.person;

  static IconData get addIcon =>
      Platform.isIOS ? CupertinoIcons.add : Icons.add;

  static IconData get searchIcon =>
      Platform.isIOS ? CupertinoIcons.search : Icons.search;

  static IconData get menuIcon =>
      Platform.isIOS ? CupertinoIcons.bars : Icons.menu;

  static IconData get calendarIcon =>
      Platform.isIOS ? CupertinoIcons.calendar : Icons.calendar_today;

  static IconData get infoIcon =>
      Platform.isIOS ? CupertinoIcons.info : Icons.info_outline;

  static IconData get sendIcon =>
      Platform.isIOS ? CupertinoIcons.paperplane : Icons.send;

  static IconData get checkIcon =>
      Platform.isIOS ? CupertinoIcons.checkmark_circle : Icons.check_circle_outline;

  static IconData get checkFilledIcon =>
      Platform.isIOS ? CupertinoIcons.checkmark_circle_fill : Icons.check_circle;

  static IconData get emailIcon =>
      Platform.isIOS ? CupertinoIcons.mail : Icons.email_outlined;

  static IconData get lockIcon =>
      Platform.isIOS ? CupertinoIcons.lock : Icons.lock_outline;

  static IconData get visibilityIcon =>
      Platform.isIOS ? CupertinoIcons.eye : Icons.visibility;

  static IconData get visibilityOffIcon =>
      Platform.isIOS ? CupertinoIcons.eye_slash : Icons.visibility_off;

  static IconData get closeIcon =>
      Platform.isIOS ? CupertinoIcons.clear : Icons.close;

  static IconData get historyIcon =>
      Platform.isIOS ? CupertinoIcons.clock : Icons.history;

  static IconData get priorityIcon =>
      Platform.isIOS ? CupertinoIcons.exclamationmark_triangle : Icons.priority_high;

  static IconData get feedbackIcon =>
      Platform.isIOS ? CupertinoIcons.chat_bubble_text : Icons.feedback_outlined;

  static IconData get helpIcon =>
      Platform.isIOS ? CupertinoIcons.question_circle : Icons.help_outline;

  static IconData get insightsIcon =>
      Platform.isIOS ? CupertinoIcons.graph_square : Icons.insights;

  static IconData get downloadIcon =>
      Platform.isIOS ? CupertinoIcons.arrow_down_circle : Icons.download;

  static IconData get deleteIcon =>
      Platform.isIOS ? CupertinoIcons.trash : Icons.delete_outline;

  static IconData get rateIcon =>
      Platform.isIOS ? CupertinoIcons.star : Icons.star_outline;

  static IconData get privacyIcon =>
      Platform.isIOS ? CupertinoIcons.shield : Icons.privacy_tip_outlined;

  static IconData get editIcon =>
      Platform.isIOS ? CupertinoIcons.pencil : Icons.edit;

  static IconData get filterIcon =>
      Platform.isIOS ? CupertinoIcons.slider_horizontal_3 : Icons.filter_list;

  static IconData get refreshIcon =>
      Platform.isIOS ? CupertinoIcons.refresh : Icons.refresh;

  static IconData get timerRunIcon =>
      Platform.isIOS ? CupertinoIcons.play : Icons.play_arrow;

  static IconData get timerPauseIcon =>
      Platform.isIOS ? CupertinoIcons.pause : Icons.pause;

  static IconData get quoteIcon =>
      Platform.isIOS ? CupertinoIcons.text_quote : Icons.format_quote;

  static IconData get focusModeIcon =>
      Platform.isIOS ? CupertinoIcons.timer : Icons.timer;

  static IconData get breakIcon =>
      Platform.isIOS ? CupertinoIcons.clock_fill : Icons.free_breakfast;

  static IconData get routineIcon =>
      Platform.isIOS ? CupertinoIcons.repeat : Icons.repeat;

  static IconData get taskCompletedIcon =>
      Platform.isIOS ? CupertinoIcons.checkmark_circle_fill : Icons.task_alt;

  static IconData get accessTimeIcon =>
      Platform.isIOS ? CupertinoIcons.time : Icons.access_time;

  static IconData get personOutlineIcon =>
      Platform.isIOS ? CupertinoIcons.person : Icons.person_outline;

  static IconData get chevronLeftIcon =>
      Platform.isIOS ? CupertinoIcons.chevron_left : Icons.chevron_left;

  static IconData get chevronRightIcon =>
      Platform.isIOS ? CupertinoIcons.chevron_right : Icons.chevron_right;

  static IconData get eventNoteIcon =>
      Platform.isIOS ? CupertinoIcons.doc_text : Icons.event_note;

  static IconData get autoAwesomeIcon =>
      Platform.isIOS ? CupertinoIcons.star_fill : Icons.auto_awesome;

  static IconData get volumeOffIcon =>
      Platform.isIOS ? CupertinoIcons.volume_off : Icons.volume_off_outlined;

  static IconData get doNotDisturbIcon =>
      Platform.isIOS ? CupertinoIcons.moon : Icons.do_not_disturb_on_outlined;

  static IconData get waterDropIcon =>
      Platform.isIOS ? CupertinoIcons.drop : Icons.water_drop_outlined;
}