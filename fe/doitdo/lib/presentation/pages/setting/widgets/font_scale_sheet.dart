import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/providers/font_scale_provider.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_bottom_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_sheet_action_button.dart';

Future<double?> showFontScaleSheet({
  required BuildContext context,
  required double current,
}) {
  return showDoitdoBottomSheet<double>(
    context: context,
    child: _FontScaleSheet(initialScale: current),
  );
}

class _FontScaleSheet extends StatefulWidget {
  const _FontScaleSheet({required this.initialScale});

  final double initialScale;

  @override
  State<_FontScaleSheet> createState() => _FontScaleSheetState();
}

class _FontScaleSheetState extends State<_FontScaleSheet> {
  late double _scale;

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              '원하는 글자 크기를 설정해보세요',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 미리보기 카드
              _PreviewCard(scale: _scale, colors: colors),
              const SizedBox(height: 20),
              // 슬라이더
              _ScaleSlider(
                scale: _scale,
                colors: colors,
                onChanged: (v) => setState(() => _scale = v),
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
                      onPressed: () => Navigator.of(context).pop(_scale),
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

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.scale, required this.colors});

  final double scale;
  final DoitdoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘의 할 일',
            style: AppTextStyles.titleSmall.copyWith(
              color: colors.textPrimary,
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '아침 운동하기',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textPrimary,
              fontSize: 14 * scale,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '영단어 50개 외우기',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
              fontSize: 14 * scale,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '일기 쓰기',
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.textHint,
              fontSize: 12 * scale,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScaleSlider extends StatelessWidget {
  const _ScaleSlider({
    required this.scale,
    required this.colors,
    required this.onChanged,
  });

  final double scale;
  final DoitdoColors colors;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colors.primary,
            inactiveTrackColor: colors.border,
            thumbColor: colors.primary,
            overlayColor: colors.primary.withOpacity(0.12),
            trackHeight: 4,
          ),
          child: Slider(
            value: scale,
            min: FontScaleNotifier.min,
            max: FontScaleNotifier.max,
            divisions: 8,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '작게',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.textHint,
                ),
              ),
              Text(
                '크게',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.textHint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
