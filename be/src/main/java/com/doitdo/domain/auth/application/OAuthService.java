package com.doitdo.domain.auth.application;

import com.doitdo.domain.auth.api.dto.resp.OAuthLoginResp;
import com.doitdo.domain.auth.entity.OAuthProvider;

public interface OAuthService {

	OAuthLoginResp login(OAuthProvider provider, String accessToken);
}
