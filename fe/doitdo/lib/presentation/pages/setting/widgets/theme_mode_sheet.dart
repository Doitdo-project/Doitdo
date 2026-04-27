import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_bottom_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_sheet_action_button.dart';

/// 설정 > 화면 모드 선택 바텀시트.
///
/// 라이트 / 다크 두 장의 미리보기 카드를 보여주고 [확인] 으로 확정.
/// "시스템 모드" 는 선택지에서 제외 — 저장값이 system 인 경우 실제 현재 밝기에 해당하는 쪽을 사전 선택.
///
/// 반환값: 사용자가 [확인] 을 누른 경우 선택한 [ThemeMode], [이전] / 바깥 탭 / 뒤로가기 시 null.
Future<ThemeMode?> showThemeModeSheet({
  required BuildContext context,
  required ThemeMode current,
}) {
  final brightness = MediaQuery.of(context).platformBrightness;
  final initial = current == ThemeMode.system
      ? (brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light)
      : current;

  return showDoitdoBottomSheet<ThemeMode>(
    context: context,
    child: _ThemeModeSheet(initialSelection: initial),
  );
}

class _ThemeModeSheet extends StatefulWidget {
  const _ThemeModeSheet({required this.initialSelection});

  /// 시트 오픈 시 초기 선택값. 반드시 [ThemeMode.light] 또는 [ThemeMode.dark].
  final ThemeMode initialSelection;

  @override
  State<_ThemeModeSheet> createState() => _ThemeModeSheetState();
}

class _ThemeModeSheetState extends State<_ThemeModeSheet> {
  late ThemeMode _selected = widget.initialSelection;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 타이틀 위아래로 숨 쉴 공간을 더 둔다 (drag handle / 카드와 너무 붙지 않게).
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              '가장 편안한 화면을 선택해보세요',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 카드 / 버튼 영역에 추가 좌우 여백 — 시트 기본 패딩(20) 위에 10 더해 총 30.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ThemePreviewCard(
                      mode: ThemeMode.light,
                      label: '라이트 모드',
                      isSelected: _selected == ThemeMode.light,
                      onTap: () =>
                          setState(() => _selected = ThemeMode.light),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ThemePreviewCard(
                      mode: ThemeMode.dark,
                      label: '다크 모드',
                      isSelected: _selected == ThemeMode.dark,
                      onTap: () =>
                          setState(() => _selected = ThemeMode.dark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DoitdoSheetActionButton(
                      label: '이전',
                      isPrimary: false,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DoitdoSheetActionButton(
                      label: '확인',
                      onPressed: () => Navigator.of(context).pop(_selected),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 라이트 / 다크 미리보기 카드.
///
/// 시안(Figma SVG) 비율 그대로 구현:
///   외곽 선택 래퍼 159×271 / 내부 카드 143×190 (rx=24) / 8px 패딩.
///   내부에는 아바타 + 텍스트 라인 2개 + 이미지 박스 + 하단 라인 2개.
/// 내부 모든 색상은 "실제 라이트/다크 톤을 시각적으로 비교" 하는 게 목적이므로
/// `context.colors` 시맨틱 토큰 대신 고정 hex 사용.
class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.mode,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette =
        mode == ThemeMode.light ? _lightPalette : _darkPalette;

    // 선택 상태 강조 컬러 (테두리 + 라벨 텍스트) — 시안 고정 브랜드 톤.
    const accent = Color(0xFF894D1E);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          // 두 카드 모두 항상 회색 배경을 유지 — 선택 전환 시 배경이 튀어나오는 느낌 방지.
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(24),
          // 비선택 시에도 같은 두께의 투명 테두리를 두어 레이아웃 점프 방지.
          border: Border.all(
            color: isSelected ? accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              // 시안은 143×190 이지만 내부 컨텐츠 총합(32+12+70.66+12+12+8+12 = 158.66)이
              // 가용 영역(190-32 padding = 158) 보다 0.66px 크다.
              // AspectRatio 를 143:192 로 1.34px 여유를 줘서 overflow 경고를 없앰 — 눈으로는 구분 불가.
              aspectRatio: 143 / 192,
              child: _MiniAppPreview(palette: palette),
            ),
            const SizedBox(height: 20),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? accent : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 미리보기 카드 내부의 "앱 화면 미니어처".
///
/// 시안의 143×190 기준 치수를 카드 실제 폭에 비례 스케일(`s`) 해서 그린다.
class _MiniAppPreview extends StatelessWidget {
  const _MiniAppPreview({required this.palette});
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final s = constraints.maxWidth / 143;
        return Container(
          padding: EdgeInsets.all(16 * s),
          decoration: BoxDecoration(
            color: palette.bg,
            borderRadius: BorderRadius.circular(24 * s),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 상단: 아바타 + 텍스트 라인 2개 ──
              SizedBox(
                height: 32 * s,
                child: Row(
                  children: [
                    Container(
                      width: 32 * s,
                      height: 32 * s,
                      decoration: BoxDecoration(
                        color: palette.avatar,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 15 * s),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 6 * s,
                            decoration: BoxDecoration(
                              color: palette.topLines,
                              borderRadius: BorderRadius.circular(3 * s),
                            ),
                          ),
                          SizedBox(height: 4 * s),
                          Row(
                            children: [
                              Container(
                                width: 32 * s,
                                height: 6 * s,
                                decoration: BoxDecoration(
                                  color: palette.topLines,
                                  borderRadius: BorderRadius.circular(3 * s),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12 * s),
              // ── 이미지 박스 + 내부 카드 ──
              AspectRatio(
                aspectRatio: 111 / 70.66,
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.imageBox,
                    borderRadius: BorderRadius.circular(8 * s),
                  ),
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 73.98 / 111,
                      heightFactor: 35.33 / 70.66,
                      child: Container(
                        decoration: BoxDecoration(
                          color: palette.innerCard,
                          borderRadius: BorderRadius.circular(4 * s),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12 * s),
              // ── 하단 텍스트 라인 2개 (두 번째는 88.8/111 폭) ──
              Container(
                height: 12 * s,
                decoration: BoxDecoration(
                  color: palette.bottomLines,
                  borderRadius: BorderRadius.circular(4 * s),
                ),
              ),
              SizedBox(height: 8 * s),
              Row(
                children: [
                  // 88.8 : 22.2 비율로 좌측 정렬 라인.
                  Expanded(
                    flex: 888,
                    child: Container(
                      height: 12 * s,
                      decoration: BoxDecoration(
                        color: palette.bottomLines,
                        borderRadius: BorderRadius.circular(4 * s),
                      ),
                    ),
                  ),
                  const Spacer(flex: 222),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 미리보기 카드 색상 세트 — 라이트 / 다크 각각 시안(SVG) 의 hex 를 그대로.
class _Palette {
  const _Palette({
    required this.bg,
    required this.avatar,
    required this.topLines,
    required this.imageBox,
    required this.innerCard,
    required this.bottomLines,
  });

  final Color bg;
  final Color avatar;
  final Color topLines;
  final Color imageBox;
  final Color innerCard;
  final Color bottomLines;
}

const _lightPalette = _Palette(
  bg: Colors.white,
  avatar: Color(0xFFFFDCC6),
  topLines: Color(0xFFE2E2E2),
  imageBox: Color(0xFFF3F3F3),
  innerCard: Colors.white,
  bottomLines: Color(0xFFE8E8E8),
);

const _darkPalette = _Palette(
  bg: Color(0xFF1C1917),
  avatar: Color(0xFF44403C),
  topLines: Color(0xFF292524),
  imageBox: Color(0xFF292524),
  innerCard: Color(0xFF1C1917),
  bottomLines: Color(0xFF44403C),
);

