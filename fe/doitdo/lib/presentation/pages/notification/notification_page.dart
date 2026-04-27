import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/pages/notification/notification_view_model.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_dialog.dart';

/// 알림 목록 전체 화면.
///
/// - bottom nav 없는 전체 화면 (parentNavigatorKey: rootNavigatorKey 로 push).
/// - 필터 칩(전체/안 읽음/저녁/아침/할 일) + 알림 리스트 + 빈/로딩/에러 상태.
/// - GET /api/notifications 페이지네이션 연동.
class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();

  // ── 스와이프 코치마크 ─────────────────────────
  // 첫 진입 시 1번째 알림 아이템을 살짝 좌측으로 자동 슬라이드해
  // "밀어서 삭제" 인터랙션을 시각적으로 가르친다.
  // SharedPreferences 키 하나로 본 적 있는 사용자는 다시 안 보이게.
  static const _swipeHintSeenKey = 'noti_swipe_hint_seen';
  static const _hintSwipeDistance = 72.0; // 좌측으로 미는 거리(px)

  late final AnimationController _hintController;
  late final Animation<double> _hintOffset;
  bool _hintRunning = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // TweenSequence: 0 → -dist (in) → -dist hold → 0 (out)
    _hintOffset = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -_hintSwipeDistance)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(-_hintSwipeDistance),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -_hintSwipeDistance, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 35,
      ),
    ]).animate(_hintController);

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowHint());
  }

  Future<void> _maybeShowHint() async {
    if (!mounted) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final seen = prefs.getBool(_swipeHintSeenKey) ?? false;
    if (seen) return;

    // 첫 데이터가 그려진 뒤(약간 지연) 자연스럽게 시작.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final state = ref.read(notificationViewModelProvider);
    if (state.filtered.isEmpty) return; // 보여줄 아이템이 없으면 스킵

    setState(() => _hintRunning = true);
    await _hintController.forward(from: 0);
    if (!mounted) return;
    setState(() => _hintRunning = false);
    await prefs.setBool(_swipeHintSeenKey, true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  /// 리스트 끝 80px 전에 도달하면 다음 페이지 로드
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 80) {
      ref.read(notificationViewModelProvider.notifier).loadMore();
    }
  }

  /// 전체 삭제 확인 다이얼로그 → 사용자가 동의하면 ViewModel.deleteAll 호출.
  /// 실패 시 스낵바로 알림.
  Future<void> _confirmDeleteAll(NotificationViewModel vm) async {
    final ok = await showDoitdoDialog(
      context: context,
      title: '모든 알림을 삭제할까요?',
      message: '삭제된 알림은 복구할 수 없어요.',
      confirmLabel: '삭제',
      cancelLabel: '취소',
    );
    if (ok != true) return;
    if (!mounted) return;

    try {
      await vm.deleteAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림을 모두 삭제했어요.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(notificationViewModelProvider);
    final vm     = ref.read(notificationViewModelProvider.notifier);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 상단 바 ─────────────────────────────
            // 메뉴는 항상 노출 — 모두 읽음 / 전체 삭제 두 액션 모두 상시 가능.
            // 안 읽은 게 없으면 API 가 no-op 으로 처리되므로 호출해도 무해.
            _NotiTopBar(
              unreadCount: state.unreadCount,
              onMarkAll: vm.markAllAsRead,
              onDeleteAll:
                  state.items.isEmpty ? null : () => _confirmDeleteAll(vm),
              onBack: () => context.pop(),
            ),

            // ── 필터 칩 ─────────────────────────────
            _FilterChipRow(
              selected: state.filter,
              onSelected: vm.setFilter,
            ),

            // ── 구분선 ───────────────────────────────
            Divider(height: 1, thickness: 1, color: colors.divider),

            // ── 본문 ────────────────────────────────
            Expanded(child: _buildBody(context, state, vm, colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationState state,
    NotificationViewModel vm,
    DoitdoColors colors,
  ) {
    // 에러 (목록이 비었을 때만)
    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48.sp, color: colors.textHint),
            SizedBox(height: 12.h),
            Text('알림을 불러오지 못했어요',
                style: AppTextStyles.bodyLarge.copyWith(color: colors.textSecondary)),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: vm.refresh,
              child: Text('다시 시도',
                  style: AppTextStyles.bodyMedium.copyWith(color: colors.primary)),
            ),
          ],
        ),
      );
    }

    // 첫 로딩 스피너
    if (state.isLoading && state.items.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: colors.primary),
      );
    }

    // 빈 상태
    if (state.filtered.isEmpty) {
      return _EmptyState(filter: state.filter);
    }

    // 목록
    return RefreshIndicator(
      onRefresh: vm.refresh,
      color: colors.primary,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: state.filtered.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) =>
            Divider(height: 1, thickness: 1, color: colors.divider),
        itemBuilder: (context, i) {
          if (i == state.filtered.length) {
            // 페이지네이션 로딩 인디케이터
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Center(
                child: SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                ),
              ),
            );
          }
          final item = state.filtered[i];
          final dismissible = Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20.w),
              color: Colors.red.shade400,
              child: Icon(Icons.delete_outline_rounded,
                  color: Colors.white, size: 22.sp),
            ),
            onDismissed: (_) => vm.deleteNotification(item.id),
            child: _NotiItem(
              item: item,
              onTap: () {
                if (!item.isRead) vm.markAsRead(item.id);
              },
            ),
          );

          // 첫 진입 코치마크: 1번째 아이템에만 자동 슬라이드 애니메이션 덧입힘.
          // Stack 으로 빨간 배경을 뒤에 깔고 위에 Transform.translate 로 미끄러뜨린다.
          if (i == 0 && _hintRunning) {
            return AnimatedBuilder(
              animation: _hintController,
              builder: (context, _) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20.w),
                        color: Colors.red.shade400,
                        child: Icon(Icons.delete_outline_rounded,
                            color: Colors.white, size: 22.sp),
                      ),
                    ),
                    IgnorePointer(
                      ignoring: true,
                      child: Transform.translate(
                        offset: Offset(_hintOffset.value, 0),
                        child: dismissible,
                      ),
                    ),
                  ],
                );
              },
            );
          }
          return dismissible;
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 상단 바
// ──────────────────────────────────────────────

/// TopBar 의 점 3개 메뉴 액션.
enum _TopAction { markAll, deleteAll }

class _NotiTopBar extends StatelessWidget {
  const _NotiTopBar({
    required this.unreadCount,
    required this.onBack,
    this.onMarkAll,
    this.onDeleteAll,
  });

  final int unreadCount;
  final VoidCallback onBack;
  final VoidCallback? onMarkAll;
  final VoidCallback? onDeleteAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasMenu = onMarkAll != null || onDeleteAll != null;

    return Container(
      color: colors.topBarBg,
      padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 4.h),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 20.sp, color: colors.textPrimary),
            splashRadius: 20.r,
          ),
          SizedBox(width: 4.w),

          Text('알림',
              style: AppTextStyles.titleMedium.copyWith(color: colors.textPrimary)),

          if (unreadCount > 0) ...[
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE2782B),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '$unreadCount',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],

          const Spacer(),

          // 점 3개 메뉴 — 모두 읽음 / 전체 삭제 액션을 통합.
          // 둘 다 사용 불가(목록 비어 있음 + unread 0) 면 메뉴 자체를 숨김.
          if (hasMenu)
            PopupMenuButton<_TopAction>(
              icon: Icon(Icons.more_vert_rounded,
                  size: 22.sp, color: colors.textPrimary),
              tooltip: '메뉴',
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              itemBuilder: (context) => [
                if (onMarkAll != null)
                  PopupMenuItem<_TopAction>(
                    value: _TopAction.markAll,
                    height: 44,
                    child: Row(
                      children: [
                        Icon(Icons.done_all_rounded,
                            size: 18.sp, color: colors.textSecondary),
                        SizedBox(width: 10.w),
                        Text(
                          '모두 읽음',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: colors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                if (onDeleteAll != null)
                  PopupMenuItem<_TopAction>(
                    value: _TopAction.deleteAll,
                    height: 44,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18.sp, color: Colors.red.shade400),
                        SizedBox(width: 10.w),
                        Text(
                          '전체 삭제',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: Colors.red.shade400),
                        ),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                switch (value) {
                  case _TopAction.markAll:
                    onMarkAll?.call();
                    break;
                  case _TopAction.deleteAll:
                    onDeleteAll?.call();
                    break;
                }
              },
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 필터 칩 가로 스크롤 줄
// ──────────────────────────────────────────────
class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.selected,
    required this.onSelected,
  });

  final NotiFilter selected;
  final ValueChanged<NotiFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.background,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: NotiFilter.values.map((f) {
            final isSelected = f == selected;
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: GestureDetector(
                onTap: () => onSelected(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE2782B)
                        : colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    f.label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isSelected ? Colors.white : colors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 알림 아이템 한 줄
// ──────────────────────────────────────────────
class _NotiItem extends StatelessWidget {
  const _NotiItem({required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors   = context.colors;
    final typeInfo = _typeInfo(item.type);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: item.isRead
            ? colors.background
            : typeInfo.bgColor.withOpacity(0.45),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 타입 아이콘 — 아바타는 테마 중립(회색) 으로 두고, 타입 구분은
            // 오른쪽 위 칩(_TypeChip) 으로만 한다. 색상 경쟁을 줄여 목록이 차분해진다.
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Icon(
                  typeInfo.iconData,
                  size: 20.sp,
                  color: colors.textSecondary,
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TypeChip(type: item.type),
                      const Spacer(),
                      Text(
                        _fmtRel(item.createdAt),
                        style: AppTextStyles.labelMedium
                            .copyWith(color: colors.textHint),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight:
                          item.isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    item.message,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: colors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 안 읽음 점
            if (!item.isRead) ...[
              SizedBox(width: 8.w),
              Container(
                margin: EdgeInsets.only(top: 6.h),
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  color: typeInfo.dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 상대 시간 포맷.
  /// 서버 시계 skew / timezone 누락으로 미래 시각이 들어와 diff 가 음수로
  /// 잡히는 케이스를 방어한다 (예전엔 음수도 `< 1` 에 걸려 전부 "방금" 으로 표시됨).
  /// 또 1분 미만 구간을 초 단위로 더 잘게 쪼개 "방금만 줄줄이" 보이는 문제를 완화.
  String _fmtRel(DateTime dt) {
    final diff = DateTime.now().difference(dt);

    // 미래 (서버 시계 앞섬 / timezone 파싱 어긋남) → "방금"
    if (diff.isNegative) return '방금';

    final secs = diff.inSeconds;
    if (secs < 10)  return '방금';
    if (secs < 60)  return '$secs초 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24)   return '${diff.inHours}시간 전';
    if (diff.inDays == 1)    return '어제';
    return '${diff.inDays}일 전';
  }
}

// ──────────────────────────────────────────────
// 타입 칩
// ──────────────────────────────────────────────
class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});
  final NotificationType type;

  @override
  Widget build(BuildContext context) {
    final info = _typeInfo(type);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: info.chipColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        type.label,
        style: AppTextStyles.labelSmall.copyWith(
          color: info.chipTextColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 빈 상태
// ──────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final NotiFilter filter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 52.sp,
            color: colors.textHint,
          ),
          SizedBox(height: 16.h),
          Text(
            '알림이 없어요',
            style: AppTextStyles.bodyLarge.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: 6.h),
          Text(
            '두잇이가 곧 소식을 전할 거예요',
            style: AppTextStyles.bodySmall.copyWith(color: colors.textHint),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 타입별 색상/아이콘 헬퍼
// ──────────────────────────────────────────────
class _NotiTypeInfo {
  const _NotiTypeInfo({
    required this.bgColor,
    required this.dotColor,
    required this.chipColor,
    required this.chipTextColor,
    required this.iconData,
  });

  /// 행 배경 tint (미읽음 상태에서만 사용, opacity 낮게).
  final Color bgColor;

  /// 오른쪽 끝 미읽음 점 / 칩 강조색.
  final Color dotColor;
  final Color chipColor;
  final Color chipTextColor;

  /// 왼쪽 아바타에 그릴 아이콘. 실제 색상은 테마 중립 회색으로 주입된다.
  final IconData iconData;
}

_NotiTypeInfo _typeInfo(NotificationType type) {
  switch (type) {
    case NotificationType.evening:
      return const _NotiTypeInfo(
        bgColor: Color(0xFFFFF6EE),
        dotColor: Color(0xFFE2782B),
        chipColor: Color(0xFFFDE7D4),
        chipTextColor: Color(0xFFB85A1C),
        iconData: Icons.dark_mode_rounded,
      );
    case NotificationType.morning:
      return const _NotiTypeInfo(
        bgColor: Color(0xFFFFF9EC),
        dotColor: Color(0xFFF2B23A),
        chipColor: Color(0xFFFFE9B8),
        chipTextColor: Color(0xFF8A5A00),
        iconData: Icons.wb_sunny_rounded,
      );
    case NotificationType.todoDone:
      return const _NotiTypeInfo(
        bgColor: Color(0xFFF0F7EE),
        dotColor: Color(0xFF4CAF50),
        chipColor: Color(0xFFD9EBD5),
        chipTextColor: Color(0xFF2E7D32),
        iconData: Icons.check_circle_rounded,
      );
    case NotificationType.todoReminder:
      return const _NotiTypeInfo(
        bgColor: Color(0xFFF1F6FF),
        dotColor: Color(0xFF4A7DDB),
        chipColor: Color(0xFFE0EBFF),
        chipTextColor: Color(0xFF2D5BB8),
        iconData: Icons.notifications_active_rounded,
      );
    case NotificationType.todoSnoozed:
      return const _NotiTypeInfo(
        bgColor: Color(0xFFF7F1FF),
        dotColor: Color(0xFF8B5CF6),
        chipColor: Color(0xFFEAE0FF),
        chipTextColor: Color(0xFF5B3DAE),
        iconData: Icons.snooze_rounded,
      );
    case NotificationType.tamagochiFarewell:
      return const _NotiTypeInfo(
        bgColor: Color(0xFFFDF4F9),
        dotColor: Color(0xFFD06AA7),
        chipColor: Color(0xFFF5E2EE),
        chipTextColor: Color(0xFFA53F7B),
        iconData: Icons.favorite_rounded,
      );
    case NotificationType.tamagochiGrowth:
      return const _NotiTypeInfo(
        bgColor: Color(0xFFFFF6EE),
        dotColor: Color(0xFFE2782B),
        chipColor: Color(0xFFFDE7D4),
        chipTextColor: Color(0xFFB85A1C),
        iconData: Icons.auto_awesome_rounded,
      );
    case NotificationType.unknown:
      return const _NotiTypeInfo(
        bgColor: Color(0xFFF5F5F5),
        dotColor: Color(0xFF9E9E9E),
        chipColor: Color(0xFFE0E0E0),
        chipTextColor: Color(0xFF616161),
        iconData: Icons.notifications_rounded,
      );
  }
}
