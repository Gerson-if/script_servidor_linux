#!/bin/bash

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem Cor

# Função para exibir o menu
mostrar_menu() {
    clear
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${GREEN}🔹              MENU PRINCIPAL                 🔹${NC}"
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${YELLOW}1. Executar script de instalacao e configuracao do${NC}"
    echo -e "   ${BLUE}Apache e MariaDB${NC}"
    echo -e "${YELLOW}2. Listar arquivos no diretorio atual${NC}"
    echo -e "${YELLOW}3. Mostrar o uso do disco${NC}"
    echo -e "${YELLOW}4. Configurar painel admin do banco de dados${NC}"
    echo -e "${YELLOW}5. Sair${NC}"
    echo -e "${GREEN}==================================================${NC}"
    echo -n "Escolha uma opcao: "
}

# Função para ler a opção escolhida pelo usuário e executar a ação correspondente
processar_escolha() {
    local escolha
    read escolha
    case $escolha in
        1)
            echo -e "${RED}Executando script de configuração...${NC}"
            chmod 777 linux_config.sh
            sudo ./linux_config.sh
            ;;
        2) ls -l;;
        3) df -h;;
        4) 
            echo -e "${RED}Configurando painel admin do banco de dados...${NC}"
            sudo cp admin.php /var/www/html/
            sudo chmod 777 /var/www/html/admin.php
            echo "Painel admin configurado. Acesse usando: http://localhost/admin.php"
            echo "faca login com seu usuario root e sua senha que voce definiu"
            sleep 3
            ;;
        5) 
            echo "Saindo do programa..." 
            exit 0
            ;;
        *) echo -e "${RED}Opcao invalida! Tente novamente.${NC}";;
    esac
    echo ""
    read -p "Pressione qualquer tecla para continuar..." -n 1 -r
    echo
}

# Loop principal do programa
while true
do
    mostrar_menu
    processar_escolha
done
