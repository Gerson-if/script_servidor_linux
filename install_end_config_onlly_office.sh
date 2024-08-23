#!/bin/bash

LOG_FILE="onlyoffice_installation.log"

# Função para verificar erros e rastrear falhas, sem quebrar o script
check_error() {
    if [ $? -ne 0 ]; then
        echo "Erro durante: $1" | tee -a $LOG_FILE
        echo "Tentando corrigir o erro automaticamente..." | tee -a $LOG_FILE
        
        # Tentativa de correção automática (apt-get -f install)
        sudo apt-get -f install -y | tee -a $LOG_FILE
        if [ $? -ne 0 ]; then
            echo "Correção automática falhou para: $1" | tee -a $LOG_FILE
        else
            echo "Correção automática bem-sucedida para: $1" | tee -a $LOG_FILE
        fi
    fi
}

# Função para instalar comandos necessários, incluindo os mais básicos
install_prerequisites() {
    echo "Verificando e instalando comandos necessários..." | tee -a $LOG_FILE

    # Verifica e instala sudo se não estiver presente
    if ! command -v sudo &> /dev/null; then
        echo "Sudo não encontrado. Instalando sudo..." | tee -a $LOG_FILE
        apt-get update && apt-get install -y sudo | tee -a $LOG_FILE
        check_error "Instalação do sudo"
    fi

    # Verifica e instala o curl se não estiver presente
    if ! command -v curl &> /dev/null; then
        echo "Curl não encontrado. Instalando curl..." | tee -a $LOG_FILE
        sudo apt-get install -y curl | tee -a $LOG_FILE
        check_error "Instalação do curl"
    fi

    # Verifica e instala o gnupg2 se não estiver presente
    if ! command -v gpg &> /dev/null; then
        echo "GnuPG não encontrado. Instalando gnupg2..." | tee -a $LOG_FILE
        sudo apt-get install -y gnupg2 | tee -a $LOG_FILE
        check_error "Instalação do gnupg2"
    fi

    # Verifica e instala o apt-transport-https se não estiver presente
    if ! dpkg -s apt-transport-https &> /dev/null; then
        echo "Apt-transport-https não encontrado. Instalando apt-transport-https..." | tee -a $LOG_FILE
        sudo apt-get install -y apt-transport-https | tee -a $LOG_FILE
        check_error "Instalação do apt-transport-https"
    fi

    # Verifica e instala o lsb-release se não estiver presente
    if ! command -v lsb_release &> /dev/null; then
        echo "LSB Release não encontrado. Instalando lsb-release..." | tee -a $LOG_FILE
        sudo apt-get install -y lsb-release | tee -a $LOG_FILE
        check_error "Instalação do lsb-release"
    fi

    # Verifica e instala o ca-certificates se não estiver presente
    if ! dpkg -s ca-certificates &> /dev/null; then
        echo "CA Certificates não encontrado. Instalando ca-certificates..." | tee -a $LOG_FILE
        sudo apt-get install -y ca-certificates | tee -a $LOG_FILE
        check_error "Instalação do ca-certificates"
    fi

    echo "Todos os comandos necessários foram instalados ou já estavam presentes." | tee -a $LOG_FILE
}

# Menu de opções
menu() {
    echo "Selecione uma opção:"
    echo "1) Instalar ONLYOFFICE Document Server"
    echo "2) Remover ONLYOFFICE Document Server"
    echo "3) Sair"
    read -p "Opção: " option
    case $option in
        1) install_onlyoffice ;;
        2) remove_onlyoffice ;;
        3) exit 0 ;;
        *) echo "Opção inválida"; menu ;;
    esac
}

# Função de instalação
install_onlyoffice() {
    echo "Atualizando o sistema..." | tee -a $LOG_FILE
    sudo apt update && sudo apt upgrade -y | tee -a $LOG_FILE
    check_error "Atualização do sistema"

    echo "Instalando dependências..." | tee -a $LOG_FILE
    install_prerequisites
    sudo apt install -y curl gnupg2 | tee -a $LOG_FILE
    check_error "Instalação de dependências"

    echo "Adicionando o repositório ONLYOFFICE..." | tee -a $LOG_FILE
    curl -sSL https://download.onlyoffice.com/repo/onlyoffice.key | sudo apt-key add - | tee -a $LOG_FILE
    echo "deb https://download.onlyoffice.com/repo/debian squeeze main" | sudo tee /etc/apt/sources.list.d/onlyoffice.list | tee -a $LOG_FILE
    sudo apt update | tee -a $LOG_FILE
    check_error "Adição do repositório ONLYOFFICE"

    echo "Instalando o ONLYOFFICE Document Server..." | tee -a $LOG_FILE
    sudo apt install -y onlyoffice-documentserver | tee -a $LOG_FILE
    check_error "Instalação do ONLYOFFICE Document Server"

    echo "ONLYOFFICE Document Server instalado com sucesso!" | tee -a $LOG_FILE
}

# Função de remoção
remove_onlyoffice() {
    echo "Removendo ONLYOFFICE Document Server..." | tee -a $LOG_FILE
    sudo apt remove --purge -y onlyoffice-documentserver | tee -a $LOG_FILE
    sudo rm -rf /etc/onlyoffice /var/log/onlyoffice /var/lib/onlyoffice | tee -a $LOG_FILE
    check_error "Remoção do ONLYOFFICE Document Server"

    echo "ONLYOFFICE Document Server removido com sucesso!" | tee -a $LOG_FILE
}

# Execução do menu
menu
