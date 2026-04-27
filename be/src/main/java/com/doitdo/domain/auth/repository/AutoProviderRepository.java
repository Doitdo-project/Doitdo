package com.doitdo.domain.auth.repository;

import com.doitdo.domain.auth.entity.AutoProvider;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AutoProviderRepository extends JpaRepository<AutoProvider, Long> {

	Optional<AutoProvider> findByProviderAndProviderUid(String provider, String providerUid);

	// UNIQUE 제약 누락으로 DB에 이미 중복 row가 남아 있을 때
	// findByProviderAndProviderUid 가 NonUniqueResultException 을 던지는 상황 방어용.
	// 호출부에서 stream().findFirst() 로 winner 선택.
	List<AutoProvider> findAllByProviderAndProviderUid(String provider, String providerUid);

	void deleteAllByUserId(Long userId);

	// Apple revoke 호출 대상 추출용. provider 별 분기 호출 시 KAKAO/GOOGLE 도 사용 가능.
	List<AutoProvider> findAllByUserIdAndProvider(Long userId, String provider);
}
