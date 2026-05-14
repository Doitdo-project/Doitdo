package com.doitdo.global.mail;

public interface MailService {

	void sendPasswordResetMail(String toEmail, String resetLink);
}
