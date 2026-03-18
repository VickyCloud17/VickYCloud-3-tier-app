<?php
// =============================================================
//  VickYCloud — Secure Dashboard
//  File: app-tier/dashboard.php
//  Security:
//    - Session required (redirects to login if not set)
//    - Session timeout after 30 minutes inactivity
//    - Admin-only sections clearly marked
//    - Role-based UI rendering
// =============================================================

session_start();

// -------------------------------------------------------------
//  Auth check — redirect to login if no session
// -------------------------------------------------------------
if (!isset($_SESSION['user_id'])) {
    header('Location: login.html?error=Please+login+to+access+the+dashboard');
    exit;
}

// -------------------------------------------------------------
//  Session timeout — 30 minutes inactivity
// -------------------------------------------------------------
$timeout = 30 * 60; // 30 minutes
if (isset($_SESSION['last_activity']) && (time() - $_SESSION['last_activity']) > $timeout) {
    session_unset();
    session_destroy();
    header('Location: login.html?error=Session+expired.+Please+login+again.');
    exit;
}
$_SESSION['last_activity'] = time();

// -------------------------------------------------------------
//  DB connection
// -------------------------------------------------------------
$host = getenv('DB_HOST') ?: 'mysql-service';
$user = getenv('DB_USER') ?: 'vickyuser';
$pass = getenv('DB_PASS') ?: 'password123';
$db   = getenv('DB_NAME') ?: 'devopsdb';

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    die("DB Error: " . $conn->connect_error);
}

// -------------------------------------------------------------
//  Current user info from session
// -------------------------------------------------------------
$current_user_id   = (int) $_SESSION['user_id'];
$current_user_name = $_SESSION['user_name']  ?? 'User';
$current_username  = $_SESSION['username']   ?? '';
$current_role      = $_SESSION['user_role']  ?? 'developer';
$is_admin          = ($current_role === 'admin');

// -------------------------------------------------------------
//  Fetch dashboard stats
// -------------------------------------------------------------
$total_users    = $conn->query("SELECT COUNT(*) c FROM users")->fetch_assoc()['c'];
$total_messages = $conn->query("SELECT COUNT(*) c FROM messages")->fetch_assoc()['c'];
$new_messages   = $conn->query("SELECT COUNT(*) c FROM messages WHERE status='new'")->fetch_assoc()['c'];
$total_logins   = $conn->query("SELECT COUNT(*) c FROM login_logs WHERE status='success'")->fetch_assoc()['c'];
$total_deploys  = $conn->query("SELECT COUNT(*) c FROM deployments WHERE status='success'")->fetch_assoc()['c'];
$failed_logins  = $conn->query("SELECT COUNT(*) c FROM login_logs WHERE status='failed' AND created_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)")->fetch_assoc()['c'];

// -------------------------------------------------------------
//  Fetch data — admin sees all, developer sees limited
// -------------------------------------------------------------

// Messages — all roles can see
$messages = $conn->query(
    "SELECT id, first_name, last_name, email, company, cloud, message, status, created_at
     FROM messages ORDER BY created_at DESC LIMIT 10"
);

// Users — admin only
$users = null;
if ($is_admin) {
    $users = $conn->query(
        "SELECT id, username, first_name, last_name, email, role,
                mfa_enabled, login_attempts, last_login, created_at
         FROM users ORDER BY created_at DESC"
    );
}

// Login logs — admin sees all, developer sees own only
if ($is_admin) {
    $logs = $conn->query(
        "SELECT l.id, u.username, u.email, l.ip_address, l.status, l.created_at
         FROM login_logs l
         LEFT JOIN users u ON l.user_id = u.id
         ORDER BY l.created_at DESC LIMIT 20"
    );
} else {
    $logs = $conn->query(
        "SELECT l.id, u.username, u.email, l.ip_address, l.status, l.created_at
         FROM login_logs l
         LEFT JOIN users u ON l.user_id = u.id
         WHERE l.user_id = $current_user_id
         ORDER BY l.created_at DESC LIMIT 10"
    );
}

// Deployments — all roles can see
$deployments = $conn->query(
    "SELECT id, service_name, version, environment, status, deployed_by, deployed_at
     FROM deployments ORDER BY deployed_at DESC LIMIT 10"
);

$conn->close();
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>VickYCloud — Dashboard</title>
  <link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=IBM+Plex+Mono:wght@400;500&family=Manrope:wght@300;400;500;600&display=swap" rel="stylesheet"/>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    :root {
      --bg:      #04060f; --surface: #090d1e; --card: #0b1120;
      --border:  rgba(99,179,255,0.12); --accent: #3b82f6;
      --accent2: #06b6d4; --accent3: #8b5cf6; --text: #e8edf8;
      --muted:   #7a8aaa; --green: #10b981; --red: #ef4444;
      --orange:  #f97316; --yellow: #eab308;
    }
    body { font-family: 'Manrope', sans-serif; background: var(--bg); color: var(--text); min-height: 100vh; }

    /* SIDEBAR */
    .sidebar {
      position: fixed; left: 0; top: 0; bottom: 0; width: 220px;
      background: var(--surface); border-right: 1px solid var(--border);
      display: flex; flex-direction: column; padding: 24px 0; z-index: 100;
    }
    .sidebar-brand {
      display: flex; align-items: center; gap: 10px;
      padding: 0 20px 24px; font-family: 'Syne', sans-serif;
      font-size: 1.2rem; font-weight: 800;
      border-bottom: 1px solid var(--border); margin-bottom: 12px;
    }
    .brand-icon {
      width: 30px; height: 30px;
      background: linear-gradient(135deg, var(--accent), var(--accent3));
      border-radius: 7px; display: grid; place-items: center; font-size: 0.9rem;
    }
    .brand-text span { color: var(--accent); }
    .nav-section {
      padding: 8px 12px 4px; font-family: 'IBM Plex Mono', monospace;
      font-size: 0.62rem; color: var(--muted);
      letter-spacing: 0.12em; text-transform: uppercase;
    }
    .nav-item {
      display: flex; align-items: center; gap: 10px;
      padding: 10px 20px; font-size: 0.875rem; font-weight: 500;
      color: var(--muted); text-decoration: none;
      border-radius: 8px; margin: 2px 8px; cursor: pointer; transition: all 0.2s;
    }
    .nav-item:hover { background: rgba(255,255,255,0.05); color: var(--text); }
    .nav-item.active { background: rgba(59,130,246,0.12); color: var(--accent); }
    .nav-icon { font-size: 1rem; width: 20px; text-align: center; }
    .nav-badge {
      margin-left: auto; background: var(--accent); color: #fff;
      font-size: 0.65rem; padding: 1px 7px; border-radius: 100px;
    }
    .admin-only-nav {
      opacity: <?= $is_admin ? '1' : '0.3' ?>;
      pointer-events: <?= $is_admin ? 'auto' : 'none' ?>;
    }
    .sidebar-footer {
      margin-top: auto; padding: 16px 20px; border-top: 1px solid var(--border);
    }
    .user-info { display: flex; align-items: center; gap: 10px; margin-bottom: 12px; }
    .user-avatar {
      width: 34px; height: 34px;
      background: linear-gradient(135deg, var(--accent), var(--accent3));
      border-radius: 50%; display: grid; place-items: center;
      font-size: 0.85rem; font-weight: 700; flex-shrink: 0;
    }
    .user-name  { font-size: 0.82rem; font-weight: 600; }
    .user-role  { font-size: 0.7rem; color: var(--muted); font-family: 'IBM Plex Mono', monospace; }
    .logout-btn {
      display: flex; align-items: center; gap: 8px; width: 100%;
      padding: 9px 12px; background: rgba(239,68,68,0.08);
      border: 1px solid rgba(239,68,68,0.2); border-radius: 8px;
      color: #fca5a5; font-size: 0.82rem; font-weight: 600;
      cursor: pointer; text-decoration: none; transition: all 0.2s;
    }
    .logout-btn:hover { background: rgba(239,68,68,0.15); }

    /* MAIN */
    .main { margin-left: 220px; padding: 32px; }
    .page-header {
      display: flex; align-items: center; justify-content: space-between;
      margin-bottom: 28px;
    }
    .page-title { font-family: 'Syne', sans-serif; font-size: 1.6rem; font-weight: 800; }
    .page-subtitle { color: var(--muted); font-size: 0.875rem; margin-top: 4px; }
    .live-badge {
      display: flex; align-items: center; gap: 8px;
      background: rgba(16,185,129,0.1); border: 1px solid rgba(16,185,129,0.25);
      border-radius: 100px; padding: 6px 14px;
      font-family: 'IBM Plex Mono', monospace; font-size: 0.72rem; color: var(--green);
    }
    .live-badge::before { content: '●'; font-size: 0.45rem; animation: pulse 2s infinite; }

    /* STATS */
    .stats-grid { display: grid; grid-template-columns: repeat(5,1fr); gap: 14px; margin-bottom: 28px; }
    .stat-card {
      background: var(--card); border: 1px solid var(--border);
      border-radius: 14px; padding: 18px; transition: transform 0.2s;
    }
    .stat-card:hover { transform: translateY(-3px); }
    .stat-card:nth-child(1) { border-top: 2px solid var(--accent); }
    .stat-card:nth-child(2) { border-top: 2px solid var(--green); }
    .stat-card:nth-child(3) { border-top: 2px solid var(--accent2); }
    .stat-card:nth-child(4) { border-top: 2px solid var(--accent3); }
    .stat-card:nth-child(5) { border-top: 2px solid var(--red); }
    .stat-icon { font-size: 1.3rem; margin-bottom: 8px; }
    .stat-val { font-family: 'Syne', sans-serif; font-size: 1.8rem; font-weight: 800; }
    .stat-card:nth-child(1) .stat-val { color: var(--accent); }
    .stat-card:nth-child(2) .stat-val { color: var(--green); }
    .stat-card:nth-child(3) .stat-val { color: var(--accent2); }
    .stat-card:nth-child(4) .stat-val { color: var(--accent3); }
    .stat-card:nth-child(5) .stat-val { color: var(--red); }
    .stat-lbl { color: var(--muted); font-size: 0.78rem; margin-top: 3px; }

    /* SECTIONS */
    .section { margin-bottom: 28px; }
    .section-header {
      display: flex; align-items: center; justify-content: space-between;
      margin-bottom: 14px;
    }
    .section-title {
      font-family: 'Syne', sans-serif; font-size: 1rem; font-weight: 700;
      display: flex; align-items: center; gap: 8px;
    }
    .section-count {
      background: rgba(59,130,246,0.15); color: var(--accent);
      font-size: 0.7rem; font-family: 'IBM Plex Mono', monospace;
      padding: 2px 8px; border-radius: 100px;
    }
    .admin-only-section {
      opacity: <?= $is_admin ? '1' : '0.4' ?>;
      position: relative;
    }
    .admin-only-section::after {
      content: <?= $is_admin ? "''" : "'🔒 Admin only'" ?>;
      <?php if (!$is_admin): ?>
      position: absolute; top: 50%; left: 50%;
      transform: translate(-50%, -50%);
      background: rgba(4,6,15,0.85); padding: 12px 24px;
      border-radius: 10px; font-size: 0.9rem; color: var(--muted);
      border: 1px solid var(--border); z-index: 10;
      <?php endif; ?>
    }

    /* TABLE */
    .table-wrap {
      background: var(--card); border: 1px solid var(--border);
      border-radius: 14px; overflow: hidden;
    }
    table { width: 100%; border-collapse: collapse; }
    thead { background: rgba(255,255,255,0.03); }
    th {
      padding: 12px 16px; text-align: left;
      font-family: 'IBM Plex Mono', monospace;
      font-size: 0.68rem; color: var(--muted);
      letter-spacing: 0.1em; text-transform: uppercase;
      border-bottom: 1px solid var(--border);
    }
    td {
      padding: 12px 16px; font-size: 0.845rem;
      border-bottom: 1px solid rgba(99,179,255,0.05);
      vertical-align: middle;
    }
    tr:last-child td { border-bottom: none; }
    tr:hover td { background: rgba(255,255,255,0.02); }

    /* BADGES */
    .badge {
      display: inline-flex; align-items: center; gap: 4px;
      padding: 3px 10px; border-radius: 100px;
      font-size: 0.7rem; font-weight: 600;
      font-family: 'IBM Plex Mono', monospace;
    }
    .badge-new      { background: rgba(59,130,246,0.15);  color: var(--accent); }
    .badge-read     { background: rgba(122,138,170,0.12); color: var(--muted); }
    .badge-replied  { background: rgba(16,185,129,0.15);  color: var(--green); }
    .badge-success  { background: rgba(16,185,129,0.15);  color: var(--green); }
    .badge-failed   { background: rgba(239,68,68,0.15);   color: var(--red); }
    .badge-locked   { background: rgba(249,115,22,0.15);  color: var(--orange); }
    .badge-pending  { background: rgba(234,179,8,0.15);   color: var(--yellow); }
    .badge-running  { background: rgba(6,182,212,0.15);   color: var(--accent2); }
    .badge-admin    { background: rgba(139,92,246,0.15);  color: var(--accent3); }
    .badge-developer{ background: rgba(59,130,246,0.12);  color: var(--accent); }
    .badge-viewer   { background: rgba(122,138,170,0.12); color: var(--muted); }
    .badge-production{ background: rgba(239,68,68,0.12);  color: var(--red); }
    .badge-staging  { background: rgba(234,179,8,0.12);   color: var(--yellow); }
    .badge-dev      { background: rgba(16,185,129,0.12);  color: var(--green); }

    .two-col { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
    .msg-preview {
      max-width: 200px; white-space: nowrap;
      overflow: hidden; text-overflow: ellipsis;
      color: var(--muted); font-size: 0.8rem;
    }
    .action-btn {
      padding: 6px 14px; background: rgba(59,130,246,0.1);
      border: 1px solid rgba(59,130,246,0.2); border-radius: 6px;
      color: var(--accent); font-size: 0.78rem; font-weight: 600;
      cursor: pointer; text-decoration: none; transition: all 0.2s;
    }
    .action-btn:hover { background: rgba(59,130,246,0.2); }
    .empty-row td {
      text-align: center; padding: 32px;
      color: var(--muted); font-size: 0.875rem;
    }
    .alert-banner {
      background: rgba(239,68,68,0.1); border: 1px solid rgba(239,68,68,0.25);
      border-radius: 10px; padding: 12px 16px; margin-bottom: 20px;
      display: flex; align-items: center; gap: 10px;
      font-size: 0.85rem; color: #fca5a5;
    }

    /* Session timer */
    .session-timer {
      font-family: 'IBM Plex Mono', monospace;
      font-size: 0.68rem; color: var(--muted);
      margin-top: 8px; text-align: center;
    }

    @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.3} }

    @media (max-width: 1200px) { .stats-grid { grid-template-columns: repeat(3,1fr); } }
    @media (max-width: 1024px) { .two-col { grid-template-columns: 1fr; } }
    @media (max-width: 768px)  { .sidebar { display: none; } .main { margin-left: 0; padding: 20px; } }
  </style>
</head>
<body>

<!-- SIDEBAR -->
<aside class="sidebar">
  <div class="sidebar-brand">
    <div class="brand-icon">⚡</div>
    <div class="brand-text">VickY<span>Cloud</span></div>
  </div>

  <div class="nav-section">// Platform</div>
  <a class="nav-item active" href="dashboard.php"><span class="nav-icon">📊</span> Dashboard</a>
  <a class="nav-item" href="index.html"><span class="nav-icon">🌐</span> Homepage</a>

  <div class="nav-section">// Data</div>
  <a class="nav-item" href="#messages"><span class="nav-icon">✉️</span> Messages
    <?php if($new_messages > 0): ?><span class="nav-badge"><?= $new_messages ?></span><?php endif; ?>
  </a>
  <a class="nav-item admin-only-nav" href="#users"><span class="nav-icon">👥</span> Users</a>
  <a class="nav-item" href="#logs"><span class="nav-icon">🔐</span> Login Logs</a>
  <a class="nav-item" href="#deployments"><span class="nav-icon">🚀</span> Deployments</a>

  <?php if ($is_admin): ?>
  <div class="nav-section">// Admin</div>
  <a class="nav-item" href="register.html"><span class="nav-icon">➕</span> Add User</a>
  <?php endif; ?>

  <div class="sidebar-footer">
    <div class="user-info">
      <div class="user-avatar"><?= strtoupper(substr($current_user_name, 0, 1)) ?></div>
      <div>
        <div class="user-name"><?= htmlspecialchars($current_user_name) ?></div>
        <div class="user-role"><?= htmlspecialchars($current_role) ?><?= $is_admin ? ' 👑' : '' ?></div>
      </div>
    </div>
    <a href="logout.php" class="logout-btn">🚪 Sign Out</a>
    <div class="session-timer" id="session-timer">Session: 30:00</div>
  </div>
</aside>

<!-- MAIN -->
<main class="main">

  <div class="page-header">
    <div>
      <div class="page-title">Dashboard <?= $is_admin ? '👑' : '' ?></div>
      <div class="page-subtitle">Welcome back, <?= htmlspecialchars($current_user_name) ?> 👋
        <?= $is_admin ? '<span style="color:var(--accent3);font-size:0.8rem;margin-left:8px">Admin Access</span>' : '' ?>
      </div>
    </div>
    <div class="live-badge">All Systems Operational</div>
  </div>

  <?php if ($failed_logins > 5): ?>
  <div class="alert-banner">
    ⚠️ <strong><?= $failed_logins ?> failed login attempts</strong> in the last 24 hours. Check login logs for suspicious activity.
  </div>
  <?php endif; ?>

  <!-- STATS -->
  <div class="stats-grid">
    <div class="stat-card"><div class="stat-icon">👥</div><div class="stat-val"><?= $total_users ?></div><div class="stat-lbl">Total Users</div></div>
    <div class="stat-card"><div class="stat-icon">✉️</div><div class="stat-val"><?= $total_messages ?></div><div class="stat-lbl">Messages <?php if($new_messages>0):?><span style="color:var(--accent);font-size:0.7rem">(<?=$new_messages?> new)</span><?php endif;?></div></div>
    <div class="stat-card"><div class="stat-icon">🔐</div><div class="stat-val"><?= $total_logins ?></div><div class="stat-lbl">Successful Logins</div></div>
    <div class="stat-card"><div class="stat-icon">🚀</div><div class="stat-val"><?= $total_deploys ?></div><div class="stat-lbl">Deployments</div></div>
    <div class="stat-card"><div class="stat-icon">🚨</div><div class="stat-val"><?= $failed_logins ?></div><div class="stat-lbl">Failed Logins (24h)</div></div>
  </div>

  <!-- MESSAGES -->
  <div class="section" id="messages">
    <div class="section-header">
      <div class="section-title">✉️ Recent Messages <span class="section-count"><?= $total_messages ?> total</span></div>
    </div>
    <div class="table-wrap">
      <table>
        <thead><tr><th>#</th><th>Name</th><th>Email</th><th>Company</th><th>Cloud</th><th>Message</th><th>Status</th><th>Date</th></tr></thead>
        <tbody>
          <?php if ($messages->num_rows === 0): ?>
            <tr class="empty-row"><td colspan="8">No messages yet — submit the contact form to see data here</td></tr>
          <?php else: while ($row = $messages->fetch_assoc()): ?>
          <tr>
            <td style="color:var(--muted);font-family:'IBM Plex Mono',monospace;font-size:0.75rem"><?= $row['id'] ?></td>
            <td><?= htmlspecialchars($row['first_name'].' '.$row['last_name']) ?></td>
            <td style="color:var(--muted);font-size:0.8rem"><?= htmlspecialchars($row['email']) ?></td>
            <td style="color:var(--muted);font-size:0.8rem"><?= htmlspecialchars($row['company']??'—') ?></td>
            <td><?php if($row['cloud']):?><span class="badge badge-new"><?= htmlspecialchars($row['cloud']) ?></span><?php else:?>—<?php endif;?></td>
            <td><div class="msg-preview" title="<?= htmlspecialchars($row['message']) ?>"><?= htmlspecialchars($row['message']) ?></div></td>
            <td><span class="badge badge-<?= $row['status'] ?>"><?= $row['status'] ?></span></td>
            <td style="color:var(--muted);font-size:0.78rem;font-family:'IBM Plex Mono',monospace"><?= date('d M Y', strtotime($row['created_at'])) ?></td>
          </tr>
          <?php endwhile; endif; ?>
        </tbody>
      </table>
    </div>
  </div>

  <!-- USERS + LOGS (two columns) -->
  <div class="two-col">

    <!-- USERS — Admin only -->
    <div class="section admin-only-section" id="users">
      <div class="section-header">
        <div class="section-title">👥 Users <span class="section-count"><?= $total_users ?></span></div>
        <?php if ($is_admin): ?><a href="register.html" class="action-btn">+ Add User</a><?php endif; ?>
      </div>
      <div class="table-wrap">
        <table>
          <thead><tr><th>User</th><th>Email</th><th>Role</th><th>MFA</th><th>Attempts</th><th>Joined</th></tr></thead>
          <tbody>
            <?php if (!$is_admin): ?>
              <tr class="empty-row"><td colspan="6">🔒 Admin access required</td></tr>
            <?php elseif ($users->num_rows === 0): ?>
              <tr class="empty-row"><td colspan="6">No users found</td></tr>
            <?php else: while ($row = $users->fetch_assoc()): ?>
            <tr>
              <td>
                <div style="display:flex;align-items:center;gap:8px">
                  <div style="width:28px;height:28px;background:linear-gradient(135deg,var(--accent),var(--accent3));border-radius:50%;display:grid;place-items:center;font-size:0.7rem;font-weight:700;flex-shrink:0"><?= strtoupper(substr($row['first_name'],0,1)) ?></div>
                  <div>
                    <div style="font-size:0.82rem;font-weight:600"><?= htmlspecialchars($row['username']) ?></div>
                    <div style="font-size:0.72rem;color:var(--muted)"><?= htmlspecialchars($row['first_name'].' '.$row['last_name']) ?></div>
                  </div>
                </div>
              </td>
              <td style="color:var(--muted);font-size:0.78rem"><?= htmlspecialchars($row['email']) ?></td>
              <td><span class="badge badge-<?= $row['role'] ?>"><?= $row['role'] ?><?= $row['role']==='admin'?' 👑':'' ?></span></td>
              <td style="font-size:0.8rem;color:<?= $row['mfa_enabled']?'var(--green)':'var(--muted)' ?>"><?= $row['mfa_enabled']?'🔐 On':'○ Off' ?></td>
              <td style="font-family:'IBM Plex Mono',monospace;font-size:0.78rem;color:<?= $row['login_attempts']>3?'var(--red)':'var(--muted)' ?>"><?= $row['login_attempts'] ?><?= $row['login_attempts']>3?' ⚠️':'' ?></td>
              <td style="color:var(--muted);font-size:0.72rem;font-family:'IBM Plex Mono',monospace"><?= date('d M Y', strtotime($row['created_at'])) ?></td>
            </tr>
            <?php endwhile; endif; ?>
          </tbody>
        </table>
      </div>
    </div>

    <!-- LOGIN LOGS -->
    <div class="section" id="logs">
      <div class="section-header">
        <div class="section-title">🔐 Login Logs <span class="section-count"><?= $is_admin?'all':'yours' ?></span></div>
      </div>
      <div class="table-wrap">
        <table>
          <thead><tr><th>User</th><th>IP Address</th><th>Status</th><th>Time</th></tr></thead>
          <tbody>
            <?php if ($logs->num_rows === 0): ?>
              <tr class="empty-row"><td colspan="4">No login activity yet</td></tr>
            <?php else: while ($row = $logs->fetch_assoc()): ?>
            <tr>
              <td style="font-size:0.82rem"><?= htmlspecialchars($row['username']??'unknown') ?></td>
              <td style="font-family:'IBM Plex Mono',monospace;font-size:0.78rem;color:var(--muted)"><?= htmlspecialchars($row['ip_address']) ?></td>
              <td><span class="badge badge-<?= $row['status'] ?>"><?= $row['status'] ?></span></td>
              <td style="color:var(--muted);font-size:0.72rem;font-family:'IBM Plex Mono',monospace"><?= date('d M H:i', strtotime($row['created_at'])) ?></td>
            </tr>
            <?php endwhile; endif; ?>
          </tbody>
        </table>
      </div>
    </div>

  </div>

  <!-- DEPLOYMENTS -->
  <div class="section" id="deployments">
    <div class="section-header">
      <div class="section-title">🚀 Deployments <span class="section-count"><?= $total_deploys ?> successful</span></div>
    </div>
    <div class="table-wrap">
      <table>
        <thead><tr><th>#</th><th>Service</th><th>Version</th><th>Environment</th><th>Status</th><th>Deployed By</th><th>Date</th></tr></thead>
        <tbody>
          <?php if ($deployments->num_rows === 0): ?>
            <tr class="empty-row"><td colspan="7">No deployments yet — GitHub Actions will populate this automatically</td></tr>
          <?php else: while ($row = $deployments->fetch_assoc()): ?>
          <tr>
            <td style="color:var(--muted);font-family:'IBM Plex Mono',monospace;font-size:0.75rem"><?= $row['id'] ?></td>
            <td style="font-weight:600"><?= htmlspecialchars($row['service_name']) ?></td>
            <td style="font-family:'IBM Plex Mono',monospace;font-size:0.8rem;color:var(--accent2)"><?= htmlspecialchars($row['version']) ?></td>
            <td><span class="badge badge-<?= $row['environment'] ?>"><?= $row['environment'] ?></span></td>
            <td><span class="badge badge-<?= $row['status'] ?>"><?= $row['status'] ?></span></td>
            <td style="color:var(--muted);font-size:0.8rem"><?= htmlspecialchars($row['deployed_by']??'—') ?></td>
            <td style="color:var(--muted);font-size:0.72rem;font-family:'IBM Plex Mono',monospace"><?= date('d M Y H:i', strtotime($row['deployed_at'])) ?></td>
          </tr>
          <?php endwhile; endif; ?>
        </tbody>
      </table>
    </div>
  </div>

</main>

<script>
// Session countdown timer (30 min)
let seconds = 30 * 60;
const timer = document.getElementById('session-timer');
setInterval(() => {
  seconds--;
  if (seconds <= 0) { window.location.href = 'logout.php'; return; }
  const m = Math.floor(seconds / 60).toString().padStart(2,'0');
  const s = (seconds % 60).toString().padStart(2,'0');
  timer.textContent = `Session: ${m}:${s}`;
  if (seconds < 300) timer.style.color = 'var(--red)'; // red when < 5 min
}, 1000);

// Smooth scroll for nav links
document.querySelectorAll('.nav-item[href^="#"]').forEach(link => {
  link.addEventListener('click', e => {
    e.preventDefault();
    document.querySelector(link.getAttribute('href'))?.scrollIntoView({behavior:'smooth'});
    document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('active'));
    link.classList.add('active');
  });
});
</script>
</body>
</html>