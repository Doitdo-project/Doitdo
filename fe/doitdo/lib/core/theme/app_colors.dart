import 'package:flutter/material.dart';

class AppColors {
  // 1. 로그인 / 회원가입
  static const Color loginBtnOn = Color(0xFFE2782B);
  static const Color loginBtnOff = Color(0xFFC5C5C5);
  static const Color textFieldHint = Color(0xFFB3B3B3);
  static const Color textDefault = Color(0xFF000000);
  static const Color btnText = Color(0xFFFFFFFF);

  // 2. 메인 (다마고치)
  static const Color streakBg = Color(0xFFFFF8F2);
  static const Color streakCheck = Color(0xFFE2782B);
  static const Color streakCheckX = Color(0xFFEAE8DE);
  static const Color categoryHealth = Color(0xFFCB3A45);
  static const Color categorySomeday = Color(0xFFFFE2E7);
  static const Color categorySomedayText = Color(0xFF006316);

  // 3. 상점 / 도감
  static const Color shopText = Color(0xFF316F57);
  static const Color chipSelectedBg = Color(0xFFAFF0D2);
  static const Color chipSelectedText = Color(0xFF316F57);
  static const Color chipUnselectedBg = Color(0xFFF6F4EB); // 아이템 배경 공용
  static const Color chipUnselectedText = Color(0xFF65655D);

  // 4. 캘린더
  static const Color calendarPoint = Color(0xFFE2782B); // 주간/월 선택, 칩 버튼
  static const Color calendarDateText = Color(0xFF5B6061); // 캐릭터 문구 포함
  static const Color bubbleBg = Color(0xFFF2F4F4); // 말풍선, 칩버튼 배경
  static const Color highlightElement = Color(0xFF835026); // 반복 아이콘 등
  static const Color componentBg = Color(0xFFF2F4F4);

  // 5. 설정
  static const Color characterCircleBg = Color(0xFFFFF5EE);
  static const Color settingPoint = Color(0xFFE2782B); // 이모지, 토글 ON, 시간
  static const Color settingText = Color(0xFF316F57);
  static const Color logoutCircle = Color(0xFFFFDAD6);
  static const Color textLowIntensity = Color(0xFFAEB3B3); // 또는 B3B3B3
  static const Color subHeader = Color(0xFF7A5742);
  static const Color cardHintBg = Color(0xFF857469);
  static const Color homeCalendarSelectedBg = Color(0xFFFFEBD5);
  static const Color themeBorder = Color(0xFF894D1E);
  static const Color themeBg = Color(0xFFF3F3F3);
  static const Color toggleOff = Color(0xFFDFE3E4);
  static const Color timeCardBg = Color(0xFFA5A5A5);

  // 6. 카테고리별 컬러 (1~8)
  static const Color category1 = Color(0xFFE1F7E7);
  static const Color category2 = Color(0xFFFFEED6);
  static const Color category3 = Color(0xFFFADBDE);
  static const Color category4 = Color(0xFFFFC6D0);
  static const Color category5 = Color(0xFFDAFBFB);
  static const Color category6 = Color(0xFFE0EBF5);
  static const Color category7 = Color(0xFFC3D6F2);
  static const Color category8 = Color(0xFF789CCE);

  // 리스트로 관리하면 인덱스로 접근하기 편합니다 (예: 카테고리 색상 불러오기)
  static const List<Color> categories = [
    category1, category2, category3, category4,
    category5, category6, category7, category8,
  ];
}