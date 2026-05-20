package com.doitdo.global.mail;

public interface MailService {

	void sendPasswordResetCodeMail(String toEmail, String code);
}
