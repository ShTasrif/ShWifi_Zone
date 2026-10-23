#!/bin/sh
# TASRIF WIFI ZONE - Auto Cleanup & Device Manager Pro
# Router IP: 192.168.2.1

echo -e "\n\033[1;36m=== TASRIF WIFI ZONE Pro Installer ===\033[0m"
echo "[*] Initializing setup... Please wait."

# 1. 🧹 FULL CLEANUP OF OLD CONFIGURATIONS
echo "[*] Cleaning all old configurations..."
rm -rf /www/cgi-bin/auth /www/cgi-bin/admin_api /www/admin /www/index.html 2>/dev/null
touch /etc/vouchers.txt /tmp/active_users.txt
sed -i '/session_manager.sh/d' /etc/crontabs/root 2>/dev/null
sed -i '/CAPTIVE_PORTAL/d' /etc/firewall.user 2>/dev/null

# Remove all old WiFi Interfaces
uci -q delete wireless.repeater
while uci -q delete wireless.@wifi-iface[0]; do :; done

# 2. 🌐 PREMIUM CAPTIVE PORTAL UI
echo "[*] Generating Premium User Portal..."
mkdir -p /www/cgi-bin /www/admin
if ! grep -q "123456" /etc/vouchers.txt; then echo "123456|60" > /etc/vouchers.txt; fi

cat << 'EOF' > /www/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TASRIF WIFI ZONE</title>
    <style>
        * { box-sizing: border-box; font-family: 'Segoe UI', sans-serif; }
        body { margin: 0; padding: 0; height: 100vh; display: flex; align-items: center; justify-content: center; background: url('https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=1920') no-repeat center center/cover; }
        .overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0, 0, 0, 0.6); }
        .login-box { position: relative; z-index: 1; background: rgba(255, 255, 255, 0.1); backdrop-filter: blur(10px); padding: 40px; border-radius: 20px; border: 1px solid rgba(255, 255, 255, 0.2); text-align: center; width: 90%; max-width: 400px; color: white; box-shadow: 0 15px 25px rgba(0,0,0,0.5); }
        h1 { margin: 0 0 10px; font-size: 28px; font-weight: 700; text-transform: uppercase; color: #00e6ff; text-shadow: 0 0 10px rgba(0, 230, 255, 0.5); }
        p { margin-bottom: 30px; font-size: 14px; color: #ddd; }
        input { width: 100%; padding: 15px; margin-bottom: 20px; border: none; border-radius: 8px; background: rgba(0,0,0,0.5); color: white; font-size: 16px; text-align: center; outline: none; border: 1px solid transparent; transition: 0.3s; }
        input:focus { border: 1px solid #00e6ff; background: rgba(0,0,0,0.8); }
        button { width: 100%; padding: 15px; border: none; border-radius: 8px; background: linear-gradient(45deg, #00e6ff, #0077ff); color: white; font-size: 16px; font-weight: bold; cursor: pointer; transition: 0.3s; }
        button:hover { transform: translateY(-2px); }
        #msg { margin-top: 15px; font-weight: bold; min-height: 20px; }
        .footer { margin-top: 20px; font-size: 12px; color: #aaa; }
    </style>
</head>
<body>
    <div class="overlay"></div>
    <div class="login-box">
        <h1>TASRIF WIFI</h1>
        <p>Premium Internet Access Zone</p>
        <input type="text" id="voucher" placeholder="Enter Voucher Code" required autocomplete="off">
        <button id="connBtn" onclick="login()">CONNECT NOW</button>
        <div id="msg"></div>
        <div class="footer">&copy; TASRIF CyberSH. All Rights Reserved.</div>
    </div>
    <script>
        function login() {
            let code = document.getElementById('voucher').value;
            let btn = document.getElementById('connBtn');
            let msg = document.getElementById('msg');
            if(!code) { msg.innerText = "Please enter a code!"; msg.style.color = "#ff4d4d"; return; }
            btn.innerText = "AUTHENTICATING...";
            fetch('/cgi-bin/auth', { method: 'POST', body: 'voucher=' + encodeURIComponent(code) })
            .then(res => res.json()).then(data => {
                msg.style.color = (data.status === 'success') ? '#00ff88' : '#ff4d4d';
                msg.innerText = data.message;
                if(data.status === 'success') {
                    btn.innerText = "CONNECTED";
                    btn.style.background = "linear-gradient(45deg, #00ff88, #00aa55)";
                    setTimeout(() => window.location.href = 'http://neverssl.com', 1500);
                } else { btn.innerText = "CONNECT NOW"; }
            }).catch(() => { msg.innerText = "Network Error!"; btn.innerText = "CONNECT NOW"; });
        }
    </script>
</body>
</html>
EOF

# 3. ⚙️ ADMIN PANEL UI (Device Manager added)
echo "[*] Generating Pro Admin Dashboard..."
cat << 'EOF' > /www/admin/index.html
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TASRIF - Network Admin</title>
    <style>
        :root { --bg: #0f172a; --card: #1e293b; --primary: #3b82f6; --text: #f8fafc; --success: #10b981; --warn: #f59e0b; }
        body { font-family: 'Segoe UI', sans-serif; background: var(--bg); color: var(--text); margin: 0; padding: 20px; }
        .container { max-width: 900px; margin: auto; }
        .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 1px solid #334155; padding-bottom: 15px; }
        .header h2 { margin: 0; color: var(--primary); }
        .nav { display: flex; gap: 10px; margin-bottom: 20px; overflow-x: auto; }
        .nav button { flex: 1; padding: 12px; background: #334155; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: bold; }
        .nav button.active { background: var(--primary); }
        .tab { display: none; }
        .active-tab { display: block; }
        .dashboard-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 20px; }
        .card { background: var(--card); padding: 20px; border-radius: 12px; text-align: center; border: 1px solid #334155; }
        .card h3 { margin: 0; color: #94a3b8; font-size: 14px; text-transform: uppercase; }
        .card h1 { margin: 15px 0 0; font-size: 36px; }
        select, button, input { padding: 12px; border-radius: 8px; border: none; font-size: 14px; margin-right: 5px; }
        select, input { background: #334155; color: white; border: 1px solid #475569; width: 100%; margin-bottom: 10px; }
        .btn-primary { background: var(--primary); color: white; cursor: pointer; font-weight: bold; width: 100%; margin-bottom: 10px; }
        .btn-success { background: var(--success); color: white; cursor: pointer; font-weight: bold; }
        .table-container { background: var(--card); border-radius: 12px; padding: 20px; border: 1px solid #334155; overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; text-align: left; }
        th, td { padding: 12px; border-bottom: 1px solid #334155; white-space: nowrap; }
        th { color: #94a3b8; font-size: 12px; text-transform: uppercase; }
        .badge-active { background: var(--success); color: white; padding: 4px 8px; border-radius: 4px; font-size: 12px; }
        .badge-pending { background: var(--warn); color: white; padding: 4px 8px; border-radius: 4px; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2>⚙️ TASRIF WIFI ADMIN</h2>
            <span>IP: 192.168.2.1</span>
        </div>
        
        <div class="nav">
            <button class="active" onclick="switchTab('dashboard', this)">Dashboard & Vouchers</button>
            <button onclick="switchTab('devices', this)">Connected Devices (MAC)</button>
        </div>

        <!-- DASHBOARD TAB -->
        <div id="dashboard" class="tab active-tab">
            <div class="dashboard-grid">
                <div class="card"><h3>Active Connections</h3><h1 id="stat-users" style="color:var(--success);">0</h1></div>
                <div class="card"><h3>Available Vouchers</h3><h1 id="stat-vouchers" style="color:var(--primary);">0</h1></div>
            </div>
            <div class="card" style="text-align:left; margin-bottom: 20px;">
                <h3>🎟️ Generate Access Code</h3>
                <div style="display: flex; gap: 10px; margin-top:10px;">
                    <select id="v-duration" style="margin:0;"><option value="60">1 Hour</option><option value="180">3 Hours</option><option value="1440">1 Day</option><option value="10080">7 Days</option></select>
                    <button class="btn-primary" onclick="generateVoucher()" style="margin:0;">Generate Code</button>
                </div>
                <p id="gen-msg" style="color: var(--success); font-weight:bold; margin-top:10px;"></p>
            </div>
            <div class="table-container">
                <h3>📝 Latest Unused Vouchers</h3>
                <table><thead><tr><th>Code</th><th>Duration</th><th>Status</th></tr></thead><tbody id="voucher-list"></tbody></table>
            </div>
        </div>

        <!-- DEVICES TAB -->
        <div id="devices" class="tab">
            <div class="table-container">
                <h3>📱 Live Connected Devices</h3>
                <p style="font-size:12px; color:#94a3b8;">Approve devices manually without a voucher code.</p>
                <table>
                    <thead><tr><th>Device Name</th><th>MAC Address</th><th>IP Address</th><th>Status</th><th>Action</th></tr></thead>
                    <tbody id="device-list"><tr><td colspan="5">Loading devices...</td></tr></tbody>
                </table>
            </div>
        </div>
    </div>

    <script>
        function switchTab(id, btn) {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active-tab'));
            document.querySelectorAll('.nav button').forEach(b => b.classList.remove('active'));
            document.getElementById(id).classList.add('active-tab');
            btn.classList.add('active');
            if(id === 'devices') loadDevices();
        }

        function loadStats() {
            fetch('/cgi-bin/admin_api?action=stats').then(res => res.json()).then(data => {
                document.getElementById('stat-users').innerText = data.active;
                document.getElementById('stat-vouchers').innerText = data.total_vouchers;
                let vHtml = '';
                data.voucher_list.forEach(v => {
                    let p = v.split('|');
                    if(p.length === 2) vHtml += `<tr><td><strong>${p[0]}</strong></td><td>${Math.round(p[1]/60)} Hr(s)</td><td><span class="badge-active">Unused</span></td></tr>`;
                });
                document.getElementById('voucher-list').innerHTML = vHtml || "<tr><td colspan='3'>No vouchers.</td></tr>";
            });
        }
        setInterval(loadStats, 5000); loadStats();

        function generateVoucher() {
            let duration = document.getElementById('v-duration').value;
            fetch('/cgi-bin/admin_api?action=generate&duration=' + duration)
            .then(res => res.json()).then(data => {
                document.getElementById('gen-msg').innerText = "Generated: " + data.code;
                loadStats();
            });
        }

        // LOAD LIVE DHCP DEVICES
        function loadDevices() {
            fetch('/cgi-bin/admin_api?action=get_clients').then(res => res.json()).then(data => {
                let html = '';
                if(data.length === 0) html = "<tr><td colspan='5'>No devices connected yet.</td></tr>";
                data.forEach(d => {
                    let stat = d.status === 'Active' ? '<span class="badge-active">Connected</span>' : '<span class="badge-pending">Pending Auth</span>';
                    let action = d.status === 'Pending' ? 
                        `<div style="display:flex; gap:5px;"><select id="dur-${d.mac}" style="margin:0; width:80px; padding:5px;"><option value="60">1H</option><option value="1440">1D</option><option value="43200">30D</option></select>
                        <button class="btn-success" style="padding:6px 12px; margin:0;" onclick="approveMac('${d.mac}')">Approve</button></div>` : '<span style="color:#94a3b8; font-size:12px;">Authorized</span>';
                    
                    html += `<tr><td>${d.host}</td><td>${d.mac}</td><td>${d.ip}</td><td>${stat}</td><td>${action}</td></tr>`;
                });
                document.getElementById('device-list').innerHTML = html;
            });
        }

        // MANUALLY APPROVE A DEVICE MAC
        function approveMac(mac) {
            let duration = document.getElementById(`dur-${mac}`).value;
            fetch('/cgi-bin/admin_api', {
                method: 'POST', headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: `action=approve_mac&mac=${encodeURIComponent(mac)}&duration=${duration}`
            }).then(res => res.json()).then(data => {
                if(data.status === 'success') { alert('Device Internet Access Granted!'); loadDevices(); }
            });
        }
    </script>
</body>
</html>
EOF

# 4. 🗄️ BACKEND APIs (New MAC & DHCP Parsers)
echo "[*] Compiling Advanced CGI APIs..."
cat << 'EOF' > /www/cgi-bin/auth
#!/bin/sh
read POST_DATA
VOUCHER=$(echo "$POST_DATA" | awk -F'=' '{print $2}')
CLIENT_MAC=$(cat /proc/net/arp | grep "$REMOTE_ADDR " | awk '{print $4}')
VALID_VOUCHER=$(grep "^$VOUCHER|" /etc/vouchers.txt)

echo "Content-type: application/json"
echo ""

if [ -n "$VALID_VOUCHER" ]; then
    DURATION=$(echo $VALID_VOUCHER | cut -d'|' -f2)
    EXPIRY_TIME=$(($(date +%s) + $DURATION * 60))
    iptables -t nat -I CAPTIVE_PORTAL 1 -m mac --mac-source $CLIENT_MAC -j RETURN
    echo "$CLIENT_MAC|$EXPIRY_TIME" >> /tmp/active_users.txt
    sed -i "/^$VOUCHER|/d" /etc/vouchers.txt
    echo '{"status": "success", "message": "Internet Access Granted!"}'
else
    echo '{"status": "error", "message": "Invalid or Expired Code!"}'
fi
EOF

cat << 'EOF' > /www/cgi-bin/admin_api
#!/bin/sh
echo "Content-type: application/json"
echo ""
read POST_DATA

if echo "$QUERY_STRING" | grep -q "action=stats"; then
    ACTIVE=$(wc -l < /tmp/active_users.txt 2>/dev/null || echo "0")
    TOTAL_V=$(wc -l < /etc/vouchers.txt 2>/dev/null || echo "0")
    V_LIST=$(tail -n 10 /etc/vouchers.txt 2>/dev/null | awk '{printf "\"%s\",", $0}' | sed 's/,$//')
    echo "{\"active\":\"$ACTIVE\", \"total_vouchers\":\"$TOTAL_V\", \"voucher_list\":[$V_LIST]}"
    exit 0

elif echo "$QUERY_STRING" | grep -q "action=generate"; then
    DURATION=$(echo "$QUERY_STRING" | awk -F'duration=' '{print $2}' | awk -F'&' '{print $1}')
    NEW_CODE=$(awk -v min=100000 -v max=999999 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')
    echo "$NEW_CODE|$DURATION" >> /etc/vouchers.txt
    echo "{\"status\":\"success\", \"code\":\"$NEW_CODE\"}"
    exit 0

elif echo "$QUERY_STRING" | grep -q "action=get_clients"; then
    # Parse native OpenWrt DHCP Leases to get Device MAC, IP and Hostname
    awk -v active="$(cat /tmp/active_users.txt 2>/dev/null)" '
    BEGIN { print "["; sep="" }
    {
        mac=$2; ip=$3; host=$4;
        status = (active ~ mac"\\|") ? "Active" : "Pending";
        if (host == "*") host = "Unknown Device";
        printf "%s{\"mac\":\"%s\", \"ip\":\"%s\", \"host\":\"%s\", \"status\":\"%s\"}", sep, mac, ip, host, status;
        sep=",\n"
    }
    END { print "\n]" }
    ' /tmp/dhcp.leases
    exit 0

elif echo "$POST_DATA" | grep -q "action=approve_mac"; then
    MAC=$(echo "$POST_DATA" | awk -F'mac=' '{print $2}' | awk -F'&' '{print $1}' | sed 's/%3A/:/g')
    DURATION=$(echo "$POST_DATA" | awk -F'duration=' '{print $2}' | awk -F'&' '{print $1}')
    EXPIRY=$(($(date +%s) + $DURATION * 60))
    
    iptables -t nat -I CAPTIVE_PORTAL 1 -m mac --mac-source $MAC -j RETURN
    echo "$MAC|$EXPIRY" >> /tmp/active_users.txt
    echo '{"status":"success"}'
    exit 0
fi
EOF
chmod +x /www/cgi-bin/*

# 5. 🛡️ FIREWALL & SESSION MANAGER
echo "[*] Setting up Firewall & Cron Manager..."
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

cat << 'EOF' >> /etc/firewall.user
iptables -t nat -N CAPTIVE_PORTAL 2>/dev/null
iptables -t nat -I PREROUTING -p tcp --dport 80 -j CAPTIVE_PORTAL
iptables -t nat -A CAPTIVE_PORTAL -d 192.168.2.1 -j RETURN
iptables -t nat -A CAPTIVE_PORTAL -p tcp -j DNAT --to-destination 192.168.2.1:80
EOF

# 6. 📡 APPLY SYSTEM SETTINGS
echo "[*] Applying Network & WiFi Changes..."
uci set network.lan.ipaddr='192.168.2.1'
uci set wireless.radio0.disabled='0'
uci add wireless wifi-iface
uci set wireless.@wifi-iface[-1].device='radio0'
uci set wireless.@wifi-iface[-1].network='lan'
uci set wireless.@wifi-iface[-1].mode='ap'
uci set wireless.@wifi-iface[-1].ssid='TASRIF WIFI ZONE'
uci set wireless.@wifi-iface[-1].encryption='none' 
uci set uhttpd.main.error_page='/index.html'

uci commit network
uci commit wireless
uci commit uhttpd

# 7. 🚀 REBOOT
echo -e "\n\033[1;32m[+] Pro Installation Configured Successfully!\033[0m"
echo -e "================================================="
echo -e "🌐 Captive Portal: http://192.168.2.1"
echo -e "⚙️ Custom Admin:  http://192.168.2.1/admin"
echo -e "================================================="
echo -e "\033[1;33m[*] Applying changes and REBOOTING the router now...\033[0m"
echo -e "Please reconnect to 'TASRIF WIFI ZONE' after 1 minute."

(sleep 2; reboot) &
exit 0
