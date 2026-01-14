#!/bin/bash

# ==============================================================================
# maxperf_static.sh
# A static audit script to check common Linux performance settings.
#
# USAGE:
#   sudo ./maxperf_static.sh
#
# DESCRIPTION:
#   This script reads various system configuration files and parameters to
#   generate a report on settings that can impact performance. It does NOT
#   make any changes to the system.
#
# AUTHOR: AI Assistant
# VERSION: 1.1
# ==============================================================================

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper Functions ---

# Function to print a section header
print_header() {
    echo -e "\n${BLUE}--- $1 ---${NC}"
}

# Function to check a setting and print the result
# Args: setting_name, current_value, recommended_value, description
check_setting() {
    local setting_name="$1"
    local current_value="$2"
    local recommended_value="$3"
    local description="$4"

    # Use awk to handle potential multi-line outputs from sysctl -a
    current_value=$(echo "$current_value" | awk '{print $1}')

    if [[ "$current_value" == "$recommended_value" ]]; then
        echo -e "[$setting_name].......... ${GREEN}OK${NC} (Current: $current_value)"
    else
        echo -e "[$setting_name].......... ${YELLOW}WARN${NC} (Current: $current_value, Recommended: $recommended_value)"
    fi
    echo "  > $description"
}

# --- Main Script Logic ---

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root to read all system settings.${NC}" 
   exit 1
fi

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}         MaxPerf Static Audit Report${NC}"
echo -e "${BLUE}============================================================${NC}"

# 1. System Information
print_header "System Information"
echo "OS Version: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel Version: $(uname -r)"
echo "CPU Info: $(lscpu | grep 'Model name' | cut -d':' -f2- | xargs)"
echo "Architecture: $(uname -m)"
echo "Total Memory: $(free -h | awk '/^Mem:/ {print $2}')"

# 2. CPU Governor Check
print_header "CPU Performance Governor"
CPU_GOVERNOR_PATH="/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
if [ -f "$CPU_GOVERNOR_PATH" ]; then
    CURRENT_GOVERNOR=$(cat $CPU_GOVERNOR_PATH)
    if [[ "$CURRENT_GOVERNOR" == "performance" ]]; then
        echo -e "CPU Governor......... ${GREEN}OK${NC} (Current: $CURRENT_GOVERNOR)"
    else
        echo -e "CPU Governor......... ${YELLOW}WARN${NC} (Current: $CURRENT_GOVERNOR, Recommended: performance)"
    fi
    echo "  > Sets the CPU frequency policy. 'performance' keeps it at max."
else
    echo -e "CPU Governor......... ${YELLOW}INFO${NC} (Not available, common on virtual machines)"
fi

# 3. System Limits (ulimit)
print_header "System Limits (ulimit)"
check_setting "Open Files (-n)" "$(ulimit -n)" "65536" "Max number of open file descriptors for a session."
check_setting "Max User Processes (-u)" "$(ulimit -u)" "32768" "Max number of processes available to a single user."

# 4. Kernel Parameters (sysctl)
print_header "Kernel Parameters (sysctl)"

# Networking
echo -e "\n${BLUE}  -- Networking --${NC}"
check_setting "net.core.rmem_max" "$(sysctl -n net.core.rmem_max 2>/dev/null)" "134217728" "Max socket receive buffer size."
check_setting "net.core.wmem_max" "$(sysctl -n net.core.wmem_max 2>/dev/null)" "134217728" "Max socket send buffer size."
check_setting "net.ipv4.tcp_rmem" "$(sysctl -n net.ipv4.tcp_rmem 2>/dev/null)" "4096 65536 134217728" "TCP receive buffer (min, default, max)."
check_setting "net.ipv4.tcp_wmem" "$(sysctl -n net.ipv4.tcp_wmem 2>/dev/null)" "4096 65536 134217728" "TCP send buffer (min, default, max)."
check_setting "net.core.netdev_max_backlog" "$(sysctl -n net.core.netdev_max_backlog 2>/dev/null)" "5000" "Max number of packets in the receive queue."
check_setting "net.ipv4.ip_local_port_range" "$(sysctl -n net.ipv4.ip_local_port_range 2>/dev/null)" "1024 65535" "Range of ports available for outbound connections."
check_setting "net.ipv4.tcp_congestion_control" "$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)" "bbr" "TCP congestion control algorithm. 'bbr' is modern and high-performance."

# Memory Management
echo -e "\n${BLUE}  -- Memory Management --${NC}"
check_setting "vm.swappiness" "$(sysctl -n vm.swappiness 2>/dev/null)" "10" "Tendency to swap memory pages to disk. Lower is better for servers."
check_setting "vm.dirty_ratio" "$(sysctl -n vm.dirty_ratio 2>/dev/null)" "15" "Max % of memory that can be dirty before processes are forced to write."
check_setting "vm.dirty_background_ratio" "$(sysctl -n vm.dirty_background_ratio 2>/dev/null)" "5" "% of memory that can be dirty before background writeback starts."

# File System
echo -e "\n${BLUE}  -- File System --${NC}"
check_setting "fs.file-max" "$(sysctl -n fs.file-max 2>/dev/null)" "2097152" "System-wide limit on file handles."
check_setting "fs.inotify.max_user_watches" "$(sysctl -n fs.inotify.max_user_watches 2>/dev/null)" "524288" "Max number of files a user can watch with inotify."

# 5. Disk I/O Scheduler
print_header "Disk I/O Scheduler"
# Check for common block devices (sd*, nvme*)
for device in /sys/block/sd*/queue/scheduler /sys/block/nvme*/queue/scheduler; do
    if [ -f "$device" ]; then
        dev_name=$(echo $device | cut -d'/' -f4)
        current_sched=$(cat $device | awk '{print $2}')
        # For SSDs/NVMe, 'none' or 'mq-deadline' is often best.
        # For HDDs, 'cfq' or 'deadline' might be used.
        # This is a complex topic, so we'll just report the current state.
        echo -e "[$dev_name Scheduler].... ${YELLOW}INFO${NC} (Current: $current_sched)"
        echo "  > The I/O scheduler. 'none' is often best for modern SSD/NVMe."
    fi
done


echo -e "\n${BLUE}============================================================${NC}"
echo -e "${GREEN}           MaxPerf Static Audit Complete${NC}"
echo -e "${BLUE}============================================================${NC}"
echo -e "NOTE: 'WARN' does not mean your system is broken. It indicates a deviation from a common high-performance tuning profile. Adjust values based on your specific workload and needs."
