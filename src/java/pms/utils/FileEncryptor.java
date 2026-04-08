package pms.utils;

import java.security.SecureRandom;
import java.util.Base64;
import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;

public class FileEncryptor {

    private static final String ALGORITHM = "AES/GCM/NoPadding";
    private static final String KEY_ALGORITHM = "PBKDF2WithHmacSHA256";
    private static final int GCM_IV_LENGTH = 12;
    private static final int GCM_TAG_LENGTH = 128;
    private static final int KEY_LENGTH = 256;
    private static final int ITERATION_COUNT = 65536;
    private static final byte[] SALT = "PMSFileSalt2024".getBytes();

    public byte[] encrypt(byte[] data, String password) throws Exception {
        SecretKey key = deriveKey(password);
        byte[] iv = generateIv();
        Cipher cipher = Cipher.getInstance(ALGORITHM);
        GCMParameterSpec parameterSpec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
        cipher.init(Cipher.ENCRYPT_MODE, key, parameterSpec);
        byte[] encryptedData = cipher.doFinal(data);

        byte[] encryptedDataWithIv = new byte[iv.length + encryptedData.length];
        System.arraycopy(iv, 0, encryptedDataWithIv, 0, iv.length);
        System.arraycopy(encryptedData, 0, encryptedDataWithIv, iv.length, encryptedData.length);
        return encryptedDataWithIv;
    }

    public byte[] decrypt(byte[] encryptedDataWithIv, String password) throws Exception {
        byte[] iv = new byte[GCM_IV_LENGTH];
        byte[] encryptedData = new byte[encryptedDataWithIv.length - GCM_IV_LENGTH];
        System.arraycopy(encryptedDataWithIv, 0, iv, 0, iv.length);
        System.arraycopy(encryptedDataWithIv, iv.length, encryptedData, 0, encryptedData.length);

        SecretKey key = deriveKey(password);
        Cipher cipher = Cipher.getInstance(ALGORITHM);
        GCMParameterSpec parameterSpec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
        cipher.init(Cipher.DECRYPT_MODE, key, parameterSpec);
        return cipher.doFinal(encryptedData);
    }

    public String encryptToBase64(byte[] data, String password) throws Exception {
        byte[] encrypted = encrypt(data, password);
        return Base64.getEncoder().encodeToString(encrypted);
    }

    public byte[] decryptFromBase64(String base64Data, String password) throws Exception {
        byte[] encryptedData = Base64.getDecoder().decode(base64Data);
        return decrypt(encryptedData, password);
    }

    public byte[] hashPassword(String password) throws Exception {
        SecretKey key = deriveKey(password);
        return key.getEncoded();
    }

    private SecretKey deriveKey(String password) throws Exception {
        SecretKeyFactory factory = SecretKeyFactory.getInstance(KEY_ALGORITHM);
        PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), SALT, ITERATION_COUNT, KEY_LENGTH);
        SecretKey tmp = factory.generateSecret(spec);
        return new SecretKeySpec(tmp.getEncoded(), "AES");
    }

    private byte[] generateIv() {
        byte[] iv = new byte[GCM_IV_LENGTH];
        new SecureRandom().nextBytes(iv);
        return iv;
    }

    public String generateSecureToken() {
        byte[] randomBytes = new byte[32];
        new SecureRandom().nextBytes(randomBytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes);
    }

    public static String generateFileId() {
        return System.currentTimeMillis() + "_" + new SecureRandom().nextInt(10000);
    }
}
