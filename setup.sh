#!/bin/sh
# OpenWrt Captive Portal Auto Setup (WAN-DHCP Mode)
# Author: CyberSH

echo -e "\n\033[1;36m=== CyberSH Captive Portal Pro Installer ===\033[0m"

# 1. CLEANUP OLD INSTALLATION
echo "[*] Removing old configuration..."
rm -rf /www/cgi-bin/auth /www/cgi-bin/admin_api /www/cgi-bin/wifi_* 2>/dev/null
rm -rf /www/admin /www/index.html /tmp/active_users.txt /etc/vouchers.txt 2>/dev/null
sed -i '/session_manager.sh/d' /etc/crontabs/root 2>/dev/null
sed -i '/CAPTIVE_PORTAL/d' /etc/firewall.user 2>/dev/null

# 2. NETWORK & WIFI SETUP (WAN DHCP & Open WiFi AP)
echo "[*] Configuring Network & WiFi..."
uci -q delete wireless.repeater
# Delete all existing WiFi interfaces and create a fresh Access Point
while uci -q delete wireless.@wifi-iface[0]; do :; done

uci set wireless.radio0.disabled='0'
uci add wireless wifi-iface
uci set wireless.@wifi-iface[-1].device='radio0'
uci set wireless.@wifi-iface[-1].network='lan'
uci set wireless.@wifi-iface[-1].mode='ap'
uci set wireless.@wifi-iface[-1].ssid='『TASRIF』ᴮᴬᴰʙᴏʏ'
# Captive Portals require OPEN encryption to auto-prompt devices
uci set wireless.@wifi-iface[-1].encryption='none' 

uci commit wireless
wifi reload

# 3. CREATE DIRECTORIES & FILES
echo "[*] Creating System Files..."
mkdir -p /www/cgi-bin /www/admin
touch /etc/vouchers.txt /tmp/active_users.txt
echo "123456|60" > /etc/vouchers.txt # Default test voucher

# 4. USER PORTAL UI (index.html)
echo "[*] Generating User UI..."
cat << 'EOF' > /www/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CyberSH WiFi Zone</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #1e3c72, #2a5298); display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; color: #333; }
        .box { background: rgba(255, 255, 255, 0.95); padding: 40px 30px; border-radius: 15px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); text-align: center; width: 90%; max-width: 350px; }
        h2 { margin-top: 0; color: #1e3c72; }
        input { width: 100%; padding: 12px; margin: 20px 0; border: 2px solid #ddd; border-radius: 8px; box-sizing: border-box; font-size: 16px; text-align: center; font-weight: bold; }
        input:focus { outline: none; border-color: #2a5298; }
        button { width: 100%; padding: 12px; background: #28a745; color: white; border: none; border-radius: 8px; font-size: 16px; font-weight: bold; cursor: pointer; transition: 0.3s; }
        button:hover { background: #218838; }
        .footer { margin-top: 20px; font-size: 12px; color: #777; }
    </style>
</head>
<body>
    <div class="box">
        <h2>📶 WiFi Login</h2>
        <p>Enter your voucher to connect</p>
        <input type="text" id="voucher" placeholder="Enter Voucher Code" required>
        <button onclick="login()">Connect to Internet</button>
        <p id="msg" style="margin-top:15px; font-weight:bold;"></p>
        <div class="footer">Powered by CyberSH</div>
    </div>
    <script>
        function login() {
            let code = document.getElementById('voucher').value;
            let btn = document.querySelector('button');
            btn.innerText = "Connecting...";
            fetch('/cgi-bin/auth', {
                method: 'POST',
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: 'voucher=' + encodeURIComponent(code)
            }).then(res => res.json()).then(data => {
                let msg = document.getElementById('msg');
                msg.style.color = (data.status === 'success') ? '#28a745' : '#dc3545';
                msg.innerText = data.message;
                btn.innerText = "Connect to Internet";
                if(data.status === 'success') setTimeout(() => window.location.href = 'http://neverssl.com', 2000);
            }).catch(() => {
                document.getElementById('msg').innerText = "Network Error";
                btn.innerText = "Connect to Internet";
            });
        }
    </script>
</body>
</html>
EOF

# 5. PROFESSIONAL ADMIN PANEL UI
echo "[*] Generating Pro Admin Dashboard..."
cat << 'EOF' > /www/admin/index.html
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CyberSH Admin Pro</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, sans-serif; background: #121212; color: #e0e0e0; margin: 0; padding: 20px; }
        .container { max-width: 800px; margin: auto; }
        .header { text-align: center; margin-bottom: 20px; border-bottom: 1px solid #333; padding-bottom: 10px; }
        .stats-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-bottom: 20px; }
        .stat-card { background: #1e1e1e; padding: 20px; border-radius: 10px; text-align: center; box-shadow: 0 4px 6px rgba(0,0,0,0.3); border: 1px solid #333; }
        .stat-card h3 { margin: 0; color: #888; font-size: 14px; text-transform: uppercase; }
        .stat-card h1 { margin: 10px 0 0; font-size: 36px; color: #4CAF50; }
        .nav { display: flex; gap: 10px; margin-bottom: 20px; }
        .nav button { flex: 1; padding: 12px; background: #2a2a2a; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: bold; transition: 0.2s; }
        .nav button.active, .nav button:hover { background: #4CAF50; }
        .tab { display: none; background: #1e1e1e; padding: 20px; border-radius: 10px; border: 1px solid #333; }
        .active-tab { display: block; }
        input, select, textarea { width: 100%; padding: 12px; margin: 10px 0; background: #2a2a2a; color: white; border: 1px solid #444; border-radius: 6px; box-sizing: border-box; }
        button.action-btn { background: #007bff; color: white; padding: 12px 20px; border: none; border-radius: 6px; cursor: pointer; font-weight: bold; width: 100%; }
        button.action-btn:hover { background: #0056b3; }
        textarea { height: 300px; font-family: monospace; }
        ul { list-style: none; padding: 0; margin: 0; }
        li { background: #2a2a2a; padding: 10px; margin-bottom: 8px; border-radius: 6px; display: flex; justify-content: space-between; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2>⚙️ CyberSH Network Admin</h2>
        </div>
        
        <div class="stats-grid">
            <div class="stat-card">
                <h3>Active Users</h3>
                <h1 id="stat-users">0</h1>
            </div>
            <div class="stat-card">
                <h3>Available Vouchers</h3>
                <h1 id="stat-vouchers" style="color: #03A9F4;">0</h1>
            </div>
        </div>

        <div class="nav">
            <button class="active" onclick="showTab('generator', this)">Vouchers</button>
            <button onclick="showTab('editor', this)">UI Editor</button>
        </div>

        <!-- Voucher Generator Tab -->
        <div id="generator" class="tab active-tab">
            <h3>🎟️ Generate New Voucher</h3>
            <select id="v-duration">
                <option value="60">1 Hour</option>
                <option value="180">3 Hours</option>
                <option value="1440">1 Day</option>
                <option value="10080">7 Days</option>
            </select>
            <button class="action-btn" onclick="generateVoucher()">Generate Code</button>
            <p id="gen-msg" style="text-align:center; color:#4CAF50; font-weight:bold; margin-top:15px;"></p>
            
            <h3 style="margin-top: 30px; border-bottom: 1px solid #333; padding-bottom:10px;">Unused Vouchers (Recent)</h3>
            <ul id="voucher-list">Loading...</ul>
        </div>

        <!-- UI Editor Tab -->
        <div id="editor" class="tab">
            <h3>💻 Live Portal Editor</h3>
            <textarea id="codeBox"></textarea>
            <button class="action-btn" onclick="saveUI()">Save Changes</button>
            <p id="saveMsg" style="text-align:center; color:#4CAF50; font-weight:bold;"></p>
        </div>
    </div>

    <script>
        function showTab(id, btn) {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active-tab'));
            document.querySelectorAll('.nav button').forEach(b => b.classList.remove('active'));
            document.getElementById(id).classList.add('active-tab');
            btn.classList.add('active');
        }

        // Fetch Stats Loop
        function loadStats() {
            fetch('/cgi-bin/admin_api?action=stats').then(res => res.json()).then(data => {
                document.getElementById('stat-users').innerText = data.active;
                document.getElementById('stat-vouchers').innerText = data.total_vouchers;
                
                let vHtml = '';
                data.voucher_list.forEach(v => {
                    let parts = v.split('|');
                    if(parts.length === 2) {
                        vHtml += `<li><strong>${parts[0]}</strong> <span>${Math.round(parts[1]/60)} Hrs</span></li>`;
                    }
                });
                document.getElementById('voucher-list').innerHTML = vHtml || "No vouchers available.";
            });
        }
        setInterval(loadStats, 5000);
        loadStats();

        // Generate Voucher
        function generateVoucher() {
            let duration = document.getElementById('v-duration').value;
            fetch('/cgi-bin/admin_api?action=generate&duration=' + duration)
            .then(res => res.json()).then(data => {
                document.getElementById('gen-msg').innerText = "Generated: " + data.code;
                loadStats();
            });
        }

        // Load & Save UI
        fetch('/cgi-bin/admin_api?action=get_ui').then(res => res.text()).then(txt => document.getElementById('codeBox').value = txt);
        
        function saveUI() {
            fetch('/cgi-bin/admin_api?action=save_ui', { method: 'POST', body: document.getElementById('codeBox').value })
            .then(res => res.json()).then(data => {
                if(data.status === 'success') document.getElementById('saveMsg').innerText = "UI Updated Successfully!";
                setTimeout(() => document.getElementById('saveMsg').innerText="", 3000);
            });
        }
    </script>
</body>
</html>
EOF

# 6. BACKEND APIs (CGI)
echo "[*] Creating Backend APIs..."

# 6.1 User Auth API
cat << 'EOF' > /www/cgi-bin/auth
#!/bin/sh
echo "Content-type: application/json"
echo ""
read POST_DATA
VOUCHER=$(echo $POST_DATA | awk -F'=' '{print $2}')
CLIENT_MAC=$(cat /proc/net/arp | grep "$REMOTE_ADDR " | awk '{print $4}')
VALID_VOUCHER=$(grep "^$VOUCHER|" /etc/vouchers.txt)
if [ -n "$VALID_VOUCHER" ]; then
    DURATION=$(echo $VALID_VOUCHER | cut -d'|' -f2)
    EXPIRY_TIME=$(($(date +%s) + $DURATION * 60))
    iptables -t nat -I CAPTIVE_PORTAL 1 -m mac --mac-source $CLIENT_MAC -j RETURN
    echo "$CLIENT_MAC|$EXPIRY_TIME" >> /tmp/active_users.txt
    sed -i "/^$VOUCHER|/d" /etc/vouchers.txt
    echo '{"status": "success", "message": "Internet Connected!"}'
else
    echo '{"status": "error", "message": "Invalid Voucher Code"}'
fi
EOF

# 6.2 Pro Admin API
cat << 'EOF' > /www/cgi-bin/admin_api
#!/bin/sh
echo "Content-type: application/json"
echo ""

if [ "$QUERY_STRING" = "action=get_ui" ]; then
    cat /www/index.html
    exit 0
elif [ "$QUERY_STRING" = "action=save_ui" ]; then
    dd ibs=1 count=$CONTENT_LENGTH 2>/dev/null > /www/index.html
    echo '{"status": "success"}'
    exit 0
elif echo "$QUERY_STRING" | grep -q "action=stats"; then
    ACTIVE=$(wc -l < /tmp/active_users.txt 2>/dev/null || echo "0")
    TOTAL_V=$(wc -l < /etc/vouchers.txt 2>/dev/null || echo "0")
    # Get last 5 vouchers to display
    V_LIST=$(tail -n 5 /etc/vouchers.txt 2>/dev/null | awk '{printf "\"%s\",", $0}' | sed 's/,$//')
    echo "{\"active\":\"$ACTIVE\", \"total_vouchers\":\"$TOTAL_V\", \"voucher_list\":[$V_LIST]}"
    exit 0
elif echo "$QUERY_STRING" | grep -q "action=generate"; then
    DURATION=$(echo "$QUERY_STRING" | awk -F'duration=' '{print $2}' | awk -F'&' '{print $1}')
    # Generate 6 digit random code
    NEW_CODE=$(awk -v min=100000 -v max=999999 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')
    echo "$NEW_CODE|$DURATION" >> /etc/vouchers.txt
    echo "{\"status\":\"success\", \"code\":\"$NEW_CODE\"}"
    exit 0
fi
EOF

chmod +x /www/cgi-bin/*

# 7. CRON & FIREWALL CONFIGURATION
echo "[*] Setting up Firewall & Session Manager..."
cat << 'EOF' > /usr/bin/session_manager.sh
#!/bin/sh
CURRENT_TIME=$(date +%s)
while IFS="|" read -r MAC EXPIRY; do
    if [ "$CURRENT_TIME" -ge "$EXPIRY" ]; then
        iptables -t nat -D CAPTIVE_PORTAL -m mac --mac-source $MAC -j RETURN 2>/dev/null
        sed -i "/^$MAC|/d" /tmp/active_users.txt
    fi
done < /tmp/active_users.txt
EOF
chmod +x /usr/bin/session_manager.sh

touch /etc/crontabs/root
if ! grep -q "session_manager.sh" /etc/crontabs/root; then
    echo "* * * * * /usr/bin/session_manager.sh" >> /etc/crontabs/root
fi

if ! grep -q "CAPTIVE_PORTAL" /etc/firewall.user; then
cat << 'EOF' >> /etc/firewall.user
iptables -t nat -N CAPTIVE_PORTAL 2>/dev/null
iptables -t nat -I PREROUTING -p tcp --dport 80 -j CAPTIVE_PORTAL
iptables -t nat -A CAPTIVE_PORTAL -p tcp -j DNAT --to-destination 192.168.1.1:80
EOF
fi

# 8. APPLY CHANGES
echo "[*] Restarting Network and Firewall Services..."
/etc/init.d/firewall restart >/dev/null 2>&1
/etc/init.d/cron restart >/dev/null 2>&1

echo -e "\n\033[1;32m[+] Pro Setup Complete!\033[0m"
echo -e "Access Admin Panel at: \033[1;33mhttp://192.168.1.1/admin\033[0m"
