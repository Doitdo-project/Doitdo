
# 🐣 DOITDO
> **할 일을 끝낼수록 캐릭터가 자란다 — 자라서 떠나면, 새로운 알이 찾아온다**

| 항목 | 내용 |
|------|------|
| 서비스명 | DOITDO |
| 개발 기간 | 2026.03 ~ 2026.05 (진행 중) |
| 개발 인원 | 6명 (FE 2, BE 2, Design 1, Infra 1) |
| 배포 | 원스토어 배포 완료 · 앱스토어/플레이스토어 심사 중 |

<br>

## 목차
- [💡 기획 배경](#-기획-배경)
- [✨ 서비스 주요 기능](#-서비스-주요-기능)
- [📱 주요 화면 및 기능 소개](#-주요-화면-및-기능-소개)
- [🛠️ 핵심 기술](#️-핵심-기술)
- [🏗️ 시스템 아키텍처](#️-시스템-아키텍처)
- [📦 버전 히스토리](#-버전-히스토리)
- [👥 팀원 소개](#-팀원-소개)
- [⚙️ 기술 스택](#️-기술-스택)

<br>

## 💡 기획 배경

### 할 일 관리, 왜 3일 만에 포기할까?

생산성 앱의 설치 후 3일 이탈률은 **77%** 에 달합니다.  
기능이 부족해서가 아닙니다. **지속할 동기가 없기 때문**입니다.

- 할 일을 완료해도 체크 표시 하나가 전부입니다.
- 보상도, 재미도, 애착도 없습니다.

이 문제를 해결하기 위해 DOITDO는 다음 목표로 개발되었습니다.

- TODO 완료 → 캐릭터 성장 → 정서적 보상으로 이어지는 구조 설계
- 다마고치형 게이미피케이션으로 꾸준한 사용 유도
- 할 일을 끝내는 행위 자체를 즐거운 경험으로 전환

<br>

## ✨ 서비스 주요 기능

### ✅ TODO 관리
- 일반 / 반복 / 기간 3가지 유형 지원
- 카테고리, 우선순위, 알림 시간 설정
- 캘린더 뷰 · 검색 · 필터 · 미루기 기능
- 잠금 해제 시 오늘 할 일 푸시 알림 (ACTION_USER_PRESENT)

### 🐾 다마고치 육성
- 알 → 슬라임 → 애기슬라임 → 성체 4단계 진화
- TODO 완료 시 캐릭터 경험치 획득
- 자유 보행 · 말풍선 · 똥치우기 미션 등 상호작용
- 성체 독립 후 도감 기록 · 새 알 자동 배정

### 🏠 방 꾸미기
- 뚜레딧(재화) 적립 → 상점에서 가구 구매
- 테마 세트 구매 · 미리보기 · 일괄 배치
- 방 꾸미기를 통한 개인화 공간 제공

### 📊 통계 · 보상
- 스트릭(연속 달성) 기록 및 7일 단위 보상
- 일일 출석 보상
- 활동 통계 (일별·주별·월별 달성 현황)

<br>

## 📱 주요 화면 및 기능 소개

### 1. 홈 화면
- 상단에서 키우고 있는 캐릭터와 방을 함께 확인할 수 있습니다.
- 캐릭터 성장 단계 및 경험치를 확인할 수 있습니다.
- 하단에서 오늘의 할 일과 언젠가 할 일 목록을 확인할 수 있습니다.

### 2. 캘린더
- 날짜별 카테고리 색상 점으로 할 일 현황을 직관적으로 파악할 수 있습니다.
- 월간/주간 캘린더 스와이프 전환이 가능합니다.
- 필터로 원하는 카테고리만 골라서 조회할 수 있습니다.

### 3. TODO 작성
- 일반 · 기간 · 반복 유형을 선택하여 할 일을 등록할 수 있습니다.
- 카테고리, 우선순위, 알림 시간을 함께 설정할 수 있습니다.

### 4. 상점 · 방 꾸미기
- 뚜레딧으로 가구를 구매하고 방을 꾸밀 수 있습니다.
- 테마 미리보기 후 일괄 배치 기능을 제공합니다.

### 5. 도감
- 독립한 캐릭터를 영구 기록으로 보관합니다.
- 같은 종류 캐릭터를 여러 번 육성할수록 도감이 채워집니다.

<br>

## 🛠️ 핵심 기술

### 옵티미스틱 UI
- TODO 생성 시 서버 응답을 기다리지 않고 즉시 목록에 반영합니다.
- POST가 백그라운드에서 처리되며, 실패 시 자동 롤백됩니다.
- **사용자 체감 응답시간 ~2초 → ~273ms (86% 개선)**

### 안티패턴 제거
- POST 1건당 후속 GET 5건이 연쇄 호출되던 구조를 분석하여 제거했습니다.
- 4가지 안티패턴(중복 호출, 응답 무시, race 조건, 반옵티미스틱) 식별 및 수정
- **POST 후 후속 GET 5건 → 0건 (-100%)**

### FCM 기반 알림 시스템
- 디바이스 토큰 등록·해제·읽음 처리·소프트 삭제까지 운영 가능한 수준으로 구현
- ACTION_USER_PRESENT 브로드캐스트로 잠금 해제 시 오늘 할 일 알림 제공

### AI 개발·운영 어시스턴트
- Discord 기반 CI/CD 모니터링 자동화
- Prometheus + Grafana 메트릭 기반 에러 파악 및 분석 자동화

<br>

## 🏗️ 시스템 아키텍처

> 아키텍처 이미지 추가 예정

- **Frontend**: Android Native (Kotlin)
- **Backend**: Spring Boot · MySQL · Redis
- **Infra**: AWS EC2 · Docker · GitLab CI/CD
- **Push**: Firebase Cloud Messaging (FCM)

<br>

## 📦 버전 히스토리

### v1.0.0 — MVP 배포
- TODO 핵심 기능 및 캐릭터 성장 흐름 구현
- 내부 테스터 배포

### v1.1.0 — 1차 피드백 반영
- TODO 생성 후 즉시 반영 (옵티미스틱 UI)
- 상점 · 가구 구매 · 방 꾸미기 추가
- 소셜 로그인 · 알림 · 위젯 오류 안정화

### v1.2.0 — 2차 피드백 반영
- 캐릭터 자유 보행 · 말풍선 · 똥치우기 미션 추가
- 반복 TODO 날짜별 수정·삭제 개선
- 테마 미리보기 · 세트 구매 · 일괄 배치 추가
- 공지사항 · 비밀번호 재설정 등 운영 기능 추가

<br>

## 👥 팀원 소개

| 역할 | 이름 | 담당 |
|------|------|------|
| Android | 오우택 | 홈 · TODO · 캘린더 · 다마고치 · 상점 화면 구현, 옵티미스틱 UI 설계 |
| Android | - | - |
| Backend | - | Spring Boot API 서버 |
| Backend | - | DB 설계 · 인프라 |
| Design | - | UI/UX 디자인 · 캐릭터 디자인 |
| Infra | - | Docker · CI/CD · 모니터링 |

<br>

## ⚙️ 기술 스택

### Frontend
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Kotlin](https://img.shields.io/badge/Kotlin-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white)
![FCM](https://img.shields.io/badge/Firebase_FCM-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)

### Backend
![Spring Boot](https://img.shields.io/badge/Spring_Boot-6DB33F?style=for-the-badge&logo=springboot&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Redis](https://img.shields.io/badge/Redis-FF4438?style=for-the-badge&logo=redis&logoColor=white)

### Infra
![EC2](https://img.shields.io/badge/EC2-FF9900?style=for-the-badge&logo=amazonec2&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![GitLab CI/CD](https://img.shields.io/badge/GitLab_CI%2FCD-FC6D26?style=for-the-badge&logo=gitlab&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)