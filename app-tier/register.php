<?php
// =============================================================
//  VickYCloud — Register Handler
//  File: app-tier/register.php
//  Creates new user account with bcrypt password hash
// =============================================================

session_start();

// Redirect if already logged in
if (isset($_SESSION['user_id'])) {
    header('Location: dashboard.php');
    exit;
}

// Only accept POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
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
    jsonResponse(false, 'Service unavailable. Please try again.');
    exit;
}

// -------------------------------------------------------------
//  Sanitize + validate inputs
// -------------------------------------------------------------
$first_name       = trim($_POST['first_name']       ?? '');
$last_name        = trim($_POST['last_name']        ?? '');
$username         = trim($_POST['username']         ?? '');
$email            = trim($_POST['email']            ?? '');
$company          = trim($_POST['company']          ?? '');
$role             = trim($_POST['role']             ?? 'developer');
$password         = $_POST['password']              ?? '';
$confirm_password = $_POST['confirm_password']      ?? '';

// Required fields
$required = compact('first_name', 'last_name', 'username', 'email', 'password', 'confirm_password');
foreach ($required as $field => $value) {
    if (empty($value)) {
        jsonResponse(false, "Field '{$field}' is required.");
        exit;
    }
}

// Email validation
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonResponse(false, 'Please enter a valid email address.');
    exit;
}

// Username validation
if (strlen($username) < 3 || strlen($username) > 80) {
    jsonResponse(false, 'Username must be between 3 and 80 characters.');
    exit;
}
if (!preg_match('/^[a-zA-Z0-9_.-]+$/', $username)) {
    jsonResponse(false, 'Username can only contain letters, numbers, underscores, dots and hyphens.');
    exit;
}

// Password strength
if (strlen($password) < 8) {
    jsonResponse(false, 'Password must be at least 8 characters.');
    exit;
}
if (!preg_match('/[A-Z]/', $password)) {
    jsonResponse(false, 'Password must contain at least one uppercase letter.');
    exit;
}
if (!preg_match('/[0-9]/', $password)) {
    jsonResponse(false, 'Password must contain at least one number.');
    exit;
}

// Password match
if ($password !== $confirm_password) {
    jsonResponse(false, 'Passwords do not match.');
    exit;
}

// Role validation
$allowed_roles = ['developer', 'viewer'];
if (!in_array($role, $allowed_roles)) {
    $role = 'developer';
}

// -------------------------------------------------------------
//  Check duplicate email or username
// -------------------------------------------------------------
$stmt = $conn->prepare(
    "SELECT id FROM users WHERE email = ? OR username = ? LIMIT 1"
);
$stmt->bind_param("ss", $email, $username);
$stmt->execute();
$stmt->store_result();

if ($stmt->num_rows > 0) {
    // Find which one is duplicate
    $stmt->close();
    $chk = $conn->prepare("SELECT id FROM users WHERE email = ? LIMIT 1");
    $chk->bind_param("s", $email);
    $chk->execute();
    $chk->store_result();
    $msg = $chk->num_rows > 0
        ? 'This email is already registered. Please login.'
        : 'This username is already taken. Please choose another.';
    $chk->close();
    $conn->close();
    jsonResponse(false, $msg);
    exit;
}
$stmt->close();

// -------------------------------------------------------------
//  Hash password and insert user
// -------------------------------------------------------------
$password_hash = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
$company_safe  = $conn->real_escape_string(strip_tags($company));
$first_safe    = $conn->real_escape_string(strip_tags($first_name));
$last_safe     = $conn->real_escape_string(strip_tags($last_name));
$user_safe     = $conn->real_escape_string(strip_tags($username));
$email_safe    = $conn->real_escape_string($email);

$insert = $conn->prepare(
    "INSERT INTO users
        (username, first_name, last_name, email, password_hash, company, role, mfa_enabled)
     VALUES (?, ?, ?, ?, ?, ?, ?, 0)"
);
$insert->bind_param(
    "sssssss",
    $user_safe,
    $first_safe,
    $last_safe,
    $email_safe,
    $password_hash,
    $company_safe,
    $role
);

if ($insert->execute()) {
    $new_user_id = $conn->insert_id;

    // Log registration as first login_log entry
    $ip    = $conn->real_escape_string($_SERVER['REMOTE_ADDR'] ?? 'unknown');
    $agent = $conn->real_escape_string(substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 255));
    $conn->query(
        "INSERT INTO login_logs (user_id, ip_address, user_agent, status)
         VALUES ($new_user_id, '$ip', '$agent', 'success')"
    );

    $insert->close();
    $conn->close();
    jsonResponse(true, 'Account created successfully! Redirecting to login…');
} else {
    $insert->close();
    $conn->close();
    jsonResponse(false, 'Registration failed. Please try again.');
}

// -------------------------------------------------------------
//  Helper
// -------------------------------------------------------------
function jsonResponse(bool $success, string $message): void {
    header('Content-Type: application/json');
    http_response_code($success ? 200 : 400);
    echo json_encode(['success' => $success, 'message' => $message]);
}