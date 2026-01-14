# Linux Utils

A collection of performance tuning and network utility scripts for Linux systems.

## Scripts

### maxperf-static.sh
**Static Linux Performance Audit Tool**

A comprehensive audit script that checks common Linux performance settings without making any changes. Reports on:
- CPU governor settings
- System limits (ulimit)
- Kernel parameters (networking, memory, filesystem)
- Disk I/O scheduler configuration

```bash
sudo ./maxperf-static.sh
```

### TetherTTL.sh
**Mobile Tethering TTL Bypass**

Configures iptables to set TTL/hop limit to bypass carrier tethering detection. Creates a systemd service for persistent configuration.

```bash
sudo ./TetherTTL.sh
```

## Installation

```bash
git clone https://github.com/jdgafx/linux-utils.git
cd linux-utils
chmod +x *.sh
```

## License

MIT License

## Author

**jdgafx** - AI Systems Engineer | Generative Developer
