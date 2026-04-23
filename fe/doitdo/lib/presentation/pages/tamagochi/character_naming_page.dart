import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/domain/entities/character.dart';
import 'package:doitdo/presentation/pages/tamagochi/character_view_model.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_padding_layout.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';

/// 알 부화 직후 이름을 짓는 화면 (STEP 3/3).
///
/// 현재 이름 저장 API 스펙이 미확정이라, 제출 버튼은 로컬 검증 + 화면 pop 만
/// 수행한다. 스펙 확정 후 [_submit] 에서 `ref.read(characterViewModelProvider
/// .notifier).renameCharacter(name)` 류를 호출하도록 연결하면 된다.
class CharacterNamingPage extends ConsumerStatefulWidget {
  const CharacterNamingPage({super.key});

  @override
  ConsumerState<CharacterNamingPage> createState() =>
      _CharacterNamingPageState();
}

class _CharacterNamingPageState extends ConsumerState<CharacterNamingPage> {
  static const int _minLen = 2;
  static const int _maxLen = 8;
  static const List<String> _suggestions = ['오둥이', '포비', '미치비', '말랑이'];

  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid {
    final v = _controller.text.trim();
    return v.length >= _minLen && v.length <= _maxLen;
  }

  void _useSuggestion(String name) {
    _controller.text = name;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: name.length),
    );
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    // TODO: 이름 저장 API 연결. 스펙 확정 전까지는 pop 만 하고 홈에서 재조회한다.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final characterAsync = ref.watch(characterViewModelProvider);
    final character = characterAsync.valueOrNull;

    return DoitdoScaffold(
      body: DoitdoPaddingLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16.h),
            Text(
              'STEP 3/3',
              style: AppTextStyles.labelMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              '새 친구에게 이름을\n지어주세요',
              style: AppTextStyles.titleLarge.copyWith(
                color: colors.textPrimary,
                fontSize: 24.sp,
                height: 1.3,
              ),
            ),
            SizedBox(height: 32.h),
            Center(child: _CharacterPreview(character: character)),
            SizedBox(height: 32.h),
            TextField(
              controller: _controller,
              maxLength: _maxLen,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSmall.copyWith(
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '이름 입력 ($_minLen~$_maxLen자)',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textHint,
                ),
                counterText: '',
                filled: true,
                fillColor: colors.surface,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              alignment: WrapAlignment.center,
              children: [
                for (final name in _suggestions)
                  _SuggestionChip(
                    label: name,
                    selected: _controller.text.trim() == name,
                    onTap: () => _useSuggestion(name),
                  ),
              ],
            ),
            const Spacer(),
            DoitdoPrimaryButton(
              label: '이름 짓기',
              onPressed:
                  (_isValid && !_submitting) ? _submit : null,
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}

class _CharacterPreview extends StatelessWidget {
  const _CharacterPreview({required this.character});

  final Character? character;

  @override
  Widget build(BuildContext context) {
    // 부화 직후 진입이라 정상 플로우에선 character.thumbnailUrl 이 있다.
    final url = character?.thumbnailUrl ?? '';
    if (url.isEmpty) {
      return Image.asset(
        'assets/images/tama_hanrabong.png',
        height: 140.h,
        fit: BoxFit.contain,
      );
    }
    return Image.network(
      url,
      height: 140.h,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Image.asset(
        'assets/images/tama_hanrabong.png',
        height: 140.h,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.primary : colors.surface,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: colors.border),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: selected ? colors.onPrimary : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}