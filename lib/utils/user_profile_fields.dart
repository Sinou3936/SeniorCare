/// users/{uid} 문서에 쓸 프로필 필드 조립 (순수 로직)
class UserProfileFields {
  const UserProfileFields._();

  /// 로그인 시마다 병합 저장할 필드.
  /// 가입일(createdAt)은 Cloud Functions 가 생성 시 한 번만 기록하므로 여기서 제외.
  static Map<String, Object?> loginUpdate({
    required bool isAnonymous,
    required Object serverTimestamp,
  }) {
    return {
      'lastLoginAt': serverTimestamp,
      'isAnonymous': isAnonymous,
    };
  }
}
