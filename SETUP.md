# 프로젝트 설정 가이드

## 초기 설정

### 1. 의존성 설치

```bash
flutter pub get
```

### 2. JSON 직렬화 코드 생성

이 프로젝트는 `json_serializable`을 사용하여 모델 클래스의 JSON 직렬화 코드를 자동 생성합니다.

다음 명령어를 실행하여 `.g.dart` 파일을 생성하세요:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

또는 파일 변경 시 자동으로 재생성하려면:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

**생성되는 파일:**
- `lib/features/auth/models/user_model.g.dart`
- `lib/features/auth/models/auth_response_model.g.dart`
- `lib/features/partition/models/partition_model.g.dart`

### 3. 백엔드 URL 설정

`lib/core/config/app_config.dart` 파일을 열어 백엔드 API URL을 설정하세요:

```dart
static const String baseUrl = 'http://localhost:8080/api';  // 개발 환경
// 또는
static const String baseUrl = 'https://your-api-domain.com/api';  // 프로덕션 환경
```

### 4. 앱 실행

```bash
flutter run
```

## 개발 환경별 설정

### 개발 환경

`lib/core/config/app_config.dart`에서 개발 환경 URL 사용:

```dart
static const String baseUrl = 'http://localhost:8080/api';
```

### 프로덕션 환경

프로덕션 배포 시에는 환경 변수나 별도 설정 파일을 사용하는 것을 권장합니다.

## 문제 해결

### JSON 직렬화 코드가 생성되지 않는 경우

1. `pubspec.yaml`에 다음이 포함되어 있는지 확인:
   ```yaml
   dev_dependencies:
     build_runner: ^2.4.7
     json_serializable: ^6.7.1
   ```

2. 다음 명령어로 캐시를 지우고 다시 생성:
   ```bash
   flutter clean
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

### 백엔드 연결 오류

1. 백엔드 서버가 실행 중인지 확인
2. `app_config.dart`의 `baseUrl`이 올바른지 확인
3. CORS 설정 확인 (웹 플랫폼의 경우)

## 다음 단계

1. 백엔드 API 엔드포인트와 응답 형식 확인
2. 모델 클래스의 필드가 백엔드 응답과 일치하는지 확인
3. API 호출 테스트
4. 에러 처리 개선
5. UI/UX 개선

