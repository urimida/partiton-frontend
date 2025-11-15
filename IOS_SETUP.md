# iOS 개발 설정 가이드

## 현재 프로젝트 구조 평가

✅ **잘 구성된 부분:**
- 기능별 모듈 구조 (Feature-First)
- 백엔드 연동을 위한 서비스 레이어
- 상태 관리 (Provider)
- 라우팅 구조
- 공통 위젯 및 유틸리티

## iOS 전용 개발을 위한 추가 설정

### 1. iOS 프로젝트 생성

프로젝트 루트에서 다음 명령어 실행:

```bash
flutter create --platforms=ios .
```

이 명령어는 `ios/` 디렉토리를 생성하고 필요한 iOS 설정 파일들을 추가합니다.

### 2. iOS 네트워크 보안 설정 (ATS)

iOS는 기본적으로 HTTPS만 허용합니다. 개발 환경에서 HTTP를 사용하려면 `ios/Runner/Info.plist`에 다음 설정을 추가해야 합니다:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <!-- 또는 특정 도메인만 허용 -->
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

**주의**: 프로덕션 빌드에서는 `NSAllowsArbitraryLoads`를 `false`로 설정하고, HTTPS를 사용해야 합니다.

### 3. iOS 시뮬레이터 vs 실제 기기

#### 시뮬레이터
- `localhost` 또는 `127.0.0.1` 사용 가능
- `http://localhost:8080/api` 그대로 사용

#### 실제 iOS 기기
- `localhost`는 기기 자체를 가리킴
- Mac의 로컬 IP 주소 사용 필요
- 예: `http://192.168.1.100:8080/api`

**설정 방법:**
`lib/core/platform/platform_config.dart`에서 환경에 따라 URL을 변경하세요.

### 4. iOS 권한 설정

필요한 권한을 `ios/Runner/Info.plist`에 추가:

```xml
<!-- 네트워크 권한 (기본 제공) -->
<!-- 카메라 권한이 필요한 경우 -->
<key>NSCameraUsageDescription</key>
<string>파티션 정보를 촬영하기 위해 카메라 접근이 필요합니다.</string>

<!-- 사진 라이브러리 권한이 필요한 경우 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>파티션 이미지를 선택하기 위해 사진 라이브러리 접근이 필요합니다.</string>
```

### 5. iOS 앱 아이콘 및 런치 스크린

- **아이콘**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`에 추가
- **런치 스크린**: `ios/Runner/Base.lproj/LaunchScreen.storyboard` 수정

### 6. iOS 빌드 설정

`ios/Podfile`에서 최소 iOS 버전 설정:

```ruby
platform :ios, '12.0'  # 또는 필요한 최소 버전
```

### 7. iOS 스타일 UI 사용 (선택사항)

현재 프로젝트는 Material Design을 사용하고 있지만, iOS 네이티브 스타일을 원한다면:

- `CupertinoApp` 사용
- `CupertinoButton`, `CupertinoTextField` 등 사용
- `lib/core/theme/app_theme.dart`에 Cupertino 테마 추가됨

## 프로젝트 구조 개선사항

### 추가된 파일

1. **`lib/core/platform/platform_config.dart`**
   - iOS 플랫폼별 설정 관리
   - 네트워크 URL 설정

2. **`lib/shared/widgets/ios_loading_indicator.dart`**
   - iOS 스타일 로딩 인디케이터
   - 플랫폼에 따라 자동으로 적절한 스타일 사용

### 수정된 파일

1. **`lib/core/theme/app_theme.dart`**
   - Cupertino 테마 추가
   - 플랫폼 감지 기능 추가

## 개발 워크플로우

### 1. 초기 설정

```bash
# Flutter 프로젝트에 iOS 플랫폼 추가
flutter create --platforms=ios .

# 의존성 설치
flutter pub get

# iOS Pod 설치
cd ios && pod install && cd ..
```

### 2. 개발 환경 실행

```bash
# iOS 시뮬레이터에서 실행
flutter run -d ios

# 특정 시뮬레이터 선택
flutter devices  # 사용 가능한 디바이스 확인
flutter run -d "iPhone 15 Pro"
```

### 3. 실제 기기에서 테스트

1. Xcode에서 프로젝트 열기: `open ios/Runner.xcworkspace`
2. Signing & Capabilities에서 개발자 계정 설정
3. USB로 기기 연결 후 실행

### 4. 빌드

```bash
# Debug 빌드
flutter build ios --debug

# Release 빌드
flutter build ios --release
```

## iOS 특화 고려사항

### 1. 키체인 사용 (보안 토큰 저장)

현재는 `shared_preferences`를 사용하고 있지만, iOS에서는 키체인을 사용하는 것이 더 안전합니다:

```yaml
# pubspec.yaml에 추가
dependencies:
  flutter_secure_storage: ^9.0.0
```

### 2. 푸시 알림 (필요한 경우)

```yaml
dependencies:
  firebase_messaging: ^14.7.0  # Firebase 사용 시
  # 또는
  flutter_local_notifications: ^16.0.0
```

### 3. iOS 상태바 스타일

`Info.plist`에서 상태바 스타일 설정:

```xml
<key>UIStatusBarStyle</key>
<string>UIStatusBarStyleLightContent</string>
```

## 체크리스트

- [ ] `flutter create --platforms=ios .` 실행
- [ ] `Info.plist`에 ATS 설정 추가 (개발 환경)
- [ ] 백엔드 URL 설정 확인 (`platform_config.dart`)
- [ ] iOS 시뮬레이터에서 테스트
- [ ] 실제 기기에서 테스트 (네트워크 URL 확인)
- [ ] 앱 아이콘 및 런치 스크린 설정
- [ ] 필요한 권한 추가
- [ ] Release 빌드 테스트

## 문제 해결

### 네트워크 연결 오류

1. **시뮬레이터**: `localhost` 사용 확인
2. **실제 기기**: Mac의 로컬 IP 주소 사용
3. **ATS 설정**: `Info.plist`에 HTTP 허용 설정 확인

### 빌드 오류

```bash
# Pod 캐시 정리
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

### 서명 오류

Xcode에서 Signing & Capabilities 설정 확인

## 결론

현재 프로젝트 구조는 **iOS 개발에 적합**합니다. 다음 단계만 진행하면 됩니다:

1. iOS 플랫폼 추가 (`flutter create --platforms=ios .`)
2. `Info.plist`에 네트워크 보안 설정 추가
3. 백엔드 URL 설정 (시뮬레이터 vs 실제 기기)
4. 필요한 권한 추가

프로젝트의 Dart 코드 구조는 이미 잘 구성되어 있어 iOS 전용 개발에 문제없습니다! 🎉

