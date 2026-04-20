# doitdo

다마고치를 키우는 TODO 앱.

## 아키텍처
Clean Architecture + MVVM

- **core**: theme, errors, constants, network, notifications, utils
- **domain**: entities, repositories(추상), usecases
- **data**: datasources(local/remote), models(dto), repositories(impl)
- **presentation**: navigation, pages/{feature}/, viewmodels, providers, widgets

**레이어링**: layer-first. `presentation/pages/` 아래만 feature-organized.

**MVVM**: Riverpod `StateNotifier` + sealed state class.
**DI**: `presentation/providers/app_data_providers.dart` 한 파일에 수동 선언.
**UseCase 레이어**: 사용 안 함. Repository가 비즈 로직 보유.

## 스택
| 영역 | 라이브러리 |
|---|---|
| 상태관리 | flutter_riverpod, riverpod_annotation |
| 모델 | freezed_annotation, json_annotation |
| 라우팅 | go_router |
| 네트워킹 | dio, retrofit |
| 푸시 | firebase_core, firebase_messaging, flutter_local_notifications |
| 로컬저장 | hive, hive_flutter, shared_preferences, path_provider |
| 환경변수 | flutter_dotenv |
| 반응형 | flutter_screenutil |
| 유틸 | logger, intl |

## 실행
```bash
flutter pub get
flutter run
```

## 코드 생성
```bash
dart run build_runner build --delete-conflicting-outputs
```

## 환경변수
`.env.example` 복사해 `.env` 생성.

## Firebase (FCM)
별도로 `flutterfire configure` 실행하여 `lib/firebase_options.dart` 생성 필요.

## 파일 네이밍
- Pages: `*_page.dart`
- ViewModels: `*_viewmodel.dart`
- Repositories: `*_repository.dart` (abstract), `*_repository_impl.dart` (impl)
- DataSources: `*_datasource.dart`, `*_datasource_impl.dart`
- DTOs: `*_dto.dart` / Entities: 단수 명사 (`todo.dart`)
