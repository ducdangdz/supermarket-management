package com.smartmarket.hrm.attendance;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.List;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

/**
 * Lưu ảnh bằng chứng chấm công trên ổ đĩa của backend.
 * Tên file là SHA-256 của nội dung ảnh, nên cùng một ảnh luôn có cùng file_hash
 * (bảng attendance_evidence có UNIQUE file_hash → không thể dùng lại ảnh cũ).
 */
@Component
public class EvidenceStorage {
    private final java.util.concurrent.ConcurrentMap<String,java.util.Set<Long>> owners=new java.util.concurrent.ConcurrentHashMap<>();
    public void registerOwner(String hash,Long employeeId){owners.computeIfAbsent(hash,k->java.util.concurrent.ConcurrentHashMap.newKeySet()).add(employeeId);}
    public boolean uploadedBy(String hash,Long employeeId){return owners.getOrDefault(hash,java.util.Set.of()).contains(employeeId);}

    /** Đường dẫn public để xem ảnh, được map tới thư mục lưu trong WebConfig. */
    public static final String PUBLIC_PREFIX = "/uploads/evidence/";
    private static final long MAX_BYTES = 5L * 1024 * 1024;
    private static final List<String> EXTENSIONS = List.of(".jpg", ".png");

    private final Path root;

    public EvidenceStorage(@Value("${app.storage.evidence-dir:uploads/evidence}") String directory) {
        this.root = Path.of(directory).toAbsolutePath().normalize();
        try {
            Files.createDirectories(root);
        } catch (IOException ex) {
            throw new UncheckedIOException("Không tạo được thư mục lưu ảnh bằng chứng: " + root, ex);
        }
    }

    public Path root() {
        return root;
    }

    /** Kiểm tra ảnh (chỉ nhận JPEG/PNG, tối đa 5MB), lưu xuống đĩa và trả về URL + hash. */
    public StoredEvidence store(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new AttendanceException("EVIDENCE_REQUIRED", "Ảnh bằng chứng trống.");
        }
        if (file.getSize() > MAX_BYTES) {
            throw new AttendanceException("EVIDENCE_TOO_LARGE", "Ảnh bằng chứng vượt quá 5MB.");
        }
        try {
            byte[] bytes = file.getBytes();
            String extension = detectExtension(bytes);
            String hash = sha256Hex(bytes);
            Path target = root.resolve(hash + extension);
            if (!Files.exists(target)) Files.write(target, bytes);
            return new StoredEvidence(PUBLIC_PREFIX + hash + extension, hash, bytes.length);
        } catch (IOException ex) {
            throw new UncheckedIOException("Không lưu được ảnh bằng chứng.", ex);
        }
    }

    /** Tìm URL của ảnh đã upload theo hash; rỗng nếu hash sai định dạng hoặc chưa upload. */
    public Optional<String> findUrl(String hash) {
        if (hash == null || !hash.matches("[0-9a-f]{64}")) return Optional.empty();
        return EXTENSIONS.stream()
                .filter(extension -> Files.exists(root.resolve(hash + extension)))
                .map(extension -> PUBLIC_PREFIX + hash + extension)
                .findFirst();
    }

    /** Nhận diện định dạng qua "magic bytes" thay vì tin Content-Type do client gửi. */
    private String detectExtension(byte[] bytes) {
        if (bytes.length > 3 && (bytes[0] & 0xFF) == 0xFF && (bytes[1] & 0xFF) == 0xD8 && (bytes[2] & 0xFF) == 0xFF) return ".jpg";
        if (bytes.length > 8 && (bytes[0] & 0xFF) == 0x89 && bytes[1] == 'P' && bytes[2] == 'N' && bytes[3] == 'G') return ".png";
        throw new AttendanceException("EVIDENCE_INVALID_TYPE", "Ảnh bằng chứng phải là JPEG hoặc PNG.");
    }

    public static String sha256Hex(byte[] bytes) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(bytes);
            StringBuilder result = new StringBuilder(64);
            for (byte item : digest) result.append(String.format("%02x", item));
            return result.toString();
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 không khả dụng.", ex);
        }
    }

    public static String sha256Hex(String value) {
        return sha256Hex(value.getBytes(StandardCharsets.UTF_8));
    }

    public record StoredEvidence(String fileUrl, String fileHash, long sizeBytes) { }
}
