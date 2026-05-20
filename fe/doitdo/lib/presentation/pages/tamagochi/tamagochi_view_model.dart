import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doitdo/core/utils/app_logger.dart';
import 'package:doitdo/domain/entities/character.dart';
import 'package:doitdo/domain/repositories/character_repository.dart';
import 'package:doitdo/presentation/pages/tamagochi/tamagochi_animation_resolver.dart';
import 'package:doitdo/presentation/pages/tamagochi/tamagochi_state.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 다마고치 메인 화면의 ViewModel.
///
/// 캐릭터(이름/성장률) 는 `characterViewModelProvider`, 할 일 목록은
/// `todoViewModelProvider` 에서 직접 watch 한다. 이 ViewModel 에는 BE 엔드포인트가
/// 아직 없는 말풍선 / 화면 전용 인터랙션 상태만 남아있다.
class TamagochiViewModel extends StateNotifier<TamagochiState> {
  TamagochiViewModel(this._characterRepository, this._prefs)
    : super(
        // 진입 직후엔 캐릭터 탭이 가능한지를 사용자가 모르기 때문에 가벼운
        // 가이드 문구를 깔아두고, 실제 탭이 오면 랜덤 풀로 교체한다.
        const TamagochiState(speechBubble: '나를 한 번 눌러봐!'),
      );

  final CharacterRepository _characterRepository;
  final SharedPreferences _prefs;

  /// 캐릭터 탭 인터랙션 in-flight 여부. 빠른 연타 시 같은 action 으로 중복 핑이
  /// 나가지 않게 막는 용도(말풍선 자체는 매 탭마다 즉시 업데이트되므로 UX 손해 없음).
  bool _tapping = false;

  /// action gif 를 [_actionDuration] 동안만 보여주고 정적 png 로 되돌릴 때 쓰는 타이머.
  /// 재탭/새 응답이 오면 cancel 후 다시 스케줄해서 항상 "마지막 응답 기준 N초" 가 되게 한다.
  Timer? _revertTimer;
  Timer? _passiveSleepTimer;
  static const Duration _actionDuration = Duration(seconds: 2);
  static const String _passiveSleepActionType = 'SLEEP';
  static const String _returnSadActionType = 'SAD';
  static const String _returnHappyActionType = 'HAPPY';
  static const String _lastTamagochiVisitAtKey = 'tamagochi.lastVisitAt';
  static const String _lastSadShownDateKey = 'tamagochi.lastSadShownDate';
  static const Duration _sadReturnThreshold = Duration(hours: 24);
  static const bool _forceReturnSadForDebug = bool.fromEnvironment(
    'DOITDO_FORCE_TAMAGOCHI_SAD',
  );

  static final Random _rng = Random();
  bool _passiveSleepEnabled = false;
  bool _passiveActionRunning = false;
  bool _sleeping = false;
  bool _sad = false;
  bool _returnSadChecked = false;

  @override
  void dispose() {
    _revertTimer?.cancel();
    _passiveSleepTimer?.cancel();
    super.dispose();
  }

  void setPassiveSleepEnabled(bool enabled) {
    if (_passiveSleepEnabled == enabled) return;
    _passiveSleepEnabled = enabled;
    _passiveSleepTimer?.cancel();
    _passiveSleepTimer = null;
    if (!enabled && _isHoldingAction) {
      _clearHoldingAction();
    }
    if (enabled) {
      _schedulePassiveSleep(initial: true);
    }
  }

  Future<void> checkReturnSad({required bool hasCharacter}) async {
    if (_returnSadChecked || !hasCharacter) return;
    _returnSadChecked = true;

    final now = DateTime.now();
    final lastVisit = _forceReturnSadForDebug
        ? now.subtract(_sadReturnThreshold + const Duration(hours: 1))
        : DateTime.tryParse(_prefs.getString(_lastTamagochiVisitAtKey) ?? '');
    await _prefs.setString(_lastTamagochiVisitAtKey, now.toIso8601String());

    if (lastVisit == null) return;
    if (now.difference(lastVisit) < _sadReturnThreshold) return;

    final todayKey = _dateKey(now);
    if (!_forceReturnSadForDebug &&
        _prefs.getString(_lastSadShownDateKey) == todayKey) {
      return;
    }
    await _prefs.setString(_lastSadShownDateKey, todayKey);

    if (!mounted || _isHoldingAction) return;
    state = state.copyWith(
      speechBubble: _pickReturnSadMessage(),
      speechBubblePinned: true,
    );
    await _triggerActionTypeAsync(_returnSadActionType);
  }

  /// 홈 캐릭터 슬롯이 탭됐을 때 호출.
  ///
  /// 동작:
  ///   1. 즉시 state 의 [TamagochiState.speechBubble] 을 랜덤 메시지로 갱신
  ///      (네트워크보다 먼저 사용자에게 반응을 보여준다).
  ///   2. 백그라운드에서 `POST /api/characters/me/actions/IDLE` 호출.
  ///      응답으로 받은 gif URL 을 [actionUrl] 에 잠깐 세팅 → 평상시 EYE gif 위에
  ///      덮어 그려 인터랙션 피드백. 실패해도 말풍선은 그대로 유지. earnedAmount
  ///      > 0 이면 [CharacterTapGain] 시그널로 floating "+N" 도 함께 발화.
  ///
  /// 평상시(EYE) 는 로컬 에셋(`assets/gif/eye/{characterId}.gif`) 으로 처리하므로
  /// 이 함수에서 EYE 를 호출하지 않는다 — 매 탭마다 서버에 핑 보내는 비용 회피 +
  /// 이후 다른 인터랙션(EAT/HAPPY 등) 추가 시에도 IDLE 자리에 새 액션을 끼워
  /// 넣기 좋다.
  ///
  /// [remainingTodayTodos] 는 "오늘의 할 일" 미완료 개수. 0 이면 칭찬 풀,
  /// 1 이상이면 잔여 todo 풀이 메시지 후보에 추가된다.
  ///
  /// [tapOrigin] 은 사용자가 탭한 글로벌 좌표. 응답에서 earnedAmount > 0 이면
  /// 이 좌표를 가진 [CharacterTapGain] 시그널을 발화 — 페이지가 받아 floating
  /// "+N" 위젯을 띄운다.
  void onCharacterTap({
    required int remainingTodayTodos,
    required int? characterId,
    required Offset tapOrigin,
  }) {
    if (_sad) {
      _resolveSadToHappy(message: _pickReturnHappyMessage());
      _schedulePassiveSleep();
      return;
    }

    if (_sleeping) {
      _clearHoldingAction(speechBubble: _pickSpeechBubble(remainingTodayTodos));
      _schedulePassiveSleep();
      return;
    }

    final message = _pickSpeechBubble(remainingTodayTodos);
    state = state.copyWith(speechBubble: message, speechBubblePinned: false);

    if (_tapping) return;
    _tapping = true;
    _triggerActionAsync(
      _pickTapAction(),
      characterId: characterId,
      tapOrigin: tapOrigin,
    ).whenComplete(() => _tapping = false);
  }

  CharacterAction _pickTapAction() =>
      _rng.nextBool() ? CharacterAction.happy : CharacterAction.idle;

  void onTodoPositiveInteraction() {
    if (!_sad) return;
    _resolveSadToHappy(message: _pickReturnHappyMessage());
  }

  /// 다음 [CharacterTapGain.tick] 값. action 응답마다 단조증가시켜 같은 amount
  /// 라도 위젯 key 가 바뀌어 floating 인스턴스가 재생성되게 한다.
  int _gainTick = 0;

  /// 똥 청소 in-flight 여부. 빠른 연타로 같은 POOP 핑이 중복 발사되는 걸 막는다.
  bool _cleaningPoop = false;

  /// 방 안 똥을 탭했을 때 호출. `POST /api/characters/me/actions/POOP` 를 날려
  /// BE 가 위생 상태를 false 로 토글하게 하고, 응답의 [earnedAmount] 가 > 0 이면
  /// 다른 액션과 동일하게 [tapOrigin] (손가락 글로벌 좌표) 에서 floating "+N" 발화.
  /// 페이지는 별도 brush.gif 오버레이를 2초 띄우는 UX 만 따로 관리한다.
  Future<void> cleanupPoop({required Offset tapOrigin}) async {
    if (_cleaningPoop) return;
    _cleaningPoop = true;
    try {
      await _triggerActionAsync(CharacterAction.poop, tapOrigin: tapOrigin);
    } finally {
      _cleaningPoop = false;
    }
  }

  Future<void> _triggerActionAsync(
    CharacterAction action, {
    int? characterId,
    required Offset tapOrigin,
  }) => _triggerActionTypeAsync(
    action.serverValue,
    characterId: characterId,
    tapOrigin: tapOrigin,
  );

  Future<void> _triggerActionTypeAsync(
    String actionType, {
    int? characterId,
    Offset? tapOrigin,
  }) async {
    try {
      final isSleepAction = _isSleepActionType(actionType);
      final isSadAction = _isSadActionType(actionType);
      final localAssetPath = resolveLocalCharacterActionAsset(
        characterId: characterId,
        actionType: actionType,
      );
      var earnedAmount = 0;
      String? url;
      if (localAssetPath == null) {
        final result = await _characterRepository.triggerActionType(actionType);
        if (!mounted) return;
        url = result.url;
        earnedAmount = result.earnedAmount;
      }
      // 코인 보상은 gif 응답 유무와 독립적으로 처리 — 빈 url 이라도 earnedAmount
      // 가 있으면 floating 시그널은 띄운다.
      if (localAssetPath != null || (url?.isNotEmpty ?? false)) {
        // gif 를 ImageCache 에 먼저 적재 → state 를 바꿔 위젯이 mount 될 때
        // Image.network 가 즉시 첫 프레임을 그려 빈 영역(깜빡임) 이 안 생긴다.
        if (url != null && url.isNotEmpty) {
          await _precacheNetworkImage(url);
          if (!mounted) return;
        }
        // 같은 url 이 다시 와도 위젯 key 가 바뀌면 gif 가 처음부터 재생된다.
        state = state.copyWith(
          actionAssetPath: localAssetPath,
          actionUrl: url,
          actionTick: state.actionTick + 1,
        );
        // 응답 도착 시점부터 2초 카운트 — 재탭/새 응답이 오면 새 타이머로 교체된다.
        _revertTimer?.cancel();
        _sleeping = isSleepAction;
        _sad = isSadAction;
        if (isSleepAction) {
          state = state.copyWith(
            speechBubble: _pickSleepMessage(),
            speechBubblePinned: true,
          );
        } else if (isSadAction) {
          state = state.copyWith(
            speechBubble: _pickReturnSadMessage(),
            speechBubblePinned: true,
          );
        } else {
          _revertTimer = Timer(_actionDuration, () {
            if (!mounted) return;
            if (!state.hasActiveActionVisual) return;
            state = state.copyWith(clearActionVisual: true);
          });
        }
      }
      if (earnedAmount > 0 && tapOrigin != null) {
        _gainTick += 1;
        state = state.copyWith(
          lastGain: CharacterTapGain(
            amount: earnedAmount,
            origin: tapOrigin,
            tick: _gainTick,
          ),
        );
      }
    } catch (e, st) {
      // 인터랙션 핑이라 실패해도 사용자 알림은 안 띄운다 — 무한 스팸 방지 +
      // 화면이 멀쩡히 동작하는데 에러만 뜨는 어색함을 피하려는 의도.
      appLogger.d(
        'character action ping failed: $actionType',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// [precacheImage] 를 BuildContext 없이 호출하기 위한 헬퍼.
  /// 첫 프레임 디코드까지 끝나면 resolve, 실패해도 그냥 통과시켜 후속 swap 을
  /// 막지 않는다(그 경우 CachedNetworkImage 가 직접 로드하므로 결과적으로 동일).
  ///
  /// 실제 표시에 [CachedNetworkImage] 를 쓰므로, 사전 디코드도 같은 provider
  /// ([CachedNetworkImageProvider]) 로 해야 동일 캐시 키에 적재된다. `NetworkImage`
  /// 를 쓰면 키가 달라 precache 가 무효가 된다.
  bool get _isHoldingAction => _sleeping || _sad;

  void _resolveSadToHappy({required String message}) {
    _clearHoldingAction(speechBubble: message);
    unawaited(_triggerActionTypeAsync(_returnHappyActionType));
  }

  void _clearHoldingAction({String? speechBubble}) {
    _sleeping = false;
    _sad = false;
    _revertTimer?.cancel();
    state = state.copyWith(
      speechBubble: speechBubble,
      speechBubblePinned: false,
      clearActionVisual: true,
    );
  }

  void _schedulePassiveSleep({bool initial = false}) {
    _passiveSleepTimer?.cancel();
    if (!_passiveSleepEnabled) return;
    _passiveSleepTimer = Timer(
      _pickPassiveSleepDelay(DateTime.now(), initial: initial),
      () => _maybeTriggerPassiveSleep(initial: initial),
    );
  }

  Duration _pickPassiveSleepDelay(DateTime now, {required bool initial}) {
    final night = _isNight(now);
    final minSeconds = initial ? (night ? 20 : 60) : (night ? 35 : 120);
    final maxSeconds = initial ? (night ? 50 : 120) : (night ? 90 : 300);
    return Duration(
      seconds: minSeconds + _rng.nextInt(maxSeconds - minSeconds + 1),
    );
  }

  Future<void> _maybeTriggerPassiveSleep({bool initial = false}) async {
    try {
      if (!mounted || !_passiveSleepEnabled) return;
      if (_tapping || _cleaningPoop || _passiveActionRunning) return;
      if (state.hasActiveActionVisual) return;

      final now = DateTime.now();
      final chance = _isNight(now) ? 0.70 : 0.12;
      if (_rng.nextDouble() >= chance) return;

      _passiveActionRunning = true;
      await _triggerActionTypeAsync(_passiveSleepActionType);
    } finally {
      _passiveActionRunning = false;
      if (mounted && _passiveSleepEnabled) {
        _schedulePassiveSleep();
      }
    }
  }

  bool _isNight(DateTime now) => now.hour >= 22 || now.hour < 7;

  bool _isSleepActionType(String actionType) =>
      actionType.trim().toUpperCase() == _passiveSleepActionType;

  bool _isSadActionType(String actionType) =>
      actionType.trim().toUpperCase() == _returnSadActionType;

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _precacheNetworkImage(String url) async {
    final completer = Completer<void>();
    final stream = CachedNetworkImageProvider(
      url,
    ).resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
      onError: (_, _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  String _pickSpeechBubble(int remainingTodayTodos) {
    final pool = <String>[
      ..._guideMessages,
      ..._moodMessages,
      if (remainingTodayTodos <= 0)
        ..._allDoneMessages
      else ...[
        ..._remainingMessages,
        '오늘 할 일이 $remainingTodayTodos개 남았어!',
        '$remainingTodayTodos개만 더 끝내면 돼!',
      ],
    ];
    return pool[_rng.nextInt(pool.length)];
  }

  String _pickReturnSadMessage() =>
      _returnSadMessages[_rng.nextInt(_returnSadMessages.length)];

  String _pickReturnHappyMessage() =>
      _returnHappyMessages[_rng.nextInt(_returnHappyMessages.length)];

  String _pickSleepMessage() =>
      _sleepMessages[_rng.nextInt(_sleepMessages.length)];

  // ─── 말풍선 풀 ──────────────────────────────────────────────────
  // 문구는 가볍게/짧게 유지(말풍선 폭이 좁음). 16~20자 이내.

  static const List<String> _guideMessages = [
    '나 자주 눌러줘!',
    '쓰담쓰담 좋아~',
    '여기 눌러봐, 반응할게!',
    '심심하면 또 눌러줘',
    'ʕ •ɷ•ʔฅ',
    '(╭☞•́⍛•̀)╭☞',
    'ฅ ʕ•ᴥ•ʔ',
  ];

  static const List<String> _moodMessages = [
    '오늘 기분 어때?',
    '같이 있어서 좋아!',
    '졸린 듯... 말 듯...',
    '뭔가 신난다!',
    '(๑￫ܫ￩๑)',
    '(♡´౪♡)',
    '(❁´▽❁)',
  ];

  static const List<String> _remainingMessages = [
    '아직 할 일이 남았어!',
    '할 일 끝내고 같이 놀자!',
    '오늘도 화이팅이야!',
    '조금만 더 힘내봐~',
    '( •̀ω•́ )✧',
    'ᕙ(•̀‸•́‶)ᕗ',
    'ᕦ(ò_óˇ)ᕤ',
    '(๑•̀ㅂ•́)و✧',
    '=͟͟͞͞( •̀д•́)))',
    '⋌༼ •̀ ⌂ •́ ༽⋋',
  ];

  static const List<String> _allDoneMessages = [
    '오늘 할 일 다 끝냈네!',
    '수고했어, 푹 쉬자~',
    '같이 빈둥거려볼까?',
    'ლ(╹◡╹ლ)',
    'ლ(◞‿◟ლ)',
    '♡(๑•̀ڡ•́๑)',
    '(๑・ω-)～♥”',
    '(੭ ˃̶̀ロ˂̶́)੭⁾',
  ];

  static const List<String> _returnSadMessages = [
    'ㅜ.ㅜ',
    'ㅜㅁㅜ',
    'ㅜoㅜ',
    'ㅜ^ㅜ',
    '(｡•́︿•̀｡)',
    '(｡T ω T｡)',
    '˃̣̣̣̣̣︿˂̣̣̣̣̣',
    'ŏ̥̥̥̥םŏ̥̥̥̥',
    '•᷄⌓•᷅',
  ];

  static const List<String> _returnHappyMessages = [
    '다시 왔네!',
    '기다렸어!',
    '이제 같이 놀자!',
    '와줘서 고마워!',
    '₍ᐢ..ᐢ₎♡',
    'ฅ՞•ﻌ•՞ฅ',
    'ʕ •ɷ•ʔฅ',
    'ꈍㅅꈍ✿',
    '(ღ˘⌣˘ღ)',
    '(๑°꒵°๑)·♡',
    '(ღゝ◡╹)ノ♡',
    '(♥ω♥ ) ~♪',
  ];

  static const List<String> _sleepMessages = [
    'zzz...',
    '( ˘Θ˘)',
    '(๑ᵕ⌓ᵕ̤)',
    '(ᴗ˳ᴗ)',
    '(˘ㅂ˘ )',
    '(　-ⓞ-)',
    '( ˘﹃˘ )',
  ];
}

final tamagochiViewModelProvider =
    StateNotifierProvider.autoDispose<TamagochiViewModel, TamagochiState>(
      (ref) => TamagochiViewModel(
        ref.watch(characterRepositoryProvider),
        ref.watch(sharedPreferencesProvider),
      ),
    );
