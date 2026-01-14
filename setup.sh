#!/bin/bash

# Script de Setup DevOps - Foco: Aplot Cloud
# Sistema: Ubuntu Server 24.04 LTS (Minimal Proof)
# Versão: 16.0 (Robustez Total contra falhas de dependência)

set -e

echo "------------------------------------------------"
echo "INICIANDO SETUP DEVOPS: APLOT CLOUD"
echo "------------------------------------------------"

# 0. CONFIGURAÇÃO DE CHAVE SSH
echo "[0/13] Configuração de Acesso..."
echo "----------------------------------------------------------------"
echo "DICA: Gere a chave NO SEU COMPUTADOR:"
echo "ssh-keygen -t ed25519 -C 'seu-email'"
echo "Copie o conteúdo de: ~/.ssh/id_ed25519.pub"
echo "----------------------------------------------------------------"

read -p "Deseja colar sua Chave Pública agora? (s/n): " confirm_ssh
if [[ $confirm_ssh == [sS] ]]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    echo "Cole a chave pública e aperte ENTER:"
    read ssh_key
    if [ -n "$ssh_key" ]; then
        echo "$ssh_key" >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
        echo "✅ Chave SSH salva."
    else
        echo "⚠️ Nenhuma chave colada."
    fi
fi

# 1. AJUSTE DE DATA E HORA
echo "[1/13] Sincronizando relógio (SP)..."
sudo timedatectl set-timezone America/Sao_Paulo
sudo timedatectl set-ntp true

# 2. PREPARAÇÃO DO AMBIENTE (A VACINA CONTRA ERROS)
echo "[2/13] Preparando ambiente Minimal..."
echo "   - Atualizando lista de pacotes..."
sudo apt update -y

echo "   - Instalando gerenciador de repositórios..."
# Isso evita falha ao tentar adicionar repositórios
sudo apt install software-properties-common -y

echo "   - Ativando repositório Universe (Para Fastfetch/Ncdu)..."
# Isso evita o erro "Unable to locate package"
sudo add-apt-repository universe -y
sudo add-apt-repository multiverse -y

echo "   - Instalando ferramentas essenciais..."
# Garante que comandos básicos existam antes de serem usados
sudo apt install curl wget unzip git tar -y

echo "✅ Ambiente base preparado com sucesso."

# 3. SEGURANÇA SSH
echo "[3/13] Instalando Fail2Ban..."
sudo apt install fail2ban -y

echo "--- ATENÇÃO: Segurança SSH ---"
read -p "Deseja desativar ROOT e SENHAS (Requer Chave SSH)? (s/n): " lock_ssh
if [[ $lock_ssh == [sS] ]]; then
    if [ -s ~/.ssh/authorized_keys ]; then
        echo "🔒 Blindando SSH..."
        sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
        sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
        sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
        sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
        sudo systemctl restart ssh
        echo "✅ SSH Reiniciado e Seguro."
    else
        echo "❌ ERRO: Nenhuma chave encontrada! Abortando bloqueio."
    fi
fi

# 4. FIREWALL (UFW)
read -p "[4/13] Ativar Firewall (Recomendado)? (s/n): " confirm_ufw
if [[ $confirm_ufw == [sS] ]]; then
    echo "Verificando instalação do UFW..."
    # Verifica se o UFW existe, se não, instala
    if ! command -v ufw &> /dev/null; then
        echo "   - UFW não encontrado. Instalando..."
        sudo apt install ufw -y
    fi
    
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow https
    sudo ufw --force enable
    echo "✅ Firewall ativo."
fi

# 5. OTIMIZAÇÃO (KERNEL & HARDWARE)
echo "[5/13] Otimizando Sistema..."

# 5.1 MODO NOTEBOOK
read -p "Este servidor é um NOTEBOOK (Laptop)? (s/n): " is_laptop
if [[ $is_laptop == [sS] ]]; then
    echo "💻 Configurando para NÃO suspender ao fechar a tampa..."
    sudo sed -i 's/^#HandleLidSwitch=suspend/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
    sudo sed -i 's/^HandleLidSwitch=suspend/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
    sudo systemctl restart systemd-logind
    echo "✅ Modo 'Server Laptop' ativado!"
fi

# 5.2 OTIMIZAÇÃO RAM
echo "Aplicando otimização de Kernel..."
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf
sudo sysctl -p > /dev/null

# 6. NETWORK HARDENING
echo "[6/13] Proteção de Rede..."
cat << 'EOF' | sudo tee -a /etc/sysctl.d/99-security-hardening.conf
net.ipv4.conf.all.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_source_route = 0
EOF
sudo sysctl --system > /dev/null

# 7. MONITORAMENTO
echo "[7/13] Instalando Monitoramento..."
sudo apt install btop -y

# 8. FERRAMENTAS EXTRAS
echo "[8/13] Kit DevOps..."
read -p "Instalar Kit Completo (Ncdu, Fastfetch, Rede)? (s/n): " confirm_tools
if [[ $confirm_tools == [sS] ]]; then
    # Como já ativamos o Universe no passo 2, isso aqui VAI funcionar
    sudo apt install net-tools iputils-ping dnsutils ncdu fastfetch -y
    
    if ! grep -q "fastfetch" ~/.bashrc; then
        echo -e "\n# Visual\nfastfetch" >> ~/.bashrc
    fi
    echo "✅ Ferramentas instaladas."
fi

# 9. MANUTENÇÃO AUTOMÁTICA
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades

# 10. ESTRUTURA
mkdir -p ~/projects/aplot-cloud/{infra,app,logs,backups}

# 11. SWAP
if [ ! -f /swapfile ]; then
    echo "[11/13] Criando Swap de 2GB..."
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

# 12. ALIASES & MENU
echo "[12/13] Configurando menu..."
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
alias disco='ncdu /'
alias backup-aplot='tar -cvzf ~/projects/aplot-cloud/backups/backup-$(date +%F).tar.gz ~/projects/aplot-cloud/app'

# Menu
alias atalhos='echo -e "\n🚀 ATALHOS APLOT CLOUD:\n----------------------\n g            : git\n b            : btop\n up           : Atualizar tudo\n ports        : Ver portas\n disco        : Limpar disco\n aplot        : Ir para projeto\n atalhos      : Mostrar lista\n"'
EOF
fi

echo "------------------------------------------------"
echo "🚀 SETUP APLOT CLOUD FINALIZADO!"
echo "------------------------------------------------"
echo "Execute: source ~/.bashrc"
echo "------------------------------------------------"
