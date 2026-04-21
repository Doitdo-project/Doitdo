package com.doitdo.domain.auth.repository;

import com.doitdo.domain.auth.entity.AutoProvider;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AutoProviderRepository extends JpaRepository<AutoProvider, Long> {

	Optional<AutoProvider> findByProviderAndProviderUid(String provider, String providerUid);
}
