# 빠른 디버깅 시작 가이드 ⚡

## 지금 바로 시작하기

### 1단계: 앱 실행

```bash
cd /Users/urimida/Documents/partition/Frontend
flutter run
```

시뮬레이터(iPhone 16e)가 이미 켜져 있으면 자동으로 연결됩니다!

### 2단계: Hot Reload 사용

앱 실행 중:
- 코드 수정 → 파일 저장 → 터미널에서 **`r`** 키
- 즉시 시뮬레이터에 반영! ⚡

### 3단계: 로그 확인

터미널에서 다음과 같은 로그를 볼 수 있습니다:

```
🔐 로그인 시도 시작
이메일: test@example.com
✅ 로그인 성공
사용자 ID: demo-user-001
```

## Cursor에서 브레이크포인트 사용

1. **코드 열기**: `lib/features/auth/screens/login_screen.dart`
2. **브레이크포인트 설정**: 줄 번호 왼쪽 클릭 (빨간 점)
3. **디버깅 시작**: F5 또는 상단 "Run and Debug"
4. **변수 확인**: Variables 패널에서 값 확인

## 주요 디버깅 포인트

### 로그인 플로우 추적

**로그인 화면** (`login_screen.dart`):
- 줄 26: `_handleLogin()` - 로그인 버튼 클릭 시
- 브레이크포인트 여기서 멈춰서 입력값 확인

**인증 Provider** (`auth_provider.dart`):
- 줄 18: `login()` - 실제 로그인 로직
- 줄 27: 더미 사용자 생성 부분
- Variables 패널에서 `_user` 객체 확인

## 유용한 단축키

- **`r`**: Hot Reload
- **`R`**: Hot Restart  
- **`q`**: 앱 종료
- **F5**: 디버깅 시작
- **F10**: Step Over
- **F11**: Step Into

## 문제 발생 시

터미널에 에러가 표시됩니다. 에러 메시지를 복사해서 확인하세요!

자세한 내용은 `DEBUGGING_GUIDE.md` 참고하세요.

