package pms.utils;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.WriterException;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;

import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.Serializable;
import java.net.URLEncoder;
import java.util.Base64;
import java.util.EnumMap;
import java.util.Map;
import javax.imageio.ImageIO;

public class QrCodeGenerator implements Serializable {

    private static final long serialVersionUID = 1L;
    private static final int DEFAULT_SIZE = 250;
    private static final int MAX_SIZE = 500;

    public String generateQrCodeBase64(String content) {
        return generateQrCodeBase64(content, DEFAULT_SIZE);
    }

    public String generateQrCodeBase64(String content, int size) {
        if (content == null || content.trim().isEmpty()) {
            throw new IllegalArgumentException("QR content khong duoc null hoac rong.");
        }
        if (size <= 0) size = DEFAULT_SIZE;
        if (size > MAX_SIZE) size = MAX_SIZE;

        ByteArrayOutputStream baos = null;
        try {
            BufferedImage image = generateQrImage(content.trim(), size);
            baos = new ByteArrayOutputStream();
            ImageIO.write(image, "PNG", baos);
            byte[] imageBytes = baos.toByteArray();
            return Base64.getEncoder().encodeToString(imageBytes);
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException("Loi tao QR code: " + e.getMessage(), e);
        } finally {
            if (baos != null) { try { baos.close(); } catch (Exception ignored) {} }
        }
    }

    private BufferedImage generateQrImage(String content, int size) throws WriterException {
        QRCodeWriter writer = new QRCodeWriter();

        Map<EncodeHintType, Object> hints = new EnumMap<>(EncodeHintType.class);
        hints.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.M);
        hints.put(EncodeHintType.MARGIN, 1);
        hints.put(EncodeHintType.CHARACTER_SET, "UTF-8");

        BitMatrix bitMatrix = writer.encode(content, BarcodeFormat.QR_CODE, size, size, hints);

        int width = bitMatrix.getWidth();
        int height = bitMatrix.getHeight();
        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);

        for (int x = 0; x < width; x++) {
            for (int y = 0; y < height; y++) {
                image.setRGB(x, y, bitMatrix.get(x, y) ? 0x000000 : 0xFFFFFF);
            }
        }
        return image;
    }

    public String generateVietQrContent(String bankBin, String accountNumber,
            String accountName, double amount, String description) {
        if (bankBin == null || bankBin.trim().isEmpty()) {
            throw new IllegalArgumentException("Bank BIN khong duoc null hoac rong.");
        }
        if (accountNumber == null || accountNumber.trim().isEmpty()) {
            throw new IllegalArgumentException("So tai khoan khong duoc null hoac rong.");
        }
        if (accountName == null) accountName = "";
        if (description == null) description = "";

        if (amount <= 0) {
            throw new IllegalArgumentException("So tien thanh toan phai lon hon 0.");
        }

        String amountStr = String.format("%.0f", amount);

        StringBuilder sb = new StringBuilder();
        sb.append("38");
        sb.append("|");
        sb.append("01");
        sb.append("|");
        sb.append("");
        sb.append("|");
        sb.append(bankBin.trim());
        sb.append("|");
        sb.append(accountNumber.trim());
        sb.append("|");
        sb.append(accountName.trim());
        sb.append("|");
        sb.append(amountStr);
        sb.append("|");
        sb.append(description.trim());
        return sb.toString();
    }

    public String generatePaymentQrRaw(String bankBin, String accountNumber,
            String accountName, double amount, String billCode) {
        if (bankBin == null || bankBin.trim().isEmpty()) {
            throw new IllegalArgumentException("Bank BIN khong duoc null hoac rong.");
        }
        if (accountNumber == null || accountNumber.trim().isEmpty()) {
            throw new IllegalArgumentException("So tai khoan khong duoc null hoac rong.");
        }
        String desc = "TT HOA DON " + (billCode != null ? billCode.trim() : "");
        return generateVietQrContent(bankBin.trim(), accountNumber.trim(),
                accountName, amount, desc);
    }

    public String generateVietQrUrl(String bankBin, String accountNumber,
            String accountName, double amount, String billCode) {
        if (bankBin == null || bankBin.trim().isEmpty()) {
            throw new IllegalArgumentException("Bank BIN khong duoc null.");
        }
        if (accountNumber == null || accountNumber.trim().isEmpty()) {
            throw new IllegalArgumentException("So tai khoan khong duoc null.");
        }

        String addInfo = "TT HOA DON " + (billCode != null ? billCode.trim() : "");
        String accName = accountName != null ? accountName : "";

        String url = "https://img.vietqr.io/image/"
                + bankBin.trim()
                + "-"
                + accountNumber.trim()
                + "-compact.png"
                + "?amount=" + (long) amount
                + "&addInfo=" + encodeUrl(addInfo)
                + "&accountName=" + encodeUrl(accName);
        return url;
    }

    public String generateQrDataUrl(String bankBin, String accountNumber,
            String accountName, double amount, String billCode) {
        String raw = generatePaymentQrRaw(bankBin, accountNumber, accountName, amount, billCode);
        String base64 = generateQrCodeBase64(raw, DEFAULT_SIZE);
        return "data:image/png;base64," + base64;
    }

    private String encodeUrl(String value) {
        try {
            return URLEncoder.encode(value, "UTF-8");
        } catch (Exception e) {
            return value != null ? value : "";
        }
    }
}
