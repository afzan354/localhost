#!/data/data/com.termux/files/usr/bin/bash

# Script untuk memperbaiki permission issue

echo "🔧 Memperbaiki permission scripts..."

# Set permission untuk semua scripts
chmod +x /sdcard/termux-localhost/scripts/*.sh

# Hapus symlink yang rusak
rm -f /data/data/com.termux/files/usr/bin/start-localhost
rm -f /data/data/com.termux/files/usr/bin/stop-localhost
rm -f /data/data/com.termux/files/usr/bin/restart-localhost

# Buat script baru langsung di /usr/bin
cat > /data/data/com.termux/files/usr/bin/start-localhost << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

LOCALHOST_DIR="/sdcard/termux-localhost"
CONFIG_DIR="$LOCALHOST_DIR/config"
LOG_DIR="$LOCALHOST_DIR/logs"

echo -e "\033[1;32m============================================\033[0m"
echo -e "\033[1;32m    Starting Termux Localhost Services    \033[0m"
echo -e "\033[1;32m============================================\033[0m"

# Check if services already running
if pgrep -f "mysqld" > /dev/null; then
    echo -e "\033[1;33m[WARNING]\033[0m MySQL sudah berjalan"
else
    echo -e "\033[1;34m[INFO]\033[0m Starting MySQL..."
    mysqld_safe --defaults-file="$CONFIG_DIR/my.cnf" > /dev/null 2>&1 &
    sleep 3
    if pgrep -f "mysqld" > /dev/null; then
        echo -e "\033[1;32m[SUCCESS]\033[0m MySQL started ✓"
    else
        echo -e "\033[1;31m[ERROR]\033[0m MySQL failed to start"
        echo "Check log: cat $LOG_DIR/mysql_error.log"
    fi
fi

if pgrep -f "httpd" > /dev/null; then
    echo -e "\033[1;33m[WARNING]\033[0m Apache sudah berjalan"
else
    echo -e "\033[1;34m[INFO]\033[0m Starting Apache..."
    httpd -f "$CONFIG_DIR/httpd.conf" > /dev/null 2>&1 &
    sleep 2
    if pgrep -f "httpd" > /dev/null; then
        echo -e "\033[1;32m[SUCCESS]\033[0m Apache started ✓"
    else
        echo -e "\033[1;31m[ERROR]\033[0m Apache failed to start"
        echo "Check log: cat $LOG_DIR/apache_error.log"
    fi
fi

echo ""
echo -e "\033[1;36m🌐 Web Server: http://localhost:8080\033[0m"
echo -e "\033[1;36m📊 phpMyAdmin: http://localhost:8080/phpmyadmin\033[0m"
echo -e "\033[1;36m📁 Root Directory: $LOCALHOST_DIR/www\033[0m"
echo -e "\033[1;36m📋 Config Directory: $CONFIG_DIR\033[0m"
echo ""
echo -e "\033[1;35mPress Ctrl+C to stop services (atau jalankan 'stop-localhost' di terminal lain)\033[0m"

# Keep script running
trap 'echo -e "\n\033[1;31mStopping services...\033[0m"; pkill -f mysqld; pkill -f httpd; exit 0' INT
while true; do
    sleep 1
done
EOF

cat > /data/data/com.termux/files/usr/bin/stop-localhost << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

echo -e "\033[1;31m============================================\033[0m"
echo -e "\033[1;31m    Stopping Termux Localhost Services    \033[0m"
echo -e "\033[1;31m============================================\033[0m"

echo -e "\033[1;34m[INFO]\033[0m Stopping Apache..."
pkill -f httpd
if ! pgrep -f "httpd" > /dev/null; then
    echo -e "\033[1;32m[SUCCESS]\033[0m Apache stopped ✓"
else
    echo -e "\033[1;31m[ERROR]\033[0m Apache still running"
fi

echo -e "\033[1;34m[INFO]\033[0m Stopping MySQL..."
pkill -f mysqld
sleep 2
if ! pgrep -f "mysqld" > /dev/null; then
    echo -e "\033[1;32m[SUCCESS]\033[0m MySQL stopped ✓"
else
    echo -e "\033[1;31m[ERROR]\033[0m MySQL still running"
fi

echo ""
echo -e "\033[1;32mSemua services berhasil dihentikan!\033[0m"
EOF

cat > /data/data/com.termux/files/usr/bin/restart-localhost << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

echo -e "\033[1;33m🔄 Restarting Localhost Server...\033[0m"
echo ""

stop-localhost
sleep 2
start-localhost
EOF

# Set permission untuk scripts baru
chmod +x /data/data/com.termux/files/usr/bin/start-localhost
chmod +x /data/data/com.termux/files/usr/bin/stop-localhost
chmod +x /data/data/com.termux/files/usr/bin/restart-localhost

echo "✅ Permission fixed!"
echo ""
echo "Coba jalankan sekarang:"
echo "start-localhost"
