package com.doitdo.domain.user.application;

import com.doitdo.domain.user.api.dto.resp.CheckDuplicateResp;

public interface UserService {

	CheckDuplicateResp checkEmailDuplicate(String email);

	CheckDuplicateResp checkUsernameDuplicate(String username);
}
