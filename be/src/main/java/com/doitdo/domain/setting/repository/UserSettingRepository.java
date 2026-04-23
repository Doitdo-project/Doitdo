package com.doitdo.domain.setting.repository;

import com.doitdo.domain.setting.entity.UserSetting;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserSettingRepository extends JpaRepository<UserSetting, Long> {

	Optional<UserSetting> findByUserId(Long userId);

	List<UserSetting> findAllByEveningReminderEnabledTrueAndEveningReminderTime(LocalTime time);
}
