#!/bin/bash

# Path to your OpenVPN client configuration file
OVPN_FILE="/path/to/your/file.ovpn"


# Function to check if the VPN tunnel is up
is_vpn_up() {
  if ifconfig | grep -q "tun0"; then
    if ifconfig tun0 | grep -q "UP"; then
      return 0
    fi
  fi
  return 1
}

# Function to restart the VPN tunnel
restart_vpn() {
  openvpn --config "$OVPN_FILE" --daemon
  echo "Restarting VPN..."
  sudo systemctl restart openvpn
}

# Main loop
while true; do
  if ! is_vpn_up; then
    echo "VPN is down, restarting..."
    restart_vpn
  fi
  sleep 10
done
