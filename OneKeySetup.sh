#!/bin/bash

# 开启bbr加速
echo 'net.core.default_qdisc=fq' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Install vscode
sudo apt-get install wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
sudo apt install apt-transport-https
sudo apt update
sudo apt install code # or code-insiders

# Install docker and docker-compose
# Run the following command to uninstall all conflicting packages:
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo curl -L "https://github.com/docker/compose/releases/download/v2.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 为docker配置ipv6连接
sudo mkdir -p /etc/docker
echo '{
 "log-driver": "json-file",
 "log-opts": {
        "max-size": "20m",
        "max-file": "3"
 },
 "ipv6": true,
 "fixed-cidr-v6": "2001:db8:abc1::/64",  
 "experimental": true,
 "ip6tables": true
}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker

# Create Nginx Proxy Manager directories and YAML file
mkdir -p /root/docker-files/npm
cd /root/docker-files/npm
# mkdir -p /root/data/docker_data/npm/data
echo 'version: '3'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'  # 保持默认即可，不建议修改左侧的80
      - '2336:81'  # 冒号左边可以改成自己服务器未被占用的端口
      - '443:443' # 保持默认即可，不建议修改左侧的443
    volumes:
      - ./data:/data # 冒号左边可以改路径，现在是表示把数据存放在在当前文件夹下的 data 文件夹中
      - ./letsencrypt:/etc/letsencrypt  # 冒号左边可以改路径，现在是表示把数据存放在在当前文件夹下的 letsencrypt 文件夹中
' > /root/docker-files/npm/docker-compose.yaml
docker compose up -d


# Create portainer directories and YAML file
mkdir -p /root/docker-files/portainer
cd /root/docker-files/portainer
mkdir -p /root/data/docker_data/portainer/data
echo 'version: "3"
services:
  portainer:
    image: portainer/portainer:latest
    container_name: portainer
    ports:
      - "2335:9000"
    volumes:
      - /root/data/docker_data/portainer/data:/data
      - /var/run/docker.sock:/var/run/docker.sock' > /root/docker-files/portainer/docker-compose.yaml

docker compose up -d

# docker-files/qbittorrent
mkdir -p /root/docker-files/downloads
mkdir -p /root/docker-files/qbittorrent
cd /root/docker-files/qbittorrent
echo 'version: "2"
services:
  qbittorrent:
    image: linuxserver/qbittorrent
    container_name: qbittorrent
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai # 你的时区
      - UMASK_SET=022
      - WEBUI_PORT=2356 # 将此处修改成你欲使用的 WEB 管理平台端口 
    volumes:
      - ./config:/config # 绝对路径请修改为自己的config文件夹
      - /root/docker-files/downloads:/downloads # 绝对路径请修改为自己的downloads文件夹
    ports:
      - 6881:6881 
      - 6881:6881/udp
      - 2356:2356
    restart: unless-stopped
    network_mode: bridge' > docker-compose.yaml

docker compose up -d

docker exec qbittorrent ping6 -c4 youtube.com
