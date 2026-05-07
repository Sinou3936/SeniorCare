# SeniorCare

어르신의 약 복용과 병원 일정을 관리하고, 가족이 실시간으로 현황을 확인할 수 있는 Flutter 앱입니다.

취업 포트폴리오 겸 실사용 목적으로 제작 중입니다.

---

## 주요 기능

### 어르신 모드
- **홈** — 주간 달력 + 시간대별(아침/점심/저녁/취침) 복용 현황
- **약 관리** — 약 목록 조회, 추가(OCR 촬영 or 갤러리), 수정, 삭제
- **병원** — 예약/진료 일정 등록, 수정, 삭제, 조회
- **내 코드** — 가족 연결용 6자리 코드 확인 및 공유

### 가족 모드
- **홈** — 부모님 복용 현황 실시간 확인 (복수 부모 탭 전환 지원)
- **알림** — 미복용 알림 리스트 (읽음/안읽음 구분)
- **병원** — 부모님 예약 일정 조회
- **코드 연결** — 6자리 코드 입력으로 부모님과 연결

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
| OCR | Google ML Kit |
| AI 파싱 | Claude / GPT API (약 이름 추출) |

---

## 프로젝트 구조

```
lib/
├── main.dart
├── models/
│   ├── medicine.dart         # 약 모델
│   ├── medicine_log.dart     # 복용 기록 모델
│   └── appointment.dart      # 병원 예약 모델
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
    │   ├── senior_hospital_screen.dart
    │   ├── senior_hospital_add_screen.dart
    │   └── senior_hospital_detail_screen.dart
    └── family/
        ├── family_code_input_screen.dart
        ├── family_main_screen.dart
        ├── family_home_screen.dart
        ├── family_notification_screen.dart
        └── family_hospital_screen.dart
```

---

## Firestore 데이터 구조

```
users/{uid}
  └── code: "A3K9X2"          # 시니어-가족 연결 코드

medicines/{medicineId}
  ├── name: "혈압약"
  ├── photoUrl: ""
  ├── times: ["08:00", "21:00"]
  ├── startDate: Timestamp
  └── endDate: Timestamp

medicine_logs/{logId}
  ├── medicineId: ""
  ├── medicineName: "혈압약"
  ├── scheduledTime: Timestamp
  ├── taken: false
  └── takenAt: Timestamp | null

appointments/{appointmentId}
  ├── hospitalName: "서울내과"
  ├── date: Timestamp
  └── memo: ""
```

---

## 시작하기

### 요구 사항
- Flutter SDK 3.x
- Android Studio 또는 VS Code
- Firebase 프로젝트 (연동 예정)

### 실행

```bash
flutter pub get
flutter run
```

> 현재 Firebase 미연동 상태로, 더미 데이터로 UI 동작을 확인할 수 있습니다.  
> 가족 모드 연결 코드 테스트: `A3K9X2`

---

## 개발 현황

| 항목 | 상태 |
|------|------|
| 어르신 모드 UI | ✅ 완료 |
| 가족 모드 UI | ✅ 완료 |
| 코드 연결 화면 | ✅ 완료 |
| Firebase Auth | 🔲 예정 |
| Firestore CRUD | 🔲 예정 |
| FCM 푸시 알림 | 🔲 예정 |
| OCR 약 인식 | 🔲 예정 |
| Cloud Functions | 🔲 예정 |

---

## 라이선스

개인 포트폴리오 프로젝트입니다. 무단 배포를 금합니다.
