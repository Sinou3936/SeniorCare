# 작업 이력

약봄 개발 과정의 날짜별 작업 기록입니다.

---

### 2026-06-25 — 앱 내 정책 화면 / 문의 폼(이메일 발송)

- **설정 "정보" 섹션** — 앱 기능 아래 카드로 정리. 시니어: 개인정보처리방침·계정·데이터 삭제 안내 / 보호자: +문의하기 (기존 하단 푸터 링크 대체)
- **앱 내 정책 화면** — `privacy-policy.md`·`account-deletion.md`를 에셋 번들 후 `flutter_markdown`으로 렌더(외부 브라우저 대신, 오프라인 OK, 단일 소스). 정책 내 외부 링크는 탭 시 브라우저로 열림
- **문의 폼 → 이메일 발송** — 보호자 설정에 문의 폼(카테고리: 오류/버그·기능 제안·사용 문의·기타 + 내용). 보내기 → Cloud Function `sendInquiry`(nodemailer + Gmail SMTP)로 이메일 발송. Firestore 저장 없음, 인증 필요, 시크릿(GMAIL_USER·GMAIL_APP_PASSWORD)으로 발송 계정 보호
- **보호자 코드 입력 포커스 글로우 수정** — `_focusNode` 리스너 누락으로 현재 칸 하이라이트가 안 뜨던 문제(autofocus 후 미갱신) 수정
- **설정 버전 표시 동적화** — `package_info_plus`로 pubspec 버전 자동 반영

---

### 2026-06-24 — 오프라인 대응 / 앱 표시명 약봄

- **앱 오프라인 실행 수정 (B5)** — `NotificationService.init()`의 `FirebaseMessaging.getToken()`이 오프라인에서 멈춰 `runApp()`에 도달하지 못해 앱이 안 뜨던 문제. FCM 토큰 등록을 백그라운드 비차단으로 분리하고, `main.dart`도 `runApp()`을 Firestore 재등록보다 먼저 호출
- **복용 기록 오프라인 작동** — 복용 체크·모두 복용(`setLogTaken`)과 풀스크린 복용완료(`markDoseTakenAt`)가 서버 응답을 기다리며 멈추던 문제. 쓰기는 비대기, 조회는 캐시(`Source.cache`)로 전환 → 오프라인에서도 즉시 로컬 기록, 온라인 복귀 시 자동 동기화
- **온라인 필수 동작 가드** — `ConnectivityService` 추가 (실제 소켓 연결로 판정해 DNS 캐시 false-positive 방지). 오프라인이면 안내 모달 / 전체화면 게이트로 차단:
  - 약·병원 추가(진입 전)·수정(상세에서 바로)·삭제
  - 가족 모드 — 모드선택 버튼·코드 입력·재진입 3겹 차단 (오프라인 시 오래된 캐시로 복용 현황 오인 방지)
  - 코드 발급, 구글 계정 연결, 데이터 초기화
- **앱 표시명 약봄** — 모드선택 타이틀·설정 버전 표시를 SeniorCare → 약봄

---

### 2026-06-23 — 비공개 테스트 피드백 수정 / 시각 기반 알림 문구

- **가족 코드 입력 키보드 재표시 (B1)** — 시스템 버튼으로 키보드를 내리면 `FocusNode`가 포커스를 유지해 `requestFocus()`가 무시되던 문제, 이미 포커스인 경우 `SystemChannels.textInput.invokeMethod('TextInput.show')`로 강제 재표시
- **모드 선택 뒤로가기 흐름 개선 (B2)** — 모드선택→코드입력을 `pushReplacement`→`push`로 바꿔 뒤로가기 시 모드선택 복귀, 연결 성공 후엔 `pushAndRemoveUntil`로 가족 메인을 루트로 만들어 뒤로가기 시 앱 종료
- **풀스크린 알람 상태바 코랄 적용 (B3)** — `SafeArea(top: false)` + 상단 패딩에 `MediaQuery.padding.top` 추가해 코랄 헤더가 상태바 영역까지 덮도록 (기존 상단 회색 노출 제거)
- **시각 기반 알림 문구 (G)** — 알림 그룹이 정확한 시각 단위로 묶이는 점을 반영해 시각을 문구에 포함
  - 시니어 알람: "오전 8시 약 드실 시간이에요" (슬롯이 전부 바르는약이면 "바르실")
  - 시니어 리마인더: "오전 8시 약, 아직 안 드셨어요?"
  - 보호자 FCM: "부모님이 오전 8시 [약] 아직 복용하지 않으셨어요" (Cloud Functions `koreanTimeLabel(millis)` 헬퍼 추가, KST=UTC+9 보정)

---

### 2026-06-09 — Google Play 비공개 테스트 출시 준비

- **개인정보처리방침 / 계정·데이터 삭제 안내 페이지** — `privacy-policy.md`, `account-deletion.md` 작성, GitHub Pages front matter + permalink로 고정 주소 적용
- **데이터 보안 설문 작성** — 건강정보·사용자ID·기기ID·FCM·이메일 수집 항목 입력, 전송 암호화 명시
- **그래픽 이미지 1024×500 생성** — `tools/make_feature_graphic.py`(PIL)로 스플래시 기반 페더 그래픽 자동 생성
- **AAB 빌드·서명** — 업로드 키스토어 생성, `build.gradle.kts`에 release `signingConfig` 연결, `key.properties` 기반 서명 적용 (키스토어 / 키 비밀번호는 `.gitignore` 처리)
- **Google Play 내부 테스트 업로드** — AAB 1.0.0+1 업로드 완료, 비공개 테스트 시작

---

### 2026-06-08 — 풀스크린 알람 안정화 / 알람 시스템 리팩토링

- **슬롯 단위 알람** — 약별 개별 알람 → 시간대(슬롯)별로 묶어 알람 1개로 통합, 약 목록은 SharedPreferences 캐시
- **풀스크린 알람 화면** — 화면 OFF 시 잠금화면 위에 전체 화면 알람 표시 (`fullScreenIntent`), 약 목록 + 복용 완료 / 10분 후 다시 알림 버튼
- **풀스크린 화면 OFF 판별 정상화** — 매니페스트 `turnScreenOn` 제거 후 `MainActivity`에서 "화면상태 읽기 → 직접 화면 켜기" 순서를 앱이 직접 제어 (기존엔 시스템이 onCreate보다 먼저 화면을 켜 판별이 깨짐)
- **화면 ON/OFF 라우팅** — 화면 OFF는 풀스크린, 화면 ON 배너 탭은 홈으로 분기
- **화면 ON 알람 소리** — 복약 알람 채널 `playSound` 활성화 (배너 + 소리 + 진동)
- **스누즈·자동종료 잠금화면 복귀** — "10분 후"·1분 자동종료 시 앱에 진입하지 않고 잠금화면으로 복귀, 복용 완료만 홈 이동
- **보호자 미복용 알림 슬롯 묶기** — Cloud Task 키를 `uid_복용시각`으로 변경, 같은 시간대 약 N개를 FCM 1개로 통합 발송
- **가족 미복용 알림 토글 실동작** — 토글 상태를 Firestore에 저장, Cloud Functions가 발송 전 확인
- **미복용 알림 문구 중립화** — "드시지 않으셨어요" → "복용하지 않으셨어요" (먹는약/바르는약 모두 포함)
- **버그 수정** — 복용 완료 버튼이 실제 복용 처리 누락 / 약 변경 시 병원 알람 삭제 / 과거 날짜 로그 중복 누적 / 슬롯 단위 로그 누락

---

### 2026-05-26 (2차) — 알림 토글 실제 동작 / 병원 알림 토글 추가

- **복약 알림 토글 실제 동작** — OFF 시 전체 약 알람 즉시 취소, ON 시 재등록. 약 추가·수정 시에도 토글 상태 확인 후 조건부 스케줄링
- **병원 예약 알림 토글 추가** — 앱 기능 섹션에 토글 UI 추가, OFF 시 미래 예약 알람 즉시 취소 / ON 시 재등록
- **FCM 토글 연동** — `_showLocal` (포그라운드 FCM 수신)도 토글 OFF 시 표시 차단
- **앱 재시작 시 토글 확인** — `main.dart`에서 복약·병원 알림 토글 값 확인 후 조건부 재등록
- **`PrefsService` 병원 알림 키 추가** — `hospital_notification_enabled` 저장·로드
- **코드 검증 버그 수정** — `TextScaler` 위치 오류(`MaterialApp.builder`로 이동), `mode_select_screen` Column overflow, `time_utils_test` 슬롯 경계·timezone 갱신

---

### 2026-05-26 — 슬롯 개편 / 약 종류 / 병원 알림 / UI 정리

- **새벽 슬롯 추가** — 0:00~6:59 (기본값 04:00, 기본 비활성), 아이콘 `dark_mode_outlined`
- **슬롯 경계 재정의** — 저녁 최대 20:29, 취침 20:30 시작으로 통일 (홈·추가·수정 화면 전체 일치)
- **약 종류 2그룹** — `MedicineType` enum (oral / topical) 추가, 알림 문구 분기 ("드실 시간" / "바르실 시간")
- **수정 시 미래 로그 반영** — `updateMedicine`: 오늘·미래 미복용 로그 삭제 후 접근 시 자동 재생성
- **병원 예약 알림** — 예약 2시간 전 로컬 알림, 추가·수정 시 등록 / 삭제 시 취소
- **병원 알림 재등록 버그 수정** — 앱 재시작 시 `rescheduleAppointmentAlarms`로 미래 예약 알림 복원
- **시스템 글자 크기 무시** — `MaterialApp.builder`에 `TextScaler.noScaling` 적용, 시스템 설정 무관하게 UI 고정
- **UI overflow 수정 5곳** — 보호자 설정 "재설치 후 코드", 시니어 설정 3곳, 가족 홈 화면
- **불필요 UI 제거** — 홈 상단 "내 코드" 버튼, 카카오톡 공유 버튼, 설정 화면 상단 톱니바퀴 아이콘
- **Cloud Functions 개편** — pubsub 5분 크론 → Cloud Tasks 방식 전환 (medicine_log 생성 시 20분 후 태스크 예약, OIDC 인증)
- **테스트 57개 전체 통과** — 슬롯 경계 갱신 + timezone `setUpAll` 추가

---

### 2026-05-18 — 미복용 알림 개편 / 안정성 개선

- **미복용 리마인더 추가 (시니어)** — 복용 알림 +10분 후 "아직 드시지 않으셨나요?" 로컬 알림 추가, 복용 체크 시 자동 취소
- **Cloud Functions 개편 (보호자)** — `onUpdate` 트리거 → `pubsub.schedule('every 5 minutes')` 교체, 20분 미복용 기준으로 변경, collectionGroup 쿼리로 전체 사용자 스캔
- **Samsung 알람 재등록 버그 수정** — `alarmClock` 모드 one-shot 특성 반영, 앱 시작 시 전체 활성 약 알람 재등록 (`rescheduleAllAlarms`)
- **버튼 연속 클릭 방지** — 약 추가/병원 추가 저장 버튼 `_isSaving` 가드로 중복 호출 차단
- **가족 앱 세션 유지** — `linkedSeniorUid` SharedPreferences 캐싱, 재실행 시 코드 재입력 없이 자동 복원
- **Firestore 오프라인 캐시** — `persistenceEnabled: true` 설정으로 오프라인 / 느린 네트워크 대응
- **홈 화면 반응 속도 개선** — `StreamBuilder`를 state 변수로 분리해 날짜 탭 전환 시 깜빡임 제거
- **약 시간 범위 제한** — 아침 07:00~09:00, 점심 11:30~15:00, 저녁 17:30~20:00 경계 벗어나지 않도록 clamp 처리
- **복용 종료일 기본값 변경** — 30일 → 7일
- **날짜 picker 한국어** — 약/병원 추가·수정 화면 `showDatePicker` locale 명시 (`ko_KR`)
- **스플래시 이미지 변경** — `splash_screen.png` → `app_icon.png` 단일화, 배경색 유지 fix

---

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
