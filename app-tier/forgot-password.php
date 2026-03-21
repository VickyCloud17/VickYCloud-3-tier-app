<?php
// =============================================================
//  VickYCloud — Forgot Password Handler
//  File: app-tier/forgot-password.php
//  Flow:
//    Step 1: POST action=request&email=xxx
//            → generates 6-digit token, stores in DB, returns token
//    Step 2: POST action=reset&email=xxx&token=xxx&password=xxx
//            → validates token, updates password hash
// =============================================================

header('Content-Type: application/json');

// DB connection from environment variables
$host = getenv('DB_HOST') ?: 'mysql-service';
$user = getenv('DB_USER') ?: 'vickyuser';
$pass = getenv('DB_PASS') ?: 'password123';
$db   = getenv('DB_NAME') ?: 'devopsdb';

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    echo json_encode(['success' => false, 'message' => 'Service unavailable. Please try again.']);
    exit;
}

// Only POST allowed
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Method not allowed.']);
    exit;
}

// Ensure reset_tokens table exists
$conn->query("
    CREATE TABLE IF NOT EXISTS reset_tokens (
        id         INT          AUTO_INCREMENT PRIMARY KEY,
        user_id    INT          NOT NULL,
        token      VARCHAR(10)  NOT NULL,
        expires_at DATETIME     NOT NULL,
        used       TINYINT(1)   DEFAULT 0,
        created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT fk_reset_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
");

$action = trim($_POST['action'] ?? '');

// =============================================================
//  ACTION: request — generate reset token
// =============================================================
if ($action === 'request') {
    $email = trim($_POST['email'] ?? '');

    if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        echo json_encode(['success' => false, 'message' => 'Please enter a valid email address.']);
        exit;
    }

    // Find user
    $stmt = $conn->prepare("SELECT id, first_name FROM users WHERE email = ? LIMIT 1");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();
    $user_data = $result->fetch_assoc();
    $stmt->close();

    // Always return success even if email not found (security — don't reveal if email exists)
    if (!$user_data) {
        // Return fake token so user can't enumerate emails
        echo json_encode([
            'success' => true,
            'token'   => sprintf('%06d', rand(100000, 999999)),
            'message' => 'If this email is registered, a reset token has been generated.'
        ]);
        exit;
    }

    // Delete any existing unused tokens for this user
    $uid = (int) $user_data['id'];
    $conn->query("DELETE FROM reset_tokens WHERE user_id = $uid AND used = 0");

    // Generate 6-digit token
    $token   = sprintf('%06d', rand(100000, 999999));
    $expires = date('Y-m-d H:i:s', time() + 15 * 60); // 15 minutes

    $stmt = $conn->prepare(
        "INSERT INTO reset_tokens (user_id, token, expires_at) VALUES (?, ?, ?)"
    );
    $stmt->bind_param("iss", $uid, $token, $expires);
    $stmt->execute();
    $stmt->close();
    $conn->close();

    echo json_encode([
        'success' => true,
        'token'   => $token,
        'message' => 'Reset token generated successfully.'
    ]);
    exit;
}

// =============================================================
//  ACTION: reset — validate token and update password
// =============================================================
if ($action === 'reset') {
    $email    = trim($_POST['email']    ?? '');
    $token    = trim($_POST['token']    ?? '');
    $password = $_POST['password']      ?? '';

    // Validate inputs
    if (empty($email) || empty($token) || empty($password)) {
        echo json_encode(['success' => false, 'message' => 'All fields are required.']);
        exit;
    }

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        echo json_encode(['success' => false, 'message' => 'Invalid email address.']);
        exit;
    }

    // Password strength
    if (strlen($password) < 8) {
        echo json_encode(['success' => false, 'message' => 'Password must be at least 8 characters.']);
        exit;
    }
    if (!preg_match('/[A-Z]/', $password)) {
        echo json_encode(['success' => false, 'message' => 'Password must contain an uppercase letter.']);
        exit;
    }
    if (!preg_match('/[0-9]/', $password)) {
        echo json_encode(['success' => false, 'message' => 'Password must contain a number.']);
        exit;
    }

    // Find user
    $stmt = $conn->prepare("SELECT id FROM users WHERE email = ? LIMIT 1");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result    = $stmt->get_result();
    $user_data = $result->fetch_assoc();
    $stmt->close();

    if (!$user_data) {
        echo json_encode(['success' => false, 'message' => 'Invalid email or token.']);
        exit;
    }

    $uid = (int) $user_data['id'];

    // Find valid token
    $stmt = $conn->prepare(
        "SELECT id FROM reset_tokens
         WHERE user_id = ? AND token = ? AND used = 0 AND expires_at > NOW()
         LIMIT 1"
    );
    $stmt->bind_param("is", $uid, $token);
    $stmt->execute();
    $result     = $stmt->get_result();
    $token_data = $result->fetch_assoc();
    $stmt->close();

    if (!$token_data) {
        echo json_encode(['success' => false, 'message' => 'Invalid or expired token. Please request a new one.']);
        exit;
    }

    $token_id = (int) $token_data['id'];

    // Hash new password
    $hash = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);

    // Update password + reset login attempts
    $stmt = $conn->prepare(
        "UPDATE users SET password_hash = ?, login_attempts = 0, locked_until = NULL WHERE id = ?"
    );
    $stmt->bind_param("si", $hash, $uid);
    $stmt->execute();
    $stmt->close();

    // Mark token as used
    $conn->query("UPDATE reset_tokens SET used = 1 WHERE id = $token_id");

    $conn->close();

    echo json_encode([
        'success' => true,
        'message' => 'Password reset successfully! Redirecting to login…'
    ]);
    exit;
}

// Unknown action
echo json_encode(['success' => false, 'message' => 'Invalid action.']);
$conn->close();