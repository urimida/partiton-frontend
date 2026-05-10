# Flutter 디버깅 가이드

## 빠른 시작

### 1. 시뮬레이터에 앱 띄우기

```bash
cd /Users/urimida/Documents/partition/Frontend
open -a Simulator  # 시뮬레이터 열기 (이미 켜져 있으면 생략)
flutter run        # 앱 실행
```

### 2. Hot Reload 사용

앱 실행 중:

- **`r`** 키 → Hot Reload (빠른 새로고침, 상태 유지)
- **`R`** 키 → Hot Restart (전체 재시작)
- **`q`** 키 → 앱 종료

## Cursor/VS Code에서 디버깅

### 브레이크포인트 설정

1. 코드 줄 번호 왼쪽 회색 영역 클릭 → 빨간 점(브레이크포인트) 생성
2. 상단 메뉴: **Run and Debug** (F5) 또는 왼쪽 사이드바의 디버그 아이콘 클릭
3. "Flutter (Debug)" 선택

### 디버깅 단축키

- **F5**: 디버깅 시작/계속
- **F9**: 브레이크포인트 토글
- **F10**: Step Over (한 줄씩 실행)
- **F11**: Step Into (함수 안으로 들어가기)
- **Shift + F11**: Step Out (함수 밖으로 나오기)
- **Shift + F5**: 디버깅 중지

### 디버깅 패널

디버깅 중 다음 정보를 확인할 수 있습니다:

- **Variables**: 현재 스코프의 모든 변수 값
- **Watch**: 특정 변수/표현식 감시
- **Call Stack**: 함수 호출 스택
- **Breakpoints**: 설정한 브레이크포인트 목록
- **Debug Console**: print 로그 및 에러 메시지

## 디버깅 방법

### 1. Print 디버깅

기본 print 사용:

```dart
print('여기까지 들어옴');
print('사용자 이메일: $email');
```

디버그 헬퍼 사용 (권장):

```dart
import 'package:partition_app/shared/utils/debug_helper.dart';

DebugHelper.log('로그인 시도');
DebugHelper.logApiRequest('POST', '/auth/login', data: {'email': email});
DebugHelper.logError('로그인 실패', error: e);
```

### 2. 브레이크포인트 디버깅

중단하고 싶은 줄에 브레이크포인트 설정:

```dart
Future<void> _handleLogin() async {
  // 여기에 브레이크포인트 설정
  final authProvider = context.read<AuthProvider>();
  final success = await authProvider.login(...);
  // Variables 패널에서 success 값 확인 가능
}
```

### 3. 조건부 브레이크포인트

특정 조건에서만 멈추고 싶을 때:

1. 브레이크포인트 우클릭
2. "Edit Breakpoint" 선택
3. 조건 입력 (예: `email == "test@example.com"`)

## 주요 디버깅 포인트

### 인증 플로우

**로그인 화면** (`lib/features/auth/screens/login_screen.dart`):

```dart
Future<void> _handleLogin() async {
  DebugHelper.log('로그인 버튼 클릭');
  DebugHelper.log('이메일: ${_emailController.text}');

  final authProvider = context.read<AuthProvider>();
  final success = await authProvider.login(...);

  DebugHelper.log('로그인 결과: $success');
  // 브레이크포인트 여기서 멈춰서 success 값 확인
}
```

**인증 Provider** (`lib/features/auth/providers/auth_provider.dart`):

```dart
Future<bool> login(String email, String password) async {
  DebugHelper.logStateChange('AuthProvider', 'login 시작');
  DebugHelper.log('입력된 이메일: $email');

  // 더미 사용자 생성 부분에 브레이크포인트
  _user = UserModel(...);

  DebugHelper.logStateChange('AuthProvider', 'login 완료');
  return true;
}
```

### API 호출 (나중에 백엔드 연동 시)

**API Client** (`lib/core/network/api_client.dart`):

```dart
Future<Response> get(String path, ...) async {
  DebugHelper.logApiRequest('GET', path);

  try {
    final response = await _dio.get(...);
    DebugHelper.logApiResponse(path, response.statusCode, response.data);
    return response;
  } catch (e) {
    DebugHelper.logError('API 호출 실패', error: e);
    rethrow;
  }
}
```

### 파티션 목록 로딩

**Partition Provider** (`lib/features/partition/providers/partition_provider.dart`):

```dart
Future<void> loadPartitions() async {
  DebugHelper.log('파티션 목록 로딩 시작');

  try {
    _partitions = await _partitionService.getPartitions();
    DebugHelper.log('파티션 개수: ${_partitions.length}');
    // 브레이크포인트로 _partitions 내용 확인
  } catch (e) {
    DebugHelper.logError('파티션 로딩 실패', error: e);
  }
}
```

## 에러 찾기

### 런타임 에러

터미널에서 빨간 글씨로 표시됩니다:

```
Error: ...
Stack trace:
  ...
```

### 레이아웃 에러

시뮬레이터 화면에 노란/빨간 줄이 표시되고, 터미널에 상세 로그:

```
RenderFlex overflowed by 42 pixels on the right
```

해결: `SingleChildScrollView` 추가 또는 `Expanded`/`Flexible` 사용

### 네트워크 에러

API 호출 실패 시:

```dart
DebugHelper.logApiRequest('POST', '/auth/login');
// 터미널에서 요청 내용 확인
DebugHelper.logApiResponse('/auth/login', response.statusCode, response.data);
// 응답 내용 확인
```

## 유용한 디버깅 팁

### 1. 위젯 빌드 추적

```dart
@override
Widget build(BuildContext context) {
  DebugHelper.logBuild('LoginScreen');
  // 불필요한 리빌드 확인 가능
  return ...
}
```

### 2. 상태 변경 추적

```dart
void _setLoading(bool value) {
  DebugHelper.logStateChange('AuthProvider', 'isLoading: $value');
  _isLoading = value;
  notifyListeners();
}
```

### 3. 네트워크 요청/응답 전체 로깅

`ApiClient`에 이미 로깅이 포함되어 있습니다. 터미널에서 확인하세요.

### 4. 변수 값 확인

브레이크포인트에서 Variables 패널을 사용하거나:

```dart
DebugHelper.log('현재 사용자: ${_user?.email}');
DebugHelper.log('파티션 목록: ${_partitions.map((p) => p.name).join(", ")}');
```

## Flutter DevTools (고급)

더 상세한 분석이 필요하면:

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

브라우저에서 열리고, 앱 실행 중 연결하면:

- 위젯 트리 시각화
- 성능 프로파일링
- 메모리 사용량 확인
- 네트워크 요청 모니터링

## 문제 해결

### 디버거가 연결되지 않을 때

```bash
flutter clean
flutter pub get
flutter run
```

### 브레이크포인트가 작동하지 않을 때

1. Debug 모드로 실행 중인지 확인 (Release 모드에서는 작동 안 함)
2. Cursor/VS Code 재시작
3. Flutter 확장 프로그램 재설치

### 로그가 너무 많을 때

```dart
// 특정 조건에서만 로그
if (kDebugMode && someCondition) {
  DebugHelper.log('중요한 로그만');
}
```

## 빠른 체크리스트

- [ ] 시뮬레이터 실행 중
- [ ] `flutter run` 성공
- [ ] Hot Reload 작동 (`r` 키)
- [ ] Cursor에서 브레이크포인트 설정 가능
- [ ] Debug Console에서 로그 확인 가능
- [ ] Variables 패널에서 변수 값 확인 가능

이제 개발자 모드로 완전히 전환되었습니다! 🚀
