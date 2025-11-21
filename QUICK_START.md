# 빠른 시작 가이드

## 현재 상황

iOS 시뮬레이터가 감지되지 않습니다. 다음 중 하나를 선택하세요:

## 옵션 1: macOS에서 실행 (가장 빠름) ⚡

```bash
cd Frontend
flutter run -d macos
```

또는:

```bash
cd Frontend
flutter run -d macos --hot
```

**Hot Reload 사용:**
- 코드 수정 후 터미널에서 `r` 키 입력
- 또는 파일 저장 시 자동 반영 (VS Code)

## 옵션 2: Chrome에서 실행 (웹)

```bash
cd Frontend
flutter run -d chrome
```

## 옵션 3: iOS 시뮬레이터 설정 (시간 필요)

### 1. Xcode 설치 확인

```bash
xcode-select --version
```

만약 오류가 나면:
- App Store에서 Xcode 설치
- 또는 Command Line Tools 설치:
  ```bash
  xcode-select --install
  ```

### 2. Xcode 라이선스 동의

```bash
sudo xcodebuild -license accept
```

### 3. iOS 시뮬레이터 열기

```bash
open -a Simulator
```

### 4. Flutter 실행

```bash
cd Frontend
flutter run
```

## 추천: 지금 바로 시작하기

**가장 빠른 방법 - macOS에서 실행:**

```bash
cd /Users/urimida/Documents/partition/Frontend
flutter run -d macos
```

앱이 실행되면:
1. 코드 수정
2. 파일 저장 (`Cmd + S`)
3. 터미널에서 `r` 키 입력
4. **즉시 확인!** ⚡

## Hot Reload 단축키

- `r` - Hot Reload (빠름, 상태 유지)
- `R` - Hot Restart (전체 재시작)
- `q` - 앱 종료

## 문제 해결

### "No devices found" 오류

```bash
# 사용 가능한 디바이스 확인
flutter devices

# 특정 디바이스로 실행
flutter run -d macos      # macOS
flutter run -d chrome      # Chrome
flutter run -d ios         # iOS (시뮬레이터 필요)
```

### 의존성 오류

```bash
cd Frontend
flutter clean
flutter pub get
```

## 다음 단계

1. **지금**: macOS에서 실행해서 개발 시작
2. **나중**: iOS 시뮬레이터 설정 후 iOS에서 테스트

macOS에서도 Hot Reload가 완벽하게 작동합니다! 🚀

