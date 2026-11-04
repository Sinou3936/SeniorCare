/**
 * Auth 사용자 정보 → Firestore users 문서 필드 변환 (순수 로직)
 */

function buildProfileFromAuthUser(authUser) {
  const lastSignInTime = authUser.metadata.lastSignInTime;
  const providers = authUser.providerData || [];
  return {
    createdAt: new Date(authUser.metadata.creationTime),
    lastLoginAt: lastSignInTime ? new Date(lastSignInTime) : null,
    isAnonymous: providers.length === 0,
  };
}

module.exports = { buildProfileFromAuthUser };
