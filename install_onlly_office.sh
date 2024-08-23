#!/bin/bash

# Função para exibir o menu
menu() {
    clear
    echo "====================================="
    echo "  ONLYOFFICE Document Server - Menu  "
    echo "====================================="
    echo "1. Instalar ONLYOFFICE Document Server"
    echo "2. Remover ONLYOFFICE Document Server"
    echo "3. Sair"
    echo "====================================="
    echo -n "Escolha uma opção: "
}

# Função para instalar ONLYOFFICE Document Server
instalar_onlyoffice() {
    echo "Instalando ONLYOFFICE Document Server..."
    sudo snap install onlyoffice-ds
    echo "Instalação concluída!"
    read -p "Pressione Enter para continuar..."
}

# Função para remover ONLYOFFICE Document Server
remover_onlyoffice() {
    echo "Removendo ONLYOFFICE Document Server..."
    sudo snap remove onlyoffice-ds
    echo "Remoção concluída!"
    read -p "Pressione Enter para continuar..."
}

# Loop principal do menu
while true; do
    menu
    read opcao
    case $opcao in
        1)
            instalar_onlyoffice
            ;;
        2)
            remover_onlyoffice
            ;;
        3)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida! Tente novamente."
            read -p "Pressione Enter para continuar..."
            ;;
    esac
done
