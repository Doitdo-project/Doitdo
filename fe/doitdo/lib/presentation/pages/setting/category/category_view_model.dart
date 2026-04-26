import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/data/models/category_dto.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 팔레트 목록 Provider.
///
/// 앱 라이프타임 동안 캐시 유지 (autoDispose 없음).
/// 바텀시트에서 색상 피커를 그릴 때 ref.watch 로 구독한다.
final paletteProvider =
    FutureProvider<PaletteListResp>((ref) {
  return ref.read(categoryRepositoryProvider).getPalettes();
});

/// 설정 > 카테고리 화면 상태 및 서버 연동 로직.
///
/// [build] 에서 카테고리 목록을 즉시 조회한다.
/// 추가·수정·삭제 성공 시 state 를 직접 갱신해 서버 재요청 없이 UI 를 최신화한다.
class CategoryViewModel extends AsyncNotifier<List<CategoryResp>> {
  @override
  Future<List<CategoryResp>> build() =>
      ref.read(categoryRepositoryProvider).getCategories();

  Future<void> addCategory({
    required String name,
    required int colorId,
  }) async {
    final repo = ref.read(categoryRepositoryProvider);
    final created = await repo.createCategory(name: name, colorId: colorId);
    // 성공 시 기존 목록 끝에 추가 — 재요청 없이 낙관적 업데이트.
    state = AsyncData([...state.requireValue, created]);
  }

  Future<void> editCategory({
    required int categoryId,
    required String name,
    required int colorId,
  }) async {
    final repo = ref.read(categoryRepositoryProvider);
    final updated = await repo.updateCategory(
      categoryId: categoryId,
      name: name,
      colorId: colorId,
    );
    state = AsyncData(
      state.requireValue
          .map((c) => c.categoryId == categoryId ? updated : c)
          .toList(),
    );
  }

  Future<void> removeCategory(int categoryId) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.deleteCategory(categoryId);
    state = AsyncData(
      state.requireValue.where((c) => c.categoryId != categoryId).toList(),
    );
  }

  /// 활성 팔레트 변경 — 모든 카테고리의 색을 [newPaletteId] 의 같은 인덱스 색으로 PATCH.
  ///
  /// 매핑 정책:
  ///   - 각 카테고리의 현재 colorId 가 어느 팔레트의 K번째 색인지 역추론
  ///   - 새 팔레트의 K번째 colorId 로 변경
  ///   - 새 팔레트의 색 수가 더 적으면 마지막 색으로 폴백 (보통 동일하지만 방어)
  ///   - 이미 새 팔레트의 같은 colorId 를 쓰고 있는 카테고리는 PATCH 생략 (네트워크 절약)
  ///
  /// 부분 실패 처리: 카테고리 N개 PATCH 중 일부 실패해도 성공한 것까지는 state 갱신,
  /// 실패한 카테고리는 기존 색 유지. 첫 에러는 rethrow 해서 View 가 SnackBar 띄울 수 있게.
  Future<void> applyPaletteToAll({
    required int newPaletteId,
    required PaletteListResp paletteList,
  }) async {
    final palettes = paletteList.items;
    final newPalette = palettes.firstWhere(
      (p) => p.paletteId == newPaletteId,
      orElse: () => throw StateError('palette $newPaletteId not found'),
    );

    // 팔레트별 baseColorId (1-based 누적). colorId = baseId + index.
    final baseIdByPaletteId = <int, int>{};
    int base = 1;
    for (final p in palettes) {
      baseIdByPaletteId[p.paletteId] = base;
      base += p.colors.length;
    }
    final newBaseId = baseIdByPaletteId[newPaletteId]!;

    final repo = ref.read(categoryRepositoryProvider);
    final cats = state.requireValue;
    final updated = <CategoryResp>[];
    Object? firstError;

    for (final c in cats) {
      // 현재 colorId 가 어느 팔레트의 몇 번째인지 역추론
      int? indexInOld;
      for (final p in palettes) {
        final pBase = baseIdByPaletteId[p.paletteId]!;
        if (c.colorId >= pBase && c.colorId < pBase + p.colors.length) {
          indexInOld = c.colorId - pBase;
          break;
        }
      }

      final idx = indexInOld ?? 0;
      final newIdx = idx.clamp(0, newPalette.colors.length - 1);
      final newColorId = newBaseId + newIdx;

      if (newColorId == c.colorId) {
        updated.add(c);
        continue;
      }

      try {
        final result = await repo.updateCategory(
          categoryId: c.categoryId,
          name: c.categoryName,
          colorId: newColorId,
        );
        updated.add(result);
      } catch (e) {
        firstError ??= e;
        updated.add(c);
      }
    }

    state = AsyncData(updated);
    if (firstError != null) throw firstError;
  }
}

final categoryViewModelProvider =
    AsyncNotifierProvider<CategoryViewModel, List<CategoryResp>>(
  CategoryViewModel.new,
);
