# Flutter Hot Reload 가이드

시뮬레이터에서 코드 변경사항을 바로바로 확인하는 방법입니다.

## 🚀 빠른 시작

### 1. 앱 실행 (Hot Reload 활성화)

터미널에서 다음 명령어 실행:

```bash
cd /Users/urimida/Documents/partition/Frontend
flutter run
```

또는 특정 iOS 시뮬레이터 지정:

```bash
flutter run -d "iPhone 15 Pro"
```

### 2. Hot Reload 사용법

앱이 실행 중일 때:

- **`r` 키** - Hot Reload (빠른 새로고침)
- **`R` 키** - Hot Restart (전체 재시작)
- **`q` 키** - 앱 종료

## 📝 VS Code에서 사용하기

### 자동 Hot Reload 설정

1. **VS Code 확장 설치**
   - Flutter 확장 설치 (이미 설치되어 있을 수 있음)

2. **실행 및 디버깅**
   - `F5` 키를 누르거나
   - 디버그 패널에서 "Run and Debug" 선택
   - "Flutter" 선택

3. **코드 수정 시 자동 Hot Reload**
   - 파일을 저장하면 (`Cmd + S`) 자동으로 Hot Reload
   - 또는 `Cmd + Shift + P` → "Flutter: Hot Reload"

### 수동 Hot Reload
- `Cmd + Shift + P` → "Flutter: Hot Reload"
- 또는 터미널에서 `r` 입력

## 🎯 Android Studio에서 사용하기

1. **실행**
   - 상단의 실행 버튼 클릭
   - 또는 `Shift + F10`

2. **Hot Reload**
   - 코드 수정 후 저장하면 자동 Hot Reload
   - 또는 🔥 버튼 클릭 (Hot Reload 버튼)

3. **Hot Restart**
   - 🔄 버튼 클릭 (Hot Restart 버튼)

## ⚡ Hot Reload vs Hot Restart

### Hot Reload (`r`)
- **빠름** (1-2초)
- 상태 유지 (변수 값, 스크롤 위치 등)
- **제한사항:**
  - `main()` 함수 변경 불가
  - 전역 변수 초기화 불가
  - `initState()` 변경 불가

### Hot Restart (`R`)
- **느림** (5-10초)
- 앱 전체 재시작
- 상태 초기화
- **모든 변경사항 반영 가능**

## 🔧 최적화 팁

### 1. 빠른 Hot Reload를 위한 설정

`main.dart`에서 불필요한 초기화 제거:

```dart
void main() {
  // WidgetsFlutterBinding.ensureInitialized(); // 필요할 때만
  runApp(const PartitionApp());
}
```

### 2. 개발 모드 최적화

`pubspec.yaml`에 개발 의존성 확인:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```

### 3. 빌드 모드

```bash
# Debug 모드 (기본, Hot Reload 지원)
flutter run

# Release 모드 (Hot Reload 불가, 최적화됨)
flutter run --release
```

## 🐛 문제 해결

### Hot Reload가 작동하지 않는 경우

1. **앱 재시작**
   ```bash
   # 터미널에서 R 입력 (Hot Restart)
   # 또는
   flutter run
   ```

2. **캐시 정리**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **시뮬레이터 재시작**
   - 시뮬레이터 종료 후 다시 실행

### Hot Reload가 느린 경우

1. **불필요한 패키지 제거**
2. **큰 위젯을 작은 위젯으로 분리**
3. **const 위젯 사용** (성능 향상)

## 💡 실전 팁

### 빠른 개발 워크플로우

1. **터미널 두 개 사용**
   - 터미널 1: `flutter run` (앱 실행)
   - 터미널 2: 코드 편집

2. **자동 저장 설정**
   - VS Code: `"files.autoSave": "afterDelay"` 설정

3. **Hot Reload 단축키**
   - VS Code: `Cmd + Shift + P` → "Flutter: Hot Reload"
   - 또는 터미널에서 `r` 키

### 코드 작성 시 주의사항

Hot Reload가 잘 작동하도록:

```dart
// ✅ 좋은 예 (Hot Reload 가능)
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

// ❌ 나쁜 예 (Hot Reload 어려움)
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  int _counter = 0; // 이 값은 Hot Reload로 초기화 안됨
  
  @override
  void initState() {
    super.initState();
    // 이 부분은 Hot Reload로 변경 안됨
  }
}
```

## 📱 iOS 시뮬레이터 특화 팁

### 시뮬레이터 빠르게 실행

```bash
# 특정 시뮬레이터로 바로 실행
flutter run -d "iPhone 15 Pro"

# 또는 시뮬레이터 먼저 열기
open -a Simulator
flutter run
```

### 시뮬레이터 단축키
- `Cmd + K` - 시뮬레이터 화면 지우기
- `Cmd + Shift + H` - 홈 버튼

## 🎨 UI 변경사항 즉시 확인

1. **색상 변경** → Hot Reload (`r`)
2. **텍스트 변경** → Hot Reload (`r`)
3. **레이아웃 변경** → Hot Reload (`r`)
4. **새 화면 추가** → Hot Restart (`R`)
5. **라우팅 변경** → Hot Restart (`R`)

## 결론

**가장 빠른 방법:**
1. `flutter run` 실행
2. 코드 수정
3. 파일 저장 (`Cmd + S`)
4. 터미널에서 `r` 키 입력
5. **즉시 확인!** ⚡

또는 VS Code에서 `F5`로 실행하면 자동으로 Hot Reload가 활성화됩니다!

