<?php
// =============================================================
//  VickYCloud — Logout Handler
//  File: app-tier/logout.php
//  Destroys session and clears remember-me cookie
// =============================================================

session_start();

// Clear remember-me cookie if set
if (isset($_COOKIE['remember_token'])) {
    // Remove token from DB
    $host = getenv('DB_HOST') ?: 'mysql-service';
    $user = getenv('DB_USER') ?: 'vickyuser';
    $pass = getenv('DB_PASS') ?: 'password123';
    $db   = getenv('DB_NAME') ?: 'devopsdb';

    $conn = new mysqli($host, $user, $pass, $db);
    if (!$conn->connect_error && isset($_SESSION['user_id'])) {
        $id = (int) $_SESSION['user_id'];
        $conn->query("UPDATE users SET remember_token = NULL WHERE id = $id");
        $conn->close();
    }
    // Expire the cookie
    setcookie('remember_token', '', time() - 3600, '/', '', true, true);
}

// Destroy session
$_SESSION = [];
session_destroy();

// Redirect to login
header('Location: login.html');
exit;