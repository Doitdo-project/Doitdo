package com.doitdo.domain.setting.repository;

import com.doitdo.domain.setting.entity.UserSetting;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserSettingRepository extends JpaRepository<UserSetting, Long> {
}
