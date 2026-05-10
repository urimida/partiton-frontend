# 귀가 공유 기능 — 백엔드 구현 가이드

> Flutter 앱 구현이 완료된 상태입니다.  
> 이 문서는 Spring Boot 서버에 귀가 공유 기능을 추가하기 위한 단계별 가이드입니다.

---

## 목차

1. [기능 개요 및 흐름](#1-기능-개요-및-흐름)
2. [API 명세 (3개 엔드포인트)](#2-api-명세)
3. [DB 테이블 설계](#3-db-테이블-설계)
4. [Entity 구현](#4-entity-구현)
5. [Repository 구현](#5-repository-구현)
6. [DTO 구현](#6-dto-구현)
7. [Service 구현](#7-service-구현)
8. [Controller 구현](#8-controller-구현)
9. [FCM 알림 연동](#9-fcm-알림-연동)
10. [중복 알림 방지 로직](#10-중복-알림-방지-로직)
11. [구현 순서 요약](#11-구현-순서-요약)
12. [테스트 방법](#12-테스트-방법)

---

## 1. 기능 개요 및 흐름

### 전체 흐름

```
Flutter 앱 (사용자 A)
  │
  │  1. 귀가 공유 토글 ON
  │  2. 집 위치 등록 (현재 GPS → 서버 저장)
  │  3. 위치 스트림 감시 (geolocator)
  │  4. 집 반경 300m 진입 감지
  │
  ▼
POST /api/households/location-events/near-home
  │
  ▼
Spring Boot 서버
  │  1. 요청한 사용자 A 확인
  │  2. A의 가구(household) 조회
  │  3. A가 위치 공유에 동의했는지 확인
  │  4. 30분 내 중복 이벤트인지 확인
  │  5. 같은 가구의 다른 멤버 FCM 토큰 조회
  │  6. FCM 푸시 알림 발송
  │
  ▼
룸메이트 기기에 푸시 알림:
  "룸메이트가 집 근처에 있는 것 같아요."
```

### 공유 정책

- 정확한 좌표 또는 이동 경로는 공유하지 않습니다.
- **"집 근처 도착 이벤트"만** 룸메이트에게 전달합니다.
- 사용자가 동의한 경우에만 이벤트를 발송합니다.
- **30분 쿨다운**: 같은 사용자의 연속 알림을 방지합니다.

---

## 2. API 명세

Flutter 앱은 아래 3개의 엔드포인트를 호출합니다.

---

### 2-1. 위치 공유 동의 저장

```
POST /api/households/location-consent
Authorization: Bearer {JWT}
Content-Type: application/json
```

**Request Body**

```json
{
  "agreed": true
}
```

**Response (성공)**

```json
{
  "isSuccess": true,
  "code": "LOCATION2001",
  "message": "위치 공유 동의가 저장되었습니다.",
  "result": {
    "userId": 1,
    "householdId": 3,
    "agreed": true
  }
}
```

---

### 2-2. 집 위치 저장

```
POST /api/households/home-location
Authorization: Bearer {JWT}
Content-Type: application/json
```

**Request Body**

```json
{
  "lat": 37.12345,
  "lng": 127.12345,
  "radius": 300
}
```

**Response (성공)**

```json
{
  "isSuccess": true,
  "code": "LOCATION2002",
  "message": "집 위치가 저장되었습니다.",
  "result": {
    "householdId": 3,
    "lat": 37.12345,
    "lng": 127.12345,
    "radius": 300
  }
}
```

---

### 2-3. 집 근처 진입 이벤트 전송 ⭐ 핵심

```
POST /api/households/location-events/near-home
Authorization: Bearer {JWT}
Content-Type: application/json
```

**Request Body**

```json
{
  "eventType": "entered_home_area"
}
```

**Response (성공)**

```json
{
  "isSuccess": true,
  "code": "LOCATION2003",
  "message": "룸메이트에게 집 근처 알림을 보냈습니다.",
  "result": {
    "notifiedUserCount": 2
  }
}
```

**Response (30분 내 중복 요청)**

```json
{
  "isSuccess": true,
  "code": "LOCATION2004",
  "message": "최근에 이미 알림을 보냈습니다.",
  "result": {
    "notifiedUserCount": 0
  }
}
```

---

## 3. DB 테이블 설계

기존 `households` 및 `users` 테이블과 함께 아래 테이블 2개를 추가합니다.

### location_sharing_consents (위치 공유 동의)

```sql
CREATE TABLE location_sharing_consents (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id      BIGINT      NOT NULL,
    household_id BIGINT      NOT NULL,
    agreed       BOOLEAN     NOT NULL DEFAULT FALSE,
    agreed_at    DATETIME,
    created_at   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_consent_user_household (user_id, household_id),
    FOREIGN KEY (user_id)      REFERENCES users(id)      ON DELETE CASCADE,
    FOREIGN KEY (household_id) REFERENCES households(id) ON DELETE CASCADE
);
```

### home_locations (가구 집 위치)

```sql
CREATE TABLE home_locations (
    id           BIGINT         AUTO_INCREMENT PRIMARY KEY,
    household_id BIGINT         NOT NULL UNIQUE,
    lat          DECIMAL(10, 7) NOT NULL,
    lng          DECIMAL(10, 7) NOT NULL,
    radius       INT            NOT NULL DEFAULT 300,  -- 미터 단위
    created_at   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (household_id) REFERENCES households(id) ON DELETE CASCADE
);
```

### near_home_events (집 근처 진입 이벤트 — 중복 방지용)

```sql
CREATE TABLE near_home_events (
    id           BIGINT   AUTO_INCREMENT PRIMARY KEY,
    user_id      BIGINT   NOT NULL,
    household_id BIGINT   NOT NULL,
    event_type   VARCHAR(50) NOT NULL DEFAULT 'entered_home_area',
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)      REFERENCES users(id)      ON DELETE CASCADE,
    FOREIGN KEY (household_id) REFERENCES households(id) ON DELETE CASCADE
);
```

---

## 4. Entity 구현

### LocationSharingConsent.java

```java
@Entity
@Table(name = "location_sharing_consents")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class LocationSharingConsent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "household_id", nullable = false)
    private Household household;

    @Column(nullable = false)
    private boolean agreed;

    @Column(name = "agreed_at")
    private LocalDateTime agreedAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public static LocationSharingConsent create(User user, Household household, boolean agreed) {
        LocationSharingConsent consent = new LocationSharingConsent();
        consent.user = user;
        consent.household = household;
        consent.agreed = agreed;
        consent.agreedAt = agreed ? LocalDateTime.now() : null;
        return consent;
    }

    public void update(boolean agreed) {
        this.agreed = agreed;
        this.agreedAt = agreed ? LocalDateTime.now() : null;
    }
}
```

### HomeLocation.java

```java
@Entity
@Table(name = "home_locations")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class HomeLocation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "household_id", nullable = false, unique = true)
    private Household household;

    @Column(nullable = false, precision = 10, scale = 7)
    private BigDecimal lat;

    @Column(nullable = false, precision = 10, scale = 7)
    private BigDecimal lng;

    @Column(nullable = false)
    private int radius = 300;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public static HomeLocation create(Household household, double lat, double lng, int radius) {
        HomeLocation hl = new HomeLocation();
        hl.household = household;
        hl.lat = BigDecimal.valueOf(lat);
        hl.lng = BigDecimal.valueOf(lng);
        hl.radius = radius;
        return hl;
    }

    public void update(double lat, double lng, int radius) {
        this.lat = BigDecimal.valueOf(lat);
        this.lng = BigDecimal.valueOf(lng);
        this.radius = radius;
    }
}
```

### NearHomeEvent.java

```java
@Entity
@Table(name = "near_home_events")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class NearHomeEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "household_id", nullable = false)
    private Household household;

    @Column(name = "event_type", nullable = false)
    private String eventType;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    public static NearHomeEvent create(User user, Household household, String eventType) {
        NearHomeEvent event = new NearHomeEvent();
        event.user = user;
        event.household = household;
        event.eventType = eventType;
        return event;
    }
}
```

---

## 5. Repository 구현

### LocationSharingConsentRepository.java

```java
public interface LocationSharingConsentRepository extends JpaRepository<LocationSharingConsent, Long> {

    Optional<LocationSharingConsent> findByUserAndHousehold(User user, Household household);

    // 특정 가구에서 동의한 사용자 목록 (A 제외)
    @Query("""
        SELECT c FROM LocationSharingConsent c
        WHERE c.household = :household
          AND c.agreed = true
          AND c.user != :excludeUser
        """)
    List<LocationSharingConsent> findAgreedMembersExcluding(
            @Param("household") Household household,
            @Param("excludeUser") User excludeUser
    );
}
```

### HomeLocationRepository.java

```java
public interface HomeLocationRepository extends JpaRepository<HomeLocation, Long> {

    Optional<HomeLocation> findByHousehold(Household household);
}
```

### NearHomeEventRepository.java

```java
public interface NearHomeEventRepository extends JpaRepository<NearHomeEvent, Long> {

    // 특정 사용자의 특정 가구 이벤트 중 cutoff 이후 가장 최근 이벤트 조회
    @Query("""
        SELECT e FROM NearHomeEvent e
        WHERE e.user = :user
          AND e.household = :household
          AND e.createdAt >= :cutoff
        ORDER BY e.createdAt DESC
        """)
    List<NearHomeEvent> findRecentEvents(
            @Param("user") User user,
            @Param("household") Household household,
            @Param("cutoff") LocalDateTime cutoff
    );
}
```

---

## 6. DTO 구현

### Request DTO

```java
// 위치 공유 동의
public record LocationConsentRequest(boolean agreed) {}

// 집 위치 저장
public record HomeLocationRequest(
        double lat,
        double lng,
        int radius
) {
    public HomeLocationRequest {
        if (radius <= 0) radius = 300;
    }
}

// 집 근처 진입 이벤트
public record NearHomeEventRequest(String eventType) {}
```

### Response DTO

```java
// 위치 공유 동의 응답
public record LocationConsentResponse(Long userId, Long householdId, boolean agreed) {}

// 집 위치 저장 응답
public record HomeLocationResponse(Long householdId, double lat, double lng, int radius) {}

// 집 근처 이벤트 응답
public record NearHomeEventResponse(int notifiedUserCount) {}
```

### 공통 응답 래퍼

기존 프로젝트에서 사용하는 `ApiResponse` 형식을 그대로 사용합니다.

```json
{
  "isSuccess": true,
  "code": "LOCATION2003",
  "message": "...",
  "result": { ... }
}
```

---

## 7. Service 구현

### HomeShareService.java

```java
@Service
@Transactional
@RequiredArgsConstructor
public class HomeShareService {

    private static final Duration NOTIFICATION_COOLDOWN = Duration.ofMinutes(30);

    private final LocationSharingConsentRepository consentRepository;
    private final HomeLocationRepository homeLocationRepository;
    private final NearHomeEventRepository nearHomeEventRepository;
    private final FcmNotificationService fcmNotificationService;
    // 기존 UserRepository, HouseholdRepository 주입 (프로젝트에 맞게 수정)
    private final UserRepository userRepository;
    private final HouseholdRepository householdRepository;
    private final HouseholdMemberRepository householdMemberRepository;

    // ── 위치 공유 동의 저장 ──────────────────────────────────────────────────

    public LocationConsentResponse saveConsent(Long userId, boolean agreed) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));
        Household household = getHouseholdByUser(user);

        LocationSharingConsent consent = consentRepository
                .findByUserAndHousehold(user, household)
                .orElse(null);

        if (consent == null) {
            consent = LocationSharingConsent.create(user, household, agreed);
            consentRepository.save(consent);
        } else {
            consent.update(agreed);
        }

        return new LocationConsentResponse(userId, household.getId(), agreed);
    }

    // ── 집 위치 저장 ─────────────────────────────────────────────────────────

    public HomeLocationResponse saveHomeLocation(Long userId, double lat, double lng, int radius) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));
        Household household = getHouseholdByUser(user);

        HomeLocation homeLocation = homeLocationRepository
                .findByHousehold(household)
                .orElse(null);

        if (homeLocation == null) {
            homeLocation = HomeLocation.create(household, lat, lng, radius);
            homeLocationRepository.save(homeLocation);
        } else {
            homeLocation.update(lat, lng, radius);
        }

        return new HomeLocationResponse(household.getId(), lat, lng, radius);
    }

    // ── 집 근처 진입 이벤트 처리 ─────────────────────────────────────────────

    @Transactional
    public NearHomeEventResponse handleNearHomeEvent(Long userId, String eventType) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));
        Household household = getHouseholdByUser(user);

        // 1. 요청한 사용자가 위치 공유에 동의했는지 확인
        boolean hasConsent = consentRepository.findByUserAndHousehold(user, household)
                .map(LocationSharingConsent::isAgreed)
                .orElse(false);

        if (!hasConsent) {
            return new NearHomeEventResponse(0);
        }

        // 2. 30분 쿨다운 — 중복 알림 방지
        LocalDateTime cutoff = LocalDateTime.now().minus(NOTIFICATION_COOLDOWN);
        List<NearHomeEvent> recentEvents = nearHomeEventRepository
                .findRecentEvents(user, household, cutoff);

        if (!recentEvents.isEmpty()) {
            // 30분 내 이미 전송된 이벤트 존재
            return new NearHomeEventResponse(0);
        }

        // 3. 이벤트 기록 저장
        NearHomeEvent event = NearHomeEvent.create(user, household, eventType);
        nearHomeEventRepository.save(event);

        // 4. 알림을 받을 룸메이트 목록 조회 (동의한 사람만)
        List<LocationSharingConsent> recipients = consentRepository
                .findAgreedMembersExcluding(household, user);

        if (recipients.isEmpty()) {
            return new NearHomeEventResponse(0);
        }

        // 5. 발신자 이름 조회
        String senderName = user.getName(); // User 엔티티 필드명에 맞게 수정

        // 6. FCM 푸시 알림 발송
        int notifiedCount = 0;
        for (LocationSharingConsent consent : recipients) {
            String fcmToken = consent.getUser().getFcmToken(); // FCM 토큰 필드명에 맞게 수정
            if (fcmToken != null && !fcmToken.isBlank()) {
                fcmNotificationService.sendNearHomeNotification(fcmToken, senderName);
                notifiedCount++;
            }
        }

        return new NearHomeEventResponse(notifiedCount);
    }

    // ── 내부 유틸 ─────────────────────────────────────────────────────────────

    private Household getHouseholdByUser(User user) {
        // 기존 프로젝트의 가구 조회 방식에 맞게 수정하세요.
        // 예시: householdMemberRepository.findByUser(user).getHousehold()
        return householdMemberRepository.findByUser(user)
                .map(HouseholdMember::getHousehold)
                .orElseThrow(() -> new RuntimeException("가입된 가구가 없습니다."));
    }
}
```

---

## 8. Controller 구현

### HomeShareController.java

```java
@RestController
@RequestMapping("/api/households")
@RequiredArgsConstructor
public class HomeShareController {

    private final HomeShareService homeShareService;

    // ── 위치 공유 동의 저장 ──────────────────────────────────────────────────

    @PostMapping("/location-consent")
    public ResponseEntity<?> saveConsent(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody LocationConsentRequest request
    ) {
        Long userId = extractUserId(userDetails);
        LocationConsentResponse result = homeShareService.saveConsent(userId, request.agreed());

        return ResponseEntity.ok(ApiResponse.success(
                "LOCATION2001",
                "위치 공유 동의가 저장되었습니다.",
                result
        ));
    }

    // ── 집 위치 저장 ─────────────────────────────────────────────────────────

    @PostMapping("/home-location")
    public ResponseEntity<?> saveHomeLocation(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody HomeLocationRequest request
    ) {
        Long userId = extractUserId(userDetails);
        HomeLocationResponse result = homeShareService.saveHomeLocation(
                userId, request.lat(), request.lng(), request.radius()
        );

        return ResponseEntity.ok(ApiResponse.success(
                "LOCATION2002",
                "집 위치가 저장되었습니다.",
                result
        ));
    }

    // ── 집 근처 진입 이벤트 ──────────────────────────────────────────────────

    @PostMapping("/location-events/near-home")
    public ResponseEntity<?> handleNearHomeEvent(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody NearHomeEventRequest request
    ) {
        Long userId = extractUserId(userDetails);
        NearHomeEventResponse result = homeShareService.handleNearHomeEvent(
                userId, request.eventType()
        );

        String message = result.notifiedUserCount() > 0
                ? "룸메이트에게 집 근처 알림을 보냈습니다."
                : "최근에 이미 알림을 보냈습니다.";

        String code = result.notifiedUserCount() > 0 ? "LOCATION2003" : "LOCATION2004";

        return ResponseEntity.ok(ApiResponse.success(code, message, result));
    }

    // ── 유틸 ─────────────────────────────────────────────────────────────────

    private Long extractUserId(UserDetails userDetails) {
        // 기존 프로젝트의 JWT/UserDetails 구조에 맞게 수정하세요.
        // 예: ((CustomUserDetails) userDetails).getUserId()
        return Long.parseLong(userDetails.getUsername());
    }
}
```

---

## 9. FCM 알림 연동

기존 프로젝트에 FCM 발송 로직이 이미 있다면 해당 서비스를 재사용합니다.  
없다면 아래를 참고해 추가합니다.

### build.gradle 의존성 (없는 경우만 추가)

```groovy
implementation 'com.google.firebase:firebase-admin:9.2.0'
```

### FcmNotificationService.java

```java
@Service
@RequiredArgsConstructor
public class FcmNotificationService {

    /**
     * 룸메이트에게 "집 근처 도착" 알림을 전송합니다.
     *
     * @param fcmToken    수신자 FCM 토큰
     * @param senderName  발신자 이름 (예: "유림")
     */
    public void sendNearHomeNotification(String fcmToken, String senderName) {
        try {
            Message message = Message.builder()
                    .setToken(fcmToken)
                    .setNotification(Notification.builder()
                            .setTitle("파티션")
                            .setBody("룸메이트가 집 근처에 있는 것 같아요.")
                            .build())
                    .putData("type", "NEAR_HOME_ARRIVAL")
                    .putData("senderName", senderName)
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
        } catch (FirebaseMessagingException e) {
            // 유효하지 않은 토큰 등은 무시 (로그만 남김)
        }
    }
}
```

### 알림 문구 가이드

| 구분 | 문구 | 이유 |
|------|------|------|
| ✅ 권장 | `"룸메이트가 집 근처에 있는 것 같아요."` | 정확한 위치 노출 없이 자연스러움 |
| ✅ 권장 | `"유림님이 귀가 중인 것 같아요."` | 이름 포함, 친근한 표현 |
| ❌ 비권장 | `"유림님이 서울시 마포구 OO에 있습니다."` | 정확한 위치 노출 — 개인정보 부담 |

---

## 10. 중복 알림 방지 로직

Service의 `handleNearHomeEvent` 내부에 이미 구현되어 있습니다.

```
요청 수신
    │
    ▼
30분 이내 같은 사용자+가구 이벤트가 있는가?
    │
    ├── YES → { notifiedUserCount: 0 } 반환 (알림 미발송)
    │
    └── NO  → 이벤트 DB 저장 → FCM 발송 → { notifiedUserCount: N } 반환
```

**쿨다운 기간 조정**

`HomeShareService.java`의 상수 한 줄만 수정하면 됩니다:

```java
// 현재 30분
private static final Duration NOTIFICATION_COOLDOWN = Duration.ofMinutes(30);

// 1시간으로 늘리려면:
private static final Duration NOTIFICATION_COOLDOWN = Duration.ofHours(1);
```

---

## 11. 구현 순서 요약

아래 순서대로 구현하면 의존성 문제 없이 진행할 수 있습니다.

```
Step 1. DB 마이그레이션
        ├── location_sharing_consents 테이블 생성
        ├── home_locations 테이블 생성
        └── near_home_events 테이블 생성

Step 2. Entity 추가
        ├── LocationSharingConsent.java
        ├── HomeLocation.java
        └── NearHomeEvent.java

Step 3. Repository 추가
        ├── LocationSharingConsentRepository.java
        ├── HomeLocationRepository.java
        └── NearHomeEventRepository.java

Step 4. DTO 추가
        ├── LocationConsentRequest / Response
        ├── HomeLocationRequest / Response
        └── NearHomeEventRequest / Response

Step 5. Service 구현
        └── HomeShareService.java

Step 6. FCM 알림 서비스 확인 또는 추가
        └── FcmNotificationService.java (기존 서비스 재사용 권장)

Step 7. Controller 추가
        └── HomeShareController.java

Step 8. 테스트
        └── Postman 또는 Flutter 앱으로 E2E 확인
```

---

## 12. 테스트 방법

### Postman으로 테스트하기

**① 로그인해서 JWT 획득**

```
POST /api/auth/login
{
  "email": "test@test.com",
  "password": "password"
}
→ accessToken 복사
```

**② 집 위치 등록**

```
POST /api/households/home-location
Authorization: Bearer {accessToken}

{
  "lat": 37.12345,
  "lng": 127.12345,
  "radius": 300
}
```

**③ 위치 공유 동의**

```
POST /api/households/location-consent
Authorization: Bearer {accessToken}

{
  "agreed": true
}
```

**④ 집 근처 진입 이벤트 전송**

```
POST /api/households/location-events/near-home
Authorization: Bearer {accessToken}

{
  "eventType": "entered_home_area"
}

→ 룸메이트 기기에 FCM 푸시 수신 확인
```

**⑤ 중복 방지 테스트**

④를 30분 이내에 다시 호출하면 `notifiedUserCount: 0` 이 반환되어야 합니다.

---

### Flutter 앱으로 E2E 테스트하기

1. 홈 탭의 **귀가 공유 토글** 켜기
2. "현재 위치를 집으로 설정" → 현재 GPS 위치 저장됨
3. 앱을 켜둔 채로 **집 반경 300m 밖**으로 이동
4. 다시 **집 반경 300m 안**으로 돌아오면 자동으로 이벤트 전송
5. 룸메이트 기기에서 푸시 알림 수신 확인

> **시뮬레이터 테스트**: iOS 시뮬레이터에서는 실제 GPS 이동이 없으므로  
> Xcode의 **Features > Location > Custom Location**으로 좌표를 수동 변경해 테스트할 수 있습니다.

---

## 참고 — Flutter 앱에서 호출하는 위치

| 이벤트 | 호출 시점 | 파일 |
|--------|-----------|------|
| 집 위치 저장 | 다이얼로그에서 "현재 위치 설정" 버튼 탭 | `home_share_provider.dart` |
| 위치 공유 동의 | 귀가 공유 토글 ON/OFF | `home_share_provider.dart` |
| 집 근처 진입 이벤트 | geolocator 스트림에서 집 반경 진입 감지 시 | `home_share_provider.dart` |

서버 응답이 실패하더라도 Flutter 앱은 `catchError`로 무시하고 정상 동작합니다.  
백엔드 구현 전까지는 앱의 로컬 기능(토글·위치 설정)은 정상적으로 사용 가능합니다.
