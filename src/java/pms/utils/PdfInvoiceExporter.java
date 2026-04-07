package pms.utils;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;
import pms.model.BillDTO;
import pms.model.BillLineDTO;
import pms.model.CustomerDTO;
import pms.model.PaymentDTO;

public final class PdfInvoiceExporter {

    private PdfInvoiceExporter() {
    }

    public static byte[] exportInvoice(BillDTO bill,
            CustomerDTO customer,
            PaymentDTO payment,
            List<BillLineDTO> lines,
            String companyName,
            String companyAddress,
            String companyPhone,
            String companyEmail) {

        DecimalFormat money = new DecimalFormat("#,###");
        SimpleDateFormat dateTime = new SimpleDateFormat("dd/MM/yyyy HH:mm");
        java.util.Date issuedAt = bill != null && bill.getBill_created_at() != null
                ? new java.util.Date(bill.getBill_created_at().getTime())
                : (bill != null ? bill.getBill_date() : null);

        String paymentStatus = "Chờ thanh toán";
        if (payment != null && payment.getStatus() != null) {
            if ("PAID".equalsIgnoreCase(payment.getStatus())) {
                paymentStatus = "Đã thanh toán";
            } else if ("EXPIRED".equalsIgnoreCase(payment.getStatus())) {
                paymentStatus = "Hết hạn";
            }
        }

        String paymentCode = (payment != null && payment.getPaymentId() > 0)
                ? String.format("PAY-%04d", payment.getPaymentId())
                : "-";
        String paidAt = (payment != null && payment.getPaidAt() != null)
                ? dateTime.format(payment.getPaidAt())
                : "-";

        List<String> contentLines = new ArrayList<>();
        contentLines.add(safe(companyName, "PMS MANUFACTURING"));
        contentLines.add(safe(companyAddress, "Địa chỉ chưa cập nhật"));
        contentLines.add("Hotline: " + safe(companyPhone, "Chưa cập nhật") + " | Email: " + safe(companyEmail, "Chưa cập nhật"));
        contentLines.add("");
        contentLines.add("HÓA ĐƠN / INVOICE");
        contentLines.add("Mã hóa đơn: #" + (bill != null ? String.format("%06d", bill.getBill_id()) : "-"));
        contentLines.add("Ngày lập: " + (issuedAt != null ? dateTime.format(issuedAt) : "-"));
        contentLines.add("");
        contentLines.add("KHÁCH HÀNG");
        contentLines.add("Tên: " + safe(customer != null ? customer.getCustomer_name() : null, "Khách lẻ"));
        contentLines.add("SĐT: " + safe(customer != null ? customer.getPhone() : null, "Chưa có SĐT"));
        contentLines.add("Email: " + safe(customer != null ? customer.getEmail() : null, "Chưa có email"));
        contentLines.add("");
        contentLines.add("THÔNG TIN GIAO DỊCH");
        contentLines.add("Mã giao dịch: " + paymentCode);
        contentLines.add("Trạng thái: " + paymentStatus);
        if (payment != null && "PAID".equalsIgnoreCase(payment.getStatus())) {
            contentLines.add("Đã thanh toán lúc: " + paidAt);
        }
        contentLines.add("");
        contentLines.add("CHI TIẾT HÓA ĐƠN");
        if (lines != null && !lines.isEmpty()) {
            int index = 1;
            for (BillLineDTO line : lines) {
                String item = safe(line.getItemType(), "-");
                String qty = String.valueOf(line.getQuantity());
                String unitPrice = money.format(line.getUnitPrice()) + " VND";
                String total = money.format(line.getLineTotal()) + " VND";
                contentLines.add(index + ". " + item);
                contentLines.add("   SL: " + qty + " | Đơn giá: " + unitPrice + " | Thành tiền: " + total);
                index++;
            }
        } else {
            contentLines.add("Không có chi tiết dòng hàng.");
        }
        contentLines.add("");
        contentLines.add("Tổng tiền: " + (bill != null ? money.format(bill.getTotal_amount()) + " VND" : "-"));
        contentLines.add("Phương thức thanh toán: Chuyển khoản / QR");
        contentLines.add("Ghi chú: Thank you for choosing us!");

        return buildPdf(contentLines);
    }

    private static byte[] buildPdf(List<String> lines) {
        StringBuilder content = new StringBuilder();
        content.append("BT\n");
        content.append("/F1 12 Tf\n");
        content.append("14 TL\n");
        content.append("50 790 Td\n");

        boolean firstLine = true;
        for (String line : lines) {
            if (!firstLine) {
                content.append("T*\n");
            }
            firstLine = false;
            content.append("(").append(escapePdfText(toPdfText(line))).append(") Tj\n");
        }
        content.append("ET\n");

        byte[] contentBytes = content.toString().getBytes(StandardCharsets.ISO_8859_1);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        List<Integer> offsets = new ArrayList<>();

        writeAscii(out, "%PDF-1.4\n");
        writeAscii(out, "%âãÏÓ\n");

        offsets.add(out.size());
        writeAscii(out, "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n");

        offsets.add(out.size());
        writeAscii(out, "2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n");

        offsets.add(out.size());
        writeAscii(out, "3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>\nendobj\n");

        offsets.add(out.size());
        writeAscii(out, "4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>\nendobj\n");

        offsets.add(out.size());
        writeAscii(out, "5 0 obj\n<< /Length " + contentBytes.length + " >>\nstream\n");
        out.write(contentBytes, 0, contentBytes.length);
        writeAscii(out, "endstream\nendobj\n");

        int xrefOffset = out.size();
        writeAscii(out, "xref\n0 6\n");
        writeAscii(out, "0000000000 65535 f \n");
        for (Integer offset : offsets) {
            writeAscii(out, String.format("%010d 00000 n \n", offset));
        }
        writeAscii(out, "trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n" + xrefOffset + "\n%%EOF");
        return out.toByteArray();
    }

    private static String safe(String value, String fallback) {
        return value != null && !value.trim().isEmpty() ? value.trim() : fallback;
    }

    private static void writeAscii(ByteArrayOutputStream out, String value) {
        byte[] bytes = value.getBytes(StandardCharsets.ISO_8859_1);
        out.write(bytes, 0, bytes.length);
    }

    private static String toPdfText(String value) {
        StringBuilder sb = new StringBuilder();
        String source = value != null ? value : "";
        for (int i = 0; i < source.length(); i++) {
            char c = source.charAt(i);
            sb.append(mapVietnameseChar(c));
        }
        return sb.toString();
    }

    private static char mapVietnameseChar(char c) {
        switch (c) {
            case 'À': case 'Á': case 'Ả': case 'Ã': case 'Ạ': case 'Ă': case 'Ằ': case 'Ắ': case 'Ẳ': case 'Ẵ': case 'Ặ': case 'Â': case 'Ầ': case 'Ấ': case 'Ẩ': case 'Ẫ': case 'Ậ': return 'A';
            case 'à': case 'á': case 'ả': case 'ã': case 'ạ': case 'ă': case 'ằ': case 'ắ': case 'ẳ': case 'ẵ': case 'ặ': case 'â': case 'ầ': case 'ấ': case 'ẩ': case 'ẫ': case 'ậ': return 'a';
            case 'È': case 'É': case 'Ẻ': case 'Ẽ': case 'Ẹ': case 'Ê': case 'Ề': case 'Ế': case 'Ể': case 'Ễ': case 'Ệ': return 'E';
            case 'è': case 'é': case 'ẻ': case 'ẽ': case 'ẹ': case 'ê': case 'ề': case 'ế': case 'ể': case 'ễ': case 'ệ': return 'e';
            case 'Ì': case 'Í': case 'Ỉ': case 'Ĩ': case 'Ị': return 'I';
            case 'ì': case 'í': case 'ỉ': case 'ĩ': case 'ị': return 'i';
            case 'Ò': case 'Ó': case 'Ỏ': case 'Õ': case 'Ọ': case 'Ô': case 'Ồ': case 'Ố': case 'Ổ': case 'Ỗ': case 'Ộ': case 'Ơ': case 'Ờ': case 'Ớ': case 'Ở': case 'Ỡ': case 'Ợ': return 'O';
            case 'ò': case 'ó': case 'ỏ': case 'õ': case 'ọ': case 'ô': case 'ồ': case 'ố': case 'ổ': case 'ỗ': case 'ộ': case 'ơ': case 'ờ': case 'ớ': case 'ở': case 'ỡ': case 'ợ': return 'o';
            case 'Ù': case 'Ú': case 'Ủ': case 'Ũ': case 'Ụ': case 'Ư': case 'Ừ': case 'Ứ': case 'Ử': case 'Ữ': case 'Ự': return 'U';
            case 'ù': case 'ú': case 'ủ': case 'ũ': case 'ụ': case 'ư': case 'ừ': case 'ứ': case 'ử': case 'ữ': case 'ự': return 'u';
            case 'Ỳ': case 'Ý': case 'Ỷ': case 'Ỹ': case 'Ỵ': return 'Y';
            case 'ỳ': case 'ý': case 'ỷ': case 'ỹ': case 'ỵ': return 'y';
            case 'Đ': return 'D';
            case 'đ': return 'd';
            default: return c;
        }
    }

    private static String escapePdfText(String value) {
        StringBuilder escaped = new StringBuilder();
        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);
            if (c == '\\' || c == '(' || c == ')') {
                escaped.append('\\');
            }
            if (c == '\r' || c == '\n') {
                escaped.append(' ');
            } else {
                escaped.append(c);
            }
        }
        return escaped.toString();
    }
}
