# Zero-Cost Backend Deployment Guide (Oracle Cloud)

This guide details how to deploy your anonymous backend on an **Oracle Cloud Always Free (Ampere A1)** instance.

## 1. Prerequisites
- **Oracle Cloud Account**: Sign up for the "Always Free" tier.
- **SSH Key**: Ensure you have an SSH key pair generated (`ssh-keygen -t ed25519`).
- **FileZilla / SCP**: To transfer files to the server.

## 2. Oracle Cloud Instance Setup
1. **Create Instance**:
   - Go to **Compute -> Instances -> Create Instance**.
   - **Image**: Ubuntu 22.04 Minimal (or latest).
   - **Shape**: Ampere (ARM64) - Select 4 OCPUs and 24 GB RAM (Maximize the free tier!).
   - **Networking**: Create a new VCN. Ensure it has a public IP.
   - **SSH Keys**: Upload your Public Key (`.pub`).
   - Click **Create**.

2. **Network Security (Ingress Rules)**:
   - Go to **VCN -> Security Lists**.
   - **Ingress Rules**:
     - Allow Port `22` (SSH).
     - **CRITICAL**: Do NOT open ports `80`, `443`, `1883`, or `5432` to the public internet (0.0.0.0/0).
     - **Tor Only**: Since we are using a Hidden Service, **NO inbound ports** need to be open besides SSH (and even SSH can be hidden behind Tor if you're paranoid).
     - *Exception*: If you use Coturn (WebRTC) without Tor for speed, you must open UDP `3478` and UDP range `49152–65535`.

## 3. Server Configuration

SSH into your server:
```bash
ssh ubuntu@<your-vps-public-ip>
```

### A. Install Docker & Docker Compose
Since this is an ARM64 (Ampere) instance, we need compatible images. (Most official images support ARM64).

```bash
# Update System
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
```
*Logout and login again to apply group changes.*

### B. Transfer Project Files
Copy the `backend/` folder from your local machine to the VPS.
```bash
# From your local machine
scp -r ./backend ubuntu@<your-vps-ip>:~/backend
```

### C. Directory Setup (On Server)
Ensure correct permissions for Tor and Mosquitto volumes.
```bash
cd ~/backend
mkdir -p tor_keys mosquitto_data mosquitto_log postgres_data
sudo chown -R 100:101 tor_keys # Tor usually runs as user 100/101 in Alpine
sudo chmod 700 tor_keys
```

## 4. Launching the Stack

Run the infrastructure:
```bash
docker-compose up -d
```

Check logs:
```bash
docker-compose logs -f
```

## 5. Retrieve Your Onion Address
Once Tor has started, it generates the hostname.

```bash
# Execute into the container to read the hostname
docker exec -it tor_hidden_service cat /var/lib/tor/hidden_service/hostname
```

**Output Example**: `vtwod4...raz7.onion`

### **COPY THIS ADDRESS.**
You must update your Flutter app's `TransportService` with this address.

## 6. Testing Connectivity
You cannot `curl` this address from the normal internet. You must use Tor.

**From your local machine (if Tor is installed):**
```bash
torify curl http://<your-onion-address>.onion
```
*(Note: Since we are exposing raw TCP (Mosquitto) and not HTTP on port 80 in the config, curl might fail unless you set up an HTTP adapter. For Mosquitto testing, use `mosquitto_pub` with SOCKS5 proxy).*

## 7. Operational Security (OpSec)
- **Firewall**: Enable `ufw` and only allow SSH.
  ```bash
  sudo ufw allow ssh
  sudo ufw enable
  ```
- **Updates**: Enable unattended-upgrades.
- **Backups**: Periodically backup `tor_keys` and `postgres_data`. If you lose `tor_keys`, your onion address changes forever.

---
**Done!** Your Zero-Cost, Anonymous Backend is live.
