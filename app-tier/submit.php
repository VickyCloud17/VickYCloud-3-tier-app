<?php
// ─────────────────────────────────────────────────────────────────
//  VickYCloud — Form Handler (submit.php)
//  Fields: first_name, last_name, email, company, cloud, message
//  Protected: session check + prepared statements + rate limiting
// ─────────────────────────────────────────────────────────────────

session_start();

define('DB_HOST', 'mysql-service');
define('DB_USER', 'vickyuser');
define('DB_PASS', 'password123');
define('DB_NAME', 'devopsdb');

// ── DB Connection ──────────────────────────────────────────────
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
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
    $accept = $_SERVER['HTTP_ACCEPT'] ?? '';
    if (str_contains($accept, 'application/json')) {
        header('Content-Type: application/json');
        echo json_encode(['success' => $success, 'message' => $msg]);
        return;
    }
    http_response_code($success ? 200 : 400);
    $icon  = $success ? '✅' : '❌';
    $color = $success ? '#10b981' : '#ef4444';
    echo "<!DOCTYPE html><html><head>
        <meta charset='UTF-8'/>
        <meta http-equiv='refresh' content='3;url=index.html'/>
        <title>VickYCloud</title>
        <style>
            body{margin:0;display:flex;align-items:center;justify-content:center;
                 min-height:100vh;background:#04060f;font-family:sans-serif;color:#e8edf8;}
            .box{background:#0e1428;border:1px solid rgba(99,179,255,0.15);
                 border-radius:16px;padding:40px 48px;text-align:center;max-width:420px;}
            .icon{font-size:2.5rem;margin-bottom:14px;}
            p{color:#7a8aaa;font-size:0.9rem;margin-top:10px;}
            strong{color:{$color};font-size:1.05rem;}
        </style></head><body>
        <div class='box'>
            <div class='icon'>{$icon}</div>
            <strong>{$msg}</strong>
            <p>Redirecting back in 3 seconds…</p>
        </div></body></html>";
}