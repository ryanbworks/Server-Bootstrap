#!/bin/bash

# Script de Setup DevOps - Foco: Aplot Cloud
# Sistema: Ubuntu Server 24.04 LTS

set -e

echo "------------------------------------------------"
echo "INICIANDO SETUP DEVOPS PARA APLOT CLOUD"
echo "------------------------------------------------"

# 1. ATUALIZAÇÃO GERAL
echo "[1/6] Atualizando repositórios e pacotes do sistema..."
sudo apt update && sudo apt upgrade -y

# 2. FIREWALL UFW
read -p "[2/6] Deseja configurar o Firewall (SSH/HTTP/HTTPS)? (s/n): " confirm_ufw
if [[ $confirm_ufw == [sS] ]]; then
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow https
    sudo ufw --force enable
    echo "Firewall ativado!"
else
    echo "Pulando Firewall."
fi

# 3. DOCKER
echo "[3/6] Pulando instalação do Docker."

# 4. DOCKER COMPOSE
echo "[4/6] Pulando instalação do Docker Compose."

# 5. BTOP
echo "[5/6] Instalando BTOP para monitoramento..."
sudo apt install btop -y

# 6. FERRAMENTAS DE REDE
echo "------------------------------------------------"
echo "FERRAMENTAS DE REDE EXPLICAÇÃO:"
echo " - CURL/WGET: Downloads e testes de API."
echo " - NET-TOOLS: Comando netstat para ver portas."
echo " - IPUTILS-PING: Testar latência e conexão."
echo " - DNSUTILS: Comando dig para domínios."
echo "------------------------------------------------"
read -p "[6/6] Deseja instalar o kit de ferramentas de rede? (s/n): " confirm_net
if [[ $confirm_net == [sS] ]]; then
    sudo apt install curl wget net-tools iputils-ping dnsutils -y
    echo "Ferramentas de rede instaladas!"
else
    echo "Pulando ferramentas de rede."
fi

# EXTRAS
echo "------------------------------------------------"
echo "CONFIGURANDO EXTRAS (SWAP, PASTAS E ATALHOS)"
echo "------------------------------------------------"

# Swap de 2GB
if [ ! -f /swapfile ]; then
    echo "Criando arquivo de Swap..."
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

# Estrutura Aplot Cloud
mkdir -p ~/projects/aplot-cloud/{infra,app,logs,deploy}

# Aliases
if ! grep -q "Aliases DevOps" ~/.bashrc; then
cat << 'EOF' >> ~/.bashrc

# Aliases DevOps Aplot Cloud
alias g='git'
alias b='btop'
alias ll='ls -lah'
alias myip='curl ifconfig.me'
alias up='sudo apt update && sudo apt upgrade -y'
alias ports='sudo netstat -tpln'
alias aplot='cd ~/projects/aplot-cloud'
EOF
fi

echo "------------------------------------------------"
echo "SETUP FINALIZADO PARA APLOT CLOUD!"
echo "Execute: source ~/.bashrc"
echo "------------------------------------------------"
