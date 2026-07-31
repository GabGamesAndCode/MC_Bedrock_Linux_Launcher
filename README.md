# MC Bedrock Linux Launcher (`mc-bedrock-launcher.sh`)

A smart and automated Bash script to install, update, and launch **BedrockOnLinux** seamlessly.

> *Note: This is an independent wrapper script and helper tool for [BedrockOnLinux](https://github.com/Wyze3306/BedrockOnLinux) created by Wyze3306.*

## What the script does

1. **Checks the installation** of BedrockOnLinux on the machine.
2. If it is not installed, it detects your distribution (Debian/Ubuntu/Mint via a `.deb` package or other distros via the AppImage) and automatically downloads the latest version from GitHub.
3. If it is already installed, it checks for updates (`bedrock-on-linux update`).
4. **Launches the game** (`bedrock-on-linux play`) automatically.

## Usage

1. Download or clone this repository, then place the `mc-bedrock-launcher.sh` script wherever you prefer.
2. Open a terminal in the script's directory and make it executable:
   ```bash
   chmod +x mc-bedrock-launcher.sh
   ```

3. Run the script:
   ```bash
   ./mc-bedrock-launcher.sh
   ```



## Required Dependencies

* `curl`
* `wget`
* `dpkg` (for Debian/Ubuntu/Mint-based systems)
<<<<<<< HEAD
=======

```
>>>>>>> 551192d (feat: add robust gpu crash handling and lockfile to launcher)
