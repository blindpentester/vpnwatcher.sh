# VPN and Tor Management Script Overview

This document provides a detailed explanation of the Bash script that manages VPN and Tor services. It includes descriptions of functions, processes, and overall workflow to help understand how each component works.

## Table of Contents
1. [Overview](#overview)
2. [Script Functions](#script-functions)
   - [reset_to_dhcp](#reset_to_dhcp)
   - [configure_dns](#configure_dns)
   - [check_vpn](#check_vpn)
   - [terminate_vpn](#terminate_vpn)
   - [start_vpn](#start_vpn)
   - [restart_tor](#restart_tor)
   - [check_tor_connection](#check_tor_connection)
   - [stop_vpn_and_tor](#stop_vpn_and_tor)
   - [monitor_connections](#monitor_connections)
3. [Process Flow](#process-flow)
4. [Execution and Monitoring](#execution-and-monitoring)
5. [Conclusion](#conclusion)

## Overview

This Bash script manages VPN and Tor connections, ensuring that the network configurations are dynamically adjusted based on the status of each service. It also monitors the VPN connection and Tor service stability and re-establishes them when necessary.

The script uses DNS configurations and specific service management commands to ensure network privacy and connectivity. It automates the process of connecting, disconnecting, and monitoring the VPN and Tor services.

## Script Functions

### `reset_to_dhcp`

- **Description**: Resets DNS settings and switches back to DHCP configuration.
- **Process**:
  1. Unsets the immutable attribute on the `/etc/resolv.conf` file.
  2. Sets the DNS to a local fallback DNS address.
  3. Re-enables DHCP client to refresh IP and DNS configuration.
  4. Makes `/etc/resolv.conf` immutable again to prevent unauthorized changes.

```bash
sudo chattr -i /etc/resolv.conf
echo "nameserver $local_dns" | sudo tee /etc/resolv.conf
sudo dhclient -r && sudo dhclient
sudo chattr +i /etc/resolv.conf
```

### `configure_dns`

- **Description**: Configures DNS settings for use with VPN or Tor.
- **Process**:
  1. Makes `/etc/resolv.conf` file writable.
  2. Sets the DNS to the preferred DNS address.
  3. Sets `/etc/resolv.conf` back to immutable.

```bash
sudo chattr -i /etc/resolv.conf
echo "nameserver $desired_dns" | sudo tee /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
```

### `check_vpn`

- **Description**: Checks if the VPN is currently running by looking for the `tun0` network interface.
- **Process**: Uses `ip a | grep tun0` to determine if the VPN is active.

```bash
vpn_interface=$(ip a | grep tun0)
```

### `terminate_vpn`

- **Description**: Terminates any existing OpenVPN sessions.
- **Process**:
  1. Stops the OpenVPN service if it is managed by systemd.
  2. Kills all existing OpenVPN processes manually.
  3. Verifies that no OpenVPN processes are running.

```bash
sudo systemctl stop openvpn
sudo pkill -9 -f openvpn
```

### `start_vpn`

- **Description**: Starts the OpenVPN client using a specified configuration file and credentials.
- **Process**:
  1. Checks if OpenVPN is already running.
  2. Starts the OpenVPN client.
  3. Verifies VPN connectivity by checking for the `tun0` interface.

```bash
sudo openvpn --config "$vpn_config" --auth-user-pass "$vpn_credentials" &
```

### `restart_tor`

- **Description**: Restarts the Tor service to ensure connectivity.
- **Process**: Uses `sudo systemctl restart tor` and allows time for the service to stabilize.

```bash
sudo systemctl restart tor
```

### `check_tor_connection`

- **Description**: Validates the Tor connection by using `proxychains` and `curl` to check the Tor project's connection verification page.
- **Process**:
  1. Uses `proxychains curl -s https://check.torproject.org`.
  2. Looks for the "Congratulations" message to verify a successful connection.
  3. Restarts Tor if the connection is not established.

```bash
proxychains curl -s https://check.torproject.org
```

### `stop_vpn_and_tor`

- **Description**: Stops both the VPN and Tor services and resets DNS settings.
- **Process**:
  1. Terminates VPN and Tor services.
  2. Kills any proxychains processes.
  3. Resets DNS to local settings.

```bash
terminate_vpn
sudo killall proxychains
sudo systemctl stop tor
reset_to_dhcp
```

### `monitor_connections`

- **Description**: Monitors VPN and Tor connections and re-establishes them if needed.
- **Process**:
  1. Periodically checks the status of the VPN and Tor services.
  2. Restarts VPN and Tor services if connectivity is lost.

```bash
vpn_up=$(ping -c 1 -W 3 10.8.0.1)
tor_connected=$(proxychains curl -s https://check.torproject.org)
```

## Process Flow

1. **Script Initialization**:
   - The script begins by invoking the `monitor_connections` function.
   
2. **VPN and DNS Configuration**:
   - `start_vpn` is called to establish a VPN connection using the provided configuration file and credentials.
   - If the VPN connection is successful, DNS is configured using `configure_dns`.

3. **Tor Service Management**:
   - Tor is restarted using the `restart_tor` function.
   - The Tor connection is validated using `check_tor_connection`.

4. **Continuous Monitoring**:
   - The script enters a continuous monitoring state using `monitor_connections`, periodically checking the status of both the VPN and Tor.
   - If either connection is lost, the script attempts to re-establish connectivity.

## Execution and Monitoring

To run this script, execute it as a Bash script:

```bash
./vpn_tor_script.sh
```

### Logging and Output

The script uses different symbols to indicate the status of each process:

- `[ ಠ‿ಠ ]` : Success indicator
- `[ (⊙_☉) ]` : Informational message
- `[ ୧༼ಠ益ಠ༽୨ ]` : Error or alert message

These messages help differentiate between normal operations and issues that may require attention.

## Conclusion

This Bash script automates the process of managing VPN and Tor services, ensuring consistent connectivity and security. By monitoring the services in real-time and re-establishing connections as needed, the script provides robust network management and privacy.
