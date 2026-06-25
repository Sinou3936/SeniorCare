# 문의 폼 + 앱 내 정책 화면 설계 (2026-06-25)

약봄 설정에 "정보" 섹션을 추가하고, 개인정보처리방침·계정삭제 안내를 앱 내 화면으로,
문의하기를 앱 내 폼 → 서버(Cloud Function) 이메일 발송으로 구현한다.

## 배경 / 결정

- 기존 문의하기는 `mailto`(url_launcher) 방식이었으나 — 메일 앱 의존 + UX 문제로 폐기.
- 정책 페이지는 외부 GitHub Pages 링크였으나 — 브라우저 이동/오프라인 문제로 앱 내 화면 전환.
- Firestore 저장은 하지 않는다(문의는 이메일로만).

## ① 설정 "정보" 섹션 (앱 기능 아래, 동일 카드/행 스타일)

- **시니어 설정**: 개인정보처리방침 · 계정·데이터 삭제 안내 (문의하기 없음 — 시니어는 문의 주체 아님)
- **보호자 설정**: 문의하기 · 개인정보처리방침 · 계정·데이터 삭제 안내
- 기존 하단 푸터 링크 제거. 버전 표시(동적 `약봄 v$version`)만 맨 아래 유지.

## ② 앱 내 정책 화면

- `privacy-policy.md`, `account-deletion.md`를 Flutter 에셋으로 번들(단일 소스 — GitHub Pages도 같은 파일 사용).
- 화면에서 Jekyll front matter(`--- ... ---`) 제거 후 마크다운 렌더.
- 렌더: flutter_markdown 또는 경량 인하우스 변환(헤더/볼드/리스트/문단) — 구현 시 의존성 상태 보고 결정.
- GitHub Pages 페이지는 Play 콘솔 개인정보처리방침 URL용으로 유지.

## ③ 문의 폼 화면 (보호자만)

- 카테고리(라디오/칩): `오류/버그 · 기능 제안 · 사용 문의 · 기타`
- 내용 입력(멀티라인, 필수)
- "보내기" → `ensureOnline` 가드 → Cloud Function 호출 → 완료 안내("문의가 접수됐어요") 후 닫기
- 발송 중 로딩/중복 제출 방지

## ④ 서버 발송 (Cloud Function, nodemailer + Gmail)

- HTTPS callable function 신규. 입력 `{ category, content }`.
- nodemailer + Gmail SMTP(앱 비밀번호)로 `khyunseong9630@gmail.com`에 발송.
  - 앱 비밀번호는 기존 발급분 재사용. **Functions 시크릿**(`functions:secrets:set`)으로 등록, 코드엔 시크릿 이름만.
- 메일 제목 예: `[약봄 문의/오류·버그]`, 본문: 카테고리 + 내용 + 익명 uid.
- Firestore 저장 없음.

## ⑤ 정리(제거)

- `lib/utils/external_links.dart`의 mailto(`openSupportEmail`) 제거.
- `url_launcher`가 더는 안 쓰이면 의존성 제거(정책=앱내, 문의=폼+서버).
- 의존성 추가: 마크다운 렌더용(결정 후).

## 구현 순서 (테스트하며 점진적)

1. ② 정책 화면 + 에셋 → 빌드 확인
2. ① 설정 정보 섹션(양쪽) + 푸터/ mailto 정리 → 빌드 확인
3. ③ 문의 폼 UI(제출은 임시) → 빌드 확인
4. ④ Cloud Function 배포 + 폼 연결 → 실제 메일 수신 검증

## 선행 준비(사용자)

- `khyunseong9630@gmail.com` (또는 기존 앱비밀번호 계정) 2FA + 앱 비밀번호 — 기존 발급분 재사용 가능.
- ④ 단계에서 Functions 시크릿 등록 필요.
