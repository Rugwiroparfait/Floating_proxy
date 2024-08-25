#!/bin/bash

# Log file location
log_file="/var/log/proxy_setup.log"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$log_file"
}

# Function to set system-wide proxy
set_proxy_system_wide() {
    log "Starting proxy setup."

    echo "Enter the proxy server address (IP or URL):"
    read -r proxy_address
    echo "Enter the proxy server port for HTTP/HTTPS:"
    read -r proxy_port
    echo "Enter the SOCKS proxy port for SSH:"
    read -r socks_port

    # Check if inputs are not empty
    if [[ -z "$proxy_address" || -z "$proxy_port" || -z "$socks_port" ]]; then
        log "Error: Proxy address, HTTP/HTTPS port, and SOCKS port must be provided."
        exit 1
    fi

    # Set system-wide proxy for APT
    sudo touch /etc/apt/apt.conf
    echo "Acquire::http::Proxy \"http://$proxy_address:$proxy_port\";" | sudo tee /etc/apt/apt.conf
    echo "Acquire::https::Proxy \"http://$proxy_address:$proxy_port\";" | sudo tee -a /etc/apt/apt.conf
    log "APT proxy settings configured."

    # Set system-wide proxy for Docker
    docker_config_dir="/etc/systemd/system/docker.service.d"
    sudo mkdir -p "$docker_config_dir"
    docker_config_file="$docker_config_dir/http-proxy.conf"
    echo -e "[Service]\nEnvironment=\"HTTP_PROXY=http://$proxy_address:$proxy_port\"\nEnvironment=\"HTTPS_PROXY=http://$proxy_address:$proxy_port\"" | sudo tee "$docker_config_file"
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    log "Docker proxy settings configured."

    # Configure Snap Store
    snap_proxy_file="/etc/environment"
    if grep -q "http_proxy" "$snap_proxy_file"; then
        sudo sed -i "s|http_proxy=.*|http_proxy=http://$proxy_address:$proxy_port|" "$snap_proxy_file"
    else
        echo "http_proxy=http://$proxy_address:$proxy_port" | sudo tee -a "$snap_proxy_file"
    fi
    if grep -q "https_proxy" "$snap_proxy_file"; then
        sudo sed -i "s|https_proxy=.*|https_proxy=http://$proxy_address:$proxy_port|" "$snap_proxy_file"
    else
        echo "https_proxy=http://$proxy_address:$proxy_port" | sudo tee -a "$snap_proxy_file"
    fi
    sudo systemctl restart snapd
    log "Snap Store proxy settings configured."

    # Configure rkhunter
    rkhunter_config_file="/etc/rkhunter.conf"
    sudo sed -i "s|^HTTP_PROXY=.*|HTTP_PROXY=http://$proxy_address:$proxy_port|" "$rkhunter_config_file"
    sudo sed -i "s|^HTTPS_PROXY=.*|HTTPS_PROXY=http://$proxy_address:$proxy_port|" "$rkhunter_config_file"
    log "rkhunter proxy settings configured."

    # Configure environment variables for all users
    env_file="/etc/profile.d/proxy.sh"
    echo -e "export HTTP_PROXY=http://$proxy_address:$proxy_port\nexport HTTPS_PROXY=http://$proxy_address:$proxy_port\nexport SOCKS_PROXY=socks://$proxy_address:$socks_port" | sudo tee "$env_file"
    source "$env_file"
    log "System-wide environment variables configured."

    # Update PlayOnLinux environment
    playonlinux_script="/usr/local/bin/playonlinux"
    if [ ! -f "$playonlinux_script" ]; then
        sudo touch "$playonlinux_script"
    fi
    echo -e "#!/bin/bash\nexport HTTP_PROXY=\"http://$proxy_address:$proxy_port\"\nexport HTTPS_PROXY=\"http://$proxy_address:$proxy_port\"\nexport SOCKS_PROXY=\"socks://$proxy_address:$socks_port\"\nexec /usr/bin/playonlinux" | sudo tee "$playonlinux_script"
    sudo chmod +x "$playonlinux_script"
    log "PlayOnLinux proxy settings configured."

    # Configure curl system-wide
    curl_config_file="/etc/curl/curlrc"
    sudo mkdir -p "$(dirname "$curl_config_file")"
    echo "proxy = http://$proxy_address:$proxy_port" | sudo tee "$curl_config_file"
    log "curl proxy settings configured."

    # Configure wget system-wide
    wget_config_file="/etc/wgetrc"
    echo "http_proxy = http://$proxy_address:$proxy_port" | sudo tee "$wget_config_file"
    echo "https_proxy = http://$proxy_address:$proxy_port" | sudo tee -a "$wget_config_file"
    log "wget proxy settings configured."

    # Configure Python packages proxy
    pip_config_file="/etc/pip.conf"
    echo -e "[global]\nproxy = http://$proxy_address:$proxy_port" | sudo tee "$pip_config_file"
    log "Python proxy settings configured."

    # Configure system-wide environment variables for Python
    if grep -q "PYTHONHTTPPROXY" "$snap_proxy_file"; then
        sudo sed -i "s|PYTHONHTTPPROXY=.*|PYTHONHTTPPROXY=http://$proxy_address:$proxy_port|" "$snap_proxy_file"
    else
        echo "PYTHONHTTPPROXY=http://$proxy_address:$proxy_port" | sudo tee -a "$snap_proxy_file"
    fi
    log "Python system-wide environment variables configured."

    # Configure npm proxy settings
    npm_config_file="/etc/npmrc"
    echo "proxy=http://$proxy_address:$proxy_port" | sudo tee "$npm_config_file"
    echo "https-proxy=http://$proxy_address:$proxy_port" | sudo tee -a "$npm_config_file"
    log "npm proxy settings configured."

    # Configure GitHub proxy settings
    git config --global http.proxy "http://$proxy_address:$proxy_port"
    git config --global https.proxy "http://$proxy_address:$proxy_port"
    log "GitHub proxy settings configured."

    # Configure VSCode proxy settings
    vscode_settings_dir="$HOME/.config/Code/User"
    vscode_settings_file="$vscode_settings_dir/settings.json"
    sudo mkdir -p "$vscode_settings_dir"
    if [ ! -f "$vscode_settings_file" ]; then
        echo "{}" | sudo tee "$vscode_settings_file"
    fi
    sudo jq --arg http_proxy "http://$proxy_address:$proxy_port" \
        --arg https_proxy "http://$proxy_address:$proxy_port" \
        '. + {"http.proxy": $http_proxy, "https.proxy": $https_proxy}' "$vscode_settings_file" | sudo tee "$vscode_settings_file" > /dev/null
    log "VSCode proxy settings configured."

    # Configure ping command with proxy
    if [ ! -f "/usr/bin/tcpping" ]; then
        log "Installing tcpping to enable proxy for ping commands."
        sudo apt-get install tcpping -y
    fi

    # Set up alias for ping to use proxy
    echo "alias ping='tcpping $proxy_address'" | sudo tee -a /etc/bash.bashrc
    source /etc/bash.bashrc
    log "ping command alias configured with proxy."

    log "System-wide proxy settings have been set for APT, Docker, Snap Store, rkhunter, curl, wget, PlayOnLinux, Python packages, npm, GitHub, VSCode, and ping."
}

# Function to unset system-wide proxy
unset_proxy_system_wide() {
    log "Unsetting system-wide proxy settings."

    # Unset system-wide proxy for APT
    sudo rm -f /etc/apt/apt.conf
    log "APT proxy settings removed."

    # Unset system-wide proxy for Docker
    docker_config_file="/etc/systemd/system/docker.service.d/http-proxy.conf"
    if [ -f "$docker_config_file" ]; then
        sudo rm "$docker_config_file"
    fi
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    log "Docker proxy settings removed."

    # Remove Snap Store proxy settings
    snap_proxy_file="/etc/environment"
    sudo sed -i '/http_proxy/d' "$snap_proxy_file"
    sudo sed -i '/https_proxy/d' "$snap_proxy_file"
    sudo systemctl restart snapd
    log "Snap Store proxy settings removed."

    # Remove rkhunter proxy settings
    rkhunter_config_file="/etc/rkhunter.conf"
    sudo sed -i 's|^HTTP_PROXY=.*|HTTP_PROXY=|' "$rkhunter_config_file"
    sudo sed -i 's|^HTTPS_PROXY=.*|HTTPS_PROXY=|' "$rkhunter_config_file"
    log "rkhunter proxy settings removed."

    # Remove system-wide environment variables
    env_file="/etc/profile.d/proxy.sh"
    if [ -f "$env_file" ]; then
        sudo rm "$env_file"
    fi
    log "System-wide environment variables removed."

    # Remove PlayOnLinux environment script
    playonlinux_script="/usr/local/bin/playonlinux"
    if [ -f "$playonlinux_script" ]; then
        sudo rm "$playonlinux_script"
    fi
    log "PlayOnLinux proxy settings removed."

    # Unset curl system-wide
    curl_config_file="/etc/curl/curlrc"
    if [ -f "$curl_config_file" ]; then
        sudo rm "$curl_config_file"
    fi
    log "curl proxy settings removed."

    # Unset wget system-wide
    wget_config_file="/etc/wgetrc"
    if [ -f "$wget_config_file" ]; then
        sudo rm "$wget_config_file"
    fi
    log "wget proxy settings removed."

    # Unset Python proxy settings
    pip_config_file="/etc/pip.conf"
    if [ -f "$pip_config_file" ]; then
        sudo rm "$pip_config_file"
    fi
    log "Python proxy settings removed."

    # Unset npm proxy settings
    npm_config_file="/etc/npmrc"
    if [ -f "$npm_config_file" ]; then
        sudo rm "$npm_config_file"
    fi
    log "npm proxy settings removed."

    # Unset GitHub proxy settings
    git config --global --unset http.proxy
    git config --global --unset https.proxy
    log "GitHub proxy settings removed."

    # Unset VSCode proxy settings
    vscode_settings_file="$HOME/.config/Code/User/settings.json"
    if [ -f "$vscode_settings_file" ]; then
        sudo jq 'del(.["http.proxy", "https.proxy"])' "$vscode_settings_file" | sudo tee "$vscode_settings_file" > /dev/null
    fi
    log "VSCode proxy settings removed."

    # Remove ping command alias
    sudo sed -i '/alias ping/d' /etc/bash.bashrc
    source /etc/bash.bashrc
    log "ping command alias removed."

    log "System-wide proxy settings have been removed."
}

# Main script execution
echo "Choose an option:"
echo "1) Set system-wide proxy"
echo "2) Unset system-wide proxy"
read -r choice

case $choice in
    1)
        set_proxy_system_wide
        ;;
    2)
        unset_proxy_system_wide
        ;;
    *)
        log "Invalid option selected. Exiting."
        exit 1
        ;;
esac

