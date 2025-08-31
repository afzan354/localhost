#!/data/data/com.termux/files/usr/bin/bash

# ================================================
# Termux Localhost Auto Installer
# Apache + PHP + MySQL + phpMyAdmin
# Data disimpan di sdcard untuk kemudahan editing
# ================================================

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Direktori utama di sdcard
LOCALHOST_DIR="/sdcard/termux-localhost"
WEB_DIR="$LOCALHOST_DIR/www"
CONFIG_DIR="$LOCALHOST_DIR/config"
LOG_DIR="$LOCALHOST_DIR/logs"
DATA_DIR="$LOCALHOST_DIR/data"

# Function untuk print dengan warna
print_header() {
    echo -e "${PURPLE}=========================================${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}=========================================${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Function untuk membuat progress bar
show_progress() {
    local duration=$1
    local message=$2
    echo -n -e "${YELLOW}$message${NC} "
    
    for ((i=0; i<duration; i++)); do
        echo -n "▓"
        sleep 0.1
    done
    echo -e " ${GREEN}✓${NC}"
}

# Function untuk check permission storage
check_storage_permission() {
    if [ ! -w "/sdcard" ]; then
        print_error "Tidak dapat mengakses /sdcard"
        print_info "Pastikan Termux memiliki permission storage:"
        print_info "Settings → Apps → Termux → Permissions → Storage → Allow"
        print_info "Atau jalankan: termux-setup-storage"
        exit 1
    fi
}

# Function untuk backup konfigurasi lama jika ada
backup_old_config() {
    if [ -d "$LOCALHOST_DIR" ]; then
        print_warning "Direktori localhost sudah ada, membuat backup..."
        mv "$LOCALHOST_DIR" "${LOCALHOST_DIR}-backup-$(date +%Y%m%d-%H%M%S)"
        print_success "Backup berhasil dibuat"
    fi
}

# Function untuk membuat struktur direktori
create_directory_structure() {
    print_step "Membuat struktur direktori di sdcard..."
    
    mkdir -p "$LOCALHOST_DIR"
    mkdir -p "$WEB_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$DATA_DIR/mysql"
    mkdir -p "$LOCALHOST_DIR/scripts"
    mkdir -p "$LOCALHOST_DIR/backup"
    
    print_success "Struktur direktori berhasil dibuat"
}

# Function untuk install package yang diperlukan
install_packages() {
    print_step "Update package list..."
    show_progress 10 "Updating packages"
    pkg update -y > /dev/null 2>&1
    
    print_step "Install package yang diperlukan..."
    
    # List package yang dibutuhkan
    PACKAGES="apache2 php php-apache mariadb wget unzip curl nano git"
    
    for package in $PACKAGES; do
        print_info "Installing $package..."
        pkg install -y $package > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            print_success "$package installed ✓"
        else
            print_error "Failed to install $package"
        fi
    done
}

# Function untuk download dan setup phpMyAdmin
setup_phpmyadmin() {
    print_step "Download dan setup phpMyAdmin..."
    
    cd "$WEB_DIR"
    
    # Download phpMyAdmin
    print_info "Downloading phpMyAdmin..."
    wget -q --show-progress -O phpmyadmin.zip "https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip"
    
    if [ $? -eq 0 ]; then
        print_success "phpMyAdmin downloaded successfully"
        
        # Extract
        print_info "Extracting phpMyAdmin..."
        unzip -q phpmyadmin.zip
        mv phpMyAdmin-5.2.1-all-languages phpmyadmin
        rm phpmyadmin.zip
        
        # Create config
        cat > "$WEB_DIR/phpmyadmin/config.inc.php" << 'EOF'
<?php
/**
 * phpMyAdmin configuration for Termux
 */

// Blowfish secret for cookie auth
$cfg['blowfish_secret'] = 'termux-localhost-phpmyadmin-secret-key-2024';

// Server configuration
$i = 0;
$i++;

$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['host'] = 'localhost';
$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['AllowNoPassword'] = true;

// Directories for saving/loading files from the web interface
$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';

// Other settings
$cfg['DefaultLang'] = 'en';
$cfg['ServerDefault'] = 1;
$cfg['VersionCheck'] = false;

// Theme
$cfg['ThemeDefault'] = 'pmahomme';

// Navigation
$cfg['NavigationTreeEnableGrouping'] = false;
$cfg['NavigationTreeDbSeparator'] = '_';
$cfg['NavigationTreeTableSeparator'] = '__';

// Memory and time limits
$cfg['MemoryLimit'] = '512M';
$cfg['ExecTimeLimit'] = 300;

// Session settings
$cfg['LoginCookieValidity'] = 3600;
$cfg['LoginCookieStore'] = 0;
$cfg['LoginCookieDeleteAll'] = true;

// Security
$cfg['ForceSSL'] = false;
$cfg['CheckConfigurationPermissions'] = false;
?>
EOF
        
        print_success "phpMyAdmin setup completed"
    else
        print_error "Failed to download phpMyAdmin"
    fi
}

# Function untuk membuat konfigurasi Apache
create_apache_config() {
    print_step "Membuat konfigurasi Apache..."
    
    cat > "$CONFIG_DIR/httpd.conf" << EOF
# Termux Apache Configuration
ServerRoot "/data/data/com.termux/files/usr"
Listen 8080

# Load necessary modules
LoadModule authz_core_module lib/apache2/mod_authz_core.so
LoadModule authz_host_module lib/apache2/mod_authz_host.so
LoadModule authz_user_module lib/apache2/mod_authz_user.so
LoadModule auth_basic_module lib/apache2/mod_auth_basic.so
LoadModule access_compat_module lib/apache2/mod_access_compat.so
LoadModule authn_file_module lib/apache2/mod_authn_file.so
LoadModule authn_core_module lib/apache2/mod_authn_core.so
LoadModule authz_groupfile_module lib/apache2/mod_authz_groupfile.so
LoadModule rewrite_module lib/apache2/mod_rewrite.so
LoadModule php_module lib/apache2/mod_php.so
LoadModule mpm_prefork_module lib/apache2/mod_mpm_prefork.so
LoadModule unixd_module lib/apache2/mod_unixd.so
LoadModule status_module lib/apache2/mod_status.so
LoadModule autoindex_module lib/apache2/mod_autoindex.so
LoadModule dir_module lib/apache2/mod_dir.so
LoadModule alias_module lib/apache2/mod_alias.so
LoadModule negotiation_module lib/apache2/mod_negotiation.so
LoadModule mime_module lib/apache2/mod_mime.so

# Server settings
ServerName localhost:8080
ServerAdmin webmaster@localhost
DocumentRoot "$WEB_DIR"
DirectoryIndex index.php index.html index.htm

# Directory permissions
<Directory />
    AllowOverride none
    Require all denied
</Directory>

<Directory "$WEB_DIR">
    Options Indexes FollowSymLinks MultiViews
    AllowOverride All
    Require all granted
</Directory>

# PHP handler
<FilesMatch \.php$>
    SetHandler application/x-httpd-php
</FilesMatch>

# MIME types
TypesConfig etc/apache2/mime.types
AddType application/x-httpd-php .php
AddType application/x-httpd-php-source .phps

# Logging (ke sdcard)
ErrorLog "$LOG_DIR/apache_error.log"
CustomLog "$LOG_DIR/apache_access.log" combined
LogLevel warn

# Performance settings
Timeout 300
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5

# MPM Prefork settings
<IfModule mod_mpm_prefork.c>
    StartServers 1
    MinSpareServers 1
    MaxSpareServers 3
    MaxRequestWorkers 50
    MaxConnectionsPerChild 1000
</IfModule>

# Security
ServerTokens Prod
ServerSignature Off

# Enable rewrite engine
RewriteEngine On

# Status page
<Location "/server-status">
    SetHandler server-status
    Require all granted
</Location>

# Alias for easy access
Alias /logs "$LOG_DIR"
<Directory "$LOG_DIR">
    Options Indexes
    AllowOverride None
    Require all granted
</Directory>
EOF

    print_success "Konfigurasi Apache berhasil dibuat"
}

# Function untuk membuat konfigurasi PHP
create_php_config() {
    print_step "Membuat konfigurasi PHP..."
    
    cat > "$CONFIG_DIR/php.ini" << EOF
[PHP]
engine = On
short_open_tag = On
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
serialize_precision = -1
zend.enable_gc = On

; Resource Limits
max_execution_time = 300
max_input_time = 60
memory_limit = 512M

; Error handling
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = On
display_startup_errors = On
log_errors = On
error_log = "$LOG_DIR/php_error.log"

; Data Handling
variables_order = "GPCS"
request_order = "GP"
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 100M
default_mimetype = "text/html"
default_charset = "UTF-8"

; File Uploads
file_uploads = On
upload_max_filesize = 100M
max_file_uploads = 20
upload_tmp_dir = "$DATA_DIR/tmp"

; Fopen wrappers
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60

; Date
date.timezone = Asia/Jakarta

; Session
session.save_handler = files
session.save_path = "$DATA_DIR/sessions"
session.use_strict_mode = 0
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.gc_maxlifetime = 1440

; MySQLi
mysqli.default_socket = /data/data/com.termux/files/usr/tmp/mysql.sock
mysqli.allow_persistent = On
mysqli.max_persistent = -1
mysqli.max_links = -1
mysqli.default_port = 3306
mysqli.reconnect = Off
EOF

    # Buat direktori yang diperlukan
    mkdir -p "$DATA_DIR/tmp"
    mkdir -p "$DATA_DIR/sessions"
    
    print_success "Konfigurasi PHP berhasil dibuat"
}

# Function untuk setup MySQL
setup_mysql() {
    print_step "Setup MySQL/MariaDB..."
    
    # Initialize database jika belum ada
    if [ ! -d "$DATA_DIR/mysql/mysql" ]; then
        print_info "Initializing MySQL database..."
        mysql_install_db --user=mysql --basedir=/data/data/com.termux/files/usr --datadir="$DATA_DIR/mysql"
        print_success "MySQL database initialized"
    fi
    
    # Create MySQL config
    cat > "$CONFIG_DIR/my.cnf" << EOF
[client]
port = 3306
socket = /data/data/com.termux/files/usr/tmp/mysql.sock

[mysql]
no-auto-rehash
default-character-set = utf8mb4

[mysqld]
port = 3306
socket = /data/data/com.termux/files/usr/tmp/mysql.sock
datadir = $DATA_DIR/mysql
log-error = $LOG_DIR/mysql_error.log
pid-file = /data/data/com.termux/files/usr/tmp/mysqld.pid

# Character set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
init-connect = 'SET NAMES utf8mb4'

# Security
bind-address = 127.0.0.1
skip-external-locking
skip-name-resolve

# Performance
key_buffer_size = 16M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 16K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
thread_cache_size = 8
query_cache_size = 16M
tmp_table_size = 16M
max_heap_table_size = 16M
max_connections = 50

# InnoDB
innodb_buffer_pool_size = 16M
innodb_log_file_size = 5M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
EOF
    
    print_success "MySQL setup completed"
}

# Function untuk membuat homepage
create_homepage() {
    print_step "Membuat homepage..."
    
    cat > "$WEB_DIR/index.php" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🚀 Termux Localhost Server</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(45deg, #667eea, #764ba2);
            color: white;
            text-align: center;
            padding: 40px 20px;
        }
        
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .header p {
            font-size: 1.2em;
            opacity: 0.9;
        }
        
        .content {
            padding: 40px;
        }
        
        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 40px;
        }
        
        .status-card {
            background: #f8f9ff;
            border-radius: 10px;
            padding: 20px;
            border-left: 4px solid #667eea;
        }
        
        .status-card h3 {
            color: #333;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .status-card .value {
            font-size: 1.5em;
            font-weight: bold;
            color: #667eea;
        }
        
        .services {
            background: #f8f9ff;
            border-radius: 10px;
            padding: 30px;
            margin-bottom: 30px;
        }
        
        .services h2 {
            color: #333;
            margin-bottom: 20px;
            text-align: center;
        }
        
        .service-links {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }
        
        .service-link {
            display: block;
            background: white;
            color: #333;
            text-decoration: none;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            border: 2px solid #e1e5e9;
        }
        
        .service-link:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
            border-color: #667eea;
        }
        
        .service-link .icon {
            font-size: 2em;
            margin-bottom: 10px;
        }
        
        .info-section {
            background: white;
            border-radius: 10px;
            padding: 30px;
            border: 1px solid #e1e5e9;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-top: 20px;
        }
        
        @media (max-width: 768px) {
            .info-grid {
                grid-template-columns: 1fr;
            }
            
            .header h1 {
                font-size: 2em;
            }
            
            .content {
                padding: 20px;
            }
        }
        
        .footer {
            text-align: center;
            padding: 20px;
            color: #666;
            font-size: 0.9em;
        }
        
        .success { color: #27ae60; }
        .warning { color: #f39c12; }
        .error { color: #e74c3c; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Termux Localhost</h1>
            <p>Apache • PHP • MySQL • phpMyAdmin</p>
        </div>
        
        <div class="content">
            <div class="status-grid">
                <div class="status-card">
                    <h3>🌐 Server Status</h3>
                    <div class="value success">✅ Online</div>
                </div>
                
                <div class="status-card">
                    <h3>🐘 PHP Version</h3>
                    <div class="value"><?php echo phpversion(); ?></div>
                </div>
                
                <div class="status-card">
                    <h3>⚡ Server Port</h3>
                    <div class="value"><?php echo $_SERVER['SERVER_PORT']; ?></div>
                </div>
                
                <div class="status-card">
                    <h3>📁 Document Root</h3>
                    <div class="value" style="font-size: 0.9em; word-break: break-all;">
                        <?php echo $_SERVER['DOCUMENT_ROOT']; ?>
                    </div>
                </div>
            </div>
            
            <div class="services">
                <h2>🛠️ Available Services</h2>
                <div class="service-links">
                    <a href="/phpmyadmin/" class="service-link" target="_blank">
                        <div class="icon">📊</div>
                        <strong>phpMyAdmin</strong>
                        <div>Database Management</div>
                    </a>
                    
                    <a href="/info.php" class="service-link" target="_blank">
                        <div class="icon">ℹ️</div>
                        <strong>PHP Info</strong>
                        <div>Server Information</div>
                    </a>
                    
                    <a href="/server-status" class="service-link" target="_blank">
                        <div class="icon">📈</div>
                        <strong>Server Status</strong>
                        <div>Apache Status</div>
                    </a>
                    
                    <a href="/logs/" class="service-link" target="_blank">
                        <div class="icon">📋</div>
                        <strong>Log Files</strong>
                        <div>View Server Logs</div>
                    </a>
                </div>
            </div>
            
            <div class="info-section">
                <h2>📋 System Information</h2>
                <div class="info-grid">
                    <div>
                        <strong>Server Software:</strong><br>
                        <?php echo $_SERVER['SERVER_SOFTWARE']; ?>
                    </div>
                    
                    <div>
                        <strong>Server Name:</strong><br>
                        <?php echo $_SERVER['SERVER_NAME']; ?>
                    </div>
                    
                    <div>
                        <strong>Request Time:</strong><br>
                        <?php echo date('Y-m-d H:i:s', $_SERVER['REQUEST_TIME']); ?>
                    </div>
                    
                    <div>
                        <strong>Server Admin:</strong><br>
                        <?php echo $_SERVER['SERVER_ADMIN'] ?? 'webmaster@localhost'; ?>
                    </div>
                </div>
                
                <h3 style="margin-top: 20px;">🔧 PHP Extensions:</h3>
                <p style="margin-top: 10px; line-height: 1.6;">
                    <?php echo implode(', ', get_loaded_extensions()); ?>
                </p>
            </div>
        </div>
        
        <div class="footer">
            <p>🎯 Termux Localhost Tools - Data tersimpan di /sdcard/termux-localhost/</p>
        </div>
    </div>
</body>
</html>
EOF

    # Buat info.php
    cat > "$WEB_DIR/info.php" << 'EOF'
<?php
phpinfo();
?>
EOF
    
    print_success "Homepage berhasil dibuat"
}

# Function untuk membuat script startup
create_startup_scripts() {
    print_step "Membuat script startup..."
    
    # Script untuk start semua service
    cat > "$LOCALHOST_DIR/scripts/start-localhost.sh" << EOF
#!/data/data/com.termux/files/usr/bin/bash

echo -e "\033[1;32m============================================\033[0m"
echo -e "\033[1;32m    Starting Termux Localhost Services    \033[0m"
echo -e "\033[1;32m============================================\033[0m"

# Check if services already running
if pgrep -f "mysqld" > /dev/null; then
    echo -e "\033[1;33m[WARNING]\033[0m MySQL sudah berjalan"
else
    echo -e "\033[1;34m[INFO]\033[0m Starting MySQL..."
    mysqld_safe --defaults-file="$CONFIG_DIR/my.cnf" &
    sleep 3
    echo -e "\033[1;32m[SUCCESS]\033[0m MySQL started ✓"
fi

if pgrep -f "httpd" > /dev/null; then
    echo -e "\033[1;33m[WARNING]\033[0m Apache sudah berjalan"
else
    echo -e "\033[1;34m[INFO]\033[0m Starting Apache..."
    httpd -f "$CONFIG_DIR/httpd.conf" -D FOREGROUND &
    sleep 2
    echo -e "\033[1;32m[SUCCESS]\033[0m Apache started ✓"
fi

echo ""
echo -e "\033[1;36m🌐 Web Server: http://localhost:8080\033[0m"
echo -e "\033[1;36m📊 phpMyAdmin: http://localhost:8080/phpmyadmin\033[0m"
echo -e "\033[1;36m📁 Root Directory: $WEB_DIR\033[0m"
echo -e "\033[1;36m📋 Config Directory: $CONFIG_DIR\033[0m"
echo ""
echo -e "\033[1;35mTekan Ctrl+C untuk menghentikan services\033[0m"

# Keep script running
trap 'echo -e "\n\033[1;31mStopping services...\033[0m"; pkill -f mysqld; pkill -f httpd; exit 0' INT
while true; do
    sleep 1
done
EOF

    # Script untuk stop service
    cat > "$LOCALHOST_DIR/scripts/stop-localhost.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

echo -e "\033[1;31m============================================\033[0m"
echo -e "\033[1;31m    Stopping Termux Localhost Services    \033[0m"
echo -e "\033[1;31m============================================\033[0m"

echo -e "\033[1;34m[INFO]\033[0m Stopping Apache..."
pkill -f httpd
echo -e "\033[1;32m[SUCCESS]\033[0m Apache stopped ✓"

echo -e "\033[1;34m[INFO]\033[0m Stopping MySQL..."
pkill -f mysqld
echo -e "\033[1;32m[SUCCESS]\033[0m MySQL stopped ✓"

echo ""
echo -e "\033[1;32mSemua services berhasil dihentikan!\033[0m"
EOF

    # Script untuk restart
    cat > "$LOCALHOST_DIR/scripts/restart-localhost.sh" << EOF
#!/data/data/com.termux/files/usr/bin/bash

$LOCALHOST_DIR/scripts/stop-localhost.sh
sleep 2
$LOCALHOST_DIR/scripts/start-localhost.sh
EOF

    # Buat executable
    chmod +x "$LOCALHOST_DIR/scripts/"*.sh
    
    # Buat symlink ke /usr/bin untuk akses global
    ln -sf "$LOCALHOST_DIR/scripts/start-localhost.sh" "/data/data/com.termux/files/usr/bin/start-localhost"
    ln -sf "$LOCALHOST_DIR/scripts/stop-localhost.sh" "/data/data/com.termux/files/usr/bin/stop-localhost"
    ln -sf "$LOCALHOST_DIR/scripts/restart-localhost.sh" "/data/data/com.termux/files/usr/bin/restart-localhost"
    
    print_success "Script startup berhasil dibuat"
}

# Function untuk membuat README
create_readme() {
    print_step "Membuat dokumentasi..."
    
    cat > "$LOCALHOST_DIR/README.md" << 'EOF'
# 🚀 Termux Localhost Server

Server localhost lengkap untuk Termux dengan Apache, PHP, MySQL, dan phpMyAdmin.
Semua data disimpan di **sdcard** untuk kemudahan editing dan backup.

## 📁 Struktur Direktori

```
/sdcard/termux-localhost/
├── www/                    # Web root directory
│   ├── index.php          # Homepage
│   ├── info.php           # PHP info
│   └── phpmyadmin/        # phpMyAdmin
├── config/                # File konfigurasi
│   ├── httpd.conf         # Apache config
│   ├── php.ini            # PHP config
│   └── my.cnf             # MySQL config
├── logs/                  # Log files
│   ├── apache_access.log
│   ├── apache_error.log
│   ├── php_error.log
│   └── mysql_error.log
├── data/                  # Data directory
│   ├── mysql/             # MySQL database
│   ├── sessions/          # PHP sessions
│   └── tmp/               # Temporary files
├── scripts/               # Script utilities
│   ├── start-localhost.sh
│   ├── stop-localhost.sh
│   └── restart-localhost.sh
└── backup/                # Backup directory
```

## 🚀 Cara Menggunakan

### Memulai Server
```bash
start-localhost
```

### Menghentikan Server
```bash
stop-localhost
```

### Restart Server
```bash
restart-localhost
```

## 🌐 URL Akses

- **Homepage:** http://localhost:8080
- **phpMyAdmin:** http://localhost:8080/phpmyadmin
- **PHP Info:** http://localhost:8080/info.php
- **Server Status:** http://localhost:8080/server-status

## ⚙️ Konfigurasi

### Apache
- **Config:** `/sdcard/termux-localhost/config/httpd.conf`
- **Port:** 8080
- **Document Root:** `/sdcard/termux-localhost/www`

### PHP
- **Config:** `/sdcard/termux-localhost/config/php.ini`
- **Memory Limit:** 512M
- **Upload Max:** 100M
- **Timezone:** Asia/Jakarta

### MySQL
- **Config:** `/sdcard/termux-localhost/config/my.cnf`
- **Data Directory:** `/sdcard/termux-localhost/data/mysql`
- **Socket:** `/data/data/com.termux/files/usr/tmp/mysql.sock`

## 📝 Tips Editing

Karena semua file disimpan di sdcard, Anda bisa edit menggunakan:

1. **Text editor di Termux:**
   ```bash
   nano /sdcard/termux-localhost/config/httpd.conf
   ```

2. **File manager Android** dengan text editor
3. **Editor eksternal** seperti VS Code melalui file sharing

## 🔧 Troubleshooting

### Port sudah digunakan
```bash
# Cek proses yang menggunakan port 8080
lsof -i :8080

# Stop proses jika perlu
pkill -f httpd
```

### MySQL tidak bisa start
```bash
# Cek log error
cat /sdcard/termux-localhost/logs/mysql_error.log

# Reset permission
chmod -R 755 /sdcard/termux-localhost/data/mysql
```

### Apache tidak bisa akses file
```bash
# Set permission yang benar
chmod -R 755 /sdcard/termux-localhost/www
```

## 📦 Backup & Restore

### Backup
```bash
cd /sdcard
tar -czf termux-localhost-backup-$(date +%Y%m%d).tar.gz termux-localhost/
```

### Restore
```bash
cd /sdcard
tar -xzf termux-localhost-backup-YYYYMMDD.tar.gz
```

## 🆘 Support

Jika ada masalah:
1. Cek log files di `/sdcard/termux-localhost/logs/`
2. Restart services: `restart-localhost`
3. Reinstall jika diperlukan

---
**Happy Coding! 🚀**
EOF

    print_success "Dokumentasi berhasil dibuat"
}

# Function untuk create desktop shortcut (optional)
create_shortcuts() {
    print_step "Membuat shortcut..."
    
    # Create .termux directory if not exists
    mkdir -p "/data/data/com.termux/files/home/.termux/tasker"
    
    # Create start script for Termux:Tasker
    cat > "/data/data/com.termux/files/home/.termux/tasker/start_localhost.sh" << EOF
#!/data/data/com.termux/files/usr/bin/bash
cd /data/data/com.termux/files/home
start-localhost
EOF
    
    chmod +x "/data/data/com.termux/files/home/.termux/tasker/start_localhost.sh"
    
    print_success "Shortcut berhasil dibuat"
}

# Function untuk final setup
final_setup() {
    print_step "Menyelesaikan setup..."
    
    # Copy config files to termux default locations
    cp "$CONFIG_DIR/httpd.conf" "/data/data/com.termux/files/usr/etc/apache2/httpd.conf"
    cp "$CONFIG_DIR/php.ini" "/data/data/com.termux/files/usr/etc/php/php.ini"
    
    # Set proper permissions
    chmod -R 755 "$WEB_DIR"
    chmod -R 755 "$CONFIG_DIR"
    chmod -R 755 "$LOG_DIR"
    chmod -R 700 "$DATA_DIR/mysql"
    
    print_success "Setup selesai!"
}

# Function untuk test installation
test_installation() {
    print_step "Testing installation..."
    
    # Test PHP
    php -v > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_success "PHP: ✓"
    else
        print_error "PHP: ✗"
    fi
    
    # Test Apache
    httpd -v > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_success "Apache: ✓"
    else
        print_error "Apache: ✗"
    fi
    
    # Test MySQL
    mysql --version > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_success "MySQL: ✓"
    else
        print_error "MySQL: ✗"
    fi
    
    # Test phpMyAdmin
    if [ -f "$WEB_DIR/phpmyadmin/index.php" ]; then
        print_success "phpMyAdmin: ✓"
    else
        print_error "phpMyAdmin: ✗"
    fi
    
    print_success "Testing selesai"
}

# Main installation function
main() {
    clear
    print_header "TERMUX LOCALHOST AUTO INSTALLER"
    echo -e "${CYAN}Data akan disimpan di: /sdcard/termux-localhost${NC}"
    echo -e "${YELLOW}Pastikan Termux memiliki akses storage!${NC}"
    echo ""
    
    read -p "Lanjutkan instalasi? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Instalasi dibatalkan"
        exit 1
    fi
    
    # Setup storage permission
    print_step "Setup storage permission..."
    termux-setup-storage
    sleep 2
    
    # Run installation steps
    check_storage_permission
    backup_old_config
    create_directory_structure
    install_packages
    create_apache_config
    create_php_config
    setup_mysql
    setup_phpmyadmin
    create_homepage
    create_startup_scripts
    create_shortcuts
    create_readme
    final_setup
    test_installation
    
    # Final message
    print_header "INSTALASI SELESAI!"
    echo -e "${GREEN}🎉 Localhost server berhasil diinstall!${NC}"
    echo ""
    echo -e "${CYAN}📍 Lokasi files: /sdcard/termux-localhost${NC}"
    echo -e "${CYAN}🌐 Akses web: http://localhost:8080${NC}"
    echo -e "${CYAN}📊 phpMyAdmin: http://localhost:8080/phpmyadmin${NC}"
    echo ""
    echo -e "${YELLOW}Cara menggunakan:${NC}"
    echo -e "  ${GREEN}start-localhost${NC}     - Start server"
    echo -e "  ${GREEN}stop-localhost${NC}      - Stop server" 
    echo -e "  ${GREEN}restart-localhost${NC}   - Restart server"
    echo ""
    echo -e "${PURPLE}Selamat menggunakan! 🚀${NC}"
    echo ""
    
    read -p "Mau langsung start server sekarang? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        print_info "Starting localhost server..."
        start-localhost
    fi
}

# Run main function
main
