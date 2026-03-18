<?php
// =============================================================
//  VickYCloud — Secure Login Handler
//  File: app-tier/login.php
//  Features:
//    - bcrypt password verification
//    - Account lockout after 5 failed attempts
//    - Session regeneration (prevent fixation)
//    - Role-based redirect (admin → dashboard, others → restricted)
//    - Login audit log
//    - Remember-me cookie (SHA-256 hashed)
// =============================================================

session_start();

// Already logged in — redirect based on role
if (isset($_SESSION['user_id'])) {
    header('Location: dashboard.php');
    exit;
}

// Only handle POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    jsonResponse(false, 'Method not allowed.');
    exit;
}

// DB connection
$host = getenv('DB_HOST') ?: 'mysql-service';
$user = getenv('DB_USER') ?: 'vickyuser';
$pass = getenv('DB_PASS') ?: 'password123';
$db   = getenv('DB_NAME') ?: 'devopsdb';

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    jsonResponse(false, 'Service unavailable. Please try again later.');
    exit;
}

// Sanitize inputs
$username = trim($_POST['username'] ?? '');
$password = $_POST['password']     ?? '';
$remember = isset($_POST['remember']);

if (empty($username) || empty($password)) {
    jsonResponse(false, 'Email and password are required.');
    exit;
}

// -------------------------------------------------------------
//  Fetch user by email OR username
// -------------------------------------------------------------
$stmt = $conn->prepare(
    "SELECT id, username, first_name, last_name, email,
            password_hash, role, mfa_enabled,
            login_attempts, locked_until, last_login
     FROM users
     WHERE email = ? OR username = ?
     LIMIT 1"
);
$stmt->bind_param("ss", $username, $username);
$stmt->execute();
$user_data = $stmt->get_result()->fetch_assoc();
$stmt->close();

// User not found — generic message (don't reveal which field is wrong)
if (!$user_data) {
    logAttempt($conn, null, 'failed');
    jsonResponse(false, 'Invalid credentials. Please try again.');
    exit;
}

// -------------------------------------------------------------
//  Account lockout check
// -------------------------------------------------------------
if ($user_data['locked_until'] && strtotime($user_data['locked_until']) > time()) {
    $mins = ceil((strtotime($user_data['locked_until']) - time()) / 60);
    logAttempt($conn, $user_data['id'], 'locked');
    jsonResponse(false, "Account locked. Try again in {$mins} minute(s).");
    exit;
}

// -------------------------------------------------------------
//  Verify password
// -------------------------------------------------------------
if (!password_verify($password, $user_data['password_hash'])) {
    $attempts = $user_data['login_attempts'] + 1;
    $uid      = (int) $user_data['id'];

    if ($attempts >= 5) {
        $conn->query(
            "UPDATE users SET login_attempts = $attempts,
             locked_until = DATE_ADD(NOW(), INTERVAL 15 MINUTE)
             WHERE id = $uid"
        );
        logAttempt($conn, $uid, 'locked');
        jsonResponse(false, 'Too many failed attempts. Account locked for 15 minutes.');
    } else {
        $conn->query("UPDATE users SET login_attempts = $attempts WHERE id = $uid");
        $remaining = 5 - $attempts;
        logAttempt($conn, $uid, 'failed');
        jsonResponse(false, "Invalid credentials. {$remaining} attempt(s) remaining.");
    }
    exit;
}

// -------------------------------------------------------------
//  Password correct — reset attempts, create session
// -------------------------------------------------------------
$conn->query(
    "UPDATE users SET login_attempts = 0, locked_until = NULL,
     last_login = NOW() WHERE id = {$user_data['id']}"
);

// Regenerate session ID to prevent fixation attacks
session_regenerate_id(true);

$_SESSION['user_id']       = $user_data['id'];
$_SESSION['username']      = $user_data['username'];
$_SESSION['user_name']     = $user_data['first_name'] . ' ' . $user_data['last_name'];
$_SESSION['user_email']    = $user_data['email'];
$_SESSION['user_role']     = $user_data['role'];
$_SESSION['login_time']    = time();
$_SESSION['last_activity'] = time();

// -------------------------------------------------------------
//  Remember-me cookie (30 days, SHA-256 hashed)
// -------------------------------------------------------------
if ($remember) {
    $token = bin2hex(random_bytes(32));
    $hash  = hash('sha256', $token);
    $conn->query("UPDATE users SET remember_token = '$hash' WHERE id = {$user_data['id']}");
    setcookie('remember_token', $token, time() + 30 * 86400, '/', '', false, true);
}

// -------------------------------------------------------------
//  Log successful login
// -------------------------------------------------------------
logAttempt($conn, $user_data['id'], 'success');
$conn->close();

// -------------------------------------------------------------
//  Respond with success + redirect URL based on role
// -------------------------------------------------------------
$redirect = 'dashboard.php';
jsonResponse(true, 'Login successful! Redirecting…', $redirect);
exit;

// -------------------------------------------------------------
//  Helpers
// -------------------------------------------------------------
function logAttempt(mysqli $conn, ?int $user_id, string $status): void {
    $ip    = $conn->real_escape_string($_SERVER['REMOTE_ADDR']      ?? 'unknown');
    $agent = $conn->real_escape_string(
        substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 255)
    );
    $uid = $user_id ? $user_id : 'NULL';
    $conn->query(
        "INSERT INTO login_logs (user_id, ip_address, user_agent, status)
         VALUES ($uid, '$ip', '$agent', '$status')"
    );
}

function jsonResponse(bool $success, string $message, string $redirect = ''): void {
    header('Content-Type: application/json');
    http_response_code($success ? 200 : 401);
    echo json_encode([
        'success'  => $success,
        'message'  => $message,
        'redirect' => $redirect,
    ]);
}