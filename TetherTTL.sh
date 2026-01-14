#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Check if iptables and ip6tables are installed
if ! command -v iptables &> /dev/null || ! command -v ip6tables &> /dev/null; then
    echo "iptables or ip6tables not found. Please install them (e.g., 'pacman -S iptables')."
    exit 1
fi

# Create the loop script to set TTL/hop limit every 10 seconds
cat > /usr/local/bin/ttl_bypass_loop.sh << 'EOF'
#!/bin/bash
while true; do
    # Set IPv4 TTL to 65 for all outgoing packets
    iptables -t mangle -A POSTROUTING -j TTL --ttl-set 65 2>/dev/null
    # Set IPv6 hop limit to 65 for all outgoing packets
    ip6tables -t mangle -A POSTROUTING -j HL --hl-set 65 2>/dev/null
    sleep 10
done
EOF

# Make the loop script executable
chmod +x /usr/local/bin/ttl_bypass_loop.sh

# Create the systemd service file
cat > /etc/systemd/system/ttl-bypass-loop.service << 'EOF'
[Unit]
Description=Continuously set TTL and hop limit to 65 every 10 seconds
After=network.target

[Service]
ExecStart=/usr/local/bin/ttl_bypass_loop.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize the new service
systemctl daemon-reload

# Enable the service to start on boot
systemctl enable ttl-bypass-loop.service

# Start the service immediately
systemctl start ttl-bypass-loop.service

echo "TTL bypass service created, enabled, and started successfully."
