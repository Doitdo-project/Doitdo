package com.doitdo.global.mail.impl;

import com.doitdo.global.mail.MailService;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;
import java.io.UnsupportedEncodingException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class MailServiceImpl implements MailService {

	private static final String PASSWORD_RESET_SUBJECT = "[doitdo] 비밀번호 재설정 인증번호";

	private final JavaMailSender javaMailSender;

	@Value("${app.password-reset.from-address}")
	private String fromAddress;

	@Value("${app.password-reset.from-name}")
	private String fromName;

	@Value("${app.password-reset.otp-ttl-minutes}")
	private long otpTtlMinutes;

	/**
	 * 비밀번호 재설정 OTP(6자리) 메일 발송.
	 *
	 * <p>SMTP 응답 지연(1~3초)이 API 응답에 영향을 주지 않도록 {@code mailExecutor} 풀에서 비동기 처리.
	 * 발송 실패 시 사용자 응답에는 영향을 주지 않고 로그만 남긴다 — 사용자 입장에선 "메일 보냈음" 응답을 받지만
	 * 실제 도착 여부는 따로 모니터링해야 한다 (Out of scope: 발송 이력 테이블).
	 */
	@Override
	@Async("mailExecutor")
	public void sendPasswordResetCodeMail(String toEmail, String code) {
		try {
			MimeMessage message = javaMailSender.createMimeMessage();
			MimeMessageHelper helper = new MimeMessageHelper(message, false, "UTF-8");
			helper.setFrom(new InternetAddress(fromAddress, fromName, "UTF-8"));
			helper.setTo(toEmail);
			helper.setSubject(PASSWORD_RESET_SUBJECT);
			helper.setText(buildHtmlBody(code), true);

			javaMailSender.send(message);
			log.info("event=PASSWORD_RESET_MAIL_SENT to={}", maskEmail(toEmail));
		} catch (MessagingException | UnsupportedEncodingException e) {
			log.error("event=PASSWORD_RESET_MAIL_FAILED to={} reason={}", maskEmail(toEmail), e.getMessage(), e);
		}
	}

	private String buildHtmlBody(String code) {
		return """
				<!DOCTYPE html>
				<html lang="ko">
				<body style="font-family: 'Apple SD Gothic Neo', sans-serif; background:#f7f7fa; padding:32px;">
				  <table style="max-width:480px; margin:0 auto; background:#fff; border-radius:12px; padding:32px;">
				    <tr><td>
				      <h2 style="margin:0 0 16px;">비밀번호 재설정 인증번호</h2>
				      <p style="color:#333; line-height:1.6;">
				        doitdo 앱에서 아래 6자리 인증번호를 입력해주세요.
				      </p>
				      <p style="text-align:center; margin:32px 0;">
				        <span style="display:inline-block; background:#f1f3f9; color:#222; padding:18px 32px; border-radius:12px; font-size:32px; letter-spacing:8px; font-weight:bold;">%s</span>
				      </p>
				      <p style="color:#888; font-size:13px; line-height:1.5; text-align:center;">
				        이 인증번호는 <b>%d분</b> 동안 유효해요.
				      </p>
				      <p style="color:#888; font-size:13px; line-height:1.5;">
				        본인이 요청하지 않았다면 이 메일을 무시해주세요. 기존 비밀번호는 그대로 유지됩니다.
				      </p>
				    </td></tr>
				  </table>
				</body>
				</html>
				""".formatted(code, otpTtlMinutes);
	}

	private String maskEmail(String email) {
		int at = email.indexOf('@');
		if (at <= 1) {
			return "***" + (at >= 0 ? email.substring(at) : "");
		}
		return email.charAt(0) + "***" + email.substring(at);
	}
}
