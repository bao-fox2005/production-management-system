package pms.utils;

import com.openhtmltopdf.outputdevice.helper.BaseRendererBuilder.FontStyle;
import com.openhtmltopdf.pdfboxout.PdfRendererBuilder;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.Base64;
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
        SimpleDateFormat sdfDateTime = new SimpleDateFormat("dd/MM/yyyy HH:mm");

        java.util.Date invoiceIssuedAt = bill != null && bill.getBill_created_at() != null
                ? new java.util.Date(bill.getBill_created_at().getTime())
                : (bill != null ? bill.getBill_date() : null);

        String customerName = safe(customer != null ? customer.getCustomer_name() : null, "Khách lẻ");
        String customerEmail = safe(customer != null ? customer.getEmail() : null, "Chưa có email");
        String customerPhone = safe(customer != null ? customer.getPhone() : null, "Chưa có SĐT");

        String paymentStatusCode = payment != null && payment.getStatus() != null
                ? payment.getStatus().toUpperCase()
                : "PENDING";
        String paymentStatusLabel = "Chờ thanh toán";
        if ("PAID".equals(paymentStatusCode)) {
            paymentStatusLabel = "Đã thanh toán";
        } else if ("EXPIRED".equals(paymentStatusCode)) {
            paymentStatusLabel = "Hết hạn";
        }

        String paidAt = (payment != null && payment.getPaidAt() != null)
                ? sdfDateTime.format(payment.getPaidAt())
                : "-";
        String paymentCode = (payment != null && payment.getPaymentId() > 0)
                ? String.format("PAY-%04d", payment.getPaymentId())
                : "-";
        String invoiceNo = bill != null ? String.format("%06d", bill.getBill_id()) : "-";
        String invoiceDateText = invoiceIssuedAt != null ? sdfDateTime.format(invoiceIssuedAt) : "-";
        String totalAmount = bill != null ? money.format(bill.getTotal_amount()) + " VND" : "-";

        String statusClass = "status-pending";
        if ("PAID".equals(paymentStatusCode)) {
            statusClass = "status-paid";
        } else if ("EXPIRED".equals(paymentStatusCode)) {
            statusClass = "status-expired";
        }

        StringBuilder rows = new StringBuilder();
        if (lines == null || lines.isEmpty()) {
            rows.append("<tr><td colspan='4' class='empty'>Không có dòng hàng</td></tr>");
        } else {
            for (BillLineDTO line : lines) {
                if (line == null) {
                    continue;
                }
                rows.append("<tr>")
                        .append("<td class='item'>").append(escapeHtml(safe(line.getItemType(), "-"))).append("</td>")
                        .append("<td class='num'>").append(line.getQuantity()).append("</td>")
                        .append("<td class='num'>").append(escapeHtml(money.format(line.getUnitPrice()))).append(" VND</td>")
                        .append("<td class='amount'>").append(escapeHtml(money.format(line.getLineTotal()))).append(" VND</td>")
                        .append("</tr>");
            }
        }

        String logoMarkup = resolveLogoMarkup();

        String html = "<!DOCTYPE html>"
                + "<html lang='vi'><head>"
                + "<meta charset='UTF-8' />"
                + "<title>Hoa don " + escapeHtml(invoiceNo) + "</title>"
                + "<style>"
                + "@page { size: A4; margin: 10mm; }"
                + "html, body { margin: 0; padding: 0; font-family: 'InvoiceSans', Arial, sans-serif; color: #0f172a; font-size: 12px; background: #ffffff; }"
                + "* { box-sizing: border-box; }"
                + "body { line-height: 1.45; }"
                + ".page { width: 100%; }"
                + ".paper { width: 100%; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 24px; }"
                + ".header { border-bottom: 1px solid #e2e8f0; padding: 28px 34px; }"
                + ".header-table { width: 100%; border-collapse: collapse; }"
                + ".header-table td { vertical-align: top; }"
                + ".brand-wrap { width: 65%; }"
                + ".brand-table { width: 100%; border-collapse: collapse; }"
                + ".brand-table td { vertical-align: middle; }"
                + ".logo-cell { width: 72px; padding-right: 14px; }"
                + ".logo-frame { width: 56px; height: 56px; border: 1px solid #e2e8f0; border-radius: 14px; padding: 4px; background: #ffffff; display: block; }"
                + ".logo { width: 48px; height: 48px; display: block; }"
                + ".logo-fallback { width: 56px; height: 56px; border-radius: 14px; background: #1d4ed8; color: #ffffff; text-align: center; line-height: 56px; font-size: 18px; font-weight: 700; letter-spacing: 0.08em; display: block; }"
                + ".brand { font-size: 14px; font-weight: 700; letter-spacing: 0.16em; color: #1f2937; text-transform: uppercase; }"
                + ".company-sub { margin-top: 4px; font-size: 11px; color: #64748b; }"
                + ".invoice-meta { width: 35%; text-align: right; }"
                + ".invoice-no-label { font-size: 11px; font-weight: 600; text-transform: uppercase; color: #64748b; letter-spacing: 0.12em; }"
                + ".invoice-no-value { margin-top: 4px; font-size: 24px; font-weight: 700; color: #0f172a; }"
                + ".invoice-date { margin-top: 4px; font-size: 11px; color: #64748b; }"
                + ".invoice-title { margin-top: 22px; font-size: 28px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; }"
                + ".cards-wrap { padding: 24px 34px 0; }"
                + ".cards { width: 100%; border-collapse: separate; border-spacing: 0; table-layout: fixed; }"
                + ".cards td { width: 50%; vertical-align: top; }"
                + ".cards td:first-child { padding-right: 12px; }"
                + ".cards td:last-child { padding-left: 12px; }"
                + ".card { border: 1px solid #e2e8f0; border-radius: 16px; background: #ffffff; padding: 18px; height: 168px; }"
                + ".card-title { font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.14em; color: #64748b; }"
                + ".card-main { margin-top: 8px; font-size: 18px; font-weight: 700; color: #0f172a; min-height: 56px; }"
                + ".card-line { margin-top: 4px; font-size: 13px; color: #475569; white-space: nowrap; min-height: 18px; }"
                + ".status { display: inline-block; vertical-align: middle; padding: 1px 10px; border-radius: 999px; border: 1px solid transparent; font-size: 11px; font-weight: 600; line-height: 1; white-space: nowrap; text-align: center; }"
                + ".status-paid { background: transparent; color: #027a48; border: 0; padding: 0; border-radius: 0; }"
                + ".status-pending { background: transparent; color: #b54708; border: 0; padding: 0; border-radius: 0; }"
                + ".status-expired { background: #fef3f2; color: #b42318; border-color: #fecdca; }"
                + ".content { padding: 24px 34px 32px; }"
                + ".table-wrap { border: 1px solid #e2e8f0; border-radius: 16px; overflow: hidden; }"
                + ".items { width: 100%; border-collapse: collapse; table-layout: fixed; }"
                + ".items thead th { background: #f1f3f5; color: #334155; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.08em; padding: 12px 14px; text-align: left; }"
                + ".items thead th.num, .items tbody td.num, .items tbody td.amount, .items tfoot td { text-align: right; }"
                + ".items tbody td { padding: 14px; border-top: 1px solid #f1f5f9; color: #334155; font-size: 13px; }"
                + ".items tbody td.item { font-weight: 600; color: #1e293b; }"
                + ".items tbody td.amount { font-weight: 700; color: #0f172a; }"
                + ".items tfoot td { background: #f8fafc; padding: 16px 14px; }"
                + ".total-label { font-size: 16px; font-weight: 700; color: #334155; }"
                + ".total-value { font-size: 24px; font-weight: 700; color: #0f172a; white-space: nowrap; }"
                + ".empty { text-align: center !important; color: #64748b; padding: 24px 14px; }"
                + ".note-box { margin-top: 24px; border: 1px solid #e2e8f0; border-radius: 16px; background: #ffffff; padding: 18px; }"
                + ".note-line { font-size: 13px; color: #334155; }"
                + ".note-line + .note-line { margin-top: 8px; }"
                + ".note-line strong { font-weight: 700; }"
                + "</style>"
                + "</head><body>"
                + "<div class='page'>"
                + "<div class='paper'>"
                + "<div class='header'>"
                + "<table class='header-table'><tr>"
                + "<td class='brand-wrap'>"
                + "<table class='brand-table'><tr>"
                + "<td class='logo-cell'>"
                + logoMarkup
                + "</td>"
                + "<td>"
                + "<div class='brand'>" + escapeHtml(safe(companyName, "PMS MANUFACTURING")) + "</div>"
                + "<div class='company-sub'>" + escapeHtml(safe(companyAddress, "123 Anywhere St., Any City")) + "</div>"
                + "<div class='company-sub'>Hotline: " + escapeHtml(safe(companyPhone, "1900 6868"))
                + " &#183; Email: " + escapeHtml(safe(companyEmail, "contact@pms.local")) + "</div>"
                + "</td></tr></table>"
                + "</td>"
                + "<td class='invoice-meta'>"
                + "<div class='invoice-no-label'>Invoice No.</div>"
                + "<div class='invoice-no-value'>" + escapeHtml(invoiceNo) + "</div>"
                + "<div class='invoice-date'>Ngày lập: <strong>" + escapeHtml(invoiceDateText) + "</strong></div>"
                + "</td>"
                + "</tr></table>"
                + "<div class='invoice-title'>Invoice</div>"
                + "</div>"
                + "<div class='cards-wrap'>"
                + "<table class='cards'><tr>"
                + "<td><div class='card'>"
                + "<div class='card-title'>Billed to</div>"
                + "<div class='card-main'>" + escapeHtml(customerName) + "</div>"
                + "<div class='card-line'>" + escapeHtml(customerPhone) + "</div>"
                + "<div class='card-line'>" + escapeHtml(customerEmail) + "</div>"
                + "</div></td>"
                + "<td><div class='card'>"
                + "<div class='card-title'>Thông tin giao dịch</div>"
                + "<div class='card-line' style='margin-top:8px;'>Mã giao dịch: <strong>" + escapeHtml(paymentCode) + "</strong></div>"
                + "<div class='card-line'>Trạng thái: <span class='status " + statusClass + "'>" + escapeHtml(paymentStatusLabel) + "</span></div>"
                + ("PAID".equals(paymentStatusCode)
                ? "<div class='card-line'>Đã thanh toán lúc: <strong>" + escapeHtml(paidAt) + "</strong></div>"
                : "<div class='card-line'>&#160;</div>")
                + "</div></td>"
                + "</tr></table>"
                + "</div>"
                + "<div class='content'>"
                + "<div class='table-wrap'>"
                + "<table class='items'>"
                + "<thead><tr>"
                + "<th style='width:40%;'>Item</th>"
                + "<th class='num' style='width:15%;'>Quantity</th>"
                + "<th class='num' style='width:20%;'>Price</th>"
                + "<th class='num' style='width:25%;'>Amount</th>"
                + "</tr></thead>"
                + "<tbody>" + rows + "</tbody>"
                + "<tfoot><tr>"
                + "<td colspan='2'></td>"
                + "<td class='total-label'>Total</td>"
                + "<td class='total-value'>" + escapeHtml(totalAmount) + "</td>"
                + "</tr></tfoot>"
                + "</table>"
                + "</div>"
                + "<div class='note-box'>"
                + "<div class='note-line'><strong>Payment method:</strong> Chuyển khoản / QR</div>"
                + "<div class='note-line'><strong>Note:</strong> Thank you for choosing us!</div>"
                + "</div>"
                + "</div>"
                + "</div>"
                + "</div>"
                + "</body></html>";

        return buildPdf(html);
    }

    private static byte[] buildPdf(String html) {
        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            PdfRendererBuilder builder = new PdfRendererBuilder();
            builder.useFastMode();

            File fontFile = resolveFontFile();
            if (fontFile != null) {
                builder.useFont(fontFile, "InvoiceSans", 400, FontStyle.NORMAL, false);
            }

            File boldFontFile = resolveBoldFontFile();
            if (boldFontFile != null) {
                builder.useFont(boldFontFile, "InvoiceSans", 700, FontStyle.NORMAL, false);
            }

            String baseUri = new File("web").exists()
                    ? new File("web").toURI().toString()
                    : new File(".").toURI().toString();

            builder.withHtmlContent(html, baseUri);
            builder.toStream(out);
            builder.run();
            return out.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Không thể tạo PDF hóa đơn", e);
        }
    }

    private static File resolveFontFile() {
        String[] candidates = new String[]{
            "web/fonts/NotoSans-Regular.ttf",
            "src/conf/NotoSans-Regular.ttf",
            "build/web/fonts/NotoSans-Regular.ttf",
            "build/web/WEB-INF/classes/NotoSans-Regular.ttf",
            "C:/Windows/Fonts/arial.ttf",
            "C:/Windows/Fonts/tahoma.ttf",
            "C:/Windows/Fonts/segoeui.ttf"
        };

        for (String candidate : candidates) {
            File file = new File(candidate);
            if (file.exists() && file.isFile()) {
                return file;
            }
        }
        return null;
    }

    private static File resolveBoldFontFile() {
        String[] candidates = new String[]{
            "web/fonts/NotoSans-Bold.ttf",
            "src/conf/NotoSans-Bold.ttf",
            "build/web/fonts/NotoSans-Bold.ttf",
            "build/web/WEB-INF/classes/NotoSans-Bold.ttf",
            "C:/Windows/Fonts/arialbd.ttf",
            "C:/Windows/Fonts/tahomabd.ttf",
            "C:/Windows/Fonts/seguisb.ttf",
            "C:/Windows/Fonts/segoeuib.ttf"
        };

        for (String candidate : candidates) {
            File file = new File(candidate);
            if (file.exists() && file.isFile()) {
                return file;
            }
        }
        return resolveFontFile();
    }

    private static String resolveLogoMarkup() {
        String logoBase64 = resolveLogoBase64();
        if (!logoBase64.isEmpty()) {
            return "<div class='logo-frame'><img class='logo' src='data:image/png;base64,"
                    + logoBase64
                    + "' alt='PMS Logo' width='48' height='48' /></div>";
        }

        String logoUri = resolveLogoFileUri();
        if (!logoUri.isEmpty()) {
            return "<div class='logo-frame'><img class='logo' src='" + escapeHtml(logoUri)
                    + "' alt='PMS Logo' width='48' height='48' /></div>";
        }

        return "<div class='logo-fallback'>PMS</div>";
    }

    private static String resolveLogoFileUri() {
        String[] candidates = new String[]{
            "web/img/logo.png",
            "src/img/logo.png",
            "build/web/img/logo.png",
            "build/web/resources/img/logo.png"
        };

        for (String candidate : candidates) {
            File file = new File(candidate);
            if (file.exists() && file.isFile()) {
                return file.toURI().toString();
            }
        }

        return "";
    }

    private static String resolveLogoBase64() {
        String[] classpathCandidates = new String[]{
            "/pms/utils/logo-base64.txt",
            "pms/utils/logo-base64.txt",
            "/logo-base64.txt",
            "logo-base64.txt",
            "/conf/logo-base64.txt",
            "conf/logo-base64.txt"
        };

        for (String candidate : classpathCandidates) {
            String base64 = sanitizeBase64(readClasspathText(candidate));
            if (!base64.isEmpty()) {
                return base64;
            }
        }

        String[] fileCandidates = new String[]{
            "src/java/pms/utils/logo-base64.txt",
            "src/conf/logo-base64.txt",
            "logo-base64.txt",
            "build/web/logo-base64.txt",
            "build/web/WEB-INF/classes/logo-base64.txt",
            "build/web/WEB-INF/classes/pms/utils/logo-base64.txt"
        };

        for (String candidate : fileCandidates) {
            File file = new File(candidate);
            if (file.exists() && file.isFile()) {
                try {
                    String base64 = sanitizeBase64(new String(Files.readAllBytes(file.toPath()), StandardCharsets.UTF_8));
                    if (!base64.isEmpty()) {
                        return base64;
                    }
                } catch (Exception ignored) {
                }
            }
        }

        return "";
    }

    private static byte[] readClasspathBytes(String path) {
        try (InputStream input = PdfInvoiceExporter.class.getResourceAsStream(path)) {
            if (input != null) {
                return readAllBytesCompat(input);
            }
        } catch (Exception ignored) {
        }
        try (InputStream input = PdfInvoiceExporter.class.getClassLoader().getResourceAsStream(stripLeadingSlash(path))) {
            if (input != null) {
                return readAllBytesCompat(input);
            }
        } catch (Exception ignored) {
        }
        return null;
    }

    private static byte[] readAllBytesCompat(InputStream input) throws java.io.IOException {
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        byte[] chunk = new byte[4096];
        int bytesRead;
        while ((bytesRead = input.read(chunk)) != -1) {
            buffer.write(chunk, 0, bytesRead);
        }
        return buffer.toByteArray();
    }

    private static String readClasspathText(String path) {
        byte[] bytes = readClasspathBytes(path);
        return bytes == null || bytes.length == 0 ? "" : new String(bytes, StandardCharsets.UTF_8).trim();
    }

    private static String stripLeadingSlash(String value) {
        return value != null && value.startsWith("/") ? value.substring(1) : value;
    }

    private static String sanitizeBase64(String value) {
        if (value == null) {
            return "";
        }

        String sanitized = value.replaceAll("\\s+", "");
        if (sanitized.isEmpty()) {
            return "";
        }

        try {
            Base64.getDecoder().decode(sanitized);
            return sanitized;
        } catch (IllegalArgumentException ex) {
            return "";
        }
    }

    private static String safe(String value, String fallback) {
        return value != null && !value.trim().isEmpty() ? value.trim() : fallback;
    }

    private static String escapeHtml(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }
}
