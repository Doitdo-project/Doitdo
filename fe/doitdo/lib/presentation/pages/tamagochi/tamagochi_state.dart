import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Offset;

@immutable
class CharacterTapGain {
  const CharacterTapGain({
    required this.amount,
    required this.origin,
    required this.tick,
  });

  final int amount;
  final Offset origin;
  final int tick;
}

@immutable
class TamagochiState {
  const TamagochiState({
    this.speechBubble,
    this.speechBubblePinned = false,
    this.actionAssetPath,
    this.actionUrl,
    this.actionTick = 0,
    this.lastGain,
  });

  final String? speechBubble;
  final bool speechBubblePinned;
  final String? actionAssetPath;
  final String? actionUrl;
  final int actionTick;
  final CharacterTapGain? lastGain;

  bool get hasActiveActionVisual =>
      (actionAssetPath != null && actionAssetPath!.isNotEmpty) ||
      (actionUrl != null && actionUrl!.isNotEmpty);

  TamagochiState copyWith({
    String? speechBubble,
    bool? speechBubblePinned,
    String? actionAssetPath,
    String? actionUrl,
    int? actionTick,
    bool clearActionVisual = false,
    CharacterTapGain? lastGain,
  }) {
    return TamagochiState(
      speechBubble: speechBubble ?? this.speechBubble,
      speechBubblePinned: speechBubblePinned ?? this.speechBubblePinned,
      actionAssetPath: clearActionVisual
          ? null
          : (actionAssetPath ?? this.actionAssetPath),
      actionUrl: clearActionVisual ? null : (actionUrl ?? this.actionUrl),
      actionTick: actionTick ?? this.actionTick,
      lastGain: lastGain ?? this.lastGain,
    );
  }

  static const TamagochiState initial = TamagochiState();

  static ({List<bool> slots, List<DateTime> dates}) buildStreakWindow({
    required int streakDays,
    required DateTime? streakStartDate,
    required DateTime today,
  }) {
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (streakDays <= 0 || streakStartDate == null) {
      return (
        slots: List<bool>.filled(7, false),
        dates: List<DateTime>.generate(
          7,
          (i) => todayOnly.add(Duration(days: i)),
        ),
      );
    }

    final blockIndex = (streakDays - 1) ~/ 7;
    final filledInBlock = streakDays - blockIndex * 7;
    final startOnly = DateTime(
      streakStartDate.year,
      streakStartDate.month,
      streakStartDate.day,
    );
    final blockStart = startOnly.add(Duration(days: blockIndex * 7));
    final dates = List<DateTime>.generate(
      7,
      (i) => blockStart.add(Duration(days: i)),
    );
    final slots = List<bool>.generate(7, (i) => i < filledInBlock);
    return (slots: slots, dates: dates);
  }
}
