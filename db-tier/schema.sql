-- ─────────────────────────────────────────────────────────────────
--  VickYCloud — DevOps 3-Tier Application
--  Database Schema  |  db-tier/schema.sql
--  Covers: login.html + login.php + submit.php + index.html
-- ─────────────────────────────────────────────────────────────────

CREATE DATABASE IF NOT EXISTS devopsdb
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE devopsdb;

-- ══════════════════════════════════════════════════════════════════
--  TABLE 1 — USERS
--  Used by: login.php (authentication), submit.php (user_id FK)
-- ══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS users (
    id               INT           AUTO_INCREMENT PRIMARY KEY,
    username         VARCHAR(80)   UNIQUE,
    first_name       VARCHAR(100)  NOT NULL,
    last_name        VARCHAR(100)  NOT NULL,
    email            VARCHAR(255)  NOT NULL UNIQUE,
    password_hash    VARCHAR(255)  NOT NULL,              -- bcrypt via password_hash()
    company          VARCHAR(150),
    role             ENUM('admin','developer','viewer') DEFAULT 'developer',

    -- Auth security
    mfa_enabled      TINYINT(1)    DEFAULT 0,
    mfa_secret       VARCHAR(64),                         -- TOTP base32 secret
    remember_token   VARCHAR(64),                         -- SHA-256 of cookie token
    login_attempts   TINYINT       DEFAULT 0,
    locked_until     DATETIME,
    last_login       DATETIME,

    -- Timestamps
    created_at       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ══════════════════════════════════════════════════════════════════
--  TABLE 2 — MESSAGES
--  Used by: submit.php (index.html contact/demo form)
--  Fields match: first_name, last_name, email, company, cloud, message
-- ══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS messages (
    id               INT           AUTO_INCREMENT PRIMARY KEY,
    user_id          INT,                                  -- NULL = guest submission
    first_name       VARCHAR(100)  NOT NULL,
    last_name        VARCHAR(100)  NOT NULL,
    email            VARCHAR(255)  NOT NULL,
    company          VARCHAR(150),
    cloud            ENUM(
                         'AWS',
                         'Google Cloud',
                         'Azure',
                         'Multi-Cloud',
                         'On-Premise / Hybrid',
                         ''
                     ) DEFAULT '',
    message          TEXT          NOT NULL,
    status           ENUM('new','read','replied') DEFAULT 'new',
    created_at       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_messages_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE SET NULL
);

-- ══════════════════════════════════════════════════════════════════
--  TABLE 3 — LOGIN_LOGS
--  Used by: login.php — audit trail for every login attempt
-- ══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS login_logs (
    id               INT           AUTO_INCREMENT PRIMARY KEY,
    user_id          INT,
    ip_address       VARCHAR(45)   NOT NULL,               -- supports IPv6
    user_agent       VARCHAR(255),
    status           ENUM('success','failed','locked') DEFAULT 'failed',
    created_at       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_loginlogs_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE SET NULL
);

-- ══════════════════════════════════════════════════════════════════
--  TABLE 4 — DEPLOYMENTS
--  CI/CD pipeline events written by app-tier automation
-- ══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS deployments (
    id               INT           AUTO_INCREMENT PRIMARY KEY,
    service_name     VARCHAR(150)  NOT NULL,
    version          VARCHAR(50)   NOT NULL,
    environment      ENUM('dev','staging','production') NOT NULL,
    status           ENUM('pending','running','success','failed') DEFAULT 'pending',
    deployed_by      VARCHAR(100),
    deployed_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

-- ══════════════════════════════════════════════════════════════════
--  INDEXES
-- ══════════════════════════════════════════════════════════════════
CREATE INDEX idx_users_email          ON users        (email);
CREATE INDEX idx_users_username       ON users        (username);
CREATE INDEX idx_users_role           ON users        (role);

CREATE INDEX idx_messages_email       ON messages     (email);
CREATE INDEX idx_messages_status      ON messages     (status);
CREATE INDEX idx_messages_created     ON messages     (created_at);
CREATE INDEX idx_messages_user        ON messages     (user_id);

CREATE INDEX idx_loginlogs_user       ON login_logs   (user_id);
CREATE INDEX idx_loginlogs_ip         ON login_logs   (ip_address);
CREATE INDEX idx_loginlogs_created    ON login_logs   (created_at);

CREATE INDEX idx_deployments_env      ON deployments  (environment);
CREATE INDEX idx_deployments_status   ON deployments  (status);

-- ══════════════════════════════════════════════════════════════════
--  SEED DATA  (comment out before production deploy)
-- ══════════════════════════════════════════════════════════════════

-- Default admin user  |  password: Admin@1234  (change immediately)
INSERT IGNORE INTO users
    (username, first_name, last_name, email, password_hash, role, mfa_enabled)
VALUES
    ('vickyadmin', 'Vicky', 'Admin', 'admin@vicky.cloud',
     '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- bcrypt of "Admin@1234"
     'admin', 1);

-- Sample developer
INSERT IGNORE INTO users
    (username, first_name, last_name, email, password_hash, role)
VALUES
    ('devuser', 'Dev', 'User', 'dev@vicky.cloud',
     '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
     'developer');

-- Sample deployments
INSERT IGNORE INTO deployments (service_name, version, environment, status, deployed_by) VALUES
    ('frontend-service', 'v2.4.0', 'production', 'success', 'admin@vicky.cloud'),
    ('api-service',      'v1.9.3', 'production', 'success', 'admin@vicky.cloud'),
    ('mysql-service',    'v1.2.1', 'production', 'success', 'admin@vicky.cloud'),
    ('redis-cache',      'v1.0.5', 'staging',    'running', 'dev@vicky.cloud');

-- ─────────────────────────────────────────────────────────────────
--  END OF SCHEMA
-- ─────────────────────────────────────────────────────────────────