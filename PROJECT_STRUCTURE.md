# Flutter 프로젝트 구조 이해 - Partition App

Flutter 프로젝트는 여러 디렉토리와 파일로 구성되어 있으며, 각각은 프로젝트의 특정 측면을 담당합니다. 이 구조를 이해하면 Flutter 앱을 더 효율적으로 개발하고 관리할 수 있습니다.

## Flutter 프로젝트의 기본 구조

기본적인 Flutter 프로젝트 구조는 다음과 같습니다:

```
partition_app/
├── .dart_tool/          # Dart 도구 관련 파일
├── .idea/               # IDE 설정 (Android Studio)
├── android/             # 안드로이드 특화 코드
├── build/               # 빌드 출력 파일
├── ios/                 # iOS 특화 코드
├── lib/                 # Dart 코드 (핵심)
│   └── main.dart        # 앱의 진입점
├── linux/               # Linux 특화 코드
├── macos/               # macOS 특화 코드
├── test/                # 테스트 코드
├── web/                 # 웹 특화 코드
├── windows/             # Windows 특화 코드
├── assets/              # 에셋 파일 (이미지, 폰트 등)
├── .gitignore           # Git 무시 파일
├── .metadata            # Flutter 메타데이터
├── analysis_options.yaml # Dart 분석 설정
├── pubspec.lock         # 의존성 버전 잠금 파일
├── pubspec.yaml         # 프로젝트 설정 및 의존성
└── README.md            # 프로젝트 설명
```

## 주요 디렉토리

### `lib/` 디렉토리

`lib/` 디렉토리는 Flutter 프로젝트의 핵심으로, 앱의 Dart 소스 코드가 저장되는 위치입니다.

**Partition App의 lib/ 구조:**

```
lib/
├── main.dart                    # 앱의 진입점
│
├── core/                        # 앱의 핵심 설정 및 공통 기능
│   ├── config/
│   │   └── app_config.dart      # 앱 설정 및 API 엔드포인트
│   ├── network/
│   │   ├── api_client.dart      # HTTP 클라이언트
│   │   └── api_exception.dart   # API 예외 처리
│   ├── providers/
│   │   └── app_providers.dart   # 전역 Provider 설정
│   ├── router/
│   │   └── app_router.dart      # 라우팅 설정
│   ├── storage/
│   │   └── storage_service.dart # 로컬 저장소 관리
│   └── theme/
│       └── app_theme.dart       # 앱 테마 설정
│
├── features/                    # 기능별 모듈
│   ├── auth/                    # 인증 기능
│   │   ├── models/              # 데이터 모델
│   │   ├── providers/           # 상태 관리
│   │   ├── screens/             # UI 화면
│   │   └── services/            # 비즈니스 로직, API 호출
│   │
│   ├── partition/               # 파티션 관리 기능
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── services/
│   │
│   └── settings/                # 설정 기능
│       └── screens/
│
└── shared/                      # 공통 위젯 및 유틸리티
    ├── utils/                   # 유틸리티 기능
    └── widgets/                 # 재사용 가능한 위젯
```

**중요**: 기본적으로 생성되는 것은 `main.dart` 파일뿐이며, 나머지 폴더 구조는 개발자가 필요에 따라 생성하고 구성합니다.

### `main.dart`

`main.dart` 파일은 앱의 진입점으로, `main()` 함수와 루트 위젯을 포함합니다:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/router/app_router.dart';
import 'package:partition_app/core/theme/app_theme.dart';
import 'package:partition_app/core/providers/app_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PartitionApp());
}

class PartitionApp extends StatelessWidget {
  const PartitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.providers,
      child: MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        initialRoute: AppRouter.initialRoute,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
```

### `test/` 디렉토리

`test/` 디렉토리는 앱의 자동화된 테스트 코드를 포함합니다. 단위 테스트, 위젯 테스트 등을 이 디렉토리에 작성합니다.

```
test/
├── widget_test.dart          # 위젯 테스트
└── unit/                     # 단위 테스트
    └── models_test.dart
```

### `android/` 디렉토리

`android/` 디렉토리는 Android 플랫폼 관련 코드와 설정을 포함합니다.

**특히 중요한 파일들:**

- `AndroidManifest.xml`: 앱의 이름, 아이콘, 필요한 권한 등을 정의
- `build.gradle`: 앱의 버전, 의존성, 빌드 설정 등을 구성

### `ios/` 디렉토리

`ios/` 디렉토리는 iOS 플랫폼 관련 코드와 설정을 포함합니다.

**특히 중요한 파일들:**

- `Info.plist`: 앱 이름, 버전, 권한 등의 메타데이터를 포함
- `AppDelegate.swift`: iOS 앱의 진입점 및 초기화 로직을 포함

### `web/`, `macos/`, `linux/`, `windows/` 디렉토리

이 디렉토리들은 각각 웹, macOS, 리눅스, 윈도우 플랫폼을 위한 코드와 설정을 포함합니다.

## 주요 설정 파일

### `pubspec.yaml`

`pubspec.yaml`은 Flutter 프로젝트의 핵심 설정 파일로, 앱의 메타데이터, 의존성, 에셋 등을 정의합니다:

```yaml
name: partition_app
description: A Flutter application for partition management
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  dio: ^5.4.0
  shared_preferences: ^2.2.2

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
```

**주요 항목들:**

- `name`: 앱의 패키지 이름
- `version`: 앱의 버전(버전 코드+빌드 번호 형식)
- `dependencies`: 앱이 사용하는 패키지 의존성
- `dev_dependencies`: 개발 시에만 필요한 패키지 의존성
- `flutter`: Flutter 특화 설정 (에셋, 폰트, 테마 등)

### `analysis_options.yaml`

`analysis_options.yaml`은 Dart 코드 분석기의 설정을 정의하여 코드 품질과 일관성을 유지하는 데 도움을 줍니다:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - avoid_print
    - prefer_const_constructors
    - sort_child_properties_last

analyzer:
  errors:
    missing_required_param: error
```

### `.gitignore`

`.gitignore` 파일은 Git 버전 관리 시스템에서 무시해야 할 파일들을 지정합니다. Flutter 프로젝트에서는 빌드 결과물, 임시 파일, IDE 파일 등이 여기에 포함됩니다.

## 프로젝트 구조화 패턴

### 기능별 구조 (Feature-First) - 현재 사용 중

앱의 기능별로 디렉토리를 구성하는 방식으로, Partition App에서 사용하는 구조입니다:

```
lib/
├── main.dart
├── core/              # 공통 기능
├── features/          # 기능별 모듈
│   ├── auth/
│   ├── partition/
│   └── settings/
└── shared/            # 공통 위젯 및 유틸리티
```

**장점:**

- 기능별로 코드가 명확하게 분리됨
- 대규모 앱에 적합
- 팀 작업 시 충돌 최소화

### 계층별 구조 (Layer-First)

앱의 아키텍처 계층별로 디렉토리를 구성하는 방식:

```
lib/
├── main.dart
├── screens/           # 모든 화면 UI
├── widgets/           # 모든 재사용 위젯
├── models/            # 모든 데이터 모델
├── services/          # 모든 서비스 로직
└── utils/             # 유틸리티 함수
```

**장점:**

- 작거나 중간 규모의 앱에 적합
- 구조가 단순함

## 모범 사례 및 권장 사항

### 1. 명확한 명명 규칙

- **파일 이름**: `snake_case.dart` (예: `user_profile.dart`)
- **클래스 이름**: `PascalCase` (예: `UserProfile`)
- **변수 및 함수 이름**: `camelCase` (예: `userName`, `getUserInfo()`)

### 2. 프로젝트 구조 일관성 유지

- 처음부터 명확한 구조 계획 수립
- 프로젝트 전체에 동일한 규칙 적용
- 팀 내 구조 합의 및 문서화

### 3. 관련 코드 그룹화

- 관련된 코드는 함께 위치
- 너무 깊은 중첩 디렉토리 피하기 (일반적으로 3-4 수준 이내)
- 디렉토리 이름은 내용을 명확히 반영

### 4. 불필요한 분할 피하기

- 파일이 너무 많아지면 관리가 어려울 수 있음
- 단일 위젯이나 작은 기능을 여러 파일로 나누지 않기
- 너무 큰 파일도 피하기 (일반적으로 300-500줄 이내)

## 백엔드 연동 구조

### API 클라이언트

`lib/core/network/api_client.dart`에서 Dio를 사용하여 HTTP 통신을 처리합니다:

- 자동 토큰 추가 (Authorization 헤더)
- 요청/응답 로깅
- 에러 처리

### 서비스 레이어

각 기능의 `services/` 디렉토리에 있는 서비스 클래스가 백엔드 API를 호출합니다:

```dart
// partition_service.dart
class PartitionService {
  final ApiClient _apiClient = ApiClient();

  Future<List<PartitionModel>> getPartitions() async {
    final response = await _apiClient.get(AppConfig.partitionsEndpoint);
    // ...
  }
}
```

### 모델 클래스

`models/` 디렉토리에 데이터 모델을 정의하며, `json_serializable`을 사용하여 JSON 직렬화를 처리합니다.

## 상태 관리

이 프로젝트는 **Provider** 패턴을 사용합니다:

- 각 기능 모듈의 `providers/` 디렉토리에 Provider 클래스
- `AppProviders`에서 전역 Provider 등록
- 화면에서 `Consumer` 또는 `context.read()` 사용
