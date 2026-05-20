package com.doitdo.domain.auth.application;

import com.doitdo.domain.auth.api.dto.req.LoginReq;
import com.doitdo.domain.auth.api.dto.req.PasswordResetReq;
import com.doitdo.domain.auth.api.dto.req.PasswordResetRequestReq;
import com.doitdo.domain.auth.api.dto.req.PasswordResetVerifyCodeReq;
import com.doitdo.domain.auth.api.dto.req.RefreshTokenReq;
import com.doitdo.domain.auth.api.dto.req.SignupReq;
import com.doitdo.domain.auth.api.dto.resp.LoginResp;
import com.doitdo.domain.auth.api.dto.resp.PasswordResetVerifyCodeResp;
import com.doitdo.domain.auth.api.dto.resp.SignupResp;
import com.doitdo.domain.auth.api.dto.resp.TokenResp;

public interface AuthService {

	SignupResp signup(SignupReq req);

	LoginResp login(LoginReq req);

	TokenResp refresh(RefreshTokenReq req);

	void logout(Long userId);

	void requestPasswordReset(PasswordResetRequestReq req);

	PasswordResetVerifyCodeResp verifyCode(PasswordResetVerifyCodeReq req);

	void resetPassword(PasswordResetReq req);
}
