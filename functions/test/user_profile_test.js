/**
 * Cloud Functions — buildProfileFromAuthUser 단위 테스트
 * 프로덕션 모듈을 직접 import 하여 검증 (Firebase 연결 불필요)
 */

const { buildProfileFromAuthUser } = require('../user_profile');

// ── 테스트 헬퍼 ───────────────────────────────────────────────

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
    toEqualDate(expected) {
      const a = actual instanceof Date ? actual.getTime() : actual;
      const e = expected instanceof Date ? expected.getTime() : expected;
      if (a !== e)
        throw new Error(`expected ${expected && expected.toISOString ? expected.toISOString() : expected}, got ${actual && actual.toISOString ? actual.toISOString() : actual}`);
    },
  };
}

// ── 테스트 케이스 ─────────────────────────────────────────────

console.log('\nbuildProfileFromAuthUser — 가입일 변환');

test('metadata.creationTime 을 createdAt(Date)으로 변환', () => {
  const profile = buildProfileFromAuthUser({
    metadata: { creationTime: 'Mon, 05 May 2026 09:30:00 GMT' },
    providerData: [],
  });
  expect(profile.createdAt).toEqualDate(new Date('2026-05-05T09:30:00Z'));
});

console.log('\nbuildProfileFromAuthUser — 마지막 로그인 변환');

test('metadata.lastSignInTime 을 lastLoginAt(Date)으로 변환', () => {
  const profile = buildProfileFromAuthUser({
    metadata: {
      creationTime: 'Mon, 05 May 2026 09:30:00 GMT',
      lastSignInTime: 'Tue, 03 Nov 2026 22:15:00 GMT',
    },
    providerData: [],
  });
  expect(profile.lastLoginAt).toEqualDate(new Date('2026-11-03T22:15:00Z'));
});

test('한 번도 로그인한 적 없으면 lastLoginAt 은 null', () => {
  const profile = buildProfileFromAuthUser({
    metadata: { creationTime: 'Mon, 05 May 2026 09:30:00 GMT' },
    providerData: [],
  });
  expect(profile.lastLoginAt).toBe(null);
});

console.log('\nbuildProfileFromAuthUser — 익명 여부 판정');

test('providerData 가 비어 있으면 익명 계정', () => {
  const profile = buildProfileFromAuthUser({
    metadata: { creationTime: 'Mon, 05 May 2026 09:30:00 GMT' },
    providerData: [],
  });
  expect(profile.isAnonymous).toBe(true);
});

test('구글 연동 계정은 익명이 아님', () => {
  const profile = buildProfileFromAuthUser({
    metadata: { creationTime: 'Mon, 05 May 2026 09:30:00 GMT' },
    providerData: [{ providerId: 'google.com' }],
  });
  expect(profile.isAnonymous).toBe(false);
});

test('providerData 자체가 없어도 익명으로 처리', () => {
  const profile = buildProfileFromAuthUser({
    metadata: { creationTime: 'Mon, 05 May 2026 09:30:00 GMT' },
  });
  expect(profile.isAnonymous).toBe(true);
});

// ── 결과 ──────────────────────────────────────────────────────

console.log(`\n통과 ${passed} / 실패 ${failed}\n`);
process.exit(failed > 0 ? 1 : 0);
