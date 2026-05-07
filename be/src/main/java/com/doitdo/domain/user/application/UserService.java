package com.doitdo.domain.user.application;

import com.doitdo.domain.user.api.dto.req.PasswordChangeReq;
import com.doitdo.domain.user.api.dto.req.RegisterAgreementsReq;
import com.doitdo.domain.user.api.dto.req.RegisterBirthDateReq;
import com.doitdo.domain.user.api.dto.req.WithdrawReq;
import com.doitdo.domain.user.api.dto.resp.CheckDuplicateResp;
import com.doitdo.domain.user.api.dto.resp.UserInfoResp;
import com.doitdo.domain.user.api.dto.resp.WalletBalanceResp;

public interface UserService {

	CheckDuplicateResp checkEmailDuplicate(String email);

	CheckDuplicateResp checkUsernameDuplicate(String username);

	UserInfoResp getMyInfo(Long userId);

	WalletBalanceResp getMyBalance(Long userId);

	void changePassword(Long userId, PasswordChangeReq req);

	void withdraw(Long userId, WithdrawReq req);

	UserInfoResp registerBirthDate(Long userId, RegisterBirthDateReq req);

	UserInfoResp registerAgreements(Long userId, RegisterAgreementsReq req);
}
