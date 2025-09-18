# Network & Service Status Checker

A comprehensive Bash script for monitoring network connectivity and essential system services. This tool helps system administrators proactively identify network or service failures through automated checks.

***

## 🚀 Features

- **Network Connectivity Monitoring**: Ping multiple hosts to verify internet connectivity
- **System Service Monitoring**: Check status of critical system services using systemctl
- **Configurable**: Customizable host and service lists via configuration file
- **Multiple Output Formats**: Standard console output and JSON format
- **Comprehensive Logging**: Detailed logs with timestamps
- **Color-coded Output**: Easy-to-read status indicators
- **Flexible Execution**: Various command-line options for different use cases
- **Error Handling**: Proper exit codes for script automation
- **Service Validation**: Checks if services exist before monitoring

***

## 📋 Requirements

- Linux system with systemd
- Bash 4.0 or higher
- Standard utilities: `ping`, `systemctl`, `date`
- Appropriate permissions for service status checks

***

## 🛠️ Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/network-service-checker.git
cd network-service-checker
```

- (for Linux users with SSH configuraion)
```bash
git clone git@github.com:priyadeepsenwork/Network-Analyzer.git
cd network-service-checker
```

2. Make the script executable:
```bash
chmod +x network_service_checker.sh
```

3. (Optional) Create log directory:
```bash
sudo mkdir -p /var/log
```

***

## 🔧 Configuration

### 1. Default Monitored Hosts
- google.com
- 8.8.8.8 (Google DNS)
- 1.1.1.1 (Cloudflare DNS)
- github.com
- stackoverflow.com

### 2. Default Monitored Services
- sshd (SSH daemon)
- systemd-resolved (DNS resolution)
- NetworkManager (Network management)
- cron (Task scheduler)
- systemd-timesyncd (Time synchronization)

### 3. Custom Configuration

Edit `config.conf` to customize monitored hosts and services:

```bash
# Add your custom hosts
HOSTS=(
    "yourserver.com"
    "192.168.1.1"
    "custom-host.local"
)

# Add your custom services
SERVICES=(
    "nginx"
    "mysql"
    "docker"
)
```

***

## 📖 Usage

### 1. Basic Usage
```bash
# Run with default settings
./network_service_checker.sh

# Run with custom configuration
./network_service_checker.sh -c /path/to/custom.conf

# Quiet mode (minimal output)
./network_service_checker.sh -q

# JSON output format
./network_service_checker.sh -j
```

### 2. Command Line Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-v, --version` | Show version information |
| `-c, --config FILE` | Use custom configuration file |
| `-l, --log FILE` | Use custom log file |
| `-q, --quiet` | Quiet mode (minimal output) |
| `-j, --json` | Output results in JSON format |
| `--no-log` | Don't write to log file |
| `--hosts-only` | Check only network hosts |
| `--services-only` | Check only system services |

### 3. Examples

```bash
# Check only network connectivity
./network_service_checker.sh --hosts-only

# Check only services
./network_service_checker.sh --services-only

# Output to JSON for parsing
./network_service_checker.sh --json > status.json

# Custom log file
./network_service_checker.sh -l ./my_check.log

# Run without logging
./network_service_checker.sh --no-log
```

***

## 📊 Output Formats

### 1. Standard Output
```
Network & Service Status Checker v1.0
Started at: 2025-09-18 18:12:00

=== Network Connectivity Check ===
[✓] google.com is reachable
[✓] 8.8.8.8 is reachable
[✗] unreachable-host.com is unreachable
Network Summary: 2/3 hosts reachable

=== System Service Check ===
[✓] sshd is running
[✓] NetworkManager is running
[✗] nginx is not running
Service Summary: 2/3 services running

=== Overall Summary ===
[!] 2 issue(s) detected
• 1 network connectivity issue(s)
• 1 service issue(s)
```

### 2. JSON Output
```json
{
  "timestamp": "2025-09-18 18:12:00",
  "network": {
    "google.com": "UP",
    "8.8.8.8": "UP",
    "unreachable-host.com": "DOWN"
  },
  "services": {
    "sshd": "RUNNING",
    "NetworkManager": "RUNNING",
    "nginx": "STOPPED"
  }
}
```

***

## 📝 Logging

Logs are written to `/var/log/network_service_check.log` by default. Each log entry includes:
- Timestamp
- Check type (NETWORK/SERVICE)
- Host/Service name
- Status result

Sample log entry:
```
[2025-09-18 18:12:00] Starting Network & Service Status Checker v1.0
[2025-09-18 18:12:01] NETWORK: google.com is reachable
[2025-09-18 18:12:02] SERVICE: sshd is running
[2025-09-18 18:12:03] Completed with 0 issue(s) detected
```

***

## 🔄 Automation

### 1. Cron Integration

Add to crontab for automated monitoring:

```bash
# Check every 5 minutes
*/5 * * * * /path/to/network_service_checker.sh -q

# Check every hour with JSON output
0 * * * * /path/to/network_service_checker.sh -j > /var/log/hourly_status.json

# Daily comprehensive check
0 8 * * * /path/to/network_service_checker.sh
```

### 2. Systemd Timer (Alternative)

Create a systemd service and timer for more advanced scheduling:

```ini
# /etc/systemd/system/network-check.service
[Unit]
Description=Network & Service Status Check
After=network.target

[Service]
Type=oneshot
ExecStart=/path/to/network_service_checker.sh -q
User=root

# /etc/systemd/system/network-check.timer
[Unit]
Description=Run network check every 5 minutes
Requires=network-check.service

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
```

Enable the timer:
```bash
sudo systemctl enable --now network-check.timer
```

***

## 🎯 Exit Codes

The script returns meaningful exit codes for automation:

- `0`: All checks passed
- `>0`: Number of failed checks (network + service failures)

This allows for conditional actions based on results:

```bash
if ./network_service_checker.sh -q; then
    echo "All systems operational"
else
    echo "Issues detected, check logs"
    # Send alert, restart services, etc.
fi
```

***

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a Pull Request

***

## 🐛 Troubleshooting

### Common Issues

**1. Permission Denied on Log File**
```bash
# Fix log directory permissions
sudo chown $USER:$USER /var/log/
# Or use local logging
./network_service_checker.sh -l ./local.log
```

**2. Service Not Found Warnings**
- The script checks if services exist before monitoring
- Remove non-existent services from your configuration
- Services marked as "NOT_FOUND" don't count as failures

**3. Network Timeouts**
- Adjust `PING_TIMEOUT` in configuration
- Check firewall rules
- Verify DNS resolution

***

## 🔍 Advanced Usage

### 1. Integration with Monitoring Systems

**A. Nagios/Icinga Integration**
```bash
# Use exit codes for status
./network_service_checker.sh -q
case $? in
    0) echo "OK - All systems operational" ;;
    *) echo "CRITICAL - $? issues detected" ;;
esac
```

**B. Prometheus Integration**
```bash
# Generate metrics format
./network_service_checker.sh -j | jq -r '
  .network | to_entries[] | 
  "network_status{host=\"\(.key)\"} \(if .value=="UP" then 1 else 0 end)"
'
```

### 2. Custom Alert Scripts

```bash
#!/bin/bash
# alert_handler.sh
STATUS=$(/path/to/network_service_checker.sh -q; echo $?)
if [ $STATUS -gt 0 ]; then
    # Send email, Slack notification, etc.
    echo "Alert: $STATUS issues detected" | mail -s "System Alert" admin@company.com
fi
```

***

## 📊 Performance Notes
- Network checks run sequentially (can add parallel execution)
- Service checks are fast (systemctl is-active)
- Typical execution time: 10-30 seconds depending on network latency
- Memory footprint: ~10MB during execution
- Log rotation recommended for long-term deployments

***

## 📜 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.