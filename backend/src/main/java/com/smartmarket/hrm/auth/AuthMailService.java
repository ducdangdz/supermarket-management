package com.smartmarket.hrm.auth;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AuthMailService {
    private final ObjectProvider<JavaMailSender> senders;
    private final String host;
    private final String from;

    public AuthMailService(ObjectProvider<JavaMailSender> senders,
            @Value("${spring.mail.host:}") String host,
            @Value("${app.auth.mail-from:}") String from) {
        this.senders = senders;
        this.host = host;
        this.from = from;
    }

    public void ensureConfigured() {
        if (host.isBlank() || from.isBlank() || senders.getIfAvailable() == null) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Chức năng gửi mã email chưa được cấu hình. Vui lòng liên hệ quản trị viên.");
        }
    }

    public void sendCode(String email, String code, String purpose) {
        ensureConfigured();
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(email);
        message.setSubject("REGISTER".equals(purpose)
                ? "SmartMarket HRM - Xác nhận đăng ký" : "SmartMarket HRM - Đặt lại mật khẩu");
        message.setText("Mã xác nhận của bạn: " + code
                + "\nMã có hiệu lực 10 phút và chỉ sử dụng một lần."
                + "\nKhông chia sẻ mã này với người khác. Nếu bạn không yêu cầu, hãy bỏ qua email này.");
        try {
            senders.getObject().send(message);
        } catch (org.springframework.mail.MailException ex) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Chưa gửi được email xác nhận. Vui lòng thử lại sau.");
        }
    }
}
