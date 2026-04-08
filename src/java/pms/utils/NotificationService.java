package pms.utils;

import java.io.Serializable;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import pms.model.UserDAO;
import pms.model.UserDTO;

public class NotificationService implements Serializable {

    private static final long serialVersionUID = 1L;

    private static final ConcurrentHashMap<String, List<Notification>> userNotifications = new ConcurrentHashMap<>();
    private static final ConcurrentHashMap<String, Long> lastActivity = new ConcurrentHashMap<>();

    public static final String TYPE_WORKORDER = "workorder";
    public static final String TYPE_PAYMENT = "payment";
    public static final String TYPE_DEFECT = "defect";
    public static final String TYPE_INVENTORY = "inventory";
    public static final String TYPE_SYSTEM = "system";
    public static final String TYPE_PURCHASE_ORDER = "purchase_order";

    public static class Notification implements Serializable {
        private static final long serialVersionUID = 1L;
        private final String id;
        private final String type;
        private final String title;
        private final String message;
        private final String link;
        private final long timestamp;
        private boolean read;

        public Notification(String type, String title, String message, String link) {
            this.id = System.currentTimeMillis() + "_" + (int) (Math.random() * 10000);
            this.type = type;
            this.title = title;
            this.message = message;
            this.link = link != null ? link : "#";
            this.timestamp = System.currentTimeMillis();
            this.read = false;
        }

        public String getId() { return id; }
        public String getType() { return type; }
        public String getTitle() { return title; }
        public String getMessage() { return message; }
        public String getLink() { return link; }
        public long getTimestamp() { return timestamp; }
        public boolean isRead() { return read; }
        public void setRead(boolean read) { this.read = read; }

        public String toJson() {
            StringBuilder sb = new StringBuilder();
            sb.append("{\"id\":\"").append(id).append("\",");
            sb.append("\"type\":\"").append(type != null ? type : "").append("\",");
            sb.append("\"title\":\"").append(esc(title)).append("\",");
            sb.append("\"message\":\"").append(esc(message)).append("\",");
            sb.append("\"link\":\"").append(esc(link)).append("\",");
            sb.append("\"timestamp\":").append(timestamp).append(",");
            sb.append("\"read\":").append(read).append("}");
            return sb.toString();
        }

        private static String esc(String s) {
            if (s == null) return "";
            return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "").replace("\t", "\\t");
        }
    }

    public static void pushNotification(String username, Notification notification) {
        if (username == null || notification == null) return;
        userNotifications.computeIfAbsent(username, k -> new CopyOnWriteArrayList<>());
        List<Notification> list = userNotifications.get(username);
        synchronized (list) {
            list.add(0, notification);
            if (list.size() > 50) {
                list.remove(list.size() - 1);
            }
        }
        lastActivity.put(username, System.currentTimeMillis());
    }

    public static void pushToAll(Notification notification) {
        if (notification == null) return;
        for (String username : userNotifications.keySet()) {
            pushNotification(username, notification);
        }
    }

    public static void pushToAdmins(Notification notification) {
        if (notification == null) return;
        for (String adminUsername : getAdminUsernames()) {
            pushNotification(adminUsername, notification);
        }
    }

    public static List<Notification> getNotifications(String username) {
        if (username == null) return new ArrayList<>();
        List<Notification> list = userNotifications.get(username);
        if (list == null) return new ArrayList<>();
        return new ArrayList<>(list);
    }

    public static List<Notification> getUnreadNotifications(String username) {
        List<Notification> all = getNotifications(username);
        List<Notification> unread = new ArrayList<>();
        for (Notification n : all) {
            if (!n.isRead()) unread.add(n);
        }
        return unread;
    }

    public static int getUnreadCount(String username) {
        return getUnreadNotifications(username).size();
    }

    public static void markAllRead(String username) {
        if (username == null) return;
        List<Notification> list = userNotifications.get(username);
        if (list == null) return;
        for (Notification n : list) {
            n.setRead(true);
        }
    }

    public static void markRead(String username, String notificationId) {
        if (username == null || notificationId == null) return;
        List<Notification> list = userNotifications.get(username);
        if (list == null) return;
        for (Notification n : list) {
            if (n.getId().equals(notificationId)) {
                n.setRead(true);
                break;
            }
        }
    }

    public static void clearNotifications(String username) {
        if (username == null) return;
        List<Notification> list = userNotifications.get(username);
        if (list != null) {
            list.clear();
        }
    }

    public static void removeNotification(String username, String notificationId) {
        if (username == null || notificationId == null) return;
        List<Notification> list = userNotifications.get(username);
        if (list == null) return;
        list.removeIf(n -> n.getId().equals(notificationId));
    }

    public static String buildSseEvent(Notification notification) {
        return "data: " + notification.toJson() + "\n\n";
    }

    public static String buildHeartbeatEvent() {
        return "data: {\"type\":\"heartbeat\",\"timestamp\":" + System.currentTimeMillis() + "}\n\n";
    }

    public static void notifyWorkOrderCreated(int woId, String productName) {
        pushToAll(new Notification(
                TYPE_WORKORDER,
                "Lệnh sản xuất mới",
                "Lệnh sản xuất #" + woId + " (" + safeText(productName) + ") vừa được tạo.",
                "MainController?action=updateWorkOrder&id=" + woId));
    }

    public static void notifyWorkOrderCompleted(int woId, String productName) {
        pushToAll(new Notification(
                TYPE_WORKORDER,
                "Lệnh sản xuất hoàn thành",
                "Lệnh sản xuất #" + woId + " (" + safeText(productName) + ") đã hoàn thành.",
                "MainController?action=listWorkOrder"));
    }

    public static void notifyPaymentReceived(int paymentId, double amount) {
        pushToAll(new Notification(
                TYPE_PAYMENT,
                "Đã nhận thanh toán",
                "Thanh toán #" + paymentId + " - " + String.format("%,.0f", amount) + " VND đã được xác nhận.",
                "payment-list.jsp"));
    }

    public static void notifyLowStock(String itemName, int currentStock) {
        pushToAll(new Notification(
                TYPE_INVENTORY,
                "Cảnh báo tồn kho",
                "Vật tư '" + safeText(itemName) + "' còn " + currentStock + " và đang thấp hơn mức an toàn.",
                "MainController?action=searchItem"));
    }

    public static void notifyDefectDetected(String woId, String defectReason) {
        Notification notification = new Notification(
                TYPE_DEFECT,
                "Phát hiện lỗi QC",
                "WO#" + safeText(woId) + " có kết quả QC không đạt: " + safeText(defectReason) + ".",
                "QcController?action=list"
        );
        pushToAdmins(notification);
        sendDefectEmailToAdmins(woId, defectReason);
    }

    public static void notifyPurchaseOrderRequested(int poId, String itemName, int quantity, String requestedBy) {
        Notification notification = new Notification(
                TYPE_PURCHASE_ORDER,
                "Đề nghị nhập vật tư mới",
                safeText(requestedBy) + " vừa đề nghị nhập " + quantity + " " + safeText(itemName) + " (PO#" + poId + ").",
                "MainController?action=listPurchaseOrder"
        );
        pushToAdmins(notification);
        sendPurchaseOrderEmailToAdmins(poId, itemName, quantity, requestedBy);
    }

    private static List<String> getAdminUsernames() {
        List<String> usernames = new ArrayList<>();
        try {
            UserDAO userDAO = new UserDAO();
            List<UserDTO> admins = userDAO.getUsersByRole("admin");
            for (UserDTO admin : admins) {
                if (admin != null && admin.isActive() && admin.getUsername() != null && !admin.getUsername().trim().isEmpty()) {
                    usernames.add(admin.getUsername().trim());
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return usernames;
    }

    private static List<String> getAdminEmails() {
        List<String> emails = new ArrayList<>();
        try {
            UserDAO userDAO = new UserDAO();
            List<UserDTO> admins = userDAO.getUsersByRole("admin");
            for (UserDTO admin : admins) {
                if (admin != null && admin.isActive() && admin.getEmail() != null) {
                    String email = admin.getEmail().trim();
                    if (!email.isEmpty()) {
                        emails.add(email);
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return emails;
    }

    private static void sendPurchaseOrderEmailToAdmins(int poId, String itemName, int quantity, String requestedBy) {
        List<String> adminEmails = getAdminEmails();
        if (adminEmails.isEmpty()) {
            return;
        }

        EmailService emailService = new SystemConfigService().createEmailService();
        String subject = stripAccents("[PMS] Đề nghị nhập vật tư mới - PO#") + poId;
        String body = buildPurchaseOrderEmail(poId, itemName, quantity, requestedBy);
        for (String adminEmail : adminEmails) {
            emailService.sendEmail(adminEmail, subject, body);
        }
    }

    private static void sendDefectEmailToAdmins(String woId, String defectReason) {
        List<String> adminEmails = getAdminEmails();
        if (adminEmails.isEmpty()) {
            return;
        }

        EmailService emailService = new SystemConfigService().createEmailService();
        String subject = stripAccents("[PMS] Cảnh báo QC lỗi - WO#") + safeText(woId);
        String body = buildQcDefectEmail(woId, defectReason);
        for (String adminEmail : adminEmails) {
            emailService.sendEmail(adminEmail, subject, body);
        }
    }

    private static String buildPurchaseOrderEmail(int poId, String itemName, int quantity, String requestedBy) {
        return "<div style='font-family:Arial,sans-serif;max-width:600px;margin:0 auto;'>"
                + "<div style='background:#0f766e;color:#fff;padding:20px;text-align:center;'>"
                + "<h2 style='margin:0;'>Đề nghị nhập vật tư mới</h2>"
                + "</div>"
                + "<div style='padding:24px;'>"
                + "<p>Hệ thống vừa ghi nhận một đề nghị nhập vật tư mới từ người dùng.</p>"
                + "<table style='width:100%;border-collapse:collapse;margin:20px 0;'>"
                + row("Mã đề nghị", "PO#" + poId)
                + row("Vật tư", itemName)
                + row("Số lượng", String.valueOf(quantity))
                + row("Người đề nghị", requestedBy)
                + row("Thời gian", new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(new java.util.Date()))
                + "</table>"
                + "<p>Vui lòng vào màn hình đề nghị mua vật tư để xem và xử lý.</p>"
                + "</div></div>";
    }

    private static String buildQcDefectEmail(String woId, String defectReason) {
        return "<div style='font-family:Arial,sans-serif;max-width:600px;margin:0 auto;'>"
                + "<div style='background:#b91c1c;color:#fff;padding:20px;text-align:center;'>"
                + "<h2 style='margin:0;'>Cảnh báo kiểm tra chất lượng</h2>"
                + "</div>"
                + "<div style='padding:24px;'>"
                + "<p>Hệ thống vừa ghi nhận một kết quả QC không đạt.</p>"
                + "<table style='width:100%;border-collapse:collapse;margin:20px 0;'>"
                + row("Lệnh sản xuất", "WO#" + safeText(woId))
                + row("Nội dung lỗi", defectReason)
                + row("Thời gian", new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(new java.util.Date()))
                + "</table>"
                + "<p>Vui lòng vào màn hình QC để kiểm tra chi tiết và xử lý.</p>"
                + "</div></div>";
    }

    private static String row(String label, String value) {
        return "<tr>"
                + "<td style='padding:10px 12px;border:1px solid #e5e7eb;font-weight:bold;width:180px;'>" + safeText(label) + "</td>"
                + "<td style='padding:10px 12px;border:1px solid #e5e7eb;'>" + safeText(value) + "</td>"
                + "</tr>";
    }

    private static String safeText(String text) {
        if (text == null || text.trim().isEmpty()) {
            return "-";
        }
        return text.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private static String stripAccents(String value) {
        if (value == null) {
            return "";
        }
        String normalized = Normalizer.normalize(value, Normalizer.Form.NFD);
        normalized = normalized.replaceAll("\\p{M}+", "");
        return normalized.replace('đ', 'd').replace('Đ', 'D');
    }
}
