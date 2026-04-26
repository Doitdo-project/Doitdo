import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/pages/notification/notification_view_model.dart';

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

class _NotificationPageState extends ConsumerState<NotificationPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 리스트 끝 80px 전에 도달하면 다음 페이지 로드
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 80) {
      ref.read(notificationViewModelProvider.notifier).loadMore();
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
            _NotiTopBar(
              unreadCount: state.unreadCount,
              onMarkAll: state.unreadCount > 0 ? vm.markAllAsRead : null,
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
          return Dismissible(
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
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 상단 바
// ──────────────────────────────────────────────
class _NotiTopBar extends StatelessWidget {
  const _NotiTopBar({
    required this.unreadCount,
    required this.onBack,
    this.onMarkAll,
  });

  final int unreadCount;
  final VoidCallback onBack;
  final VoidCallback? onMarkAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.topBarBg,
      padding: EdgeInsets.fromLTRB(8.w, 4.h, 16.w, 4.h),
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

          if (onMarkAll != null)
            GestureDetector(
              onTap: onMarkAll,
              child: Text(
                '모두 읽음',
                style:
                    AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
              ),
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

  String _fmtRel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays == 1) return '어제';
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
    case NotificationType.todoUnlock:
      return const _NotiTypeInfo(
        bgColor: Color(0xFFF1F6FF),
        dotColor: Color(0xFF4A7DDB),
        chipColor: Color(0xFFE0EBFF),
        chipTextColor: Color(0xFF2D5BB8),
        iconData: Icons.lock_open_rounded,
      );
    case NotificationType.tamagochiFarewell:
      return const _NotiTypeInfo(
        bgColor: Color(0xFFFDF4F9),
        dotColor: Color(0xFFD06AA7),
        chipColor: Color(0xFFF5E2EE),
        chipTextColor: Color(0xFFA53F7B),
        iconData: Icons.favorite_rounded,
      );
  }
}
