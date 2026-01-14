# Aplot-Server-Bootstrap

Um script de automação para preparar servidores Ubuntu Server 24.04 LTS focado no ecossistema Aplot Cloud. 

Este projeto transforma uma instalação limpa do Ubuntu em um ambiente pronto para DevOps em segundos, otimizando o uso de hardware.

## Funcionalidades

- Otimização de Memória: Configuração automática de 2GB de Swap.
- Segurança: Configuração rápida de Firewall (UFW) para SSH, HTTP e HTTPS.
- Monitoramento: Instalação do btop para performance em tempo real.
- Organização: Criação da estrutura de diretórios para o projeto Aplot Cloud.
- Produtividade: Inclusão de Aliases (atalhos) estratégicos.

## Como usar

1. Atualize o seu terminal para ativar os atalhos:
   source ~/.bashrc

## Atalhos incluídos (Aliases)

- g: Atalho para Git
- up: Atualização completa do sistema
- b: Monitor de recursos btop
- ports: Lista portas e serviços em uso
- aplot: Pula direto para a pasta do projeto
- myip: Mostra seu IP público
