<?php
// ─────────────────────────────────────────────────────────────────
//  VickYCloud — Login Handler (login.php)
//  Handles: credential login + session + MFA token check
// ─────────────────────────────────────────────────────────────────

session_start();

define('DB_HOST', 'mysql-service');
define('DB_USER', 'vickyuser');
define('DB_PASS', 'password123');
define('DB_NAME', 'devopsdb');

// Redirect if already logged in
if (isset($_SESSION['user_id'])) {
    header('Location: dashboard.php');
    exit;
}

// ── Only handle POST ───────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: login.html');
    exit;
}

$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
if ($conn->connect_error) {
    loginError("Database connection failed. Please try again.");
}

// ── Sanitize inputs ────────────────────────────────────────────
$username = trim($_POST['username'] ?? '');
$password = trim($_POST['password'] ?? '');
$remember = isset($_POST['remember']);
$mfa_code = trim($_POST['mfa_code'] ?? '');

if (empty($username) || empty($password)) {
    loginError("Email and password are required.");
}

// ── Fetch user ─────────────────────────────────────────────────
$stmt = $conn->prepare(
    "SELECT id, first_name, last_name, email, password_hash, role,
            mfa_enabled, mfa_secret, login_attempts, locked_until
     FROM users
     WHERE email = ? OR username = ?
     LIMIT 1"
);
$stmt->bind_param("ss", $username, $username);
$stmt->execute();
$result = $stmt->get_result();
$user   = $result->fetch_assoc();
$stmt->close();

// ── Account not found ──────────────────────────────────────────
if (!$user) {
    loginError("Invalid credentials. Please try again.");
}

// ── Account lockout check ──────────────────────────────────────
if ($user['locked_until'] && strtotime($user['locked_until']) > time()) {
    $mins = ceil((strtotime($user['locked_until']) - time()) / 60);
    loginError("Account locked due to too many failed attempts. Try again in {$mins} minute(s).");
}

// ── Verify password ────────────────────────────────────────────
if (!password_verify($password, $user['password_hash'])) {
    // Increment failed attempts
    $attempts = $user['login_attempts'] + 1;
    $lock_sql  = $attempts >= 5
        ? "UPDATE users SET login_attempts = ?, locked_until = DATE_ADD(NOW(), INTERVAL 15 MINUTE) WHERE id = ?"
        : "UPDATE users SET login_attempts = ? WHERE id = ?";
    $upd = $conn->prepare($lock_sql);
    $upd->bind_param("ii", $attempts, $user['id']);
    $upd->execute();
    $upd->close();

    $remaining = max(0, 5 - $attempts);
    $msg = $remaining > 0
        ? "Invalid credentials. {$remaining} attempt(s) remaining before lockout."
        : "Too many failed attempts. Account locked for 15 minutes.";
    loginError($msg);
}

// ── Reset failed attempts on success ──────────────────────────
$conn->query("UPDATE users SET login_attempts = 0, locked_until = NULL, last_login = NOW() WHERE id = {$user['id']}");

// ── MFA check ─────────────────────────────────────────────────
if ($user['mfa_enabled']) {
    if (empty($mfa_code)) {
        // Store partial session, redirect to MFA step
        $_SESSION['mfa_pending_user'] = $user['id'];
        header('Location: login.html?mfa=1');
        exit;
    }
    // Validate TOTP (stub — integrate with a TOTP library like OTPHP)
    // if (!verifyTOTP($user['mfa_secret'], $mfa_code)) {
    //     loginError("Invalid MFA code. Please try again.");
    // }
}

// ── Create session ─────────────────────────────────────────────
session_regenerate_id(true);
$_SESSION['user_id']    = $user['id'];
$_SESSION['user_name']  = $user['first_name'] . ' ' . $user['last_name'];
$_SESSION['user_email'] = $user['email'];
$_SESSION['user_role']  = $user['role'];
$_SESSION['login_time'] = time();

// ── Remember-me cookie (30 days) ───────────────────────────────
if ($remember) {
    $token = bin2hex(random_bytes(32));
    setcookie('remember_token', $token, time() + 30 * 86400, '/', '', true, true);
    $hash = hash('sha256', $token);
    $conn->query("UPDATE users SET remember_token = '{$hash}' WHERE id = {$user['id']}");
}

// ── Log login event ────────────────────────────────────────────
$ip    = $conn->real_escape_string($_SERVER['REMOTE_ADDR'] ?? 'unknown');
$agent = $conn->real_escape_string(substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 255));
$conn->query(
    "INSERT INTO login_logs (user_id, ip_address, user_agent, status)
     VALUES ({$user['id']}, '{$ip}', '{$agent}', 'success')"
);

$conn->close();
header('Location: dashboard.php');
exit;

// ── Helper ─────────────────────────────────────────────────────
function loginError(string $msg): void {
    session_start();
    $_SESSION['login_error'] = $msg;
    header('Location: login.html?error=' . urlencode($msg));
    exit;
}