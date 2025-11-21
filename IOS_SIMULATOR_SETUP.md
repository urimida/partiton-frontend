# iOS 시뮬레이터 설정 가이드

iOS 시뮬레이터에서 앱을 실행하기 위한 단계별 가이드입니다.

## 1단계: Xcode 설정

터미널에서 다음 명령어를 실행하세요 (비밀번호 입력 필요):

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

## 2단계: CocoaPods 설치

터미널에서 다음 명령어를 실행하세요 (비밀번호 입력 필요):

```bash
sudo gem install cocoapods
```

설치가 완료되면:

```bash
pod --version
```

버전이 표시되면 설치 완료입니다.

## 3단계: iOS 의존성 설치

```bash
cd /Users/urimida/Documents/partition/Frontend/ios
pod install
cd ..
```

## 4단계: iOS 시뮬레이터 열기

방법 1: 명령어로 열기
```bash
open -a Simulator
```

방법 2: Xcode에서 열기
- Xcode 실행
- 상단 메뉴: `Xcode` → `Open Developer Tool` → `Simulator`

## 5단계: Flutter 실행

시뮬레이터가 열린 후:

```bash
cd /Users/urimida/Documents/partition/Frontend
flutter run
```

또는 특정 시뮬레이터 지정:

```bash
flutter run -d "iPhone 15 Pro"
```

## 사용 가능한 시뮬레이터 확인

```bash
flutter devices
```

또는:

```bash
xcrun simctl list devices available
```

## Hot Reload 사용하기

앱이 실행되면:

1. **코드 수정**
2. **파일 저장** (`Cmd + S`)
3. **터미널에서 `r` 키 입력** → Hot Reload ⚡
4. **즉시 화면에 반영!**

## 문제 해결

### "No devices found" 오류

1. 시뮬레이터가 열려있는지 확인
2. 시뮬레이터 재시작:
   ```bash
   killall Simulator
   open -a Simulator
   ```

### CocoaPods 설치 오류

```bash
# Homebrew로 설치 (대안)
brew install cocoapods
```

### Xcode 라이선스 동의

```bash
sudo xcodebuild -license accept
```

### 빌드 오류

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

## 빠른 실행 스크립트

모든 설정이 완료되면, 다음 명령어로 바로 실행할 수 있습니다:

```bash
cd /Users/urimida/Documents/partition/Frontend
open -a Simulator
sleep 3
flutter run
```

## 완료 체크리스트

- [ ] Xcode 설정 완료 (`xcode-select --switch`)
- [ ] CocoaPods 설치 완료 (`pod --version`)
- [ ] iOS 의존성 설치 완료 (`pod install`)
- [ ] 시뮬레이터 열기
- [ ] `flutter run` 실행 성공
- [ ] Hot Reload 작동 확인 (`r` 키)

## 다음 단계

설정이 완료되면:

```bash
cd /Users/urimida/Documents/partition/Frontend
flutter run
```

앱이 실행되면 코드를 수정하고 `r` 키를 눌러 Hot Reload를 사용하세요! 🚀


