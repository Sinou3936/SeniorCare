# 약봄

어르신의 약 복용과 병원 일정을 관리하고, 가족이 실시간으로 현황을 확인하는 Flutter 앱입니다.  
취업 포트폴리오 겸 실사용 목적으로 제작 중입니다.

---

## 기술 스택

| 분류 | 사용 기술 |
|------|-----------|
| 프레임워크 | Flutter 3.x (Android 우선) |
| 인증 | Firebase Auth (익명 로그인) |
| 데이터베이스 | Firebase Firestore |
| 푸시 알림 | Firebase Cloud Messaging (FCM) |
| 로컬 알림 | flutter_local_notifications |
| 세션 유지 | shared_preferences |
| 서버 로직 | Firebase Cloud Functions (Node.js) |

---

## 작업 이력

### 2026-05-12 — 스플래시 / 아이콘 / UX 개선

- **앱 이름 변경** — `seniorcare` → `약봄` (AndroidManifest, main.dart 반영)
- **앱 아이콘 적용** — `app_icon.png` → `flutter_launcher_icons`로 Android 적응형 아이콘 생성
- **스플래시 화면 적용** — `splash_screen.png` → `flutter_native_splash`로 생성
- **앱 색상 테마 통일** — 메인 컬러 `#E8896A` (복숭아/코랄) 전체 적용
- **스플래시 배경색 설정** — `#FDD0B8` (연복숭아) / Android 12+ `values-v31` 수동 적용
- **스플래시 원형 크롭 제거** — Android 12+ `windowSplashScreenAnimatedIcon` 제거로 해결

---

### 2026-05-08 — KST 통일 / 약 종료일 / 달력 개선

- **KST 타임존 고정** — `kstNow()` 유틸 함수 도입, 디바이스 timezone 무관하게 서울 기준 시각 사용
- **약 복용 종료일 추가** — 약 등록/수정 화면에 종료일 선택 UI 추가, 종료된 약은 목록에서 자동 제외
- **복용 기록 생성 개선** — 날짜 단위 스킵 → 약 단위 스킵으로 변경 (새 약 등록 시 당일 기록 즉시 생성)
- **달력 즉시 반영** — `initState`에서 현재 주 7일치 로그 사전 생성, 약 등록 직후 달력 점 표시
- **달력 점 색상 개선** — 빨간 점 → 흰색 반투명 (미완료) / 초록 점 (전체 완료) 으로 변경
- **약 상세 화면 개선** — 상단 대형 이미지 컨테이너 제거, 종료일 표시 추가

---

### 2026-05-07 — Cloud Functions / 알림 화면 연동 / Google 계정 연동

- **Cloud Functions 구현** — 미복용 30분 후 보호자 FCM 푸시 (1st Gen, asia-northeast3)
- **중복 알림 방지** — `notified` 플래그로 동일 로그 재발송 차단
- **알림 내역 저장** — Cloud Functions가 `notifications` 컬렉션에 기록
- **가족 알림 화면 실데이터 연동** — `watchNotifications()` 스트림, 읽음/안읽음 구분
- **Google 계정 연동** — `linkWithCredential`로 익명 계정 → Google 계정 영구 전환

---

### 2026-05-06 — 설정 / 보호자 관리 / FCM / 세션 유지

- **설정 화면 구현** — 시니어: 내 코드 확인·갱신, 보호자 목록, 알림 ON/OFF, 데이터 초기화
- **가족 설정 화면** — 연결된 부모님 확인, 연결 해제, 모드 전환
- **보호자 관리** — 6자리 코드 연결(1시간 만료), 다중 가족 연결, 개별 해제
- **세션 유지** — `shared_preferences`로 모드/알림 설정 저장, 재실행 시 자동 복원
- **FCM 클라이언트** — 토큰 Firestore 저장, 포그라운드/백그라운드 로컬 알림 수신
- **복약 알림 스케줄링** — 약 등록 시 `flutter_local_notifications` `zonedSchedule`로 매일 반복 예약

---

### 2026-05-05 — Firebase 연동

- Firebase Auth 익명 로그인 자동 실행
- Firestore CRUD — 약(`medicines`), 복용 기록(`medicine_logs`), 병원(`appointments`)
- 6자리 영숫자 코드 발급 (`codes/{code}` 컬렉션, 1시간 만료)
- 가족 코드 입력 → 시니어-가족 uid 상호 연결 (`linkedSeniorUid` / `linkedFamilyUids`)
- 가족 홈 실데이터 연동 (`watchSeniorWeekStatus` + `watchSeniorLogsForDate`)
- 달력 실제 복용 데이터 연동 (날짜별 완료율 표시)

---

### 2026-05-04 — 초기 UI 구현

- 어르신 모드 전체 화면 — 홈(주간 달력 + 복용 현황), 약 관리, 병원, 설정
- 가족 모드 전체 화면 — 홈(부모 현황), 알림, 병원, 설정
- 약 추가 플로우 — 수동 시간 설정 UI (±30분, ±1시간 버튼)
- 병원 예약 CRUD UI 완성
- 어르신 기준 대형 글씨 / 큰 버튼 UX 적용

---

## 개발 현황

| 항목 | 상태 |
|------|------|
| 어르신 모드 UI 전체 | ✅ 완료 |
| 가족 모드 UI 전체 | ✅ 완료 |
| Firebase Auth (익명 로그인 자동 실행) | ✅ 완료 |
| Firestore CRUD (약 / 병원 / 복용기록) | ✅ 완료 |
| 6자리 코드 연결 (1시간 만료) | ✅ 완료 |
| 보호자 다중 연결 / 개별 해제 | ✅ 완료 |
| 설정 화면 (시니어 / 가족) | ✅ 완료 |
| 데이터 초기화 | ✅ 완료 |
| 앱 재실행 시 모드·알림 설정 유지 | ✅ 완료 |
| 달력 실제 데이터 연동 | ✅ 완료 |
| 달력 즉시 반영 (약 등록 직후 점 표시) | ✅ 완료 |
| 달력 점 스타일 개선 (미완료 흰색 / 완료 초록) | ✅ 완료 |
| FCM 클라이언트 (토큰 저장, 로컬 알림 수신) | ✅ 완료 |
| 복약 알림 스케줄링 (시간대별 매일 반복) | ✅ 완료 |
| Cloud Functions (미복용 30분 후 보호자 푸시) | ✅ 완료 |
| 가족 알림 화면 실데이터 연동 | ✅ 완료 |
| KST 타임존 통일 (디바이스 timezone 무관) | ✅ 완료 |
| 약 복용 종료일 (등록·수정·자동 목록 제외) | ✅ 완료 |
| 앱 브랜딩 (이름·색상·아이콘·스플래시) | ✅ 완료 |
| Google 계정 연동 (익명 → 영구 계정, linkWithCredential) | ✅ 완료 |
| 가족 앱 재실행 시 세션 유지 (코드 재입력 스킵) | 🔲 예정 |

---

## Firestore 구조

```
users/{uid}
  ├── code: "A3K9X2"
  ├── linkedSeniorUid: ""
  ├── linkedFamilyUids: []
  └── fcmToken: ""

codes/{code}
  ├── ownerUid: ""
  └── createdAt: Timestamp   # 1시간 후 만료

users/{uid}/medicines/{medicineId}
  ├── name: "혈압약"
  ├── photoUrl: ""
  ├── times: ["08:00", "21:00"]
  ├── startDate: Timestamp
  └── endDate: Timestamp | null

users/{uid}/medicine_logs/{logId}
  ├── medicineId: ""
  ├── medicineName: "혈압약"
  ├── scheduledTime: Timestamp   # KST 기준
  ├── taken: false
  └── takenAt: Timestamp | null

users/{uid}/appointments/{appointmentId}
  ├── hospitalName: "서울내과"
  ├── date: Timestamp
  └── memo: ""

users/{uid}/notifications/{notificationId}
  ├── medicineName: "혈압약"
  ├── scheduledTime: Timestamp
  ├── isRead: false
  └── createdAt: Timestamp
```

---

## 실행

```bash
flutter pub get
flutter run
```

> Firebase 연동 시 `google-services.json` 및 `lib/firebase_options.dart` 필요

---

## 라이선스

개인 포트폴리오 프로젝트입니다. 무단 배포를 금합니다.
