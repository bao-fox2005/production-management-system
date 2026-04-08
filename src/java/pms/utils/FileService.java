package pms.utils;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Base64;
import javax.servlet.ServletContext;
import javax.servlet.http.Part;

public class FileService {

    private static final String UPLOAD_DIR = "/uploads/encrypted/";
    private static final long MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
    private static final String[] ALLOWED_EXTENSIONS = {
        "pdf", "doc", "docx", "xls", "xlsx", "txt", "jpg", "jpeg", "png", "zip", "rar"
    };

    private final FileEncryptor encryptor;
    private String uploadPath;

    public FileService() {
        this.encryptor = new FileEncryptor();
    }

    public void init(ServletContext servletContext) {
        this.uploadPath = servletContext.getRealPath("") + UPLOAD_DIR;
        File dir = new File(uploadPath);
        if (!dir.exists()) {
            dir.mkdirs();
        }
    }

    public boolean uploadEncryptedFile(Part filePart, String password, int uploaderId,
            String fileDescription, String relatedTable, int relatedId) throws IOException {

        if (filePart == null || filePart.getInputStream() == null) {
            return false;
        }

        String fileName = getFileName(filePart);
        if (fileName == null || fileName.isEmpty()) {
            return false;
        }

        String extension = getFileExtension(fileName);
        if (!isAllowedExtension(extension)) {
            return false;
        }

        if (filePart.getSize() > MAX_FILE_SIZE) {
            return false;
        }

        byte[] fileData = toByteArray(filePart.getInputStream());
        if (fileData == null || fileData.length == 0) {
            return false;
        }

        byte[] encryptedData;
        try {
            encryptedData = encryptor.encrypt(fileData, password);
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }

        String storedFileName = FileEncryptor.generateFileId() + ".enc";
        File outputFile = new File(uploadPath, storedFileName);
        try (FileOutputStream fos = new FileOutputStream(outputFile)) {
            fos.write(encryptedData);
        }

        return saveFileRecord(fileName, storedFileName, extension,
                filePart.getSize(), password, uploaderId, fileDescription, relatedTable, relatedId);
    }

    public byte[] downloadDecryptedFile(int fileId, String password) throws IOException {
        FileRecord record = getFileRecord(fileId);
        if (record == null) {
            return null;
        }

        File encryptedFile = new File(uploadPath, record.storedFileName);
        if (!encryptedFile.exists()) {
            return null;
        }

        byte[] encryptedData;
        try (FileInputStream fis = new FileInputStream(encryptedFile)) {
            encryptedData = toByteArray(fis);
        }

        try {
            return encryptor.decrypt(encryptedData, password);
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    public String downloadDecryptedFileBase64(int fileId, String password) throws IOException {
        byte[] decrypted = downloadDecryptedFile(fileId, password);
        if (decrypted == null) {
            return null;
        }
        return Base64.getEncoder().encodeToString(decrypted);
    }

    public boolean deleteFile(int fileId) {
        FileRecord record = getFileRecord(fileId);
        if (record == null) {
            return false;
        }

        File file = new File(uploadPath, record.storedFileName);
        if (file.exists()) {
            file.delete();
        }

        return deleteFileRecord(fileId);
    }

    public ArrayList<FileRecord> getFilesByRelated(String table, int relatedId) {
        return getFileRecordsByRelated(table, relatedId);
    }

    public ArrayList<FileRecord> getAllFiles() {
        return getAllFileRecords();
    }

    public boolean verifyPassword(int fileId, String password) {
        FileRecord record = getFileRecord(fileId);
        if (record == null) {
            return false;
        }

        File encryptedFile = new File(uploadPath, record.storedFileName);
        if (!encryptedFile.exists()) {
            return false;
        }

        byte[] encryptedData;
        try (FileInputStream fis = new FileInputStream(encryptedFile)) {
            encryptedData = toByteArray(fis);
        } catch (IOException e) {
            return false;
        }

        try {
            byte[] decrypted = encryptor.decrypt(encryptedData, password);
            return decrypted != null;
        } catch (Exception e) {
            return false;
        }
    }

    public boolean changePassword(int fileId, String oldPassword, String newPassword) {
        FileRecord record = getFileRecord(fileId);
        if (record == null) {
            return false;
        }

        File oldFile = new File(uploadPath, record.storedFileName);
        if (!oldFile.exists()) {
            return false;
        }

        byte[] decryptedData;
        try (FileInputStream fis = new FileInputStream(oldFile)) {
            decryptedData = encryptor.decrypt(toByteArray(fis), oldPassword);
        } catch (Exception e) {
            return false;
        }

        byte[] newEncrypted;
        try {
            newEncrypted = encryptor.encrypt(decryptedData, newPassword);
        } catch (Exception e) {
            return false;
        }

        String newStoredName = FileEncryptor.generateFileId() + ".enc";
        File newFile = new File(uploadPath, newStoredName);
        try (FileOutputStream fos = new FileOutputStream(newFile)) {
            fos.write(newEncrypted);
        } catch (IOException e) {
            return false;
        }

        oldFile.delete();
        return updateFileRecord(fileId, newStoredName, newPassword);
    }

    private boolean saveFileRecord(String originalName, String storedName, String extension,
            long fileSize, String passwordHash, int uploaderId,
            String description, String relatedTable, int relatedId) {
        String sql = "INSERT INTO EncryptedFile (original_name, stored_name, file_extension, "
                + "file_size, password_hash, uploader_id, file_description, related_table, "
                + "related_id, uploaded_at) VALUES(?,?,?,?,?,?,?,?,?,GETDATE())";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, originalName);
            ps.setString(2, storedName);
            ps.setString(3, extension);
            ps.setLong(4, fileSize);
            ps.setString(5, passwordHash);
            ps.setInt(6, uploaderId);
            ps.setString(7, description);
            ps.setString(8, relatedTable);
            ps.setInt(9, relatedId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    private boolean deleteFileRecord(int fileId) {
        String sql = "DELETE FROM EncryptedFile WHERE file_id = ?";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, fileId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    private boolean updateFileRecord(int fileId, String newStoredName, String newPasswordHash) {
        String sql = "UPDATE EncryptedFile SET stored_name = ?, password_hash = ? WHERE file_id = ?";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, newStoredName);
            ps.setString(2, newPasswordHash);
            ps.setInt(3, fileId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    private FileRecord getFileRecord(int fileId) {
        String sql = "SELECT * FROM EncryptedFile WHERE file_id = ?";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, fileId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapResultSet(rs);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private ArrayList<FileRecord> getFileRecordsByRelated(String table, int relatedId) {
        ArrayList<FileRecord> list = new ArrayList<>();
        String sql = "SELECT * FROM EncryptedFile WHERE related_table = ? AND related_id = ? ORDER BY uploaded_at DESC";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, table);
            ps.setInt(2, relatedId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSet(rs));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    private ArrayList<FileRecord> getAllFileRecords() {
        ArrayList<FileRecord> list = new ArrayList<>();
        String sql = "SELECT * FROM EncryptedFile ORDER BY uploaded_at DESC";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapResultSet(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    private FileRecord mapResultSet(ResultSet rs) throws Exception {
        FileRecord r = new FileRecord();
        r.fileId = rs.getInt("file_id");
        r.originalName = rs.getString("original_name");
        r.storedFileName = rs.getString("stored_name");
        r.fileExtension = rs.getString("file_extension");
        r.fileSize = rs.getLong("file_size");
        r.passwordHash = rs.getString("password_hash");
        r.uploaderId = rs.getInt("uploader_id");
        r.description = rs.getString("file_description");
        r.relatedTable = rs.getString("related_table");
        r.relatedId = rs.getInt("related_id");
        r.uploadedAt = rs.getTimestamp("uploaded_at");
        return r;
    }

    private String getFileName(Part part) {
        String contentDisp = part.getHeader("content-disposition");
        if (contentDisp == null) return null;
        String[] tokens = contentDisp.split(";");
        for (String token : tokens) {
            if (token.trim().startsWith("filename")) {
                String name = token.substring(token.indexOf("=") + 1).trim().replace("\"", "");
                return name.substring(name.lastIndexOf("\\") + 1);
            }
        }
        return null;
    }

    private String getFileExtension(String fileName) {
        if (fileName == null) return "";
        int dot = fileName.lastIndexOf(".");
        return dot > 0 ? fileName.substring(dot + 1).toLowerCase() : "";
    }

    private boolean isAllowedExtension(String ext) {
        for (String allowed : ALLOWED_EXTENSIONS) {
            if (allowed.equalsIgnoreCase(ext)) {
                return true;
            }
        }
        return false;
    }

    private byte[] toByteArray(java.io.InputStream is) throws IOException {
        java.io.ByteArrayOutputStream buffer = new java.io.ByteArrayOutputStream();
        int nRead;
        byte[] data = new byte[16384];
        while ((nRead = is.read(data, 0, data.length)) != -1) {
            buffer.write(data, 0, nRead);
        }
        buffer.flush();
        return buffer.toByteArray();
    }

    public static class FileRecord {
        public int fileId;
        public String originalName;
        public String storedFileName;
        public String fileExtension;
        public long fileSize;
        public String passwordHash;
        public int uploaderId;
        public String description;
        public String relatedTable;
        public int relatedId;
        public Timestamp uploadedAt;

        public String getFormattedSize() {
            if (fileSize < 1024) return fileSize + " B";
            if (fileSize < 1024 * 1024) return String.format("%.1f KB", fileSize / 1024.0);
            return String.format("%.1f MB", fileSize / (1024.0 * 1024.0));
        }

        public String getContentType() {
            switch (fileExtension.toLowerCase()) {
                case "pdf": return "application/pdf";
                case "doc": return "application/msword";
                case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
                case "xls": return "application/vnd.ms-excel";
                case "xlsx": return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                case "txt": return "text/plain";
                case "jpg": case "jpeg": return "image/jpeg";
                case "png": return "image/png";
                case "zip": return "application/zip";
                case "rar": return "application/x-rar-compressed";
                default: return "application/octet-stream";
            }
        }
    }
}
