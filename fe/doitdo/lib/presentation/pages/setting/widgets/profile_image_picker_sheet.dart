import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_bottom_sheet.dart';

/// 프로필 이미지 변경 바텀시트의 선택 결과.
enum ProfileImageAction { camera, gallery, reset }

/// 프로필 사진 변경 방법 선택 시트.
///
/// 반환: 사용자가 항목을 선택하면 해당 [ProfileImageAction], 취소/바깥 탭 시 null.
Future<ProfileImageAction?> showProfileImagePickerSheet(BuildContext context) {
  return showDoitdoBottomSheet<ProfileImageAction>(
    context: context,
    child: const _ProfileImagePickerSheet(),
  );
}

class _ProfileImagePickerSheet extends StatelessWidget {
  const _ProfileImagePickerSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Center(
            child: Text(
              '프로필 사진 변경',
              style: AppTextStyles.titleSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _PickerOption(
          icon: Icons.camera_alt_outlined,
          label: '사진 촬영',
          onTap: () => Navigator.of(context).pop(ProfileImageAction.camera),
        ),
        _PickerOption(
          icon: Icons.photo_library_outlined,
          label: '갤러리에서 선택',
          onTap: () => Navigator.of(context).pop(ProfileImageAction.gallery),
        ),
        _PickerOption(
          icon: Icons.refresh_outlined,
          label: '기본 이미지로 변경',
          // 삭제성 액션 — 빨강 톤으로 강조. 파괴 동작 아님(복구 가능) 이라 danger red 는 피하고
          // textSecondary 유지. 필요 시 후속에 danger 토큰 추가해 색 분리.
          onTap: () => Navigator.of(context).pop(ProfileImageAction.reset),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: colors.primary),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
