#!/bin/bash

# Define the DNS servers
desired_dns="<PREFERED DNS IP FOR WHEN ON VPN>"    # The DNS you want to use with Tor/VPN
local_dns="<HOME DNS FOR WHEN YOU WANT OFF VPN>"   # Fallback DNS when disconnecting from VPN/Tor

# Path to the OpenVPN configuration file and credentials
vpn_config="/etc/openvpn/OPENVPN_CONFIG.ovpn"  # Adjust the path to your specific .ovpn file
vpn_credentials="/etc/openvpn/CREDENTIAL-FILE"  # Replace with your actual credentials file

# Function to reset DNS and revert to DHCP
reset_to_dhcp() {
    echo "[  (⊙_☉)  ] Resetting DNS and switching back to DHCP..."
    sudo chattr -i /etc/resolv.conf
    echo "nameserver $local_dns" | sudo tee /etc/resolv.conf
    sudo dhclient -r && sudo dhclient
    sudo chattr +i /etc/resolv.conf
    echo "[ ಠ‿ಠ ] DHCP and DNS reset to default."
}

# Function to configure DNS for VPN/Tor use
configure_dns() {
    echo "[  (⊙_☉)  ] Configuring DNS for VPN/Tor..."
    sudo chattr -i /etc/resolv.conf
    echo "nameserver $desired_dns" | sudo tee /etc/resolv.conf
    sudo chattr +i /etc/resolv.conf
    echo "[ ಠ‿ಠ ] DNS set to $desired_dns"
}

# Function to check if VPN is running by verifying the tun0 interface
check_vpn() {
    echo "[  (⊙_☉)  ] Checking VPN status..."
    vpn_interface=$(ip a | grep tun0)  # Adjust the interface name if different
    if [[ -n "$vpn_interface" ]]; then
        echo "[ ಠ‿ಠ ] VPN is running (tun0 detected)."
        return 0
    else
        echo "[  ୧༼ಠ益ಠ༽୨  ] VPN is not running."
        return 1
    fi
}

# Function to terminate any existing OpenVPN sessions
terminate_vpn() {
    echo "[  (⊙_☉)  ] Terminating existing OpenVPN sessions..."

    # Attempt to stop the OpenVPN service if managed by systemd
    sudo systemctl stop openvpn
    sudo systemctl disable openvpn
    sudo systemctl mask openvpn

    # Kill all existing OpenVPN sessions
    sudo pkill -9 -f openvpn

    # Check and kill any remaining processes manually
    while pgrep openvpn > /dev/null; do
        echo "Killing remaining OpenVPN processes..."
        sudo pkill -9 -f openvpn
        sleep 1
    done

    # Verify no OpenVPN processes are running
    if pgrep openvpn > /dev/null; then
        echo "[  ୧༼ಠ益ಠ༽୨  ] OpenVPN processes are still running. Please check manually."
    else
        echo "[ ಠ‿ಠ ] All OpenVPN processes successfully terminated."
    fi
}

# Function to start VPN and ensure stability before changing DNS
start_vpn() {
    echo "[  (⊙_☉)  ] Checking if OpenVPN is already running..."
    if pgrep openvpn > /dev/null; then
        echo "[ ಠ‿ಠ ] OpenVPN is already running. Skipping restart."
        return 0
    fi

    echo "[  (⊙_☉)  ] Starting VPN..."
    sudo openvpn --config "$vpn_config" --auth-user-pass "$vpn_credentials" &
    sleep 20  # Allow time for the VPN to establish

    # Check if the VPN successfully connected by verifying the tun0 interface
    check_vpn
    if [ $? -eq 0 ]; then
        echo "[ ಠ‿ಠ ] VPN is running. Proceeding to configure DNS."
        configure_dns
        return 0
    else
        echo "[  ୧༼ಠ益ಠ༽୨  ] VPN failed to start. Check OpenVPN logs for details."
        return 1
    fi
}

# Function to restart Tor service and ensure connectivity
restart_tor() {
    echo "[  (⊙_☉)  ] Restarting Tor..."
    sudo systemctl restart tor
    sleep 10
}

# Function to validate Tor connection
check_tor_connection() {
    echo "[  (⊙_☉)  ] Validating Tor connection..."
    while true; do
        curl_output=$(proxychains curl -s https://check.torproject.org)
        if [[ $curl_output == *"Congratulations"* ]]; then
            echo "[ ಠ‿ಠ ] Tor is connected successfully."
            break
        else
            echo "[  ୧༼ಠ益ಠ༽୨  ] Tor not connected, retrying in 20 seconds..."
            sleep 20
            restart_tor
        fi
    done
}

# Function to stop VPN, Tor, and reset DNS
stop_vpn_and_tor() {
    echo "[  (⊙_☉)  ] Stopping VPN and Tor..."
    terminate_vpn  # Ensure all OpenVPN processes are terminated
    sudo killall proxychains
    sudo systemctl stop tor
    reset_to_dhcp
    echo "[ ಠ‿ಠ ] VPN and Tor services stopped."
}

# Main logic to handle VPN/Tor connection and monitoring
monitor_connections() {
    while true; do
        # Check and start VPN if necessary
        start_vpn
        if [ $? -ne 0 ]; then
            echo "[  ୧༼ಠ益ಠ༽୨  ] Failed to start VPN. Retrying in 20 seconds..."
            sleep 20
            continue
        fi

        # Check if the VPN is up by verifying the gateway or endpoint
        vpn_up=$(ping -c 1 -W 3 10.8.0.1)  # Replace with VPN gateway or endpoint
        if [ $? -ne 0 ]; then
            echo "[  ୧༼ಠ益ಠ༽୨  ] VPN connection lost. Restarting VPN and Tor..."
            stop_vpn_and_tor
            sleep 5
            continue
        fi

        # Re-check Tor status periodically
        tor_connected=$(proxychains curl -s https://check.torproject.org)
        if [[ $tor_connected != *"Congratulations"* ]]; then
            echo "[  ୧༼ಠ益ಠ༽୨  ] Tor connection lost. Restarting..."
            restart_tor
        fi

        echo "[ ಠ‿ಠ ] Connections are stable. Sleeping for 30 seconds before re-checking..."
        sleep 30
    done
}

# Script entry point
echo "[  (⊙_☉)  ] Starting VPN and Tor monitoring script..."
monitor_connections
