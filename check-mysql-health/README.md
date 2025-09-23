# Useful Scripts Collection

[![CI](https://github.com/<YOUR_USERNAME>/<YOUR_REPO_NAME>/actions/workflows/ci.yml/badge.svg)](https://github.com/<YOUR_USERNAME>/<YOUR_REPO_NAME>/actions)

This repository contains small, reusable utility scripts.  
Currently included:

- **`check-mysql-health.sh`** → verifies that MySQL is running correctly under systemd and responds to queries.

---

## Scripts

### 1. `check-mysql-health.sh`

This script performs:

1. **systemd check** – ensures `mysql.service` is active.  
2. **Ping test** – uses `mysqladmin ping` to confirm MySQL is alive.  
3. **Query test** – runs `SELECT VERSION(), NOW()` to validate MySQL responsiveness.

#### Setup

Create a credentials file to avoid password prompts:

### 1️⃣ Use `~/.my.cnf` for passwordless login

Create or edit the file in your home directory:

```ini
# ~/.my.cnf
[client]
user=root
password=yourpassword
```

Set proper permissions:

```bash
chmod 600 ~/.my.cnf
```

**Then remove `-u root -p` from all `mysql` commands** in the script.
Example:

```bash
RESULT=$(mysql -e "SELECT VERSION() AS Version, NOW() AS CurrentTime;" 2>/dev/null)
```

This allows the query to run without prompting.

---

### 2️⃣ Use a dedicated MySQL user with limited privileges

Instead of `root`, create a new user that can at least `SELECT`:

```sql
CREATE USER IF NOT EXISTS 'healthcheck'@'localhost' IDENTIFIED BY 'mypassword';
GRANT SELECT ON mysql.* TO 'healthcheck'@'localhost';
FLUSH PRIVILEGES;
```

Then update `~/.my.cnf`:

```ini
[client]
user=healthcheck
password=mypassword
```

---

### 3️⃣ Verify socket/host access

Sometimes MySQL is configured to allow `root` login only via `sudo mysql` or only via TCP (`127.0.0.1`).
Check with:

```bash
mysql -u root -p -e "SELECT VERSION();"
```

If this fails, the script cannot run queries until credentials are available.

---

After updating `~/.my.cnf` or using a dedicated user, the script will successfully log both CSV and JSON outputs to log folder.

