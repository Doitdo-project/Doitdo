package com.doitdo.domain.setting.repository;

import com.doitdo.domain.setting.entity.UserSetting;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserSettingRepository extends JpaRepository<UserSetting, Long> {

	Optional<UserSetting> findByUserId(Long userId);

	void deleteByUserId(Long userId);
}
