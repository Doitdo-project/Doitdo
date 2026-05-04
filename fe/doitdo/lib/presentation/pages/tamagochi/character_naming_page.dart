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

/// 알 부화 직후 이름을 짓는 화면.
///
/// 한 번 정한 이름은 변경 불가(스펙 합의)이므로 입력창 하단에 안내를 노출한다.
class CharacterNamingPage extends ConsumerStatefulWidget {
  const CharacterNamingPage({super.key});

  @override
  ConsumerState<CharacterNamingPage> createState() =>
      _CharacterNamingPageState();
}

class _CharacterNamingPageState extends ConsumerState<CharacterNamingPage> {
  static const int _minLen = 2;
  static const int _maxLen = 8;
  static const List<String> _suggestionPool = [
    '오둥이', '포비', '미치비', '말랑이',
    '콩이', '모찌', '푸딩이', '꼬미',
    '밤이', '솜이', '별이', '달이',
    '토리', '호두', '쫀득이', '뽀삐',
  ];

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  bool get _isValid {
    final v = _controller.text.trim();
    return v.length >= _minLen && v.length <= _maxLen;
  }

  void _useRandomSuggestion() {
    final current = _controller.text.trim();
    final candidates =
        _suggestionPool.where((n) => n != current).toList()..shuffle();
    if (candidates.isEmpty) return;
    final pick = candidates.first;
    _controller.text = pick;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: pick.length),
    );
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final ok = await ref
        .read(characterViewModelProvider.notifier)
        .renameCharacter(_controller.text.trim());
    if (!mounted) return;
    if (!ok) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름 저장에 실패했어요. 다시 시도해주세요.')),
      );
      return;
    }
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final characterAsync = ref.watch(characterViewModelProvider);
    final character = characterAsync.valueOrNull;
    final length = _controller.text.trim().length;
    final isFocused = _focusNode.hasFocus;

    return DoitdoScaffold(
      body: DoitdoPaddingLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '새 친구에게\n이름을 지어주세요',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: colors.textPrimary,
                        fontSize: 24.sp,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '한 번 정하면 바꿀 수 없으니, 신중히 지어주세요!',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 32.h),
                    Center(child: _CharacterPreview(character: character)),
                    SizedBox(height: 40.h),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isFocused
                                ? colors.primary
                                : colors.divider,
                            width: isFocused ? 1.5 : 1,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              maxLength: _maxLen,
                              style: AppTextStyles.titleSmall.copyWith(
                                color: colors.textPrimary,
                                fontSize: 18.sp,
                              ),
                              decoration: InputDecoration(
                                hintText: '이름 입력',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: colors.textHint,
                                ),
                                counterText: '',
                                isCollapsed: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10.h,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => _submit(),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '$length/$_maxLen',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          _RecommendButton(onTap: _useRandomSuggestion),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            DoitdoPrimaryButton(
              label: '이름 짓기',
              onPressed: (_isValid && !_submitting) ? _submit : null,
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
    // 부화 직후 진입이라 정상 플로우에선 character.thumbnailUrl 이 들어와 있다.
    // 하드코드 placeholder(한라봉) 로 덮어쓰지 않고 서버 이미지를 그대로 사용.
    final url = character?.thumbnailUrl ?? '';
    if (url.isEmpty) {
      return _previewPlaceholder(context);
    }
    return Image.network(
      url,
      height: 150.h,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, _, _) => _previewPlaceholder(context),
    );
  }

  Widget _previewPlaceholder(BuildContext context) {
    return SizedBox(
      height: 150.h,
      child: Center(
        child: Icon(
          Icons.pets,
          size: 72.sp,
          color: context.colors.textHint,
        ),
      ),
    );
  }
}

class _RecommendButton extends StatelessWidget {
  const _RecommendButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh,
                size: 12.sp,
                color: colors.textSecondary,
              ),
              SizedBox(width: 4.w),
              Text(
                '추천',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
