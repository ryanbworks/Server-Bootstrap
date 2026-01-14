#!/bin/bash

# Script de Setup DevOps - Foco: Aplot Cloud
# Sistema: Ubuntu Server 24.04 LTS
# Versão: 12.0 (Gold Master - Verified & Secure)

set -e

echo "------------------------------------------------"
echo "INICIANDO SETUP DEVOPS: APLOT CLOUD"
echo "------------------------------------------------"

# 0. CONFIGURAÇÃO DE CHAVE SSH (COM INSTRUÇÕES DIDÁTICAS)
echo "[0/12] Configuração de Acesso (Login Seguro)..."
echo "----------------------------------------------------------------"
echo "DICA IMPORTANTE: A chave SSH deve ser gerada no SEU COMPUTADOR."
echo "Abra outro terminal no seu PC e rode:"
echo ""
echo "   ssh-keygen -t ed25519 -C 'seu-email@exemplo.com'"
echo ""
echo "Depois, para ver o código da chave, rode no seu PC:"
echo "   cat ~/.ssh/id_ed25519.pub"
echo ""
echo "Copie o código que começa com 'ssh-ed25519' e volte aqui."
echo "----------------------------------------------------------------"

read -p "Você já copiou sua chave pública e quer colar agora? (s/n): " confirm_ssh
if [[ $confirm_ssh == [sS] ]]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    echo "Cole a chave pública inteira e aperte ENTER:"
    read ssh_key
    if [ -n "$ssh_key" ]; then
        echo "$ssh_key" >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
        echo "✅ Chave SSH salva com sucesso."
    else
        echo "⚠️ Nenhuma chave colada. Pulando etapa."
    fi
else
    echo "Pulando configuração de chave SSH."
fi

# 1. AJUSTE DE DATA E HORA
echo "[1/12] Sincronizando relógio (Timezone SP)..."
sudo timedatectl set-timezone America/Sao_Paulo
sudo timedatectl set-ntp true

# 2. ATUALIZAÇÃO GERAL
echo "[2/12] Atualizando repositórios e sistema..."
sudo apt update && sudo apt upgrade -y

# 3. SEGURANÇA (SSH HARDENING & FAIL2BAN)
echo "[3/12] Instalando Fail2Ban..."
sudo apt install fail2ban -y

echo "--- ATENÇÃO: Configuração do SSH ---"
read -p "Deseja desativar o login de ROOT e SENHAS (Requer Chave SSH)? (s/n): " lock_ssh

if [[ $lock_ssh == [sS] ]]; then
    # TRAVA DE SEGURANÇA: Só bloqueia senha se achar a chave
    if [ -s ~/.ssh/authorized_keys ]; then
        echo "🔒 Chave detectada. Aplicando blindagem máxima..."
        
        # Desativa Root
        sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
        sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
        
        # Desativa Senhas (SÓ COM CHAVE VALIDADA)
        sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
        sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
        
        sudo systemctl restart ssh
        echo "✅ SSH Reiniciado. Acesso apenas via Chave. Root bloqueado."
    else
        echo "❌ ERRO: Não encontrei chaves salvas!"
        echo "⚠️  SEGURANÇA ATIVADA: Não vou bloquear as senhas para você não perder o acesso."
    fi
else
    echo "Mantendo configurações padrão do SSH."
fi

# 4. FIREWALL UFW
read -p "[4/12] Ativar Firewall (SSH/HTTP/HTTPS)? (s/n): " confirm_ufw
if [[ $confirm_ufw == [sS] ]]; then
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow https
    sudo ufw --force enable
    echo "✅ Firewall ativo."
fi

# 5. OTIMIZAÇÃO KERNEL (8GB RAM)
echo "[5/12] Otimizando Kernel..."
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf
sudo sysctl -p > /dev/null
echo "✅ Otimizações aplicadas."

# 6. NETWORK HARDENING
echo "[6/12] Proteção contra IP Spoofing..."
cat << 'EOF' | sudo tee -a /etc/sysctl.d/99-security-hardening.conf
net.ipv4.conf.all.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_source_route = 0
EOF
sudo sysctl --system > /dev/null

# 7. MONITORAMENTO (BTOP)
echo "[7/12] Instalando Btop..."
sudo apt install btop -y

# 8. FERRAMENTAS EXTRAS (VISUAL & DISCO)
echo "[8/12] Instalando Kit DevOps (Rede + Visual)..."
read -p "Instalar Git, Ncdu, Fastfetch e Rede? (s/n): " confirm_tools
if [[ $confirm_tools == [sS] ]]; then
    sudo apt install git curl wget net-tools iputils-ping dnsutils ncdu fastfetch -y
    
    # Adiciona Fastfetch ao login
    if ! grep -q "fastfetch" ~/.bashrc; then
        echo -e "\n# Visual DevOps\nfastfetch" >> ~/.bashrc
    fi
    echo "✅ Ferramentas instaladas."
fi

# 9. MANUTENÇÃO AUTOMÁTICA
echo "[9/12] Ativando atualizações de segurança automáticas..."
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades

# 10. ESTRUTURA APLOT CLOUD
echo "[10/12] Criando pastas do projeto..."
mkdir -p ~/projects/aplot-cloud/{infra,app,logs,backups}

# 11. SWAP (2GB)
echo "[11/12] Verificando Swap..."
if [ ! -f /swapfile ]; then
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    echo "✅ Swap de 2GB criado."
fi

# 12. ALIASES & MENU
echo "[12/12] Configurando menu de atalhos..."
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

# Menu de Ajuda
alias atalhos='echo -e "\n🚀 ATALHOS APLOT CLOUD:\n----------------------\n g            : git\n b            : btop (Monitor)\n ll           : Listar arquivos\n up           : Atualizar Sistema\n ports        : Ver portas abertas\n disco        : Analisar disco (Ncdu)\n aplot        : Ir para projeto\n backup-aplot : Criar backup\n atalhos      : Mostrar essa lista\n"'
EOF
fi

echo "------------------------------------------------"
echo "🚀 SETUP APLOT CLOUD FINALIZADO!"
echo "------------------------------------------------"
echo "Agora digite: source ~/.bashrc"
echo "E teste o comando: atalhos"
echo "------------------------------------------------"
