# AGENTS.md - Shell Scripts Project

## Build Commands

```bash
# Make scripts executable
chmod +x *.sh

# Run scripts
./script-name.sh
bash script-name.sh

# Run all scripts
for script in *.sh; do echo "Running $script"; ./"$script"; done
```

## Code Style Guidelines

### Shebang
```bash
#!/bin/bash
# OR for portability
#!/usr/bin/env bash
```

### Variables
```bash
# Variables: UPPER_SNAKE_CASE
CONFIG_PATH="/etc/app/config"
LOG_FILE="/var/log/app.log"

# Local variables: lowercase
local config_file="config.json"
```

### Functions
```bash
# Functions: snake_case
function log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
}

# Call function
log_message "INFO" "Application started"
```

### Error Handling
```bash
# ✅ Correct - Exit on error
set -e

# Error handling
if ! command -v jq > /dev/null 2>&1; then
    echo "Error: jq is required but not installed."
    exit 1
fi
```

### Imports/Sourcing
```bash
# Source utility scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"
```

## Project Structure

```
*.sh              # Shell scripts
README.md         # Documentation
```

## Environment Variables

```bash
# Add to .env or export before running
CONFIG_PATH="/path/to/config"
LOG_LEVEL="debug"
```
