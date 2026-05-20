import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/domain/entities/furniture_theme.dart';
import 'package:doitdo/domain/entities/room_placement.dart';
import 'package:doitdo/domain/entities/shop_entry.dart';
import 'package:doitdo/domain/entities/shop_furniture.dart';
import 'package:doitdo/domain/entities/user_furniture.dart';
import 'package:doitdo/domain/repositories/shop_repository.dart';
import 'package:doitdo/domain/repositories/user_repository.dart';
import 'package:doitdo/presentation/pages/shop/shop_state.dart';
import 'package:doitdo/presentation/pages/tamagochi/my_room_provider.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 상점 화면 ViewModel.
///
/// 진입 시 `GET /api/shop/entry` + `GET /api/users/me/furnitures` +
/// `GET /api/shop/themes` 를 병렬로 호출해 상점 카탈로그·내 방 배치·보유 가구
/// 매핑·테마 카드 목록을 한 번에 만든다. 보유했지만 미배치 인 가구를 "배치"
/// 하려면 `userFurnitureId` 가 필요한데 shop entry 응답에는 그 ID 가 없어서
/// 별도 호출이 필요하다.
///
/// 잔액(coin) 은 BE 에 GET 엔드포인트가 아직 없어 진입 시 0 으로 시작하고,
/// `POST /purchase` 응답의 `balance` 로만 갱신된다. wallet GET 이 추가되면
/// [build] 의 `Future.wait` 에 끼워 넣어 초기값을 채워준다.
class ShopViewModel extends AutoDisposeAsyncNotifier<ShopState> {
  late ShopRepository _repo;
  late UserRepository _userRepo;

  @override
  Future<ShopState> build() async {
    _repo = ref.watch(shopRepositoryProvider);
    _userRepo = ref.watch(userRepositoryProvider);

    // 상점 데이터 + 잔액 + 테마 목록을 병렬로 조회해 첫 진입 레이턴시 최소화.
    // getBalance / listThemes 실패 시에도 상점은 정상 표시 — 실패 영역만 폴백값.
    final results = await Future.wait([
      _repo.getShopEntry(),
      _repo.listMyFurnitures(),
      _userRepo.getBalance().catchError((_) => 0),
      _repo.listThemes().catchError((_) => const <FurnitureTheme>[]),
    ]);
    final entry = results[0] as ShopEntry;
    final myFurnitures = results[1] as List<UserFurnitureItem>;
    final coins = results[2] as int;
    final themes = results[3] as List<FurnitureTheme>;

    return _composeState(
      entry: entry,
      myFurnitures: myFurnitures,
      coins: coins,
      themes: themes,
    );
  }

  // ─── 동기 액션 (서버 호출 없음) ────────────────────────────────

  void selectCategory(ShopCategory category) {
    final s = state.valueOrNull;
    if (s == null || s.selectedCategory == category) return;
    state = AsyncData(s.copyWith(selectedCategory: category));
  }

  /// 상단 탭 (가구 / 테마) 전환. 반대편 미리보기는 서로 배타 — 탭을 옮기면
  /// 자연스럽게 비활성화돼 한 화면에서 두 종류 미리보기가 섞이지 않는다.
  void selectTab(ShopTab tab) {
    final s = state.valueOrNull;
    if (s == null || s.selectedTab == tab) return;
    if (tab == ShopTab.theme) {
      // 가구 탭 → 테마 탭: 가구 멀티 미리보기 해제 (방 영역을 테마가 차지).
      state = AsyncData(
        s.copyWith(selectedTab: tab, previewingItemIds: const {}),
      );
    } else {
      // 테마 탭 → 가구 탭: 테마 미리보기 해제 (방 영역을 가구 미리보기가 차지).
      state = AsyncData(s.copyWith(selectedTab: tab, clearThemePreview: true));
    }
  }

  /// 가구 카드의 "미리보기" 토글.
  ///
  /// 카테고리당 1개 정책:
  /// - 같은 itemId 를 한 번 더 탭 → 그 카테고리만 미리보기 해제
  /// - 같은 카테고리의 다른 itemId 탭 → 그 카테고리 미리보기 교체
  /// - 다른 카테고리 탭 → 기존 미리보기는 유지하고 그 카테고리만 추가
  ///
  /// 테마 미리보기가 활성화돼 있으면 가구 미리보기를 새로 켜는 시점에 테마는 해제.
  void togglePreview(String itemId) {
    final s = state.valueOrNull;
    if (s == null) return;
    final item = _findItem(s, itemId);
    if (item == null) return;

    final next = Map<ShopCategory, String>.from(s.previewingItemIds);
    if (next[item.category] == itemId) {
      next.remove(item.category);
    } else {
      next[item.category] = itemId;
    }
    state = AsyncData(
      s.copyWith(previewingItemIds: next, clearThemePreview: true),
    );
  }

  /// 테마 카드 미리보기 토글. 같은 테마를 한 번 더 탭하면 해제.
  ///
  /// 새로 켜질 때만 서버를 호출해 합성 응답(`preview-room`)을 받아 [ShopItem]
  /// 형태로 합성한 뒤 [ShopState.themePreviewItems] 에 보관 — 방 미리보기 영역은
  /// 이 리스트를 그대로 그린다.
  ///
  /// 가구 멀티 미리보기가 켜져 있어도 테마 미리보기 켜기와 동시에 모두 해제.
  Future<bool> toggleThemePreview(
    String themeCode, {
    void Function(String message)? onFailure,
  }) async {
    final s = state.valueOrNull;
    if (s == null) return false;

    // 같은 테마 재탭 → 해제만.
    if (s.previewingThemeCode == themeCode) {
      state = AsyncData(s.copyWith(clearThemePreview: true));
      return true;
    }

    try {
      final placements = await _repo.previewThemeRoom(themeCode);
      // 응답이 도착한 시점의 현재 state 기준으로 적용 — 사용자가 그 사이 다른
      // 테마를 탭했다면 그쪽이 먼저 들어왔을 수 있으므로 valueOrNull 다시 확인.
      final cur = state.valueOrNull;
      if (cur == null) return false;
      state = AsyncData(
        cur.copyWith(
          previewingItemIds: const {},
          previewingThemeCode: themeCode,
          themePreviewItems: _placementsToShopItems(placements),
        ),
      );
      return true;
    } catch (e) {
      onFailure?.call(_errorMessage(e));
      return false;
    }
  }

  /// 테마 세트 일괄 구매. 미보유 가구만 결제되어 보유 인벤토리로 들어가며
  /// 자동 배치는 일어나지 않는다 — 풀세트 보유 상태가 되면 카드 버튼이 "배치"
  /// 로 바뀌고 [placeOwnedTheme] 가 후속으로 호출 가능해진다.
  ///
  /// `alreadyOwned == true` 인 테마는 카드 버튼이 "배치" 라 이 액션이 호출되지
  /// 않지만, 방어적으로 진입 시 알림 후 false 리턴.
  ///
  /// 성공 시 코인/카탈로그/테마 목록을 재조회 — 보유 상태가 바뀌어 카드의
  /// alreadyOwned/purchasePrice 가 갱신돼야 하므로.
  Future<bool> purchaseTheme(
    String themeCode, {
    required void Function(String message) onFailure,
  }) async {
    final s = state.valueOrNull;
    if (s == null) return false;
    final theme = _findTheme(s, themeCode);
    if (theme == null) return false;
    if (theme.alreadyOwned) {
      onFailure('이미 보유한 테마예요.');
      return false;
    }

    try {
      final purchase = await _repo.purchaseTheme(themeCode);
      await _refresh(preserveUi: s, coinsOverride: purchase.balance);
      return true;
    } catch (e) {
      onFailure(_errorMessage(e));
      return false;
    }
  }

  /// 테마 세트 구매 + 일괄 배치 (가구 카드의 purchaseAndPlace 와 동일 톤).
  /// 주문서 다이얼로그의 primary CTA "구매하고 바로 배치하기" 가 호출하는 액션.
  ///
  /// 같은 카테고리에 이미 배치된 가구는 BE 가 자동 교체. 구매 후 배치 API 가
  /// 실패해도 구매 자체는 끝난 상태이므로, 그 경우 사용자가 카드의 "배치" 로
  /// 다시 시도하면 [placeOwnedTheme] 가 자연스럽게 회복시킨다.
  Future<bool> purchaseAndPlaceTheme(
    String themeCode, {
    required void Function(String message) onFailure,
  }) async {
    final s = state.valueOrNull;
    if (s == null) return false;
    final theme = _findTheme(s, themeCode);
    if (theme == null) return false;
    if (theme.alreadyOwned) {
      onFailure('이미 보유한 테마예요.');
      return false;
    }

    try {
      final purchase = await _repo.purchaseTheme(themeCode);
      final placement = await _repo.placeTheme(themeCode);
      if (placement.items.isNotEmpty) {
        await ref.read(myRoomProvider.notifier).replaceWith(placement.items);
      }
      await _refresh(preserveUi: s, coinsOverride: purchase.balance);
      // myRoomProvider 가 cache-first 라 invalidate 하면 build() 가 캐시(직전
      // 상태) 를 한 번 emit 한 뒤 fresh 를 받아 깜빡임이 생긴다. notifier 의
      // refreshFromNetwork 로 fresh 만 떨어뜨려 변경이 즉시 반영되게 한다.
      if (placement.items.isEmpty) {
        unawaited(ref.read(myRoomProvider.notifier).refreshFromNetwork());
      }
      // 적용 후 미리보기 상태는 의미 없음 — 카드 강조도 빠지게 명시적으로 해제.
      final cur = state.valueOrNull;
      if (cur != null) {
        state = AsyncData(cur.copyWith(clearThemePreview: true));
      }
      return true;
    } catch (e) {
      onFailure(_errorMessage(e));
      return false;
    }
  }

  /// 보유한 테마 가구를 한 번에 방에 배치. 같은 카테고리에 이미 배치된 가구가
  /// 있으면 BE 가 자동 교체한다.
  ///
  /// `alreadyOwned == false` 인 테마는 카드 버튼이 "구매" 라 이 액션이 호출되지
  /// 않지만, 방어적으로 BE 가 `S03-011 THEME_NOT_FULLY_OWNED` 를 던지면
  /// onFailure 로 사용자에게 알린다 (구매 → 배치 순으로 다시 시도하도록).
  Future<bool> placeOwnedTheme(
    String themeCode, {
    required void Function(String message) onFailure,
  }) async {
    final s = state.valueOrNull;
    if (s == null) return false;
    final theme = _findTheme(s, themeCode);
    if (theme == null) return false;

    try {
      final placement = await _repo.placeTheme(themeCode);
      if (placement.items.isNotEmpty) {
        await ref.read(myRoomProvider.notifier).replaceWith(placement.items);
      }
      await _refresh(preserveUi: s);
      // myRoomProvider 가 cache-first 라 invalidate 하면 build() 가 캐시(직전
      // 상태) 를 한 번 emit 한 뒤 fresh 를 받아 깜빡임이 생긴다. notifier 의
      // refreshFromNetwork 로 fresh 만 떨어뜨려 변경이 즉시 반영되게 한다.
      if (placement.items.isEmpty) {
        unawaited(ref.read(myRoomProvider.notifier).refreshFromNetwork());
      }
      // 적용 후 미리보기 상태는 의미 없음 — 카드 강조도 빠지게 명시적으로 해제.
      final cur = state.valueOrNull;
      if (cur != null) {
        state = AsyncData(cur.copyWith(clearThemePreview: true));
      }
      return true;
    } catch (e) {
      onFailure(_errorMessage(e));
      return false;
    }
  }

  // ─── 비동기 액션 (서버 호출) ────────────────────────────────

  /// 미보유 아이템을 구매하고 즉시 방에 배치한다(주문서 확인 모달의 단일 액션).
  ///
  /// 낙관적 업데이트: 서버 응답 전에 UI 를 먼저 반영해 체감 속도를 높인다.
  /// - 탭 즉시: 코인 차감 + 아이템 placed 상태로 전환
  /// - 백그라운드: 실제 서버 호출
  /// - 실패 시: 원래 상태(s)로 롤백 + [onFailure] 콜백 호출
  Future<bool> purchaseAndPlace(
    String itemId, {
    void Function(String message)? onFailure,
  }) async {
    final s = state.valueOrNull;
    if (s == null) return false;
    final item = _findItem(s, itemId);
    if (item == null || item.status != ItemStatus.notOwned) return false;

    // 1. UI 즉시 반영 — 서버 응답 기다리지 않고 코인 차감 + placed 표시.
    //    같은 카테고리에 이미 배치된 아이템이 있다면 BE 가 자동 교체하므로
    //    낙관 업데이트에서도 함께 owned 로 강등 — 안 그러면 _refresh 가 돌아올 때까지
    //    "배치중" 뱃지가 두 카드에 동시에 떠 보인다.
    state = AsyncData(
      s.copyWith(
        coins: s.coins - item.price,
        items: s.items.map((it) {
          if (it.id == itemId) return it.copyWith(status: ItemStatus.placed);
          if (it.category == item.category && it.status == ItemStatus.placed) {
            return it.copyWith(status: ItemStatus.owned);
          }
          return it;
        }).toList(),
      ),
    );

    // 2. 서버 호출 (백그라운드)
    try {
      final purchase = await _repo.purchaseFurniture(item.furnitureId);
      await _repo.placeFurniture(purchase.userFurnitureId);
      await _refresh(preserveUi: s, coinsOverride: purchase.balance);
      // myRoomProvider 가 cache-first 라 invalidate 하면 build() 가 캐시(직전
      // 상태) 를 한 번 emit 한 뒤 fresh 를 받아 깜빡임이 생긴다. notifier 의
      // refreshFromNetwork 로 fresh 만 떨어뜨려 변경이 즉시 반영되게 한다.
      unawaited(ref.read(myRoomProvider.notifier).refreshFromNetwork());
      return true;
    } catch (e) {
      // 실패 시 낙관적 업데이트 롤백 + 에러 종류별 메시지
      state = AsyncData(s);
      onFailure?.call(_errorMessage(e));
      return false;
    }
  }

  /// 미보유 아이템을 **배치 없이** 구매만 한다(주문서 확인 모달의 "구매만 하기").
  /// 같은 카테고리에 이미 배치된 아이템을 교체하지 않고 인벤토리에만 추가하고 싶을 때.
  ///
  /// 낙관 업데이트는 구매 직후 owned 상태로 표시하고 코인을 차감한다.
  /// 실패 시 원래 상태로 롤백 + [onFailure] 콜백 호출 (UX 패턴은 purchaseAndPlace 와 동일).
  Future<bool> purchaseOnly(
    String itemId, {
    void Function(String message)? onFailure,
  }) async {
    final s = state.valueOrNull;
    if (s == null) return false;
    final item = _findItem(s, itemId);
    if (item == null || item.status != ItemStatus.notOwned) return false;

    state = AsyncData(
      s.copyWith(
        coins: s.coins - item.price,
        items: s.items
            .map(
              (it) =>
                  it.id == itemId ? it.copyWith(status: ItemStatus.owned) : it,
            )
            .toList(),
      ),
    );

    try {
      final purchase = await _repo.purchaseFurniture(item.furnitureId);
      await _refresh(preserveUi: s, coinsOverride: purchase.balance);
      return true;
    } catch (e) {
      state = AsyncData(s);
      onFailure?.call(_errorMessage(e));
      return false;
    }
  }

  /// 보유 중 아이템을 방에 배치. 같은 카테고리의 기존 배치는 BE 가 자동 교체한다.
  Future<bool> place(String itemId) async {
    final s = state.valueOrNull;
    if (s == null) return false;
    final item = _findItem(s, itemId);
    if (item == null ||
        item.status != ItemStatus.owned ||
        item.userFurnitureId == null) {
      return false;
    }

    try {
      await _repo.placeFurniture(item.userFurnitureId!);
      await _refresh(preserveUi: s);
      // myRoomProvider 가 cache-first 라 invalidate 하면 build() 가 캐시(직전
      // 상태) 를 한 번 emit 한 뒤 fresh 를 받아 깜빡임이 생긴다. notifier 의
      // refreshFromNetwork 로 fresh 만 떨어뜨려 변경이 즉시 반영되게 한다.
      unawaited(ref.read(myRoomProvider.notifier).refreshFromNetwork());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 배치된 아이템을 방에서 제거 (보유 가구 자체는 유지).
  Future<bool> unplace(String itemId) async {
    final s = state.valueOrNull;
    if (s == null) return false;
    final item = _findItem(s, itemId);
    if (item == null ||
        item.status != ItemStatus.placed ||
        item.placementId == null) {
      return false;
    }

    try {
      await _repo.removePlacement(item.placementId!);
      await _refresh(preserveUi: s);
      // myRoomProvider 가 cache-first 라 invalidate 하면 build() 가 캐시(직전
      // 상태) 를 한 번 emit 한 뒤 fresh 를 받아 깜빡임이 생긴다. notifier 의
      // refreshFromNetwork 로 fresh 만 떨어뜨려 변경이 즉시 반영되게 한다.
      unawaited(ref.read(myRoomProvider.notifier).refreshFromNetwork());
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── 내부 헬퍼 ────────────────────────────────────────────────

  /// 에러 종류별 사용자 메시지 반환.
  static String _errorMessage(Object e) {
    if (e is NetworkException) {
      return '네트워크 연결을 확인해주세요.';
    } else if (e is ServerException) {
      // 서버가 내려준 메시지가 한국어면 그대로 노출, 아니면 공용 문구.
      final msg = e.message;
      return RegExp(r'[가-힣]').hasMatch(msg)
          ? msg
          : '서버 오류가 발생했어요. 잠시 후 다시 시도해주세요.';
    } else {
      return '요청을 처리하지 못했어요. 잠시 후 다시 시도해주세요.';
    }
  }

  /// 액션 후 서버 상태를 재조회해 카탈로그·매핑·테마 메타를 갱신.
  /// UI 상태(탭·카테고리·미리보기)는 _refresh 완료 시점의 현재 state 기준으로 유지.
  /// preserveUi 는 잔액 폴백 용도로만 사용.
  ///
  /// 테마 목록도 같이 재조회 — 가구 1개를 사거나 배치하기만 해도 테마의
  /// `ownedCount`/`purchasePrice`/`alreadyOwned` 가 달라지므로 카탈로그와 동기화가
  /// 깨지지 않게 한다. 테마 호출 실패 시에는 직전 themes 를 폴백.
  Future<void> _refresh({
    required ShopState preserveUi,
    int? coinsOverride,
  }) async {
    final results = await Future.wait([
      _repo.getShopEntry(),
      _repo.listMyFurnitures(),
      _repo.listThemes().catchError((_) => preserveUi.themes),
    ]);
    final entry = results[0] as ShopEntry;
    final myFurnitures = results[1] as List<UserFurnitureItem>;
    final themes = results[2] as List<FurnitureTheme>;

    // API 호출이 끝난 시점의 현재 상태를 기준으로 UI 상태 유지.
    // 백그라운드 처리 중 사용자가 카테고리/탭을 바꿨다면 그쪽을 그대로 유지.
    final currentUi = state.valueOrNull ?? preserveUi;

    state = AsyncData(
      _composeState(
        entry: entry,
        myFurnitures: myFurnitures,
        coins: coinsOverride ?? currentUi.coins,
        themes: themes,
        preserveTab: currentUi.selectedTab,
        preserveSelected: currentUi.selectedCategory,
        preservePreviewing: currentUi.previewingItemIds,
        preserveThemeCode: currentUi.previewingThemeCode,
        preserveThemeItems: currentUi.themePreviewItems,
      ),
    );
  }

  static ShopItem? _findItem(ShopState s, String id) {
    for (final it in s.items) {
      if (it.id == id) return it;
    }
    return null;
  }

  static FurnitureTheme? _findTheme(ShopState s, String themeCode) {
    for (final t in s.themes) {
      if (t.themeCode == themeCode) return t;
    }
    return null;
  }

  /// `RoomFurniturePlacement` 응답을 미리보기 렌더용 [ShopItem] 으로 합성.
  ///
  /// 방 미리보기 위젯은 `category` + `imageUrl` 만 사용하므로 나머지 필드는
  /// 폴백값으로 채운다. id 는 `theme_${furnitureId}` 형식 — placementId 가
  /// preview 응답에서 null 로 와도 위젯 key 충돌이 없게 한다.
  static List<ShopItem> _placementsToShopItems(
    List<RoomFurniturePlacement> placements,
  ) {
    return placements
        .map(
          (p) => ShopItem(
            id: 'theme_${p.furnitureId}',
            furnitureId: p.furnitureId,
            name: p.name,
            category: ShopCategory.fromServer(p.category),
            price: 0,
            status: ItemStatus.notOwned,
            imageUrl: p.imageUrl,
          ),
        )
        .toList(growable: false);
  }

  /// 서버 응답들을 합쳐 화면용 [ShopState] 를 만든다.
  ///
  /// - placed 인 항목에는 [placementId] 까지 채워서 "해제" API 가 바로 동작.
  /// - selectedCategory 는 [preserveSelected] 우선, 없으면 [background].
  static ShopState _composeState({
    required ShopEntry entry,
    required List<UserFurnitureItem> myFurnitures,
    required int coins,
    required List<FurnitureTheme> themes,
    ShopTab? preserveTab,
    ShopCategory? preserveSelected,
    Map<ShopCategory, String>? preservePreviewing,
    String? preserveThemeCode,
    List<ShopItem>? preserveThemeItems,
  }) {
    final ufIdByFurnitureId = <int, int>{
      for (final uf in myFurnitures) uf.furnitureId: uf.userFurnitureId,
    };
    final placementIdByUfId = <int, int>{
      for (final p in entry.room)
        if (p.placementId != null && p.userFurnitureId != null)
          p.userFurnitureId!: p.placementId!,
    };

    final items = <ShopItem>[];
    for (final f in entry.furnitures) {
      final ufId = ufIdByFurnitureId[f.furnitureId];
      final placementId = ufId != null ? placementIdByUfId[ufId] : null;
      items.add(
        ShopItem(
          id: 'shop_${f.furnitureId}',
          furnitureId: f.furnitureId,
          userFurnitureId: ufId,
          placementId: placementId,
          name: f.name,
          category: ShopCategory.fromServer(f.category),
          price: f.price,
          status: _mapStatus(f.status),
          imageUrl: f.thumbnailUrl.isNotEmpty ? f.thumbnailUrl : f.imageUrl,
        ),
      );
    }

    // listThemes 응답이 furnitures[].category 를 안 내려주는 상태(BE MR !285)
    // 라, 같은 furnitureId 의 카탈로그 항목에서 카테고리를 가져와 보강한다.
    // 이미지도 응답이 빈 경우 카탈로그 이미지로 폴백 — 다이얼로그가 향후 행에
    // 썸네일을 추가해도 빈 자리가 안 보이도록.
    final catalogByFurnitureId = <int, FurnitureShopItem>{
      for (final f in entry.furnitures) f.furnitureId: f,
    };
    final enrichedThemes = themes
        .map(
          (t) => FurnitureTheme(
            themeCode: t.themeCode,
            themeName: t.themeName,
            thumbnailUrl: t.thumbnailUrl,
            furnitureCount: t.furnitureCount,
            ownedCount: t.ownedCount,
            totalPrice: t.totalPrice,
            purchasePrice: t.purchasePrice,
            alreadyOwned: t.alreadyOwned,
            furnitures: t.furnitures
                .map((tf) {
                  final catalog = catalogByFurnitureId[tf.furnitureId];
                  return ThemeFurniture(
                    furnitureId: tf.furnitureId,
                    name: tf.name,
                    category: tf.category.isNotEmpty
                        ? tf.category
                        : (catalog?.category ?? ''),
                    price: tf.price,
                    imageUrl: tf.imageUrl.isNotEmpty
                        ? tf.imageUrl
                        : (catalog?.thumbnailUrl ?? catalog?.imageUrl ?? ''),
                    owned: tf.owned,
                  );
                })
                .toList(growable: false),
          ),
        )
        .toList(growable: false);

    return ShopState(
      coins: coins,
      items: items,
      themes: enrichedThemes,
      selectedTab: preserveTab ?? ShopTab.furniture,
      selectedCategory: preserveSelected ?? ShopCategory.background,
      previewingItemIds: preservePreviewing ?? const {},
      previewingThemeCode: preserveThemeCode,
      themePreviewItems: preserveThemeItems,
    );
  }

  static ItemStatus _mapStatus(FurnitureShopStatus s) {
    switch (s) {
      case FurnitureShopStatus.placed:
        return ItemStatus.placed;
      case FurnitureShopStatus.placeable:
        return ItemStatus.owned;
      case FurnitureShopStatus.purchasable:
      case FurnitureShopStatus.unknown:
        return ItemStatus.notOwned;
    }
  }
}

final shopViewModelProvider =
    AsyncNotifierProvider.autoDispose<ShopViewModel, ShopState>(
      ShopViewModel.new,
    );
