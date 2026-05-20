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
  ///   - 각 카테고리의 현재 colorHex 가 어느 팔레트의 K번째 색인지 hex 매칭으로 찾기
  ///   - 새 팔레트의 K번째 색의 colorId 로 변경 (BE 가 직접 내려준 실제 colorId 사용)
  ///   - 새 팔레트의 색 수가 더 적으면 마지막 색으로 폴백 (보통 동일하지만 방어)
  ///   - 어느 팔레트에도 안 맞는 카테고리(외부에서 변경된 색)는 새 팔레트 0번째로 폴백
  ///   - 이미 새 팔레트의 같은 colorId 를 쓰고 있는 카테고리는 PATCH 생략 (네트워크 절약)
  ///
  /// 이전 구현은 "DB 의 colorId 가 1부터 displayOrder 순으로 연속 부여" 라는 가정에
  /// 의존해 colorId 를 추측 계산했지만, BE MR(`be/fix/palette-resp-color-id`) 로
  /// `PaletteColorResp.colorId` 가 응답에 포함되어 추측이 사라졌다.
  /// → "팔레트 변경 시 새 색이 잠깐 떴다가 옛 색으로 돌아가는" 버그가 해결된다.
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

    final repo = ref.read(categoryRepositoryProvider);
    final cats = state.requireValue;

    // 각 카테고리의 새 colorId·color 미리 계산.
    // - colorHex 매칭으로 기존 색의 팔레트 내 인덱스를 찾아 새 팔레트 같은 위치로 옮긴다.
    // - 매칭이 안 되는 케이스(외부 변경 등)는 새 팔레트 0번째로 폴백.
    final targets = cats.map((c) {
      int? indexInOld;
      for (final p in palettes) {
        final idx = p.colors.indexWhere((pc) => pc.color == c.colorHex);
        if (idx >= 0) {
          indexInOld = idx;
          break;
        }
      }
      final idx = indexInOld ?? 0;
      final newIdx = idx.clamp(0, newPalette.colors.length - 1);
      final newColor = newPalette.colors[newIdx];
      return (cat: c, newColorId: newColor.colorId, newHex: newColor.color);
    }).toList();

    // 낙관적 업데이트 — 서버 응답 전에 UI 즉시 반영
    state = AsyncData(targets.map((t) {
      if (t.newColorId == t.cat.colorId) return t.cat;
      return CategoryResp(
        categoryId:   t.cat.categoryId,
        categoryName: t.cat.categoryName,
        colorId:      t.newColorId,
        colorHex:     t.newHex,
      );
    }).toList());

    // 병렬 PATCH — 개별 실패는 원본 유지, 첫 에러는 rethrow
    try {
      final pairs = await Future.wait(
        targets.map((t) async {
          if (t.newColorId == t.cat.colorId) return (t.cat, null as Object?);
          try {
            final result = await repo.updateCategory(
              categoryId: t.cat.categoryId,
              name:       t.cat.categoryName,
              colorId:    t.newColorId,
            );
            return (result, null as Object?);
          } catch (e) {
            return (t.cat, e);
          }
        }),
      );
      state = AsyncData(pairs.map((p) => p.$1).toList());
      final firstError = pairs.map((p) => p.$2).nonNulls.firstOrNull;
      if (firstError != null) throw firstError;
    } catch (e) {
      state = AsyncData(cats); // 전체 복구
      rethrow;
    }
  }
}

final categoryViewModelProvider =
    AsyncNotifierProvider<CategoryViewModel, List<CategoryResp>>(
  CategoryViewModel.new,
);
