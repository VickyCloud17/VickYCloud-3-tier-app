<?php
// ─────────────────────────────────────────────────────────────────
//  VickYCloud — Form Handler (submit.php)
//  Fields: first_name, last_name, email, company, cloud, message
//  Protected: session check + prepared statements + rate limiting
// ─────────────────────────────────────────────────────────────────

session_start();

// ── DB Connection — reads from Kubernetes env vars ─────────────
$host = getenv('DB_HOST') ?: 'mysql-service';
$user = getenv('DB_USER') ?: 'vickyuser';
$pass = getenv('DB_PASS') ?: 'password123';
$db   = getenv('DB_NAME') ?: 'devopsdb';

// ── DB Connection ──────────────────────────────────────────────
$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    respond(false, "Service temporarily unavailable. Please try again.");
    exit;
}

// ── Only POST allowed ──────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(false, "Method not allowed.");
    exit;
}

// ── Simple rate limiting via session (5 submissions / 10 min) ──
$now = time();
if (!isset($_SESSION['submit_log'])) $_SESSION['submit_log'] = [];
$_SESSION['submit_log'] = array_filter(
    $_SESSION['submit_log'],
    fn($t) => ($now - $t) < 600          // keep last 10 mins
);
if (count($_SESSION['submit_log']) >= 5) {
    respond(false, "Too many submissions. Please wait a few minutes.");
    exit;
}

// ── Required fields ────────────────────────────────────────────
$required = ['first_name', 'last_name', 'email', 'message'];
foreach ($required as $field) {
    if (empty(trim($_POST[$field] ?? ''))) {
        respond(false, "Missing required field: {$field}");
        exit;
    }
}

// ── Sanitize ───────────────────────────────────────────────────
$first_name = sanitize($conn, $_POST['first_name']);
$last_name  = sanitize($conn, $_POST['last_name']);
$email      = sanitize($conn, $_POST['email']);
$company    = sanitize($conn, $_POST['company']  ?? '');
$cloud      = sanitize($conn, $_POST['cloud']    ?? '');
$message    = sanitize($conn, $_POST['message']);

// ── Validate email ─────────────────────────────────────────────
if (!filter_var($_POST['email'], FILTER_VALIDATE_EMAIL)) {
    respond(false, "Please enter a valid email address.");
    exit;
}

// ── Valid cloud values ─────────────────────────────────────────
$valid_clouds = ['AWS', 'Google Cloud', 'Azure', 'Multi-Cloud', 'On-Premise / Hybrid', ''];
if (!in_array($cloud, $valid_clouds, true)) {
    $cloud = '';
}

// ── Attach logged-in user if present ──────────────────────────
$user_id = $_SESSION['user_id'] ?? null;

// ── Insert message ─────────────────────────────────────────────
$stmt = $conn->prepare(
    "INSERT INTO messages
        (user_id, first_name, last_name, email, company, cloud, message)
     VALUES (?, ?, ?, ?, ?, ?, ?)"
);
$stmt->bind_param("issssss",
    $user_id,
    $first_name,
    $last_name,
    $email,
    $company,
    $cloud,
    $message
);

if ($stmt->execute()) {
    $_SESSION['submit_log'][] = $now;     // record for rate limit
    respond(true, "✅ Message received! Our team will reach out within 24 hours.");
} else {
    respond(false, "Database error. Please try again.");
}

$stmt->close();
$conn->close();


// ── Helpers ────────────────────────────────────────────────────
function sanitize(mysqli $conn, string $val): string {
    return $conn->real_escape_string(strip_tags(trim($val)));
}

function respond(bool $success, string $msg): void {
    header('Content-Type: application/json');
    http_response_code($success ? 200 : 400);
    echo json_encode(['success' => $success, 'message' => $msg]);
}