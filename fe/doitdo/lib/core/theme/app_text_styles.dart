import 'package:flutter/material.dart';

/// 앱 전역 텍스트 스타일.
///
/// fontFamily 는 의도적으로 비워둔다. `ThemeData.fontFamily` 에 사용자가 설정한
/// 폰트(예: GmarketSans / Pretendard) 가 주입되면 Flutter 가 모든 Text 위젯의
/// 기본 font 로 사용한다. fontWeight 는 pubspec.yaml 의 weight 메타데이터와
/// 매칭되어 자동으로 적절한 ttf/otf 가 선택된다.
///
/// 폰트 선택은 [fontFamilyProvider] → [AppTheme] 경유로 적용된다.
class AppTextStyles {
  AppTextStyles._();

  // ── Display ──────────────────────────────────────────────
  /// 시간 피커 숫자 (7, 30)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w500,
  );

  // ── Title ────────────────────────────────────────────────
  /// 페이지 제목 (비밀번호 찾기, 비밀번호 변경, 카테고리 추가, 주문서 확인)
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  /// 월 헤더 (4월), 상점/도감 타이틀, 회원가입
  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  /// 툴바 제목 (계정 설정, 알림 설정, 카테고리 설정), 섹션 헤더
  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  // ── Body ─────────────────────────────────────────────────
  /// 리스트 항목 (계정, 알림, 기본화면, 투두 카테고리, 로그아웃), 버튼 텍스트 (로그인, 구매, 저장하기, 확인)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  /// 할 일 항목 텍스트, 입력 필드 입력값, 설정 항목 제목 (푸시알림, 아침 리마인드, 저녁 리마인드, 금지 시간 활성화),
  /// 캘린더 일정 텍스트, 카테고리 항목 (운동), 아이템명 (딸기 모자)
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  /// 설명 서브텍스트 (두잇두로부터 알림을 수신합니다, 설정한 시간에는 알림이 울리지 않습니다,
  /// 하루의 시작을 돕는 알림, 내일을 위한 기록 리마인드), 유저 이메일 (user@email.com), 아이템 보유 상태 (보유중)
  ///
  /// Light 폰트(w300) 는 회색 색상과 만날 때 실기기에서 과하게 흐려 보여
  /// Medium/w500 으로 변경 (2024-04 가독성 개선).
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // ── Label ────────────────────────────────────────────────
  /// 태그 칩 (건강, 운동, 공부, 업무, 취미), 섹션 구분 레이블 (일반, 알림 금지 시간, 리마인드),
  /// 반복 유형 탭 (일반, 기간, 반복), 캘린더 요일 헤더 (SUN, MON ... SAT)
  static const TextStyle labelLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  /// 캘린더 날짜 숫자, 연속 달성 날짜 (DATE), 아이템 가격 (1,500$),
  /// 링크 텍스트 (회원가입, 비밀번호 찾기, 로그인 화면으로 이동)
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// 하단 네비게이션 바 (캘린더, 홈, 설정), 할 일 카테고리 뱃지 (건강, 전공 등 작은 칩), LV 레벨 표시
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );
}
