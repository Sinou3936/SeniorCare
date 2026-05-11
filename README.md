# SeniorCare

어르신의 약 복용과 병원 일정을 관리하고, 가족이 실시간으로 현황을 확인할 수 있는 Flutter 앱입니다.

취업 포트폴리오 겸 실사용 목적으로 제작 중입니다.

---

## 주요 기능

### 어르신 모드
- **홈** — 주간 달력 + 시간대별(아침/점심/저녁/취침) 복용 현황
- **약 관리** — 약 목록 조회, 추가(OCR 촬영 or 갤러리), 수정, 삭제
- **병원** — 예약/진료 일정 등록, 수정, 삭제, 조회
- **설정** — 내 코드 확인/갱신, 보호자 연결 관리, 데이터 초기화, 복약 알림 ON/OFF

### 가족 모드
- **홈** — 부모님 복용 현황 실시간 확인
- **알림** — 미복용 알림 리스트 (읽음/안읽음 구분)
- **병원** — 부모님 예약 일정 조회
- **설정** — 부모님 연결 해제, 모드 전환

---

## 스크린샷

> (추후 추가 예정)

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
| OCR | Google ML Kit (예정) |
| AI 파싱 | Claude / GPT API (약 이름 추출, 예정) |

---

## 프로젝트 구조

```
lib/
├── main.dart
├── firebase_options.dart
├── models/
│   ├── medicine.dart         # 약 모델
│   ├── medicine_log.dart     # 복용 기록 모델
│   └── appointment.dart      # 병원 예약 모델
├── services/
│   ├── auth_service.dart         # Firebase 익명 로그인
│   ├── firestore_service.dart    # Firestore CRUD + 보호자 연결
│   ├── notification_service.dart # FCM + 로컬 알림
│   └── prefs_service.dart        # 모드/알림 설정 저장
├── widgets/
│   ├── weekly_calendar.dart  # 주간 달력 위젯
│   ├── medicine_card.dart    # 약 카드 위젯
│   └── hospital_card.dart    # 병원 카드 위젯
└── screens/
    ├── mode_select_screen.dart        # 어르신/가족 모드 선택
    ├── senior/
    │   ├── senior_main_screen.dart
    │   ├── senior_home_screen.dart
    │   ├── senior_my_code_screen.dart
    │   ├── senior_medicine_screen.dart
    │   ├── senior_medicine_add_screen.dart
    │   ├── senior_medicine_detail_screen.dart
    │   ├── senior_medicine_edit_screen.dart
    │   ├── senior_hospital_screen.dart
    │   ├── senior_hospital_add_screen.dart
    │   ├── senior_hospital_detail_screen.dart
    │   ├── senior_hospital_edit_screen.dart
    │   └── senior_settings_screen.dart
    └── family/
        ├── family_code_input_screen.dart
        ├── family_main_screen.dart
        ├── family_home_screen.dart
        ├── family_notification_screen.dart
        ├── family_hospital_screen.dart
        └── family_settings_screen.dart
```

---

## Firestore 데이터 구조

```
users/{uid}
  ├── code: "A3K9X2"              # 시니어 연결 코드
  ├── linkedSeniorUid: ""         # 가족 → 시니어 연결
  ├── linkedFamilyUids: []        # 시니어 → 가족 목록
  └── fcmToken: ""                # FCM 푸시 토큰

codes/{code}
  ├── ownerUid: ""                # 코드 발급 시니어 uid
  └── createdAt: Timestamp        # 1시간 후 만료

users/{uid}/medicines/{medicineId}
  ├── name: "혈압약"
  ├── photoUrl: ""
  ├── times: ["08:00", "21:00"]
  ├── startDate: Timestamp
  └── endDate: Timestamp

users/{uid}/medicine_logs/{logId}
  ├── medicineId: ""
  ├── medicineName: "혈압약"
  ├── scheduledTime: Timestamp
  ├── taken: false
  └── takenAt: Timestamp | null

users/{uid}/appointments/{appointmentId}
  ├── hospitalName: "서울내과"
  ├── date: Timestamp
  └── memo: ""
```

---

## 시작하기

### 요구 사항
- Flutter SDK 3.x
- Android Studio 또는 VS Code
- Firebase 프로젝트 (`google-services.json` 및 `lib/firebase_options.dart` 필요)

### 실행

```bash
flutter pub get
flutter run
```

---

## 개발 현황

| 항목 | 상태 |
|------|------|
| 어르신 모드 UI | ✅ 완료 |
| 가족 모드 UI | ✅ 완료 |
| Firebase Auth (익명 로그인) | ✅ 완료 |
| Firestore CRUD (약/병원/복용기록) | ✅ 완료 |
| 6자리 코드 연결 (1시간 만료) | ✅ 완료 |
| 보호자 관리 (연결/해제) | ✅ 완료 |
| 설정 화면 (시니어/가족) | ✅ 완료 |
| 앱 재실행 시 모드 유지 | ✅ 완료 |
| 달력 실제 데이터 연동 | ✅ 완료 |
| 데이터 초기화 | ✅ 완료 |
| FCM 클라이언트 (토큰 저장, 로컬 알림) | ✅ 완료 |
| Cloud Functions (미복용 감지 자동 푸시) | 🔲 예정 |
| OCR 약 인식 (Google ML Kit) | 🔲 예정 |
| Google 계정 연동 (익명 → 영구) | 🔲 예정 |

---

## 라이선스

개인 포트폴리오 프로젝트입니다. 무단 배포를 금합니다.
