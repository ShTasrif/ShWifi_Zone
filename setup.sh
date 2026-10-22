#!/bin/sh
# OpenWrt Complete Captive Portal & WISP Repeater Auto Installer
# Author: CyberSH

echo -e "\n\033[1;36m=== CyberSH Captive Portal & WISP Installer ===\033[0m"

# 1. Directories & Database তৈরি করা
echo "[*] Creating Directories & Database..."
mkdir -p /www/cgi-bin
mkdir -p /www/admin
touch /etc/vouchers.txt
touch /tmp/active_users.txt

# 2. User Login UI (index.html)
echo "[*] Generating User UI..."
cat << 'EOF' > /www/index.html
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CyberSH WiFi Hotspot</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f4f4f9; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .box { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 4px 10px rgba(0,0,0,0.1); text-align: center; width: 90%; max-width: 350px; }
        input { width: 100%; padding: 10px; margin: 15px 0; border: 1px solid #ccc; border-radius: 5px; box-sizing: border-box; }
        button { width: 100%; padding: 10px; background: #28a745; color: white; border: none; border-radius: 5px; font-size: 16px; cursor: pointer; }
    </style>
</head>
<body>
    <div class="box">
        <h2>WiFi Login</h2>
        <input type="text" id="voucher" placeholder="Voucher Code" required>
        <button onclick="login()">Connect Internet</button>
        <p id="msg" style="color:red; margin-top:10px;"></p>
    </div>
    <script>
        function login() {
            let code = document.getElementById('voucher').value;
            fetch('/cgi-bin/auth', {
                method: 'POST',
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: 'voucher=' + encodeURIComponent(code)
            }).then(res => res.json()).then(data => {
                document.getElementById('msg').style.color = (data.status === 'success') ? 'green' : 'red';
                document.getElementById('msg').innerText = data.message;
                if(data.status === 'success') setTimeout(() => window.location.href = 'http://neverssl.com', 2000);
            });
        }
    </script>
</body>
</html>
EOF

# 3. Admin Panel UI (Scanner + Editor)
echo "[*] Generating Admin Panel UI..."
cat << 'EOF' > /www/admin/index.html
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Panel - Router</title>
    <style>
        body { font-family: Arial; padding: 15px; background: #222; color: white; }
        textarea { width: 100%; height: 300px; background: #111; color: #0f0; padding: 10px; border: 1px solid #444; box-sizing: border-box; }
        button { padding: 10px; background: #007bff; color: white; border: none; cursor: pointer; margin-top: 5px; width: 100%; }
        .tab { display: none; margin-top: 15px; }
        .active-tab { display: block; }
        .nav { display: flex; gap: 5px; }
        .nav button { background: #555; width: auto; flex: 1; }
        input { padding: 10px; width: 100%; box-sizing: border-box; margin: 5px 0; background: #333; color: white; border: 1px solid #555; }
        ul { list-style: none; padding: 0; }
        li { padding: 10px; background: #333; margin-bottom: 5px; cursor: pointer; border-radius: 4px; }
    </style>
</head>
<body>
    <h2>Router Admin Dashboard</h2>
    <div class="nav">
        <button onclick="showTab('wifi-manager'); scanWifi()">Scanner</button>
        <button onclick="showTab('editor')">UI Editor</button>
    </div>
    
    <!-- WiFi Scanner Tab -->
    <div id="wifi-manager" class="tab active-tab">
        <h3>Connect Secondary WiFi</h3>
        <button onclick="scanWifi()">🔄 Scan Networks</button>
        <div id="scan-results" style="margin-top:10px;">Loading...</div>
        <hr style="border-color:#444;">
        <input type="text" id="target-ssid" placeholder="WiFi Name (SSID)">
        <input type="password" id="target-pass" placeholder="Password (Empty if open)">
        <button onclick="connectWifi()" style="background:#28a745;">Connect to Internet</button>
        <p id="wifi-msg" style="color:yellow; text-align:center;"></p>
    </div>

    <!-- UI Editor Tab -->
    <div id="editor" class="tab">
        <h3>Live UI Editor</h3>
        <textarea id="codeBox"></textarea>
        <button onclick="saveUI()">💾 Save HTML Code</button>
        <p id="saveMsg" style="color:yellow; text-align:center;"></p>
    </div>

    <script>
        function showTab(id) {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active-tab'));
            document.getElementById(id).classList.add('active-tab');
        }
        
        fetch('/cgi-bin/admin_api?action=get_ui').then(res => res.text()).then(txt => document.getElementById('codeBox').value = txt);
        
        function saveUI() {
            document.getElementById('saveMsg').innerText = "Saving...";
            fetch('/cgi-bin/admin_api?action=save_ui', { method: 'POST', body: document.getElementById('codeBox').value })
            .then(res => res.json()).then(data => { if(data.status === 'success') document.getElementById('saveMsg').innerText = "Saved Successfully!"; });
        }

        function scanWifi() {
            document.getElementById('scan-results').innerHTML = "Scanning nearby networks...";
            fetch('/cgi-bin/wifi_scan').then(res => res.json()).then(data => {
                let html = "<ul>";
                data.forEach(net => {
                    html += `<li onclick="document.getElementById('target-ssid').value='${net.ssid}'">
                        <b>${net.ssid}</b> <span style="color:#aaa;">(${net.quality})</span><br><small>${net.encryption}</small>
                    </li>`;
                });
                document.getElementById('scan-results').innerHTML = html + "</ul>";
            }).catch(() => document.getElementById('scan-results').innerHTML = "Scan error.");
        }

        function connectWifi() {
            let ssid = document.getElementById('target-ssid').value;
            let pass = document.getElementById('target-pass').value;
            document.getElementById('wifi-msg').innerText = "Applying changes... Please wait.";
            fetch('/cgi-bin/wifi_connect', {
                method: 'POST',
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: `ssid=${encodeURIComponent(ssid)}&pass=${encodeURIComponent(pass)}`
            }).then(res => res.json()).then(data => document.getElementById('wifi-msg').innerText = data.message);
        }
    </script>
</body>
</html>
EOF

# 4. APIs তৈরি (Auth, Admin, Scan, Connect)
echo "[*] Creating Backend APIs..."

# 4.1 Auth API
cat << 'EOF' > /www/cgi-bin/auth
#!/bin/sh
echo "Content-type: application/json"
echo ""
read POST_DATA
VOUCHER=$(echo$POST_DATA | awk -F'=' '{print $2}')
CLIENT_MAC=$(cat /proc/net/arp \vert{} grep "$REMOTE_ADDR " | awk '{print $4}')
VALID_VOUCHER=$(grep "^$VOUCHER|" /etc/vouchers.txt)
if [ -n "$VALID_VOUCHER" ]; then
    DURATION=$(echo$VALID_VOUCHER | cut -d'|' -f2)
    EXPIRY_TIME=$(($(date +\%s) +$DURATION * 60))
    iptables -t nat -I CAPTIVE_PORTAL 1 -m mac --mac-source $CLIENT_MAC -j RETURN
    echo "$CLIENT_MAC\vert{}$EXPIRY_TIME" >> /tmp/active_users.txt
    sed -i "/^$VOUCHER|/d" /etc/vouchers.txt
    echo '{"status": "success", "message": "Internet Connected!"}'
else
    echo '{"status": "error", "message": "Invalid Voucher"}'
fi
EOF

# 4.2 Admin API (UI Edit)
cat << 'EOF' > /www/cgi-bin/admin_api
#!/bin/sh
if [ "$QUERY_STRING" = "action=get_ui" ]; then
    echo "Content-type: text/plain"
    echo ""
    cat /www/index.html
    exit 0
elif [ "$QUERY_STRING" = "action=save_ui" ]; then
    echo "Content-type: application/json"
    echo ""
    dd ibs=1 count=$CONTENT_LENGTH 2>/dev/null > /www/index.html
    echo '{"status": "success"}'
    exit 0
fi
EOF

# 4.3 WiFi Scan API
cat << 'EOF' > /www/cgi-bin/wifi_scan
#!/bin/sh
echo "Content-type: application/json"
echo ""
echo "["
iwinfo radio0 scan | awk -F'"' '/ESSID/ {ssid=$2} /Quality/ {split($0, a, ": "); qual=a[2]} /Encryption/ {split($0, b, ": "); enc=b[2]; printf "{\"ssid\":\"\%s\", \"quality\":\"\%s\", \"encryption\":\"\%s\"},", ssid, qual, enc}' \vert{} sed 's/,$//'
echo "]"
EOF

# 4.4 WiFi Connect API
cat << 'EOF' > /www/cgi-bin/wifi_connect
#!/bin/sh
echo "Content-type: application/json"
echo ""
read POST_DATA
SSID=$(echo "$POST_DATA" | awk -F'&' '{print $1}' | awk -F'=' '{print $2}' | sed 's/%20/ /g' | sed 's/%21/!/g' | sed 's/%40/@/g')
PASSWORD=$(echo "$POST_DATA" | awk -F'&' '{print $2}' | awk -F'=' '{print $2}' | sed 's/%20/ /g' | sed 's/%40/@/g')

uci -q delete wireless.repeater
uci set wireless.repeater=wifi-iface
uci set wireless.repeater.device='radio0'
uci set wireless.repeater.network='wwan'
uci set wireless.repeater.mode='sta'
uci set wireless.repeater.ssid="$SSID"

if [ -n "$PASSWORD" ]; then
    uci set wireless.repeater.encryption='psk2'
    uci set wireless.repeater.key="$PASSWORD"
else
    uci set wireless.repeater.encryption='none'
fi

uci set network.wwan='interface'
uci set network.wwan.proto='dhcp'
uci set network.wwan.peerdns='0'
uci delete network.wwan.dns 2>/dev/null
uci add_list network.wwan.dns='8.8.8.8'
uci add_list network.wwan.dns='8.8.4.4'

uci set firewall.@zone[1].network='wan wan6 wwan'
uci set firewall.@zone[1].masq='1'

uci commit wireless
uci commit network
uci commit firewall

(wifi reload && /etc/init.d/network restart) &

echo '{"status": "success", "message": "Network configured. Restarting WiFi..."}'
EOF

chmod +x /www/cgi-bin/*

# 5. Session Manager & Cron/Firewall
echo "[*] Configuring Session Manager & Firewall..."
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

# 6. Restart Services
echo "[*] Starting Services..."
/etc/init.d/firewall restart >/dev/null 2>&1
/etc/init.d/cron restart >/dev/null 2>&1

# Add a test voucher
if ! grep -q "123456" /etc/vouchers.txt; then echo "123456|60" >> /etc/vouchers.txt; fi

echo -e "\n\033[1;32m[+] Auto Setup Complete!\033[0m"
echo "Admin Panel: http://192.168.1.1/admin"
