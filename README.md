# 🛡️ Proxy Configuration Script
![Main Image](https://www.google.com/url?sa=i&url=https%3A%2F%2Fwww.fortinet.com%2Fresources%2Fcyberglossary%2Fproxy-server&psig=AOvVaw2tcRX30N5RyQbg8S6ALKD-&ust=1724684666472000&source=images&cd=vfe&opi=89978449&ved=0CBEQjRxqFwoTCPD5y6a1kIgDFQAAAAAdAAAAABAE)

This Bash script simplifies the process of configuring system-wide proxy settings across various applications and services on Linux. It supports setting and unsetting proxies for tools like APT, Docker, Snap Store, PlayOnLinux, and more, ensuring seamless connectivity in restricted network environments.

## 🎯 Features

- **System-wide Proxy Setup**: Automatically configures proxies for:
  - APT (Advanced Package Tool)
  - Docker
  - Snap Store
  - PlayOnLinux
  - Curl and Wget
  - Python packages
  - npm
  - GitHub
  - Visual Studio Code
  - Ping command (via tcpping)

- **System-wide Proxy Removal**: Easily revert proxy settings to restore original configurations.

## 🛠️ Usage

Clone this repository or download the script directly, then execute it to set or unset your system-wide proxy:

```bash
./proxy_setup.sh
```

### Options

1. **Set System-wide Proxy**  
   Configure proxies for various applications and services.

2. **Unset System-wide Proxy**  
   Remove proxy settings and revert to default configurations.

### Example

When you run the script, you'll be prompted to enter the proxy server address, HTTP/HTTPS port, and SOCKS proxy port for SSH. The script will then configure the necessary settings automatically.

```bash
Choose an option:
1) Set system-wide proxy
2) Unset system-wide proxy
```

## 📁 Log Files

The script logs its actions to `/var/log/proxy_setup.log`, making it easy to trace the changes made and troubleshoot if needed.

## 💻 Prerequisites

- **Bash**: Ensure you are running this script in a Bash environment.
- **Sudo Permissions**: The script requires elevated privileges to modify system settings.

## 🚀 Installation

To make this script executable, run:

```bash
chmod +x proxy_setup.sh
```

Then execute it:

```bash
./proxy_setup.sh
```

## 📜 License

This script is released under the MIT License.

---
Author: NSANZIMANA RUGWIRO Dominique Parfait
