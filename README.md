r# Partition App - Flutter Frontend

Spring 백엔드와 연동하는 Flutter 기반 파티션 관리 앱의 프론트엔드 프로젝트입니다.

## 프로젝트 구조

이 프로젝트는 **기능별 구조(Feature-First)**를 따르며, 각 기능 모듈이 독립적으로 구성되어 있습니다.

```
partition_app/
├── lib/
│   ├── main.dart                    # 앱의 진입점
│   │
│   ├── core/                        # 앱의 핵심 설정 및 공통 기능
│   │   ├── config/
│   │   │   └── app_config.dart      # 앱 설정 및 API 엔드포인트
│   │   ├── network/
│   │   │   ├── api_client.dart      # HTTP 클라이언트 (Dio 기반)
│   │   │   └── api_exception.dart   # API 예외 처리
│   │   ├── providers/
│   │   │   └── app_providers.dart   # 전역 Provider 설정
│   │   ├── router/
│   │   │   └── app_router.dart      # 라우팅 설정
│   │   ├── storage/
│   │   │   └── storage_service.dart # 로컬 저장소 관리
│   │   └── theme/
│   │       └── app_theme.dart       # 앱 테마 설정
│   │
│   ├── features/                    # 기능별 모듈
│   │   ├── auth/                    # 인증 기능
│   │   │   ├── models/
│   │   │   │   ├── user_model.dart
│   │   │   │   └── auth_response_model.dart
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   └── services/
│   │   │       └── auth_service.dart
│   │   │
│   │   ├── partition/               # 파티션 관리 기능 (핵심)
│   │   │   ├── models/
│   │   │   │   └── partition_model.dart
│   │   │   ├── providers/
│   │   │   │   └── partition_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── partition_list_screen.dart
│   │   │   │   └── partition_detail_screen.dart
│   │   │   └── services/
│   │   │       └── partition_service.dart
│   │   │
│   │   └── settings/                # 설정 기능
│   │       └── screens/
│   │           └── settings_screen.dart
│   │
│   └── shared/                      # 공통 위젯 및 유틸리티
│       ├── utils/
│       │   ├── constants.dart       # 상수 정의
│       │   └── validators.dart      # 폼 검증 유틸리티
│       └── widgets/
│           └── not_found_screen.dart
│
├── test/                            # 테스트 코드
│   └── widget_test.dart
│
├── assets/                          # 에셋 파일
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── pubspec.yaml                     # 프로젝트 설정 및 의존성
├── analysis_options.yaml            # Dart 분석 설정
└── .gitignore                       # Git 무시 파일
```

## 주요 디렉토리 설명

### `lib/core/`

앱의 핵심 설정과 공통 기능을 담당하는 디렉토리입니다.

- **config/**: 앱 설정 및 API 엔드포인트 정의
- **network/**: HTTP 통신을 위한 클라이언트 및 예외 처리
- **providers/**: 전역 상태 관리 Provider 설정
- **router/**: 화면 전환을 위한 라우팅 설정
- **storage/**: 로컬 저장소(SharedPreferences) 관리
- **theme/**: 앱 테마 설정 (라이트/다크 모드)

### `lib/features/`

기능별로 모듈화된 디렉토리입니다. 각 기능은 다음과 같은 구조를 가집니다:

```
feature_name/
├── models/          # 데이터 모델
├── providers/       # 상태 관리 (Provider)
├── screens/         # UI 화면
└── services/        # 비즈니스 로직 및 API 호출
```

#### `auth/` - 인증 기능

- 로그인/회원가입 화면
- 사용자 인증 상태 관리
- JWT 토큰 관리

#### `partition/` - 파티션 관리 기능

- 파티션 목록 조회
- 파티션 상세 정보
- 파티션 생성/수정/삭제
- 파티션 사용량 표시

#### `settings/` - 설정 기능

- 사용자 설정 관리
- 앱 설정 변경

### `lib/shared/`

여러 기능에서 공통으로 사용되는 위젯과 유틸리티입니다.

- **utils/**: 상수, 검증 함수 등
- **widgets/**: 재사용 가능한 위젯

## 주요 설정 파일

### `pubspec.yaml`

프로젝트의 의존성과 설정을 관리합니다.

**주요 의존성:**
- `provider`: 상태 관리
- `dio`: HTTP 통신
- `shared_preferences`: 로컬 저장소
- `json_annotation`, `json_serializable`: JSON 직렬화

### `app_config.dart`

백엔드 API 설정을 관리합니다. Spring 백엔드의 기본 URL과 엔드포인트를 여기서 설정합니다.

```dart
static const String baseUrl = 'http://localhost:8080/api';
```

**주의**: 실제 배포 시에는 환경별로 다른 URL을 사용하도록 설정해야 합니다.

## 백엔드 연동

### API 클라이언트

`ApiClient` 클래스는 Dio를 기반으로 구현되어 있으며, 다음과 같은 기능을 제공합니다:

- 자동 토큰 추가 (Authorization 헤더)
- 요청/응답 로깅
- 에러 처리

### 서비스 레이어

각 기능의 `services/` 디렉토리에 있는 서비스 클래스가 백엔드 API를 호출합니다.

예시:
```dart
// partition_service.dart
Future<List<PartitionModel>> getPartitions() async {
  final response = await _apiClient.get(AppConfig.partitionsEndpoint);
  // ...
}
```

## 상태 관리

이 프로젝트는 **Provider** 패턴을 사용하여 상태를 관리합니다.

- 각 기능 모듈의 `providers/` 디렉토리에 Provider 클래스가 있습니다
- `AppProviders`에서 전역 Provider를 등록합니다
- 화면에서는 `Consumer` 또는 `context.read()`를 사용하여 상태에 접근합니다

## 라우팅

`AppRouter` 클래스에서 모든 라우트를 관리합니다.

**주요 라우트:**
- `/login`: 로그인 화면
- `/register`: 회원가입 화면
- `/partitions`: 파티션 목록
- `/partitions/:id`: 파티션 상세
- `/settings`: 설정 화면

## 개발 가이드

### 1. 프로젝트 초기화

```bash
flutter pub get
```

### 2. 코드 생성 (JSON 직렬화)

모델 클래스에 `@JsonSerializable()` 어노테이션이 있는 경우, 다음 명령어로 코드를 생성해야 합니다:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. 백엔드 URL 설정

`lib/core/config/app_config.dart` 파일에서 백엔드 API URL을 설정합니다.

### 4. 실행

```bash
flutter run
```

## 다음 단계

1. **JSON 직렬화 코드 생성**: 모델 클래스의 `.g.dart` 파일 생성
2. **백엔드 API 연동**: Spring 백엔드의 실제 엔드포인트와 연동
3. **에러 처리 개선**: 사용자 친화적인 에러 메시지 표시
4. **로딩 상태 개선**: 더 나은 로딩 인디케이터 추가
5. **폼 검증 강화**: 더 상세한 입력 검증
6. **테스트 코드 작성**: 단위 테스트 및 위젯 테스트 추가

## 모범 사례

1. **명명 규칙**
   - 파일명: `snake_case.dart`
   - 클래스명: `PascalCase`
   - 변수/함수명: `camelCase`

2. **코드 구조**
   - 관련된 코드는 같은 디렉토리에 위치
   - 공통 기능은 `shared/` 디렉토리에 배치
   - 기능별로 독립적인 모듈 구성

3. **에러 처리**
   - API 호출 시 `ApiException` 사용
   - 사용자에게 명확한 에러 메시지 표시

4. **상태 관리**
   - Provider를 사용한 상태 관리
   - 불필요한 리빌드 방지

## 참고사항

- 이 프로젝트는 Flutter 3.0 이상을 요구합니다
- 백엔드는 Spring Boot 기반으로 개발되어야 합니다
- API 응답 형식은 백엔드와 협의하여 결정해야 합니다

