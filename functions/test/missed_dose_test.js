/**
 * Cloud Functions — notifyMissedDose 로직 단위 테스트
 * Firebase 연결 없이 비즈니스 로직만 검증
 */

// ── 테스트 헬퍼 ───────────────────────────────────────────────

function shouldNotify(after, nowMs) {
  if (after.taken) return { result: false, reason: '이미 복용함' };

  const scheduledTime = after.scheduledTime;
  if (!scheduledTime) return { result: false, reason: 'scheduledTime 없음' };

  const diffMinutes = (nowMs - scheduledTime.getTime()) / 1000 / 60;
  if (diffMinutes < 30) return { result: false, reason: `30분 미경과 (${diffMinutes.toFixed(1)}분)` };

  if (after.notified) return { result: false, reason: '이미 알림 발송됨' };

  return { result: true, reason: '알림 발송 조건 충족' };
}

// ── 테스트 케이스 ─────────────────────────────────────────────

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  ✅ ${name}`);
    passed++;
  } catch (e) {
    console.log(`  ❌ ${name}`);
    console.log(`     ${e.message}`);
    failed++;
  }
}

function expect(actual) {
  return {
    toBe(expected) {
      if (actual !== expected)
        throw new Error(`expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
    },
    toContain(expected) {
      if (!actual.includes(expected))
        throw new Error(`expected "${actual}" to contain "${expected}"`);
    },
  };
}

// ── 1번: 코드 입력 버그 (서버사이드 코드 검증) ─────────────────

console.log('\n[1] 코드 검증 로직');

test('6자리 코드 정규식 — 영문+숫자만 허용', () => {
  const validCodes = ['ABC123', 'XYZ789', 'A1B2C3'];
  const invalidCodes = ['abc123', 'ABC 12', 'ABC12!'];
  const regex = /^[A-Z0-9]{6}$/;

  validCodes.forEach(code => {
    if (!regex.test(code)) throw new Error(`${code} should be valid`);
  });
  invalidCodes.forEach(code => {
    if (regex.test(code)) throw new Error(`${code} should be invalid`);
  });
});

// ── 2번: 로컬 스케줄링 — 시간대 슬롯 로직 ────────────────────

console.log('\n[2] 슬롯 라벨 로직');

function slotLabel(hour) {
  if (hour < 10) return '아침';
  if (hour < 14) return '점심';
  if (hour < 20) return '저녁';
  return '취침';
}

test('8시 → 아침', () => expect(slotLabel(8)).toBe('아침'));
test('9시 59분 → 아침', () => expect(slotLabel(9)).toBe('아침'));
test('10시 → 점심', () => expect(slotLabel(10)).toBe('점심'));
test('14시 → 저녁', () => expect(slotLabel(14)).toBe('저녁'));
test('20시 → 취침', () => expect(slotLabel(20)).toBe('취침'));
test('23시 → 취침', () => expect(slotLabel(23)).toBe('취침'));

// ── 3번: 가족 홈 — 주간 시작일 계산 ──────────────────────────

console.log('\n[3] 주간 시작일 (월요일) 계산');

function weekStart(date) {
  const d = new Date(date);
  const day = d.getUTCDay(); // 0=일, 1=월
  const diff = day === 0 ? 6 : day - 1;
  d.setUTCDate(d.getUTCDate() - diff);
  d.setUTCHours(0, 0, 0, 0);
  return d;
}

test('월요일(2024-05-06)은 그대로', () => {
  const result = weekStart(new Date('2024-05-06'));
  expect(result.toISOString().slice(0, 10)).toBe('2024-05-06');
});
test('수요일(2024-05-08) → 월요일(2024-05-06)', () => {
  const result = weekStart(new Date('2024-05-08'));
  expect(result.toISOString().slice(0, 10)).toBe('2024-05-06');
});
test('일요일(2024-05-12) → 월요일(2024-05-06)', () => {
  const result = weekStart(new Date('2024-05-12'));
  expect(result.toISOString().slice(0, 10)).toBe('2024-05-06');
});

// ── 4번: Cloud Functions — 미복용 감지 로직 ──────────────────

console.log('\n[4] 미복용 30분 후 알림 조건');

const now = Date.now();
const ago35min = new Date(now - 35 * 60 * 1000);
const ago20min = new Date(now - 20 * 60 * 1000);

test('이미 복용한 경우 → 알림 안 함', () => {
  const r = shouldNotify({ taken: true, scheduledTime: ago35min }, now);
  expect(r.result).toBe(false);
  expect(r.reason).toContain('복용함');
});

test('30분 미경과 → 알림 안 함', () => {
  const r = shouldNotify({ taken: false, scheduledTime: ago20min }, now);
  expect(r.result).toBe(false);
  expect(r.reason).toContain('30분');
});

test('이미 알림 발송된 경우 → 중복 방지', () => {
  const r = shouldNotify({ taken: false, scheduledTime: ago35min, notified: true }, now);
  expect(r.result).toBe(false);
  expect(r.reason).toContain('알림 발송됨');
});

test('30분 경과 + 미복용 + 미알림 → 알림 발송', () => {
  const r = shouldNotify({ taken: false, scheduledTime: ago35min }, now);
  expect(r.result).toBe(true);
});

test('scheduledTime 없으면 → 알림 안 함', () => {
  const r = shouldNotify({ taken: false }, now);
  expect(r.result).toBe(false);
});

// ── 결과 ──────────────────────────────────────────────────────

console.log(`\n총 ${passed + failed}개 테스트: ✅ ${passed}개 통과, ❌ ${failed}개 실패\n`);
if (failed > 0) process.exit(1);
