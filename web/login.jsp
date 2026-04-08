<%--
  ===== login.jsp – Trang đăng nhập =====
  Mục đích    : Form đăng nhập duy nhất của hệ thống PMS.
  Luồng xử lý :
    1. User nhập username + password → POST tới MainController?action=loginUser
    2. UserController.login() tra cứu DB (UserDAO.Login – so sánh plain-text)
    3. Thành công: set session["user"] → redirect tới DashboardController
    4. Thất bại : set session["loginMessage"] + session["loginUsername"] → redirect lại login.jsp
  Session attributes đọc:
    - session["loginMessage"]  : Thông báo lỗi từ UserController (đọc 1 lần rồi xóa)
    - session["loginUsername"] : Username đã nhập để điền sẵn lại vào form
  JavaScript:
    - togglePasswordVisibility() : Hiện/ẩn mật khẩu (icon mắt)
    - loginErrorPopup             : Modal hiển thị thông báo lỗi, đóng bằng Esc hoặc click ngoài
    - pageshow event              : Xoá cache khi dùng nút Back để tránh hiển thị lại trang sau logout
  Phân quyền  : Không cần đăng nhập (AuthenticationFilter cho qua /login.jsp)
  Lưu ý       : Không dùng JSTL (tránh lỗi thiếu thư viện trên Tomcat).
--%>
<%@page contentType="text/html" pageEncoding="UTF-8" import="java.lang.String"%>
<%
    // Chống cache: buộc browser luôn tải lại trang login (tránh lộ trang sau logout)
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // Đọc thông báo lỗi và username từ session (nếu có – do UserController set sau login thất bại)
    String message = (String) session.getAttribute("loginMessage");
    String usernameValue = (String) session.getAttribute("loginUsername");
    if (usernameValue == null) {
        usernameValue = ""; // Tránh lỗi NullPointerException khi render value=""
    }

    // Xóa flash message khỏi session ngay sau khi đọc (chỉ hiển thị 1 lần)
    session.removeAttribute("loginMessage");
    session.removeAttribute("loginUsername");
%>
<!DOCTYPE html>
<!--
  Trang đăng nhập thật của project.
  - Không dùng JSTL để tránh lỗi thiếu thư viện trên Tomcat hiện tại.
  - Form submit trực tiếp tới `MainController` với action `loginUser`.
  - Nếu đăng nhập sai thì backend set `message` và trang này hiển thị lại thông báo lỗi.
-->
<html lang="en">
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Sign In</title>
        <style>
            :root {
                --bg: #f3f4f6;
                --surface: #ffffff;
                --surface-muted: #f8fafc;
                --border: #e5e7eb;
                --text: #111827;
                --text-muted: #6b7280;
                --text-inverse: #ffffff;
                --primary: #2563eb;
                --primary-hover: #1d4ed8;
                --primary-soft: #dbeafe;
                --danger: #dc2626;
                --danger-soft: #fee2e2;
                --shadow-sm: 0 1px 2px rgba(15, 23, 42, 0.06);
                --shadow-md: 0 4px 12px rgba(15, 23, 42, 0.1);
                --shadow-lg: 0 8px 24px rgba(15, 23, 42, 0.12);
                --radius-sm: 10px;
                --radius-md: 16px;
                font-family: Inter, "Segoe UI", Roboto, Arial, sans-serif;
            }

            * {
                box-sizing: border-box;
            }

            html,
            body {
                margin: 0;
                min-height: 100%;
                background: var(--bg);
                color: var(--text);
            }

            body {
                font-family: inherit;
            }

            button,
            input {
                font: inherit;
            }

            a {
                color: inherit;
                text-decoration: none;
            }

            .auth-shell {
                min-height: 100vh;
                display: grid;
                place-items: center;
                padding: 32px 16px;
            }

            .auth-card {
                width: min(100%, 820px);
                display: grid;
                grid-template-columns: 1fr 1fr;
                overflow: hidden;
                background: var(--surface);
                border: 1px solid var(--border);
                border-radius: var(--radius-md);
                box-shadow: var(--shadow-lg);
            }

            .auth-visual,
            .auth-form {
                padding: 48px 40px;
            }

            .auth-visual {
                background: var(--surface-muted);
                display: grid;
                place-items: center;
                border-right: 1px solid var(--border);
            }

            .auth-visual img {
                width: min(100%, 180px);
                height: auto;
                object-fit: contain;
            }

            .section-title {
                margin: 0;
                font-size: 1.5rem;
                font-weight: 700;
            }

            .section-subtitle {
                margin: 8px 0 0;
                color: var(--text-muted);
                line-height: 1.6;
                font-size: 0.95rem;
            }

            form {
                display: grid;
                gap: 20px;
                margin-top: 28px;
            }

            .field-group {
                position: relative;
            }

            .field-label {
                display: block;
                margin-bottom: 8px;
                font-weight: 600;
                font-size: 0.9rem;
                color: var(--text);
            }

            .input-wrapper {
                position: relative;
                display: flex;
                align-items: center;
            }

            .input-icon {
                position: absolute;
                left: 14px;
                color: var(--text-muted);
                pointer-events: none;
                transition: color 0.2s ease;
                display: flex;
                align-items: center;
                justify-content: center;
            }

            .input {
                width: 100%;
                padding: 13px 14px 13px 44px;
                border: 1.5px solid var(--border);
                border-radius: var(--radius-sm);
                background: var(--surface);
                color: var(--text);
                font-size: 0.95rem;
                transition: border-color 0.2s ease, box-shadow 0.2s ease;
            }

            .input::placeholder {
                color: #9ca3af;
            }

            .input:focus {
                outline: none;
                border-color: var(--primary);
                box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12);
            }

            .input:focus + .input-icon,
            .input:focus ~ .input-icon {
                color: var(--primary);
            }

            .toggle-password {
                position: absolute;
                right: 12px;
                background: none;
                border: none;
                cursor: pointer;
                color: var(--text-muted);
                padding: 4px;
                display: flex;
                align-items: center;
                justify-content: center;
                border-radius: 4px;
                transition: color 0.2s ease;
            }

            .toggle-password:hover {
                color: var(--text);
            }

            .auth-meta {
                display: flex;
                justify-content: space-between;
                align-items: center;
                gap: 12px;
                font-size: 0.9rem;
            }

            .checkbox-wrapper {
                display: flex;
                align-items: center;
                gap: 8px;
                cursor: pointer;
            }

            .checkbox-wrapper input[type="checkbox"] {
                width: 16px;
                height: 16px;
                accent-color: var(--primary);
                cursor: pointer;
            }

            .checkbox-label {
                color: var(--text-muted);
                user-select: none;
            }

            .forgot-link {
                color: var(--primary);
                font-weight: 500;
                transition: color 0.2s ease;
            }

            .forgot-link:hover {
                color: var(--primary-hover);
                text-decoration: underline;
            }

            .btn {
                display: inline-flex;
                align-items: center;
                justify-content: center;
                gap: 8px;
                padding: 13px 20px;
                border-radius: var(--radius-sm);
                border: 1px solid transparent;
                cursor: pointer;
                font-weight: 600;
                font-size: 0.95rem;
                transition: all 0.25s ease;
            }

            .btn-primary {
                background: linear-gradient(135deg, var(--primary) 0%, var(--primary-hover) 100%);
                color: var(--text-inverse);
                box-shadow: 0 2px 8px rgba(37, 99, 235, 0.3);
            }

            .btn-primary:hover {
                transform: translateY(-1px);
                box-shadow: 0 4px 16px rgba(37, 99, 235, 0.4);
            }

            .btn-primary:active {
                transform: translateY(0);
                box-shadow: 0 2px 6px rgba(37, 99, 235, 0.3);
            }

            .form-alert {
                display: none;
            }

            .login-popup-backdrop {
                position: fixed;
                inset: 0;
                background: rgba(15, 23, 42, 0.45);
                display: none;
                align-items: center;
                justify-content: center;
                padding: 24px;
                z-index: 50;
            }

            .login-popup-backdrop.is-open {
                display: flex;
            }

            .login-popup {
                width: min(100%, 420px);
                background: var(--surface);
                border-radius: 22px;
                box-shadow: 0 24px 60px rgba(15, 23, 42, 0.22);
                border: 1px solid #fecaca;
                overflow: hidden;
                animation: popupIn 0.22s ease;
            }

            .login-popup-head {
                display: flex;
                align-items: center;
                gap: 12px;
                padding: 20px 22px 12px;
            }

            .login-popup-icon {
                width: 42px;
                height: 42px;
                border-radius: 999px;
                background: var(--danger-soft);
                color: var(--danger);
                display: inline-flex;
                align-items: center;
                justify-content: center;
                font-weight: 700;
                font-size: 1.1rem;
                flex-shrink: 0;
            }

            .login-popup-title {
                margin: 0;
                font-size: 1.1rem;
                font-weight: 700;
                color: var(--text);
            }

            .login-popup-subtitle {
                margin: 4px 0 0;
                color: var(--text-muted);
                font-size: 0.92rem;
                line-height: 1.5;
            }

            .login-popup-body {
                padding: 0 22px 20px;
            }

            .login-popup-message {
                margin: 0;
                padding: 14px 16px;
                border-radius: 14px;
                background: linear-gradient(180deg, #fff1f2 0%, #ffe4e6 100%);
                color: #9f1239;
                border: 1px solid #fecdd3;
                line-height: 1.6;
            }

            .login-popup-actions {
                display: flex;
                justify-content: flex-end;
                padding: 0 22px 22px;
            }

            .login-popup-close {
                min-width: 110px;
            }

            @keyframes popupIn {
                from {
                    opacity: 0;
                    transform: translateY(10px) scale(0.98);
                }
                to {
                    opacity: 1;
                    transform: translateY(0) scale(1);
                }
            }

            @media (max-width: 860px) {
                .auth-card {
                    grid-template-columns: 1fr;
                }

                .auth-visual {
                    border-right: 0;
                    border-bottom: 1px solid var(--border);
                }

                .auth-visual,
                .auth-form {
                    padding: 36px 28px;
                }
            }
        </style>
    </head>
    <body>
        <div class="auth-shell">
            <section class="auth-card">
                <div class="auth-visual">
                    <img src="img/logo.png" alt="Application logo" />
                </div>

                <div class="auth-form">
                    <h1 class="section-title">Sign in</h1>
                    <p class="section-subtitle">Enter your credentials to access your account.</p>

                    <form action="MainController" method="post">
                        <input type="hidden" name="action" value="loginUser"/>

                        <% if (message != null && !message.trim().isEmpty()) { %>
                            <div class="form-alert"><%= message %></div>
                        <% } %>

                        <div class="field-group">
                            <label class="field-label" for="txtUsername">Username</label>
                            <div class="input-wrapper">
                                <input
                                    id="txtUsername"
                                    class="input"
                                    type="text"
                                    name="txtUsername"
                                    placeholder="Enter your username"
                                    value="<%= usernameValue %>"
                                    required
                                    autocomplete="username"
                                />
                                <span class="input-icon">
                                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                                        <circle cx="12" cy="7" r="4"></circle>
                                    </svg>
                                </span>
                            </div>
                        </div>

                        <div class="field-group">
                            <label class="field-label" for="txtPassword">Password</label>
                            <div class="input-wrapper">
                                <input
                                    id="txtPassword"
                                    class="input"
                                    type="password"
                                    name="txtPassword"
                                    placeholder="Enter your password"
                                    required
                                    autocomplete="current-password"
                                />
                                <span class="input-icon">
                                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                                        <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                                    </svg>
                                </span>
                                <button class="toggle-password" type="button" onclick="togglePasswordVisibility()" aria-label="Toggle password visibility">
                                    <svg id="eyeIcon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                                        <circle cx="12" cy="12" r="3"></circle>
                                    </svg>
                                    <svg id="eyeOffIcon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display:none">
                                        <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path>
                                        <line x1="1" y1="1" x2="23" y2="23"></line>
                                    </svg>
                                </button>
                            </div>
                        </div>

                        <div class="auth-meta">
                            <label class="checkbox-wrapper">
                                <input type="checkbox" name="rememberMe" id="rememberMe" />
                                <span class="checkbox-label">Remember me</span>
                            </label>
                            <a href="#" class="forgot-link">Forgot password?</a>
                        </div>

                        <button class="btn btn-primary" type="submit">Sign in</button>
                    </form>
                </div>
            </section>
        </div>

        <% if (message != null && !message.trim().isEmpty()) { %>
            <div id="loginErrorPopup" class="login-popup-backdrop is-open">
                <div class="login-popup" role="alertdialog" aria-modal="true" aria-labelledby="loginErrorTitle">
                    <div class="login-popup-head">
                        <div class="login-popup-icon">!</div>
                        <div>
                            <h2 id="loginErrorTitle" class="login-popup-title">Sign in failed</h2>
                            <p class="login-popup-subtitle">Please check your username and password, then try again.</p>
                        </div>
                    </div>
                    <div class="login-popup-body">
                        <p class="login-popup-message"><%= message %></p>
                    </div>
                    <div class="login-popup-actions">
                        <button id="loginPopupClose" class="btn btn-primary login-popup-close" type="button">Try again</button>
                    </div>
                </div>
            </div>
        <% } %>

        <script>
            function togglePasswordVisibility() {
                var passwordInput = document.getElementById('txtPassword');
                var eyeIcon = document.getElementById('eyeIcon');
                var eyeOffIcon = document.getElementById('eyeOffIcon');

                if (passwordInput.type === 'password') {
                    passwordInput.type = 'text';
                    eyeIcon.style.display = 'none';
                    eyeOffIcon.style.display = 'block';
                } else {
                    passwordInput.type = 'password';
                    eyeIcon.style.display = 'block';
                    eyeOffIcon.style.display = 'none';
                }
            }

            (function () {
                var popup = document.getElementById('loginErrorPopup');
                var closeButton = document.getElementById('loginPopupClose');
                var usernameInput = document.getElementById('txtUsername');
                var passwordInput = document.getElementById('txtPassword');

                function focusLoginField() {
                    if (passwordInput) {
                        passwordInput.focus();
                    } else if (usernameInput) {
                        usernameInput.focus();
                    }
                }

                if (popup) {
                    function closePopup() {
                        popup.classList.remove('is-open');
                        focusLoginField();
                    }

                    if (closeButton) {
                        closeButton.addEventListener('click', closePopup);
                    }

                    popup.addEventListener('click', function (event) {
                        if (event.target === popup) {
                            closePopup();
                        }
                    });

                    document.addEventListener('keydown', function (event) {
                        if (event.key === 'Escape' && popup.classList.contains('is-open')) {
                            closePopup();
                        }
                    });
                }

                window.addEventListener('pageshow', function (event) {
                    if (event.persisted) {
                        window.location.replace('login.jsp');
                    }
                });
            }());
        </script>
    </body>
</html>
