#!/data/data/com.termux/files/usr/bin/bash

# ================================================
# Termux Localhost Management Script
# Mengelola server localhost dengan mudah
# ================================================

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Direktori
LOCALHOST_DIR="/sdcard/termux-localhost"
WEB_DIR="$LOCALHOST_DIR/www"
CONFIG_DIR="$LOCALHOST_DIR/config"
LOG_DIR="$LOCALHOST_DIR/logs"
DATA_DIR="$LOCALHOST_DIR/data"

# Functions
print_header() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║           LOCALHOST MANAGEMENT TOOL          ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════╝${NC}"
    echo ""
}

print_menu() {
    echo -e "${CYAN}📋 MENU UTAMA:${NC}"
    echo -e "  ${GREEN}1.${NC} 🚀 Start Server"
    echo -e "  ${GREEN}2.${NC} 🛑 Stop Server" 
    echo -e "  ${GREEN}3.${NC} 🔄 Restart Server"
    echo -e "  ${GREEN}4.${NC} 📊 Status Server"
    echo -e "  ${GREEN}5.${NC} 📝 Edit Konfigurasi"
    echo -e "  ${GREEN}6.${NC} 📁 File Management"
    echo -e "  ${GREEN}7.${NC} 🗄️  Database Management"
    echo -e "  ${GREEN}8.${NC} 📋 Lihat Logs"
    echo -e "  ${GREEN}9.${NC} 💾 Backup & Restore"
    echo -e "  ${GREEN}10.${NC} 🔧 Tools & Utilities"
    echo -e "  ${GREEN}11.${NC} ❓ Help & Info"
    echo -e "  ${RED}0.${NC} ❌ Exit"
    echo ""
}

check_server_status() {
    apache_status="❌ Stopped"
    mysql_status="❌ Stopped"
    
    if pgrep -f "httpd" > /dev/null; then
        apache_status="✅ Running"
    fi
    
    if pgrep -f "mysqld" > /dev/null; then
        mysql_status="✅ Running"
    fi
    
    echo -e "${BLUE}📊 SERVER STATUS:${NC}"
    echo -e "  Apache: $apache_status"
    echo -e "  MySQL:  $mysql_status"
    echo ""
}

start_server() {
    echo -e "${GREEN}🚀 Starting Localhost Server...${NC}"
    echo ""
    
    # Start MySQL
    if ! pgrep -f "mysqld" > /dev/null; then
        echo -e "${BLUE}Starting MySQL...${NC}"
        mysqld_safe --defaults-file="$CONFIG_DIR/my.cnf" > /dev/null 2>&1 &
        sleep 3
        if pgrep -f "mysqld" > /dev/null; then
            echo -e "${GREEN}✅ MySQL started successfully${NC}"
        else
            echo -e "${RED}❌ Failed to start MySQL${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  MySQL already running${NC}"
    fi
    
    # Start Apache
    if ! pgrep -f "httpd" > /dev/null; then
        echo -e "${BLUE}Starting Apache...${NC}"
        httpd -f "$CONFIG_DIR/httpd.conf" > /dev/null 2>&1 &
        sleep 2
        if pgrep -f "httpd" > /dev/null; then
            echo -e "${GREEN}✅ Apache started successfully${NC}"
        else
            echo -e "${RED}❌ Failed to start Apache${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Apache already running${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}🌐 Access URLs:${NC}"
    echo -e "  Homepage:   http://localhost:8080"
    echo -e "  phpMyAdmin: http://localhost:8080/phpmyadmin"
    echo ""
}

stop_server() {
    echo -e "${RED}🛑 Stopping Localhost Server...${NC}"
    echo ""
    
    # Stop Apache
    if pgrep -f "httpd" > /dev/null; then
        echo -e "${BLUE}Stopping Apache...${NC}"
        pkill -f httpd
        echo -e "${GREEN}✅ Apache stopped${NC}"
    else
        echo -e "${YELLOW}⚠️  Apache not running${NC}"
    fi
    
    # Stop MySQL
    if pgrep -f "mysqld" > /dev/null; then
        echo -e "${BLUE}Stopping MySQL...${NC}"
        pkill -f mysqld
        sleep 2
        echo -e "${GREEN}✅ MySQL stopped${NC}"
    else
        echo -e "${YELLOW}⚠️  MySQL not running${NC}"
    fi
    
    echo -e "${GREEN}🎯 All services stopped${NC}"
    echo ""
}

restart_server() {
    echo -e "${YELLOW}🔄 Restarting Localhost Server...${NC}"
    echo ""
    stop_server
    sleep 2
    start_server
}

show_logs() {
    echo -e "${CYAN}📋 LOG VIEWER${NC}"
    echo -e "  ${GREEN}1.${NC} Apache Access Log"
    echo -e "  ${GREEN}2.${NC} Apache Error Log"
    echo -e "  ${GREEN}3.${NC} PHP Error Log"
    echo -e "  ${GREEN}4.${NC} MySQL Error Log"
    echo -e "  ${RED}0.${NC} Back to Main Menu"
    echo ""
    
    read -p "Pilih log (0-4): " log_choice
    
    case $log_choice in
        1)
            echo -e "${BLUE}📄 Apache Access Log (Press Ctrl+C to exit):${NC}"
            tail -f "$LOG_DIR/apache_access.log" 2>/dev/null || echo "Log file not found"
            ;;
        2)
            echo -e "${BLUE}📄 Apache Error Log (Press Ctrl+C to exit):${NC}"
            tail -f "$LOG_DIR/apache_error.log" 2>/dev/null || echo "Log file not found"
            ;;
        3)
            echo -e "${BLUE}📄 PHP Error Log (Press Ctrl+C to exit):${NC}"
            tail -f "$LOG_DIR/php_error.log" 2>/dev/null || echo "Log file not found"
            ;;
        4)
            echo -e "${BLUE}📄 MySQL Error Log (Press Ctrl+C to exit):${NC}"
            tail -f "$LOG_DIR/mysql_error.log" 2>/dev/null || echo "Log file not found"
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
}

edit_config() {
    echo -e "${CYAN}⚙️ CONFIGURATION EDITOR${NC}"
    echo -e "  ${GREEN}1.${NC} Edit Apache Config (httpd.conf)"
    echo -e "  ${GREEN}2.${NC} Edit PHP Config (php.ini)"
    echo -e "  ${GREEN}3.${NC} Edit MySQL Config (my.cnf)"
    echo -e "  ${GREEN}4.${NC} Edit Homepage (index.php)"
    echo -e "  ${RED}0.${NC} Back to Main Menu"
    echo ""
    
    read -p "Pilih konfigurasi (0-4): " config_choice
    
    case $config_choice in
        1)
            nano "$CONFIG_DIR/httpd.conf"
            echo -e "${YELLOW}Restart server untuk apply changes${NC}"
            ;;
        2)
            nano "$CONFIG_DIR/php.ini"
            echo -e "${YELLOW}Restart server untuk apply changes${NC}"
            ;;
        3)
            nano "$CONFIG_DIR/my.cnf"
            echo -e "${YELLOW}Restart server untuk apply changes${NC}"
            ;;
        4)
            nano "$WEB_DIR/index.php"
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
}

file_management() {
    echo -e "${CYAN}📁 FILE MANAGEMENT${NC}"
    echo -e "  ${GREEN}1.${NC} Browse Web Directory"
    echo -e "  ${GREEN}2.${NC} Create New PHP File"
    echo -e "  ${GREEN}3.${NC} Create New HTML File"
    echo -e "  ${GREEN}4.${NC} Delete File"
    echo -e "  ${GREEN}5.${NC} Change Permissions"
    echo -e "  ${RED}0.${NC} Back to Main Menu"
    echo ""
    
    read -p "Pilih aksi (0-5): " file_choice
    
    case $file_choice in
        1)
            echo -e "${BLUE}📂 Web Directory Contents:${NC}"
            ls -la "$WEB_DIR"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        2)
            read -p "Enter filename (without .php): " filename
            if [ -n "$filename" ]; then
                cat > "$WEB_DIR/$filename.php" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>New PHP Page</title>
</head>
<body>
    <h1>Welcome to <?php echo $filename; ?></h1>
    <p>Current time: <?php echo date('Y-m-d H:i:s'); ?></p>
</body>
</html>
EOF
                echo -e "${GREEN}✅ File $filename.php created${NC}"
                echo -e "${CYAN}Access: http://localhost:8080/$filename.php${NC}"
            fi
            ;;
        3)
            read -p "Enter filename (without .html): " filename
            if [ -n "$filename" ]; then
                cat > "$WEB_DIR/$filename.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>$filename</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
    </style>
</head>
<body>
    <h1>Welcome to $filename</h1>
    <p>This is a new HTML page.</p>
</body>
</html>
EOF
                echo -e "${GREEN}✅ File $filename.html created${NC}"
                echo -e "${CYAN}Access: http://localhost:8080/$filename.html${NC}"
            fi
            ;;
        4)
            echo -e "${BLUE}Files in web directory:${NC}"
            ls -1 "$WEB_DIR"
            echo ""
            read -p "Enter filename to delete: " filename
            if [ -f "$WEB_DIR/$filename" ]; then
                read -p "Are you sure? (y/n): " confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    rm "$WEB_DIR/$filename"
                    echo -e "${GREEN}✅ File deleted${NC}"
                fi
            else
                echo -e "${RED}File not found${NC}"
            fi
            ;;
        5)
            chmod -R 755 "$WEB_DIR"
            echo -e "${GREEN}✅ Permissions fixed${NC}"
            ;;
        0)
            return
            ;;
    esac
}

database_management() {
    echo -e "${CYAN}🗄️ DATABASE MANAGEMENT${NC}"
    echo -e "  ${GREEN}1.${NC} Open phpMyAdmin (Browser)"
    echo -e "  ${GREEN}2.${NC} MySQL Command Line"
    echo -e "  ${GREEN}3.${NC} Create Database"
    echo -e "  ${GREEN}4.${NC} Backup Database"
    echo -e "  ${GREEN}5.${NC} Import Database"
    echo -e "  ${GREEN}6.${NC} Reset MySQL Root Password"
    echo -e "  ${RED}0.${NC} Back to Main Menu"
    echo ""
    
    read -p "Pilih aksi (0-6): " db_choice
    
    case $db_choice in
        1)
            echo -e "${BLUE}Opening phpMyAdmin...${NC}"
            echo -e "${CYAN}URL: http://localhost:8080/phpmyadmin${NC}"
            ;;
        2)
            echo -e "${BLUE}MySQL Command Line (type 'exit' to quit):${NC}"
            mysql -u root
            ;;
        3)
            read -p "Enter database name: " dbname
            if [ -n "$dbname" ]; then
                mysql -u root -e "CREATE DATABASE \`$dbname\`;"
                echo -e "${GREEN}✅ Database '$dbname' created${NC}"
            fi
            ;;
        4)
            read -p "Enter database name to backup: " dbname
            if [ -n "$dbname" ]; then
                backup_file="$LOCALHOST_DIR/backup/${dbname}_$(date +%Y%m%d_%H%M%S).sql"
                mysqldump -u root "$dbname" > "$backup_file"
                echo -e "${GREEN}✅ Database backed up to: $backup_file${NC}"
            fi
            ;;
        5)
            echo -e "${BLUE}SQL files in backup directory:${NC}"
            ls -1 "$LOCALHOST_DIR/backup/"*.sql 2>/dev/null || echo "No backup files found"
            echo ""
            read -p "Enter SQL file path to import: " sqlfile
            if [ -f "$sqlfile" ]; then
                mysql -u root < "$sqlfile"
                echo -e "${GREEN}✅ Database imported successfully${NC}"
            else
                echo -e "${RED}File not found${NC}"
            fi
            ;;
        6)
            echo -e "${YELLOW}Resetting MySQL root password...${NC}"
            mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '';"
            echo -e "${GREEN}✅ Root password reset (no password)${NC}"
            ;;
        0)
            return
            ;;
    esac
}

backup_restore() {
    echo -e "${CYAN}💾 BACKUP & RESTORE${NC}"
    echo -e "  ${GREEN}1.${NC} Full Backup (All Data)"
    echo -e "  ${GREEN}2.${NC} Web Files Backup"
    echo -e "  ${GREEN}3.${NC} Database Backup"
    echo -e "  ${GREEN}4.${NC} Config Backup"
    echo -e "  ${GREEN}5.${NC} Restore from Backup"
    echo -e "  ${GREEN}6.${NC} List Backups"
    echo -e "  ${GREEN}7.${NC} Clean Old Backups"
    echo -e "  ${RED}0.${NC} Back to Main Menu"
    echo ""
    
    read -p "Pilih aksi (0-7): " backup_choice
    
    case $backup_choice in
        1)
            backup_file="$LOCALHOST_DIR/backup/full_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
            echo -e "${BLUE}Creating full backup...${NC}"
            cd /sdcard
            tar -czf "$backup_file" termux-localhost/
            echo -e "${GREEN}✅ Full backup created: $backup_file${NC}"
            ;;
        2)
            backup_file="$LOCALHOST_DIR/backup/web_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
            echo -e "${BLUE}Creating web files backup...${NC}"
            tar -czf "$backup_file" -C "$LOCALHOST_DIR" www/
            echo -e "${GREEN}✅ Web backup created: $backup_file${NC}"
            ;;
        3)
            backup_file="$LOCALHOST_DIR/backup/db_backup_$(date +%Y%m%d_%H%M%S).sql"
            echo -e "${BLUE}Creating database backup...${NC}"
            mysqldump -u root --all-databases > "$backup_file"
            echo -e "${GREEN}✅ Database backup created: $backup_file${NC}"
            ;;
        4)
            backup_file="$LOCALHOST_DIR/backup/config_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
            echo -e "${BLUE}Creating config backup...${NC}"
            tar -czf "$backup_file" -C "$LOCALHOST_DIR" config/
            echo -e "${GREEN}✅ Config backup created: $backup_file${NC}"
            ;;
        5)
            echo -e "${BLUE}Available backups:${NC}"
            ls -1 "$LOCALHOST_DIR/backup/" 2>/dev/null || echo "No backups found"
            echo ""
            read -p "Enter backup filename to restore: " backup_file
            if [ -f "$LOCALHOST_DIR/backup/$backup_file" ]; then
                echo -e "${YELLOW}⚠️  This will overwrite current data!${NC}"
                read -p "Continue? (y/n): " confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    stop_server
                    if [[ "$backup_file" == *".tar.gz" ]]; then
                        cd /sdcard
                        tar -xzf "$LOCALHOST_DIR/backup/$backup_file"
                    elif [[ "$backup_file" == *".sql" ]]; then
                        mysql -u root < "$LOCALHOST_DIR/backup/$backup_file"
                    fi
                    echo -e "${GREEN}✅ Restore completed${NC}"
                fi
            else
                echo -e "${RED}Backup file not found${NC}"
            fi
            ;;
        6)
            echo -e "${BLUE}📋 Available Backups:${NC}"
            ls -lah "$LOCALHOST_DIR/backup/" 2>/dev/null || echo "No backups found"
            ;;
        7)
            echo -e "${YELLOW}Cleaning backups older than 30 days...${NC}"
            find "$LOCALHOST_DIR/backup/" -type f -mtime +30 -delete 2>/dev/null
            echo -e "${GREEN}✅ Old backups cleaned${NC}"
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

tools_utilities() {
    echo -e "${CYAN}🔧 TOOLS & UTILITIES${NC}"
    echo -e "  ${GREEN}1.${NC} Check System Info"
    echo -e "  ${GREEN}2.${NC} Port Scanner"
    echo -e "  ${GREEN}3.${NC} Fix Permissions"
    echo -e "  ${GREEN}4.${NC} Clean Logs"
    echo -e "  ${GREEN}5.${NC} Update Components"
    echo -e "  ${GREEN}6.${NC} Generate SSL Certificate"
    echo -e "  ${GREEN}7.${NC} Network Info"
    echo -e "  ${RED}0.${NC} Back to Main Menu"
    echo ""
    
    read -p "Pilih tool (0-7): " tool_choice
    
    case $tool_choice in
        1)
            echo -e "${BLUE}📊 SYSTEM INFORMATION:${NC}"
            echo -e "  Termux Version: $(pkg show termux-tools | grep Version | cut -d: -f2)"
            echo -e "  PHP Version: $(php -v | head -n1)"
            echo -e "  Apache Version: $(httpd -v | head -n1)"
            echo -e "  MySQL Version: $(mysql --version)"
            echo -e "  Storage Usage:"
            df -h /sdcard | tail -n1
            echo -e "  Memory Usage:"
            free -h
            ;;
        2)
            echo -e "${BLUE}🔍 Scanning common ports...${NC}"
            for port in 8080 3306 80 443 22; do
                if netstat -tuln | grep ":$port " > /dev/null; then
                    echo -e "  Port $port: ${GREEN}✅ Open${NC}"
                else
                    echo -e "  Port $port: ${RED}❌ Closed${NC}"
                fi
            done
            ;;
        3)
            echo -e "${BLUE}🔧 Fixing permissions...${NC}"
            chmod -R 755 "$WEB_DIR"
            chmod -R 755 "$CONFIG_DIR"
            chmod -R 755 "$LOG_DIR"
            chmod -R 700 "$DATA_DIR/mysql"
            echo -e "${GREEN}✅ Permissions fixed${NC}"
            ;;
        4)
            echo -e "${BLUE}🧹 Cleaning logs...${NC}"
            > "$LOG_DIR/apache_access.log"
            > "$LOG_DIR/apache_error.log"
            > "$LOG_DIR/php_error.log"
            > "$LOG_DIR/mysql_error.log"
            echo -e "${GREEN}✅ Logs cleaned${NC}"
            ;;
        5)
            echo -e "${BLUE}📦 Updating components...${NC}"
            pkg update -y
            pkg upgrade apache2 php mariadb -y
            echo -e "${GREEN}✅ Components updated${NC}"
            ;;
        6)
            echo -e "${BLUE}🔐 Generating SSL certificate...${NC}"
            if command -v openssl >/dev/null; then
                cd "$CONFIG_DIR"
                openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                    -keyout localhost.key -out localhost.crt \
                    -subj "/C=ID/ST=Indonesia/L=Jakarta/O=Localhost/CN=localhost"
                echo -e "${GREEN}✅ SSL certificate generated${NC}"
                echo -e "${CYAN}Files: $CONFIG_DIR/localhost.key & localhost.crt${NC}"
            else
                echo -e "${RED}OpenSSL not installed. Run: pkg install openssl${NC}"
            fi
            ;;
        7)
            echo -e "${BLUE}🌐 NETWORK INFORMATION:${NC}"
            echo -e "  Internal IP: $(ip route get 1.1.1.1 | awk '{print $7}' | head -n1)"
            echo -e "  Network interfaces:"
            ip addr show | grep 'inet ' | awk '{print "    " $2 " (" $7 ")"}'
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

help_info() {
    echo -e "${CYAN}❓ HELP & INFORMATION${NC}"
    echo -e "  ${GREEN}1.${NC} Quick Start Guide"
    echo -e "  ${GREEN}2.${NC} Common Commands"
    echo -e "  ${GREEN}3.${NC} File Locations"
    echo -e "  ${GREEN}4.${NC} Troubleshooting"
    echo -e "  ${GREEN}5.${NC} About"
    echo -e "  ${RED}0.${NC} Back to Main Menu"
    echo ""
    
    read -p "Pilih info (0-5): " help_choice
    
    case $help_choice in
        1)
            echo -e "${BLUE}🚀 QUICK START GUIDE:${NC}"
            echo -e "1. Start server: Choose option 1"
            echo -e "2. Open browser: http://localhost:8080"
            echo -e "3. Access phpMyAdmin: http://localhost:8080/phpmyadmin"
            echo -e "4. Edit files: Use option 6 or edit directly in /sdcard/termux-localhost/www/"
            echo -e "5. View logs: Use option 8 to monitor server activity"
            ;;
        2)
            echo -e "${BLUE}📝 COMMON COMMANDS:${NC}"
            echo -e "  start-localhost     - Start server"
            echo -e "  stop-localhost      - Stop server"
            echo -e "  restart-localhost   - Restart server"
            echo -e "  localhost-manager   - Open this tool"
            echo -e "  nano /sdcard/termux-localhost/www/index.php - Edit homepage"
            ;;
        3)
            echo -e "${BLUE}📁 FILE LOCATIONS:${NC}"
            echo -e "  Web files:    /sdcard/termux-localhost/www/"
            echo -e "  Configs:      /sdcard/termux-localhost/config/"
            echo -e "  Logs:         /sdcard/termux-localhost/logs/"
            echo -e "  Database:     /sdcard/termux-localhost/data/mysql/"
            echo -e "  Backups:      /sdcard/termux-localhost/backup/"
            ;;
        4)
            echo -e "${BLUE}🔧 TROUBLESHOOTING:${NC}"
            echo -e "• Server won't start: Check if port 8080 is free"
            echo -e "• Database error: Try option 7 → 6 to reset password"
            echo -e "• Permission error: Use option 10 → 3 to fix permissions"
            echo -e "• Can't edit files: Make sure storage permission is granted"
            echo -e "• Check logs: Use option 8 to see error messages"
            ;;
        5)
            echo -e "${PURPLE}🎯 TERMUX LOCALHOST TOOLS${NC}"
            echo -e "Version: 1.0"
            echo -e "Author: Termux Community"
            echo -e "Description: Complete localhost solution for Termux"
            echo -e "Components: Apache + PHP + MySQL + phpMyAdmin"
            echo -e "Storage: All data saved to /sdcard/ for easy access"
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# Main menu loop
main_menu() {
    while true; do
        print_header
        check_server_status
        print_menu
        
        read -p "Pilih menu (0-11): " choice
        echo ""
        
        case $choice in
            1) start_server ;;
            2) stop_server ;;
            3) restart_server ;;
            4) 
                check_server_status
                read -p "Press Enter to continue..."
                ;;
            5) edit_config ;;
            6) file_management ;;
            7) database_management ;;
            8) show_logs ;;
            9) backup_restore ;;
            10) tools_utilities ;;
            11) help_info ;;
            0) 
                echo -e "${GREEN}👋 Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid choice. Please try again.${NC}"
                sleep 2
                ;;
        esac
        
        if [ "$choice" != "0" ] && [ "$choice" != "8" ]; then
            echo ""
            read -p "Press Enter to continue..."
        fi
    done
}

# Check if localhost directory exists
if [ ! -d "$LOCALHOST_DIR" ]; then
    echo -e "${RED}❌ Termux localhost not installed!${NC}"
    echo -e "${YELLOW}Please run the installer first.${NC}"
    exit 1
fi

# Start main menu
main_menu
